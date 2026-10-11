// Reads a photo or PDF of a broodmare management card with Claude and returns structured entries.
// Netlify env vars:
//   ANTHROPIC_API_KEY  (required; without it the app falls back to typing entries in by hand)
//   MAREBOOK_AI_MODEL  (optional; defaults to claude-sonnet-5-5)
//   SUPABASE_URL, SUPABASE_ANON_KEY  (optional; when set, only signed-in Marebook users can call this)

const KINDS = ["exam", "breeding", "vaccine", "deworm", "foaling", "treatment", "farrier", "dental", "other"];
const TONES = ["Good", "Fair", "Poor", "Edema 1", "Edema 2", "Edema 3", "Fluid present"];
const TYPES = ["image/jpeg", "image/png", "image/webp", "image/gif", "application/pdf"];

const json = (body, status = 200) => new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });

function prompt(today) {
  return `This is a broodmare management card: a paper breeding, teasing, vet or health record for one mare. Read every dated entry.
Reply with only JSON shaped like {"mare":{"name":"","breed":"","color":"","registry":"","regNo":"","born":""},"entries":[{"date":"YYYY-MM-DD","kind":"exam","title":"","left":"","right":"","tone":"","ovulated":false,"result":"","notes":""}]}.
- kind is one of: ${KINDS.join(", ")}.
- For ultrasound or palpation entries put left-ovary and right-ovary findings in left and right (for example "35 mm follicle", "CL").
- tone is one of ${TONES.join(", ")} or "".
- ovulated is true only when the card shows ovulation. result is Pregnant, Open, Twins or "".
- title is a short description under 8 words, such as "Ultrasound", "Bred · cooled AI", "Flu/rhino booster".
- born is a 4-digit year.
- Today is ${today}. When the card leaves out the year, use the most recent year that keeps the date on or before today.
- Skip entries you can't date. Use "" for anything unreadable. Never invent entries.`;
}

async function signedIn(req) {
  const url = process.env.SUPABASE_URL, key = process.env.SUPABASE_ANON_KEY;
  if (!url || !key) return true;
  const auth = req.headers.get("authorization") || "";
  if (!/^Bearer\s+\S+/.test(auth)) return false;
  const r = await fetch(url.replace(/\/$/, "") + "/auth/v1/user", { headers: { apikey: key, authorization: auth } });
  return r.ok;
}

export default async (req) => {
  if (req.method !== "POST") return json({ error: "POST only" }, 405);
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) return json({ error: "Card reading isn't configured" }, 501);
  if (!(await signedIn(req))) return json({ error: "Sign in first" }, 401);

  let body;
  try { body = await req.json(); } catch { return json({ error: "Bad request" }, 400); }
  const { data, mediaType } = body || {};
  const today = /^\d{4}-\d{2}-\d{2}$/.test(body?.today || "") ? body.today : new Date().toISOString().slice(0, 10);
  if (!data || typeof data !== "string" || !TYPES.includes(mediaType)) return json({ error: "Send a JPG, PNG, WebP, GIF or PDF" }, 400);
  if (data.length > 6_000_000) return json({ error: "File too large" }, 413);

  const source = { type: "base64", media_type: mediaType, data };
  const block = mediaType === "application/pdf" ? { type: "document", source } : { type: "image", source };

  const r = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": apiKey, "anthropic-version": "2023-06-01", "content-type": "application/json" },
    body: JSON.stringify({
      model: process.env.MAREBOOK_AI_MODEL || "claude-sonnet-5-5",
      max_tokens: 4000,
      messages: [{ role: "user", content: [block, { type: "text", text: prompt(today) }] }],
    }),
  });
  if (!r.ok) return json({ error: "Couldn't read the card", status: r.status }, 502);

  const out = await r.json();
  const text = (out.content || []).filter((c) => c.type === "text").map((c) => c.text).join("");
  const start = text.indexOf("{"), end = text.lastIndexOf("}");
  try {
    const parsed = JSON.parse(text.slice(start, end + 1));
    return json({ mare: parsed.mare || {}, entries: Array.isArray(parsed.entries) ? parsed.entries : [] });
  } catch {
    return json({ error: "Couldn't parse the card" }, 502);
  }
};
