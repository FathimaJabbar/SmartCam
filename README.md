# SmartCam 📸✨

A multi-functional, AI-powered camera application built with Flutter. SmartCam acts as a "Shazam for the real world," allowing users to identify objects, translate text, scan QR codes, and more, all from a single, intuitive interface.

## Features

* **Multi-Mode Camera:** A single interface provides access to five powerful tools:
    * **📷 Photo:** A fully-featured camera with flash, zoom, and lens-switching.
    * **🌐 Translate:** Uses on-device OCR to instantly read text, which is then translated using the Gemini API. Features an interactive card to re-translate to other languages.
    * **🏞️ Describe:** Leverages the Gemini 1.5 Flash model to provide rich, descriptive captions for any scene.
    * **🛍️ Shopping:** Identifies products in an image using Gemini and uses the SerpApi to find and display real-time shopping results.
    * **[ ] Scan:** An on-demand QR code scanner with options to copy or open links directly.
* **Resilient AI:** Features an intelligent fallback system. If the primary Gemini API is unavailable due to rate limits, the app seamlessly switches to backup APIs (Imagga for vision, MyMemory for translation).
* **Polished UX:** A "single screen" workflow with a frozen camera preview and a slide-up "Analysis Card" for a smooth user experience. Includes Text-to-Speech for audible results.

## Technology Stack

* **Framework:** Flutter
* **Primary AI:** Google Gemini 1.5 Flash API
* **On-Device AI:** Google ML Kit (Text Recognition v2, Language ID)
* **Backup APIs:** Imagga (Image Tagging), MyMemory (Translation)
* **Data API:** SerpApi (Google Shopping Results)
* **Core Packages:** `camera`, `mobile_scanner`, `flutter_tts`, `url_launcher`, `gal`

---