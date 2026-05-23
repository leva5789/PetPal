const functions = require("firebase-functions");
const axios = require("axios");
const cors = require("cors")({ origin: true }); // Automatically allow all origins
const admin = require("firebase-admin");

admin.initializeApp();

// Kategória kulcsok, amikkel dolgozunk
const CATEGORY_KEYS = [
  "walk",              // séta, mozgatás
  "vet",               // állatorvos, oltás, kontroll
  "feeding",           // etetés
  "watering",          // itatás
  "grooming",          // fürdetés, szőr/karma ápolás
  "training",          // tanítás, tréning
  "play",              // játék
  "medication",        // gyógyszeres kezelés
  "cleaning",          // fekhely/tál tisztítása
  "shopping",          // kutya cuccok vásárlása
  "multi_pet",         // több állatot érintő dolog
  "other_pet_related", // egyéb állatos feladat
  "not_understood",    // értelmezhetetlen / random szöveg
];

exports.petpalChat = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const userMessage = req.body.message;
      if (!userMessage || typeof userMessage !== "string") {
        res.status(400).json({ error: "Missing or invalid 'message' field" });
        return;
      }

      // TODO: Move to Google Secret Manager for production security
      const OPENAI_KEY = process.env.OPENAI_API_KEY || "YOUR_OPENAI_API_KEY_HERE";
      if (!OPENAI_KEY) {
        console.error("Missing OpenAI key in code");
        res.status(500).json({ error: "Server config error: missing OpenAI key" });
        return;
      }

      const openaiRes = await axios.post(
        "https://api.openai.com/v1/chat/completions",
        {
          model: "gpt-4.1-mini",
          messages: [
            {
              role: "system",
              content:
                "You are a helpful assistant specialized in pet care and solving pet-related problems. Please answer only questions related to pet care.",
            },
            { role: "user", content: userMessage },
          ],
        },
        {
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${OPENAI_KEY}`,
          },
        }
      );

      const aiText = openaiRes.data.choices?.[0]?.message?.content || "";
      res.status(200).json({ reply: aiText });
    } catch (err) {
      const status = err.response?.status || 500;
      const data = err.response?.data || err.message || String(err);
      console.error("OpenAI error:", data);
      res.status(status).json({
        error: "OpenAI request failed",
        details: data,
      });
    }
  });
});

exports.categorizeTask = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const description = req.body.description;
      if (!description || typeof description !== "string") {
        res.status(400).json({ error: "Missing or invalid 'description' field" });
        return;
      }

      // TODO: Move to Google Secret Manager for production security
      const OPENAI_KEY = process.env.OPENAI_API_KEY || "YOUR_OPENAI_API_KEY_HERE";
      if (!OPENAI_KEY) {
        console.error("Missing OpenAI key in code");
        res.status(500).json({ error: "Server config error: missing OpenAI key" });
        return;
      }

      const prompt = `
You are a classifier for dog-care tasks.

You receive a short Hungarian or English description about a dog-related task.
Your job is to choose EXACTLY ONE category key from this list:

- walk: walking the dog, going for a walk, running, park walk, exercise outside
- vet: vet visit, vaccination, check-up, medical examination
- feeding: feeding the dog, giving food, breakfast/dinner, treats if it's mainly feeding
- watering: giving water, refilling water bowl
- grooming: bathing, brushing fur, nail cutting, grooming, hair trimming
- training: obedience training, trick training, school, learning commands
- play: playing with the dog, playing ball, tug of war, general playtime
- medication: giving medicine, drops, ointment, pills, ongoing treatment
- cleaning: washing dog bed, cleaning bowls, cleaning crate, cleaning dog items
- shopping: buying dog food, buying toys, buying accessories
- multi_pet: task that clearly involves multiple pets (e.g. walking all dogs)
- other_pet_related: dog-care related task that does not clearly fit the above categories
- not_understood: description is nonsense, unrelated, or cannot be interpreted (e.g. "afsfhjdasfsb")

Rules:
- Answer with ONLY the category key (e.g. walk, vet, not_understood).
- No extra text, no explanation.
- If the description looks random or not understandable, use "not_understood".

Description: "${description}"
`;

      const openaiRes = await axios.post(
        "https://api.openai.com/v1/chat/completions",
        {
          model: "gpt-4.1-mini",
          messages: [
            {
              role: "system",
              content: "You are a strict JSON-free classifier. You answer with one category key only.",
            },
            {
              role: "user",
              content: prompt,
            },
          ],
          temperature: 0,
        },
        {
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${OPENAI_KEY}`,
          },
        }
      );

      let category =
        openaiRes.data?.choices?.[0]?.message?.content?.trim().toLowerCase() ||
        "not_understood";

      if (!CATEGORY_KEYS.includes(category)) {
        console.warn("Model returned unknown category:", category);
        category = "not_understood";
      }

      res.status(200).json({ category });
    } catch (err) {
      const status = err.response?.status || 500;
      const data = err.response?.data || err.message || String(err);
      console.error("OpenAI categorizeTask error:", data);
      res.status(status).json({
        error: "OpenAI categorizeTask failed",
        details: data,
        categoryFallback: "not_understood",
      });
    }
  });
});

