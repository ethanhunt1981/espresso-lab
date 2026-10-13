# ☕ Interactive Espresso Lab / Interaktives Espresso-Lab

*Note: This application is in German.*

An interactive web tool for real-time simulation of espresso extraction, fluid dynamics, and flavor profiles. Built with the assistance of **Google Gemini 4 Argon**.

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

---

## 🛠️ Local Setup

Since this project consists of a single standalone `index.html` file, no complex build tools or servers are required:

1. Clone the repository or download the `index.html`:
   ```bash
   git clone [https://github.com/ethanhunt1981/espresso-lab.git](https://github.com/ethanhunt1981/espresso-lab.git)