const crypto = require("crypto");

/**
 * Text inside the first <tag>...</tag> of [xml], CDATA unwrapped.
 * @param {string} xml An item's XML.
 * @param {string} tag Tag name, e.g. "content:encoded".
 * @return {string} The raw inner text, or "".
 */
function tagText(xml, tag) {
  const name = tag.replace(":", "\\:");
  const match = new RegExp(`<${name}(?:\\s[^>]*)?>([\\s\\S]*?)</${name}>`, "i")
      .exec(xml);
  if (!match) return "";
  return match[1].replace(/^\s*<!\[CDATA\[([\s\S]*?)\]\]>\s*$/, "$1").trim();
}

/**
 * Plain text from HTML: tags removed, common entities decoded, spaces
 * collapsed.
 * @param {string} html Some HTML.
 * @return {string} Plain text.
 */
function htmlToText(html) {
  return String(html || "")
      .replace(/<(script|style)[\s\S]*?<\/\1>/gi, " ")
      .replace(/<br\s*\/?>|<\/(p|div|li|h\d)>/gi, "\n")
      .replace(/<[^>]+>/g, " ")
      .replace(/&nbsp;/g, " ")
      .replace(/&amp;/g, "&")
      .replace(/&lt;/g, "<")
      .replace(/&gt;/g, ">")
      .replace(/&quot;/g, "\"")
      .replace(/&#0*39;|&apos;/g, "'")
      .replace(/&#(\d+);/g, (_, n) => String.fromCodePoint(Number(n)))
      .replace(/[ \t]+/g, " ")
      .replace(/\s*\n\s*/g, "\n")
      .trim();
}

/**
 * Items of an RSS 2.0 or Atom feed (WordPress /feed URLs are RSS 2.0).
 * @param {string} xml The feed.
 * @return {Array<object>} {title, link, text, published (ms or null)}.
 */
function parseFeed(xml) {
  const blocks = String(xml || "")
      .match(/<(item|entry)(?:\s[^>]*)?>[\s\S]*?<\/\1>/gi) || [];
  return blocks.map((block) => {
    let link = htmlToText(tagText(block, "link"));
    if (!link) {
      const href = /<link\b[^>]*\bhref="([^"]+)"/i.exec(block);
      link = href ? href[1] : "";
    }
    const body = tagText(block, "content:encoded") ||
      tagText(block, "content") || tagText(block, "description") ||
      tagText(block, "summary");
    const date = tagText(block, "pubDate") || tagText(block, "published") ||
      tagText(block, "updated");
    const published = Date.parse(date);
    return {
      title: htmlToText(tagText(block, "title")),
      link: link.trim(),
      text: htmlToText(body),
      published: isNaN(published) ? null : published,
    };
  }).filter((item) => /^https?:\/\//i.test(item.link));
}

/**
 * The URL used for dedupe: no hash, no utm_* parameters, no trailing slash.
 * @param {string} url A link.
 * @return {string} The normalized URL, or "" when it is not http(s).
 */
function normalizeUrl(url) {
  let parsed;
  try {
    parsed = new URL(String(url).trim());
  } catch (e) {
    return "";
  }
  if (!["http:", "https:"].includes(parsed.protocol)) return "";
  parsed.hash = "";
  for (const key of [...parsed.searchParams.keys()]) {
    if (key.toLowerCase().startsWith("utm_")) parsed.searchParams.delete(key);
  }
  return parsed.toString().replace(/\/$/, "");
}

/**
 * pendingOpportunities doc id for a source URL.
 * @param {string} url A normalized URL.
 * @return {string} A stable id.
 */
function pendingId(url) {
  return crypto.createHash("sha1").update(url).digest("hex");
}

module.exports = {tagText, htmlToText, parseFeed, normalizeUrl, pendingId};
