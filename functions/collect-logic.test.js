const test = require("node:test");
const assert = require("node:assert");
const {parseFeed, normalizeUrl, pendingId} = require("./collect-logic");
const {parseDraft} = require("./opportunity-prompt");

const rss = `<?xml version="1.0"?><rss><channel>
<title>Site</title>
<item>
  <title>Math Olympiad 2027 &amp; more</title>
  <link>https://example.org/math-2027/?utm_source=rss</link>
  <pubDate>Mon, 23 Nov 2026 10:00:00 +0000</pubDate>
  <description><![CDATA[<p>Short</p>]]></description>
  <content:encoded><![CDATA[<p>Apply by <b>1 March</b>.</p>` +
  `<p>Ages 14-18.</p>]]></content:encoded>
</item>
<item><title>No link</title></item>
</channel></rss>`;

test("reads RSS items with full content and drops linkless ones", () => {
  const items = parseFeed(rss);
  assert.strictEqual(items.length, 1);
  assert.strictEqual(items[0].title, "Math Olympiad 2027 & more");
  assert.strictEqual(items[0].text, "Apply by 1 March .\nAges 14-18.");
  assert.ok(items[0].published > 0);
});

test("reads Atom entries", () => {
  const items = parseFeed(`<feed><entry><title>A</title>
    <link href="https://example.org/a"/><summary>Hi</summary></entry></feed>`);
  assert.deepStrictEqual(items.map((i) => i.link), ["https://example.org/a"]);
});

test("normalizes URLs for dedupe", () => {
  assert.strictEqual(
      normalizeUrl("https://example.org/math-2027/?utm_source=rss#top"),
      "https://example.org/math-2027");
  assert.strictEqual(normalizeUrl("javascript:alert(1)"), "");
  assert.strictEqual(pendingId("https://a.org/x"), pendingId("https://a.org/x"));
});

test("parseDraft keeps valid fields and blanks the rest", () => {
  const draft = parseDraft("Sure!\n```json\n" + JSON.stringify({
    title: "Math Olympiad",
    category: "Olympiads",
    subjects: ["maths", "cooking"],
    website: "ftp://bad",
    deadline: "1 March",
    cost: "Free",
  }) + "\n```");
  assert.strictEqual(draft.title, "Math Olympiad");
  assert.strictEqual(draft.category, "olympiads");
  assert.deepStrictEqual(draft.subjects, ["Maths"]);
  assert.strictEqual(draft.website, "");
  assert.strictEqual(draft.deadline, "");
  assert.strictEqual(parseDraft("no json"), null);
});
