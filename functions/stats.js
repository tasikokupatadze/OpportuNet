const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const {tbilisiDay, groupEvents, expiredDays} = require("./stats-logic");

const KEEP_DAYS = 60;

/**
 * Nightly: folds opportunityEvents from before today (Tbilisi) into
 * opportunityStats/{section_id}.days[YYYY-MM-DD] and deletes them. Each
 * page's increments and deletes go in one batch, so a retry never counts
 * an event twice.
 */
exports.aggregateOpportunityStats = onSchedule({
  schedule: "every day 03:00",
  timeZone: "Asia/Tbilisi",
  timeoutSeconds: 540,
}, async () => {
  const db = admin.firestore();
  const {FieldValue} = admin.firestore;
  const today = tbilisiDay(new Date());
  const touched = new Set();
  let events = 0;

  for (;;) {
    const page = await db.collection("opportunityEvents")
        .where("day", "<", today).limit(200).get();
    if (page.empty) break;

    const batch = db.batch();
    for (const [id, stat] of groupEvents(page.docs.map((d) => d.data()))) {
      const days = {};
      for (const [day, counts] of Object.entries(stat.days)) {
        days[day] = {};
        for (const [type, n] of Object.entries(counts)) {
          days[day][type] = FieldValue.increment(n);
        }
      }
      batch.set(db.collection("opportunityStats").doc(id), {
        section: stat.section,
        opportunityId: stat.opportunityId,
        days,
        updatedAt: FieldValue.serverTimestamp(),
      }, {merge: true});
      touched.add(id);
    }
    for (const doc of page.docs) batch.delete(doc.ref);
    await batch.commit();
    events += page.size;
  }

  // Keep the days map small: the screen shows at most 30 days.
  for (const id of touched) {
    const ref = db.collection("opportunityStats").doc(id);
    const old = expiredDays((await ref.get()).get("days"), today, KEEP_DAYS);
    if (old.length) {
      await ref.update(Object.fromEntries(
          old.map((day) => [`days.${day}`, FieldValue.delete()])));
    }
  }

  logger.info("Opportunity stats aggregated.", {events, docs: touched.size});
});
