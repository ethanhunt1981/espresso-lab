/** Tailwind-Konfiguration des Espresso Lab (identisch zur bisherigen
 *  Inline-Konfiguration unter dem Play-CDN — jetzt für den lokalen Build).
 *
 *  Nebenauftrag: Nach dem Hinzufügen neuer Klassen im HTML bitte
 *    npm install  (einmalig)  und  npm run build:css  ausführen,
 *    das Ergebnis `css/tailwind.css` committen.
 */
module.exports = {
    darkMode: 'class',
    content: [
        './index.html',
        './js/**/*.{js,css}'
    ],
    theme: {
        extend: {
            fontFamily: {
                sans: ['Inter', 'sans-serif'],
                mono: ['JetBrains Mono', 'monospace'],
            },
            colors: {
                espresso: {
                    950: '#0f0a07',
                    900: '#1c130e',
                    800: '#2e1f16',
                    700: '#4a3121',
                    600: '#6e472b',
                    500: '#9c6334',
                    400: '#c88343',
                    300: '#dea366',
                    200: '#ecc599',
                    100: '#f6e3cc',
                },
                crema: '#d99b52',
            }
        }
    }
}
