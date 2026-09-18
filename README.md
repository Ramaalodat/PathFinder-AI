<div align="center">

  # 🧭 PathFinder AI
  ### *Your Intelligent Multilingual AI Tourist Guide & Travel Companion*

  [![Gemini AI](https://img.shields.io/badge/Powered%20By-Google%20Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://deepmind.google/technologies/gemini/)
  [![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Node.js](https://img.shields.io/badge/Backend-Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org/)
  [![Firebase](https://img.shields.io/badge/Auth-Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-brightgreen?style=for-the-badge)](https://flutter.dev)

  ---

  <p align="center">
    <b>PathFinder AI</b> empowers tourists to navigate foreign destinations with confidence. Powered by Google Gemini on Vertex AI, it combines real-time voice translation, scam detection, local transport routing, and social travel matching into a seamless mobile experience.
  </p>

</div>

---

## 📸 Key Highlights & Features

<table>
  <tr>
    <td width="50%">
      <h3>🎙️ Real-Time Voice & Text Translation</h3>
      <ul>
        <li><b>Speech-to-Speech:</b> Instant voice-to-voice translation for smooth local conversations.</li>
        <li><b>Multilingual Support:</b> Overcomes language barriers with drivers, vendors, and locals.</li>
        <li><b>Context-Aware:</b> Understands travel slang and localized phrasing.</li>
      </ul>
    </td>
    <td width="50%">
      <h3>🛡️ Scam Prevention & Price Advisor</h3>
      <ul>
        <li><b>Smart Price Check:</b> Compares local item/taxi prices against market averages.</li>
        <li><b>Fraud Alert:</b> Warns users instantly if prices are inflated or suspicious.</li>
        <li><b>Fair Price Guide:</b> Gives optimal price ranges for food, transport, and souvenirs.</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>🎯 Personalized Recommendations</h3>
      <ul>
        <li><b>Budget-Tailored:</b> Recommends attractions, dining, and activities based on budget.</li>
        <li><b>Cultural Etiquette:</b> Guidance on local customs, do's, and don'ts.</li>
        <li><b>Dynamic Itineraries:</b> Adaptive travel plans according to real-time weather and location.</li>
      </ul>
    </td>
    <td width="50%">
      <h3>🚌 Smart Transportation & Social Matching</h3>
      <ul>
        <li><b>Live Navigation:</b> Optimal public transit, walking, and rideshare directions.</li>
        <li><b>Traffic & Cost Optimization:</b> Displays ticket estimates and fastest routes.</li>
        <li><b>Traveler Companion Match:</b> Connects solo travelers to explore nearby sights together.</li>
      </ul>
    </td>
  </tr>
</table>

---

## 🏗️ Architecture & Tech Stack

```mermaid
graph TD
    User([📱 Traveler / Mobile App]) <--> FlutterApp[Flutter Mobile Frontend]
    FlutterApp <--> NodeBackend[Node.js / Express API Server]
    
    subgraph Google Cloud & AI Platform
        NodeBackend <--> Gemini[Google Gemini AI / Vertex AI]
        NodeBackend <--> Maps[Google Maps & Geolocation API]
        NodeBackend <--> Speech[Cloud Speech-to-Text & Text-to-Speech]
        NodeBackend <--> Weather[Google Weather API]
    end

    subgraph Authentication & External Services
        FlutterApp <--> Firebase[Firebase Auth]
        NodeBackend <--> Currency[CurrencyAPI Real-Time Rates]
    end
```

### 💻 Technologies & APIs

| Layer | Stack / Tool | Description |
| :--- | :--- | :--- |
| **Frontend** | ![Flutter](https://img.shields.io/badge/-Flutter-02569B?logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/-Dart-0175C2?logo=dart&logoColor=white) | Cross-platform mobile UI for Android & Web |
| **Backend** | ![Node.js](https://img.shields.io/badge/-Node.js-339933?logo=nodedotjs&logoColor=white) ![Express](https://img.shields.io/badge/-Express.js-000000?logo=express&logoColor=white) | RESTful API server handling business logic & integrations |
| **AI Engine** | ![Google Gemini](https://img.shields.io/badge/-Google%20Gemini-4285F4?logo=google&logoColor=white) | Core intelligence for recommendations, pricing, & translation |
| **Cloud Services** | ![Firebase](https://img.shields.io/badge/-Firebase-FFCA28?logo=firebase&logoColor=black) ![GCP](https://img.shields.io/badge/-Google%20Cloud-4285F4?logo=googlecloud&logoColor=white) | Auth, Speech-to-Text, Text-to-Speech, Maps, GeoCoding, Weather |
| **Financial API** | `CurrencyAPI` | Live foreign currency exchange & conversion calculation |

---

## 🚀 Quick Start Guide

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0+)
* [Node.js](https://nodejs.org/) (v18.0+)
* Android Studio / Android Emulator or physical device

---

### 1️⃣ Frontend Setup (Flutter)

```bash
# Navigate to the frontend workspace
cd front

# Get flutter dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run on connected Android device/emulator
flutter run
```

---

### 2️⃣ Backend Setup (Node.js)

```bash
# Open a new terminal and navigate to the backend directory
cd back

# Install package dependencies
npm install

# Start development server
npm run dev
```

---

## 👥 Meet Team GOOGLEISTS

<div align="center">

| Developer | Role | Profile |
| :--- | :--- | :--- |
| **Mohammad Al-Majali** | Backend Lead | [![GitHub](https://img.shields.io/badge/-MavisVermie-181717?logo=github)](https://github.com/MavisVermie) |
| **Marah Al-Qunbor** | Backend Engineer | [![GitHub](https://img.shields.io/badge/-MarahYousef01-181717?logo=github)](https://github.com/MarahYousef01/) |
| **Rama Al-Odat** | Frontend Lead | [![GitHub](https://img.shields.io/badge/-Ramaalodat-181717?logo=github)](https://github.com/Ramaalodat) |
| **Mohammad Al-Ali** | Frontend Engineer | [![GitHub](https://img.shields.io/badge/-Developer-181717?logo=github)](#) |

</div>

---

<div align="center">

  <b>Made with ❤️ by Team GOOGLEISTS</b><br>
  *Happy Travels with PathFinder AI! 🌍✈️*

</div>

