# ☕ Interactive Espresso Lab

*Note: This application is in German.*

An interactive web tool for real-time simulation of espresso extraction, fluid dynamics, and flavor profiles. 

---

## 🚀 Live Demo
Test the Espresso Lab directly in your browser:
👉 [https://ethanhunt1981.github.io/espresso-lab/](https://ethanhunt1981.github.io/espresso-lab/)

---

## 🔬 Features & Physics Models

The Espresso Lab combines barista science with interactive web technology:

* **Grind Size (Particle Surface Area):** Simulates coffee puck resistance and extraction kinetics based on the Kozeny-Carman principle.
* **Water Temperature:** Influences extraction velocity (acids extract quickly, bitterness increases with excessive heat or prolonged extraction).
* **Pressure & Channeling Risk:** Monitors flow dynamics and warns against sudden channeling risks under high pressure and fine grinds.
* **Visual Live Animation:** An animated bottomless portafilter displaying the "flow stream" (mouse tail), tiger striping, spray patterns, and crema build-up inside the glass.
* **Scientific Charts:** Toggle between the **SCA Brewing Control Chart (EY% vs. TDS%)** and the **Time-Kinetics Chart** (flow rate & extraction progression).
* **Extraction knowledge, built in:** four compact cards below the charts explain how to read them — the SCA EY window (18–22%), TDS strength (8–12%), the drivers of extraction, and the acid → sweet → bitter time kinetics.
* **Community Coffee Library:** Share your beans with the world — no signup required:
  * Publish your coffee (brand, origin, roast level, process) together with the exact brew settings you used (grind, temperature, pressure, shot time) and the results you achieved (EY%, TDS%, taste scores).
  * Browse the library, search by brand/origin/notes, filter by roast level, and load any profile straight into the sliders.
  * **Compare mode:** pick up to 3 profiles (⚖ button) and see all brew parameters and results side by side in a table.
  * **👍 Votes:** give a thumbs-up to profiles whose settings worked for you — one anonymous vote per browser, no registration.
  * Share any profile via link (works even offline, encoded in the URL) or export it.
  * Export single profiles as JSON files and bulk-import them anywhere (validated against the database constraints on import).

---

## 🌍 Community Library — How It Works

The library was publicly announced on Reddit's r/espresso community in October 2026. If you came from that post: welcome, and thanks for sharing your beans and recipes! ☕

The library is powered by a free [Supabase](https://supabase.com) database:

* **Reading and publishing is open to everyone** — no account, no login. Just open the app, dial in your shot, click *"Bohnenprofil der Community hinzufügen"*, and your entry appears instantly.
* **Moderation & safety:** Anonymous users can only *read* and *create* entries. Editing or deleting other people's profiles is impossible by design (Row Level Security). The repository owner moderates via the Supabase dashboard.
* **Self-hosting:** The database schema lives in [`supabase/schema.sql`](supabase/schema.sql). Run it in your own Supabase project and put your project URL + anon key in `js/config.js`.

---

## 🔒 Security

No accounts, no passwords — and the library is designed so that anonymity
never becomes a liability:

* Anonymous visitors can **read and create** entries, but **never edit or
  delete** anyone else's — enforced by database Row Level Security, even
  against direct API calls that skip the browser.
* Every field is validated server-side (length limits + value ranges) and
  new entries are rate-limited server-side, so bots can't flood or deface
  the library.
* All database content is rendered XSS-safely; shared profile links are
  validated before anything is applied to your sliders.
* The Supabase client is loaded from a pinned version with a content
  integrity hash (SRI), so a tampered CDN response is rejected.

Details live in [`supabase/schema.sql`](supabase/schema.sql) — see it yourself.
Deeper findings and verification notes are kept private by the repository
owner.

---

## 🤖 Development & AI Collaboration

This project was co-created through human-AI collaboration using **Google Gemini 4 Argon**. The user provided the prompt design, concepts, and requirements, while the AI assisted in generating and structuring the code, physics logic, and documentation.

---

## 🛠️ Local Setup

Since this project consists of a single standalone `index.html` file, no complex build tools or servers are required:

1. Clone the repository:
   ```bash
   git clone https://github.com/ethanhunt1981/espresso-lab.git
   cd espresso-lab
   ```
2. Open `index.html` directly in your browser — or serve it locally (recommended for the community features):
   ```bash
   python -m http.server 8000
   # → http://127.0.0.1:8000
   ```
3. *(Only for contributors / after adding new Tailwind classes)* rebuild the stylesheets:
   ```bash
   npm install        # once
   npm run build:css  # regenerates css/tailwind.css
   ```

### Project structure

```
index.html              # App: UI, physics engine, charts, animation
css/tailwind.css        # Compiled Tailwind output (committed)
css/tailwind.src.css    # Tailwind input (`@tailwind` directives)
tailwind.config.js      # Tailwind theme config (colors, fonts)
package.json            # Tailwind build scripts (devDependency only)
js/config.js            # Supabase project URL + anon key (public by design)
supabase/schema.sql     # Database schema & security policies (run once per project)
ROADMAP.md              # Development roadmap
```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).