exports.generatePetInfo = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const { breed, petName } = req.body;
      // ... (rest of generatePetInfo logic) ... 
      // I am truncating unchanged parts for brevity in this thought, but write_to_file needs full content.
      // Wait, replace_file_content is better if I want to just prepend and append.
      // But multi_replace_file_content is even better.
      // Actually, I will just rewrite the whole file to be safe and clean.

      // ... Re-inserting existing logic ...
      if (!breed) {
        res.status(400).json({ error: "Missing 'breed' field" });
        return;
      }
      const OPENAI_KEY = process.env.OPENAI_API_KEY || "YOUR_OPENAI_API_KEY_HERE";
      if (!OPENAI_KEY) { res.status(500).json({ error: "Missing OpenAI key" }); return; }

      const prompt = `Create a detailed, engaging profile for a ${breed} named ${petName || "the dog"}. Structure response in JSON: description, care_instructions, fun_fact. Language: English.`;
      const openaiRes = await axios.post("https://api.openai.com/v1/chat/completions", {
        model: "gpt-4.1-mini",
        messages: [{ role: "system", content: "You are a helpful pet expert. Respond in pure JSON format." }, { role: "user", content: prompt }],
        temperature: 0.7,
      }, { headers: { "Content-Type": "application/json", Authorization: `Bearer ${OPENAI_KEY}` } });

      let content = openaiRes.data.choices[0].message.content.replace(/```json/g, "").replace(/```/g, "").trim();
      res.status(200).json(JSON.parse(content));
    } catch (err) {
      console.error("Error in generatePetInfo:", err);
      res.status(500).json({ error: "Failed to generate info", details: err.message });
    }
  });
});

exports.generateDailyTip = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    // ... logic ...
    try {
      const { petName, recentTasks } = req.body;
      const OPENAI_KEY = process.env.OPENAI_API_KEY || "YOUR_OPENAI_API_KEY_HERE";
      if (!OPENAI_KEY) { res.status(500).json({ error: "Missing OpenAI key" }); return; }
      const tasksStr = recentTasks && recentTasks.length > 0 ? recentTasks.join(", ") : "no specific tasks recently";
      const prompt = `Generate a daily care tip for dog ${petName || "Buddy"}. Context: ${tasksStr}. One sentence.`;
      const openaiRes = await axios.post("https://api.openai.com/v1/chat/completions", {
        model: "gpt-4.1-mini",
        messages: [{ role: "system", content: "You are a friendly dog care companion." }, { role: "user", content: prompt }],
        temperature: 0.7,
      }, { headers: { "Content-Type": "application/json", Authorization: `Bearer ${OPENAI_KEY}` } });
      res.status(200).json({ tip: openaiRes.data.choices[0].message.content.trim() });
    } catch (err) {
      console.error("Error in generateDailyTip:", err);
      res.status(500).json({ error: "Failed to generate tip", details: err.message });
    }
  });
});

// NEW FUNCTION: Proxy for Firebase Storage Images (Fixes CORS on Web)
exports.getStorageImage = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const filePath = req.query.path;
      if (!filePath) {
        res.status(400).send("Missing path");
        return;
      }

      // 1. Get reference to the file
      const bucket = admin.storage().bucket();
      const file = bucket.file(filePath);

      const [exists] = await file.exists();
      if (!exists) {
        res.status(404).send("File not found");
        return;
      }

      // 2. Set long cache to avoid repeated function calls
      res.set('Cache-Control', 'public, max-age=31536000, s-maxage=31536000');

      // 3. Pipe the file
      const readStream = file.createReadStream();
      readStream.on('error', (err) => {
        console.error("Stream error:", err);
        res.status(500).end();
      });
      readStream.pipe(res);

    } catch (error) {
      console.error("Proxy error:", error);
      res.status(500).send("Internal Server Error");
    }
  });
});
