const TYPES = ["view", "save", "share"];
const SECTIONS = ["olympiads", "volunteering", "exchange"];

/**
 * Today's date in Georgia (UTC+4 all year) as YYYY-MM-DD, the same day
 * boundary the app uses for event ids.
 * @param {Date} now The current time.
 * @return {string} The Tbilisi calendar day.
 */
function tbilisiDay(now) {
  return new Date(now.getTime() + 4 * 3600 * 1000).toISOString().slice(0, 10);
}

/**
 * Adds up event docs into per-opportunity, per-day counts. Malformed
 * events are skipped (they are still deleted by the caller).
 * @param {Array<object>} events Event doc data.
 * @return {Map<string, object>} statsId -> {section, opportunityId, days}.
 */
function groupEvents(events) {
  const stats = new Map();
  for (const e of events) {
    if (!e || !TYPES.includes(e.type) || !SECTIONS.includes(e.section)) {
      continue;
    }
    if (typeof e.opportunityId !== "string" || !e.opportunityId) continue;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(e.day || "")) continue;

    const id = `${e.section}_${e.opportunityId}`;
    if (!stats.has(id)) {
      stats.set(id, {
        section: e.section, opportunityId: e.opportunityId, days: {},
      });
    }
    const days = stats.get(id).days;
    days[e.day] = days[e.day] || {};
    days[e.day][e.type] = (days[e.day][e.type] || 0) + 1;
  }
  return stats;
}

/**
 * Day keys older than [keepDays] before [today], to drop from a stats doc.
 * @param {object} days The stats doc's days map.
 * @param {string} today YYYY-MM-DD.
 * @param {number} keepDays How many days to keep.
 * @return {Array<string>} Day keys to delete.
 */
function expiredDays(days, today, keepDays) {
  const cutoff = new Date(`${today}T00:00:00Z`);
  cutoff.setUTCDate(cutoff.getUTCDate() - keepDays);
  const limit = cutoff.toISOString().slice(0, 10);
  return Object.keys(days || {}).filter((day) => day < limit);
}

module.exports = {TYPES, SECTIONS, tbilisiDay, groupEvents, expiredDays};
