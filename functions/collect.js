const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");
const {parseFeed, normalizeUrl, pendingId} = require("./collect-logic");
const {draftMessages, parseDraft} = require("./opportunity-prompt");
const {tbilisiDay} = require("./stats-logic");

const MAX_SOURCES = 20;
const MAX_NEW_PER_SOURCE = 5;
const MAX_NEW_PER_RUN = 25;
const SECTIONS = ["olympiads", "volunteering", "exchange"];

/**
 * Asks Groq to turn one article into listing fields.
 * @param {string} key The Groq API key.
 * @param {string} text The article text.
 * @param {string} today YYYY-MM-DD.
 * @return {Promise<object|null>} The parsed draft, or null.
 */
async function draftFromText(key, text, today) {
  const response = await axios.post(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        model: "openai/gpt-oss-120b",
        messages: draftMessages(text, today),
        temperature: 0.1,
      },
      {
        headers: {
          "Authorization": `Bearer ${key}`,
          "Content-Type": "application/json",
        },
        timeout: 60000,
      },
  );
  const choice = response.data && response.data.choices &&
    response.data.choices[0];
  return parseDraft(choice && choice.message && choice.message.content);
}

/**
 * Links and websites of everything already published, for dedupe.
 * @param {object} db Firestore.
 * @return {Promise<Set<string>>} Normalized URLs.
 */
async function publishedUrls(db) {
  const urls = new Set();
  for (const section of SECTIONS) {
    const snap = await db.collection(section).select("website", "sourceUrl")
        .get();
    for (const doc of snap.docs) {
      for (const field of ["website", "sourceUrl"]) {
        const url = normalizeUrl(doc.get(field) || "");
        if (url) urls.add(url);
      }
    }
  }
  return urls;
}

/**
 * Daily: reads the organizers' RSS sources, drafts new articles with AI and
 * queues them in pendingOpportunities for review. Never publishes.
 * @param {string} key The Groq API key.
 * @return {Promise<object>} Counts for the log.
 */
async function collect(key) {
  const db = admin.firestore();
  const {FieldValue, Timestamp} = admin.firestore;
  const today = tbilisiDay(new Date());
  const published = await publishedUrls(db);
  const sources = await db.collection("opportunitySources")
      .where("enabled", "==", true).limit(MAX_SOURCES).get();
  let queued = 0;
  let skipped = 0;

  for (const source of sources.docs) {
    let fresh = 0;
    let error = "";
    try {
      const feed = await axios.get(source.get("feedUrl"), {
        timeout: 15000,
        maxContentLength: 2 * 1024 * 1024,
        responseType: "text",
        headers: {"User-Agent": "OpportuNet feed reader"},
      });
      for (const item of parseFeed(feed.data)) {
        if (fresh >= MAX_NEW_PER_SOURCE || queued >= MAX_NEW_PER_RUN) break;
        const url = normalizeUrl(item.link);
        if (!url || published.has(url)) continue;
        const ref = db.collection("pendingOpportunities").doc(pendingId(url));
        if ((await ref.get()).exists) continue;

        fresh++;
        const text = `${item.title}\n\n${item.text}\n\nSource: ${url}`;
        const draft = await draftFromText(key, text, today);
        const isListing = draft && draft.title && draft.category;
        if (!isListing) skipped++;
        else queued++;
        const deadline = draft && draft.deadline ?
          Timestamp.fromDate(new Date(`${draft.deadline}T00:00:00Z`)) : null;
        // Skipped articles are stored too, so they are not drafted again.
        await ref.create({
          ...(draft || {}),
          deadline,
          status: isListing ? "pending" : "skipped",
          sourceUrl: url,
          sourceTitle: item.title.slice(0, 200),
          sourceId: source.id,
          sourceName: String(source.get("name") || "").slice(0, 100),
          createdAt: FieldValue.serverTimestamp(),
        });
      }
    } catch (err) {
      error = String(err.message || err).slice(0, 300);
      logger.warn("Opportunity source failed.", {source: source.id, error});
    }
    await source.ref.update({
      lastCheckedAt: FieldValue.serverTimestamp(),
      lastError: error,
      lastNewCount: fresh,
    });
  }
  return {sources: sources.size, queued, skipped};
}

/**
 * Exports the scheduled job; the Groq secret comes from index.js.
 * @param {object} secret The GROQ_API_KEY secret param.
 * @return {object} The scheduled function.
 */
function collectOpportunitiesJob(secret) {
  return onSchedule({
    schedule: "every day 06:00",
    timeZone: "Asia/Tbilisi",
    timeoutSeconds: 540,
    secrets: [secret],
  }, async () => {
    const counts = await collect(secret.value());
    logger.info("Opportunity collection done.", counts);
  });
}

module.exports = {collectOpportunitiesJob};
