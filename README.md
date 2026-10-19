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
* **Community Coffee Library:** Share your beans with the world — no signup required:
  * Publish your coffee (brand, origin, roast level, process) together with the exact brew settings you used (grind, temperature, pressure, shot time) and the results you achieved (EY%, TDS%, taste scores).
  * Browse the library, search by brand/origin/notes, filter by roast level, and load any profile straight into the sliders.
  * Share any profile via link (works even offline, encoded in the URL) or export it.

---

## 🌍 Community Library — How It Works

The library is powered by a free [Supabase](https://supabase.com) database:

* **Reading and publishing is open to everyone** — no account, no login. Just open the app, dial in your shot, click *"Bohnenprofil der Community hinzufügen"*, and your entry appears instantly.
* **Moderation & safety:** Anonymous users can only *read* and *create* entries. Editing or deleting other people's profiles is impossible by design (Row Level Security). The repository owner moderates via the Supabase dashboard.
* **Self-hosting:** The database schema lives in [`supabase/schema.sql`](supabase/schema.sql). Run it in your own Supabase project and put your project URL + anon key in `js/config.js`.

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

### Project structure

```
index.html            # App: UI, physics engine, charts, animation
js/config.js          # Supabase project URL + anon key (public by design)
supabase/schema.sql   # Database schema & security policies (run once per project)
ROADMAP.md            # Development roadmap
```

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).