const functions = require("firebase-functions");
const axios = require("axios");

// IDE ÍRD BE AZ ÚJ OPENAI KULCSOT (vagy használd functions.config()-ot)
const OPENAI_KEY = "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";

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

// EREDTI CHAT FUNKCIÓD - ezt hagyom érintetlenül ------------------------
exports.petpalChat = functions.https.onRequest(async (req, res) => {
  // CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const userMessage = req.body.message;
    if (!userMessage || typeof userMessage !== "string") {
      res.status(400).json({ error: "Missing or invalid 'message' field" });
      return;
    }

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

// ÚJ: TASK KATEGORIZÁLÓ FUNKCIÓ ----------------------------------------
exports.categorizeTask = functions.https.onRequest(async (req, res) => {
  // CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  try {
    const description = req.body.description;
    if (!description || typeof description !== "string") {
      res.status(400).json({ error: "Missing or invalid 'description' field" });
      return;
    }

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
        temperature: 0, // determinisztikusabb
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

    // Biztosítsuk, hogy csak az engedélyezett kulcsok egyike legyen
    if (!CATEGORY_KEYS.includes(category)) {
      console.warn("Model returned unknown category:", category);
      category = "not_understood";
    }

    res.status(200).json({ category });
  } catch (err) {
    const status = err.response?.status || 500;
    const data = err.response?.data || err.message || String(err);

    console.error("OpenAI categorizeTask error:", data);

    // Hiba esetén inkább not_understood-öt adunk vissza
    res.status(status).json({
      error: "OpenAI categorizeTask failed",
      details: data,
      categoryFallback: "not_understood",
    });
  }
});
