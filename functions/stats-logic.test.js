const test = require("node:test");
const assert = require("node:assert");
const {tbilisiDay, groupEvents, expiredDays} = require("./stats-logic");

test("uses the Tbilisi day, not UTC", () => {
  assert.strictEqual(tbilisiDay(new Date("2026-11-24T21:00:00Z")),
      "2026-11-25");
  assert.strictEqual(tbilisiDay(new Date("2026-11-24T19:59:00Z")),
      "2026-11-24");
});

test("groups events per opportunity, day and type", () => {
  const e = (type, id, day) => ({
    type, section: "olympiads", opportunityId: id, day,
  });
  const stats = groupEvents([
    e("view", "a", "2026-11-23"),
    e("view", "a", "2026-11-23"),
    e("save", "a", "2026-11-23"),
    e("view", "a", "2026-11-22"),
    e("share", "b", "2026-11-23"),
  ]);
  assert.deepStrictEqual(stats.get("olympiads_a").days, {
    "2026-11-23": {view: 2, save: 1},
    "2026-11-22": {view: 1},
  });
  assert.deepStrictEqual(stats.get("olympiads_b").days,
      {"2026-11-23": {share: 1}});
});

test("skips malformed events", () => {
  const stats = groupEvents([
    {type: "like", section: "olympiads", opportunityId: "a",
      day: "2026-11-23"},
    {type: "view", section: "posts", opportunityId: "a", day: "2026-11-23"},
    {type: "view", section: "olympiads", opportunityId: "", day: "x"},
    null,
  ]);
  assert.strictEqual(stats.size, 0);
});

test("expires days older than the window", () => {
  assert.deepStrictEqual(
      expiredDays({"2026-09-01": {}, "2026-11-01": {}}, "2026-11-24", 60),
      ["2026-09-01"]);
});
