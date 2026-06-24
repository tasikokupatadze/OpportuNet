const {setGlobalOptions} = require("firebase-functions/v2");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const axios = require("axios");
const cors = require("cors")({origin: true});
const {defineSecret} = require("firebase-functions/params");

const GROQ_API_KEY = defineSecret("GROQ_API_KEY");


setGlobalOptions({maxInstances: 10});

exports.callAI = onRequest(
    {secrets: [GROQ_API_KEY]},
    async (req, res) => {
      await new Promise((resolve, reject) => {
        cors(req, res, (err) => {
          if (err) reject(err);
          else resolve();
        });
      });
      try {
        const key = GROQ_API_KEY.value();
        if (!key) {
          return res.status(500).json({error: "Missing GROQ API key"});
        }
        const messages = req.body.messages;
        const temperature = req.body.temperature || 0.7;
        const response = await axios.post(
            "https://api.groq.com/openai/v1/chat/completions",
            {
              model: "llama-3.3-70b-versatile",
              messages: messages,
              temperature: temperature,
            },
            {
              headers: {
                "Authorization": `Bearer ${key}`,
                "Content-Type": "application/json",
              },
            },
        );
        res.json(response.data);
      } catch (error) {
        logger.error(
            (error.response && error.response.data) || error.message,
        );
        res.status(500).json({
          status: error.response && error.response.status,
          data: error.response && error.response.data,
          hasKey: !!GROQ_API_KEY.value(),
        });
      }
    });
