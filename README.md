# SmartCam 📸✨

A multi-functional, AI-powered camera application built with Flutter. SmartCam acts as a "Shazam for the real world," allowing users to identify products, describe scenes, translate text, and scan QR codes from a single, intuitive interface.

## 🌟 Features

* **Multi-Mode Camera:** A single screen provides access to five powerful tools:
    * **📷 Photo:** A fully-featured camera with flash, pinch-to-zoom, and lens-switching capabilities.
    * **🌐 Translate:** Instantly reads text from the camera using on-device OCR, then uses the Gemini API for accurate translation and summarization.
    * **🏞️ Describe:** Leverages the Gemini 1.5 Flash model to provide rich, descriptive captions for any scene you capture.
    * **🛍️ Shopping:** Identifies a product in an image with Gemini and uses the SerpApi to find and display real-time shopping results.
    * **🔗 Scan:** An on-demand QR code scanner with options to copy the content or open links directly in a browser.
* **Resilient AI:** Features an intelligent fallback system. If the primary Gemini API is unavailable (e.g., due to rate limits), the app seamlessly switches to backup APIs (Imagga for vision, MyMemory for translation).
* **Polished UX:** A "single screen" workflow where the camera view freezes and a slide-up "Analysis Card" presents results for a smooth, interactive experience. Includes Text-to-Speech for audible results.

## 🛠️ Technology Stack

* **Framework:** Flutter
* **AI Services:**
    * Google Gemini 1.5 Flash API (Primary)
    * SerpApi (Google Shopping Results)
    * Imagga (Image Tagging Fallback)
    * MyMemory (Translation Fallback)
* **On-Device AI:**
    * Google ML Kit (Text Recognition v2)
* **Core Flutter Packages:**
    * `camera`
    * `mobile_scanner`
    * `http`
    * `flutter_tts`
    * `url_launcher`

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed on your system:
* Flutter SDK: [Installation Guide](https://flutter.dev/docs/get-started/install)
* An IDE like VS Code or Android Studio.

### Installation & Setup

1.  **Clone the Repository**
    Open your terminal and clone the project to your local machine:
    ```bash
    git clone https://github.com/FathimaJabbar/SmartCam.git
    ```

2.  **Navigate to the Project Directory**
    ```bash
    cd SmartCam
    ```

3.  **Add API Keys (Very Important!)**
    This project requires several API keys to function. Create a new file named `lib/api_keys.dart` and paste the following code into it, adding your secret keys.

    ```dart
    // lib/api_keys.dart

    class ApiKeys {
      static const gemini = 'YOUR_GEMINI_API_KEY';
      static const serpApi = 'YOUR_SERPAPI_KEY';
      static const imaggaApi = 'YOUR_IMAGGA_API_KEY';
      static const imaggaApiSecret = 'YOUR_IMAGGA_API_SECRET';
    }
    ```
    > **Note:** To keep your keys secure, this `api_keys.dart` file should be added to your `.gitignore` file and never be committed to your repository.

4.  **Install Dependencies**
    Run the following command to download all the necessary packages:
    ```bash
    flutter pub get
    ```

5.  **Run the App**
    Make sure a device is connected or an emulator is running, then launch the app:
    ```bash
    flutter run
    ```

## 🕹️ How to Use

* The app opens directly to the camera interface.
* Select a mode from the bottom scrollable menu: **Photo**, **Translate**, **Describe**, **Shopping**, or **Scan**.
* In **Photo**, **Translate**, **Describe**, or **Shopping** mode, tap the circular shutter button to capture an image and trigger the analysis.
* In **Scan** mode, the camera will automatically detect codes.
* Results are displayed in an interactive card that slides up from the bottom.