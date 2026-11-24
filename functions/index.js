const {setGlobalOptions} = require("firebase-functions/v2");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const axios = require("axios");
const cors = require("cors")({origin: true});
const {defineSecret} = require("firebase-functions/params");

const GROQ_API_KEY = defineSecret("GROQ_API_KEY");

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

// shortcut: requests without a token are still allowed so the Play Store
// version from before this change keeps working. Flip to true once most
// users have updated (check the "callAI without token" log line).
const REQUIRE_AUTH = false;

const MAX_MESSAGES = 30;
const MAX_TOTAL_CHARS = 80000;

/**
 * Returns the caller's uid, null when no token was sent, or throws when a
 * token was sent but is invalid.
 * @param {object} req The incoming request.
 * @return {Promise<string|null>} The verified uid or null.
 */
async function callerUid(req) {
  const header = req.get("Authorization") || "";
  if (!header.startsWith("Bearer ")) return null;
  const decoded = await admin.auth().verifyIdToken(header.slice(7));
  return decoded.uid;
}

/**
 * Checks the chat messages the app sends before they reach Groq.
 * @param {*} messages The request's messages field.
 * @return {boolean} Whether the messages are a reasonable chat.
 */
function validMessages(messages) {
  if (!Array.isArray(messages) || messages.length === 0) return false;
  if (messages.length > MAX_MESSAGES) return false;
  let total = 0;
  for (const m of messages) {
    if (!m || typeof m.content !== "string") return false;
    if (!["system", "user", "assistant"].includes(m.role)) return false;
    total += m.content.length;
  }
  return total <= MAX_TOTAL_CHARS;
}

exports.callAI = onRequest(
    {secrets: [GROQ_API_KEY]},
    async (req, res) => {
      await new Promise((resolve, reject) => {
        cors(req, res, (err) => {
          if (err) reject(err);
          else resolve();
        });
      });

      if (req.method !== "POST") {
        return res.status(405).json({error: "Use POST"});
      }

      let uid;
      try {
        uid = await callerUid(req);
      } catch (err) {
        return res.status(401).json({error: "Invalid sign-in token"});
      }
      if (!uid) {
        if (REQUIRE_AUTH) {
          return res.status(401).json({error: "Sign in required"});
        }
        logger.warn("callAI without token");
      }

      const messages = req.body && req.body.messages;
      if (!validMessages(messages)) {
        return res.status(400).json({error: "Invalid messages"});
      }
      const t = Number(req.body.temperature);
      const temperature = t >= 0 && t <= 1.5 ? t : 0.7;

      try {
        const key = GROQ_API_KEY.value();
        if (!key) {
          logger.error("Missing GROQ API key");
          return res.status(500).json({error: "AI is not configured"});
        }
        const response = await axios.post(
            "https://api.groq.com/openai/v1/chat/completions",
            {
              model: "openai/gpt-oss-120b",
              messages: messages,
              temperature: temperature,
            },
            {
              headers: {
                "Authorization": `Bearer ${key}`,
                "Content-Type": "application/json",
              },
              timeout: 60000,
            },
        );
        res.json(response.data);
      } catch (error) {
        logger.error(
            (error.response && error.response.data) || error.message,
            {uid},
        );
        // Details stay in the logs; the app only needs to know it failed.
        res.status(502).json({error: "AI request failed"});
      }
    });
