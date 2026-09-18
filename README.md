<div align="center">

  <br />
  
  <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Compass.png" alt="PathFinder AI Logo" width="120" height="120" />

  # 🧭 PathFinder AI
  ### **Your Intelligent Multilingual AI Tourist Guide & Smart Travel Companion**

  <p align="center">
    <b>Empowering travelers to explore the world without language barriers, price scams, or transit confusion.</b>
    <br />
    <i>Powered by Google Gemini AI, Vertex AI, Speech Services & Flutter</i>
  </p>

  <p align="center">
    <a href="#-key-features"><b>Explore Features</b></a> •
    <a href="#-system-architecture"><b>Architecture</b></a> •
    <a href="#-quick-start-guide"><b>Quick Start</b></a> •
    <a href="#-tech-stack"><b>Tech Stack</b></a> •
    <a href="#-team-googleists"><b>The Team</b></a>
  </p>

  <br />

  <!-- Shield Badges -->
  [![Google Gemini](https://img.shields.io/badge/AI%20Engine-Google%20Gemini-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://deepmind.google/technologies/gemini/)
  [![Flutter](https://img.shields.io/badge/Frontend-Flutter%20v3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Node.js](https://img.shields.io/badge/Backend-Node.js%20v18+-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org/)
  [![Firebase](https://img.shields.io/badge/Auth-Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com/)
  [![License](https://img.shields.io/badge/License-MIT-purple.svg?style=for-the-badge)](LICENSE)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-E4405F?style=for-the-badge&logo=android&logoColor=white)](https://flutter.dev)

  <br />
  <br />

  ---

</div>

<br />

## 📌 Table of Contents

- [✨ Overview](#-overview)
- [📸 Key Features](#-key-features)
- [🏗️ System Architecture](#-system-architecture)
- [💻 Tech Stack & Integrations](#-tech-stack--integrations)
- [📁 Project Directory Structure](#-project-directory-structure)
- [🚀 Quick Start Guide](#-quick-start-guide)
  - [Prerequisites](#prerequisites)
  - [Backend Setup](#1%EF%B8%8F%E2%83%A3-backend-setup-nodejs)
  - [Frontend Setup](#2%EF%B8%8F%E2%83%A3-frontend-setup-flutter)
- [⚙️ Environment Variables](#%EF%B8%8F-environment-variables)
- [👥 Team GOOGLEISTS](#-team-googleists)
- [📄 License & Acknowledgments](#-license--acknowledgments)

<br />

---

## ✨ Overview

**PathFinder AI** is a next-generation travel application designed to solve the biggest pain points tourists face abroad: **language barriers, inflated pricing scams, navigation confusion, and solo travel isolation**.

By harnessing **Google Gemini on Vertex AI**, **Google Cloud Speech Services**, and real-time financial APIs, PathFinder AI acts as a 24/7 personal tour guide, translator, financial advisor, and navigation assistant right in your pocket.

<br />

---

## 📸 Key Features

<table width="100%">
  <tr>
    <td width="50%" valign="top">
      <div align="center">
        <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Studio%20Microphone.png" width="48" alt="Voice Translation"/>
        <h3>🎙️ Real-Time Voice & Text Translation</h3>
      </div>
      <ul>
        <li><b>Speech-to-Speech Engine:</b> Instant, natural voice translation between tourist and locals.</li>
        <li><b>Context-Aware AI:</b> Recognizes local dialects, regional slang, and conversational context.</li>
        <li><b>Multilingual Support:</b> Overcomes communication barriers with taxi drivers, vendors, and emergency contacts.</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <div align="center">
        <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Shield.png" width="48" alt="Scam Detector"/>
        <h3>🛡️ Scam Prevention & Price Advisor</h3>
      </div>
      <ul>
        <li><b>Real-Time Price Checker:</b> Evaluates item or taxi service quotes against live market averages.</li>
        <li><b>Fraud & Inflation Alerts:</b> Warns tourists immediately if a price is suspiciously high.</li>
        <li><b>Fair Price Benchmarks:</b> Displays accurate price ranges for food, transport, activities, and souvenirs.</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <div align="center">
        <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/World%20Map.png" width="48" alt="Recommendations"/>
        <h3>🎯 Personal Guide & Itineraries</h3>
      </div>
      <ul>
        <li><b>Budget-Tailored Plans:</b> Recommends activities, dining, and hidden gems custom to your budget.</li>
        <li><b>Cultural Insights & Etiquette:</b> Informs users of local customs, tipping rules, and appropriate behavior.</li>
        <li><b>Weather-Adaptive Itineraries:</b> Dynamically re-routes activities based on real-time weather forecasts.</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <div align="center">
        <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Bus.png" width="48" alt="Transit & Social"/>
        <h3>🚌 Smart Navigation & Companion Match</h3>
      </div>
      <ul>
        <li><b>Live Transit Routing:</b> Multimodal navigation across public transit, rideshares, and walking.</li>
        <li><b>Cost & Time Optimization:</b> Displays transparent fare estimates and fastest connections.</li>
        <li><b>Traveler Companion Match:</b> Safely connects solo travelers looking to explore sights together.</li>
      </ul>
    </td>
  </tr>
</table>

<br />

---

## 🏗️ System Architecture

```mermaid
graph TB
    %% Nodes Definitions
    subgraph ClientLayer ["📱 Mobile Frontend Layer (Flutter)"]
        User(["👤 Tourist / End User"])
        FlutterApp["📱 Flutter Cross-Platform App\n(Android / iOS / Web)"]
        StateMgmt["⚡ State Management & UI Components"]
    end

    subgraph BackendLayer ["⚙️ Server & API Layer (Node.js)"]
        ExpressServer["🚀 Node.js / Express API Server"]
        AuthMiddleware["🔒 Firebase Auth Middleware"]
        APIRouter["🔀 Restful API Gateway"]
    end

    subgraph ExternalServices ["☁️ Cloud & AI Integration Engine"]
        subgraph GCP ["Google Cloud Platform"]
            GeminiAI["🧠 Google Gemini AI (Vertex AI)"]
            SpeechEngine["🗣️ Cloud Speech-to-Text & Text-to-Speech"]
            MapsAPI["🗺️ Google Maps & Geolocation API"]
            WeatherAPI["☀️ Google Weather API"]
        end

        subgraph ThirdParty ["Third-Party Services"]
            FirebaseAuth["🔥 Firebase Authentication"]
            CurrencyAPI["💱 CurrencyAPI Real-Time Rates"]
        end
    end

    %% Connections
    User <--> FlutterApp
    FlutterApp <--> StateMgmt
    StateMgmt <-->|"HTTPS / REST"| ExpressServer
    
    ExpressServer --> AuthMiddleware
    AuthMiddleware --> APIRouter
    
    APIRouter <-->|"AI Prompts & Analysis"| GeminiAI
    APIRouter <-->|"Voice Audio Stream"| SpeechEngine
    APIRouter <-->|"Geo & Route Queries"| MapsAPI
    APIRouter <-->|"Live Weather Data"| WeatherAPI
    
    FlutterApp <-->|"User Sign-In / Token"| FirebaseAuth
    APIRouter <-->|"Live Exchange Rates"| CurrencyAPI

    %% Styling
    classDef client fill:#02569B,stroke:#0175C2,stroke-width:2px,color:#fff;
    classDef server fill:#339933,stroke:#2b802b,stroke-width:2px,color:#fff;
    classDef ai fill:#4285F4,stroke:#2b6cb0,stroke-width:2px,color:#fff;
    classDef ext fill:#FFCA28,stroke:#d69e2e,stroke-width:2px,color:#000;

    class FlutterApp,StateMgmt client;
    class ExpressServer,AuthMiddleware,APIRouter server;
    class GeminiAI,SpeechEngine,MapsAPI,WeatherAPI ai;
    class FirebaseAuth,CurrencyAPI ext;
```

<br />

---

## 💻 Tech Stack & Integrations

| Domain | Technology / Service | Description & Purpose |
| :--- | :--- | :--- |
| **Frontend Framework** | ![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white) ![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white) | Cross-platform high-performance UI framework for Android, iOS & Web |
| **Backend Runtime** | ![Node.js](https://img.shields.io/badge/Node.js-339933?logo=nodedotjs&logoColor=white) ![Express](https://img.shields.io/badge/Express.js-000000?logo=express&logoColor=white) | Lightweight RESTful microservice backend handling business logic |
| **Core AI Model** | ![Google Gemini](https://img.shields.io/badge/Google%20Gemini-4285F4?logo=google&logoColor=white) | Intelligence engine for price validation, translation, & itineraries |
| **Authentication** | ![Firebase](https://img.shields.io/badge/Firebase%20Auth-FFCA28?logo=firebase&logoColor=black) | Secure user authentication, OAuth logins, and session management |
| **Voice Processing** | ![GCP Speech](https://img.shields.io/badge/GCP%20Speech--to--Text-4285F4?logo=googlecloud&logoColor=white) | Real-time speech conversion and audio synthesis for voice chat |
| **Location & Maps** | ![Google Maps](https://img.shields.io/badge/Google%20Maps%20API-4285F4?logo=googlemaps&logoColor=white) | Geocoding, place lookup, distance matrix, and route calculation |
| **Currency Rates** | `CurrencyAPI` | Real-time international exchange rate calculations |

<br />

---

## 📁 Project Directory Structure

```text
PathFinder-AI/
├── 📁 back/                   # Node.js Express Backend Service
│   ├── 📁 controllers/        # Route logic & AI processing controllers
│   ├── 📁 routes/             # RESTful API endpoints
│   ├── 📁 services/           # Gemini AI, Maps & Speech integrations
│   ├── 📄 package.json        # Node dependencies & scripts
│   └── 📄 server.js           # Server entry point
│
├── 📁 front/                  # Flutter Mobile & Web Application
│   ├── 📁 lib/                # Dart source code
│   │   ├── 📁 screens/        # UI Views & App screens
│   │   ├── 📁 services/       # API clients & authentication
│   │   └── 📄 main.dart       # Flutter app entry point
│   ├── 📁 assets/             # Images, icons & static resources
│   └── 📄 pubspec.yaml        # Flutter packages & configurations
│
└── 📄 README.md               # Project documentation
```

<br />

---

## 🚀 Quick Start Guide

### Prerequisites

Ensure you have the following installed on your machine before running the project:

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0 or higher)
- [Node.js](https://nodejs.org/) (v18.0 or higher) + `npm`
- [Git](https://git-scm.com/)
- An Android Studio setup / Android Emulator or physical test device

---

### 1️⃣ Backend Setup (Node.js)

```bash
# 1. Clone the repository (if not already done)
git clone https://github.com/Ramaalodat/PathFinder-AI.git
cd PathFinder-AI

# 2. Navigate into the backend directory
cd back

# 3. Install project dependencies
npm install

# 4. Configure environment variables (create a .env file)
cp .env.example .env

# 5. Start the backend development server
npm run dev
```

*The backend server will run by default at `http://localhost:5000`.*

---

### 2️⃣ Frontend Setup (Flutter)

```bash
# 1. Open a new terminal and navigate to the frontend directory
cd front

# 2. Fetch Flutter package dependencies
flutter pub get

# 3. Run static code analysis to verify setup
flutter analyze

# 4. Launch app on connected Android emulator or device
flutter run
```

<br />

---

## ⚙️ Environment Variables

Create a `.env` file in the `back/` folder with the following variables:

```env
PORT=5000
NODE_ENV=development

# Google AI & Cloud API Keys
GEMINI_API_KEY=your_google_gemini_api_key_here
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Firebase Configuration
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
FIREBASE_PRIVATE_KEY=your_firebase_private_key

# Third-Party API Keys
CURRENCY_API_KEY=your_currency_api_key_here
```

<br />

---

## 👥 Team GOOGLEISTS

<div align="center">

| Avatar | Developer | Role | Badges | GitHub Profile |
| :---: | :--- | :--- | :---: | :---: |
| <img src="https://github.com/MavisVermie.png" width="50" style="border-radius:50%"/> | **Mohammad Al-Majali** | Backend Lead | `Node.js` `Gemini AI` | [![GitHub](https://img.shields.io/badge/-MavisVermie-181717?style=flat-square&logo=github)](https://github.com/MavisVermie) |
| <img src="https://github.com/MarahYousef01.png" width="50" style="border-radius:50%"/> | **Marah Al-Qunbor** | Backend Engineer | `Express.js` `APIs` | [![GitHub](https://img.shields.io/badge/-MarahYousef01-181717?style=flat-square&logo=github)](https://github.com/MarahYousef01) |
| <img src="https://github.com/Ramaalodat.png" width="50" style="border-radius:50%"/> | **Rama Al-Odat** | Frontend Lead | `Flutter` `UI/UX` | [![GitHub](https://img.shields.io/badge/-Ramaalodat-181717?style=flat-square&logo=github)](https://github.com/Ramaalodat) |
| <img src="https://github.com/github.png" width="50" style="border-radius:50%"/> | **Mohammad Al-Ali** | Frontend Engineer | `Dart` `Mobile` | [![GitHub](https://img.shields.io/badge/-Developer-181717?style=flat-square&logo=github)](#) |

</div>

<br />

---

<div align="center">

  <img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Airplane.png" width="40" alt="Airplane"/>
  <br />
  <b>Designed with ❤️ by Team GOOGLEISTS</b>
  <br />
  <i>Safe & Intelligent Travels with PathFinder AI! 🌍✨</i>

  <br /><br />

  <a href="#-pathfinder-ai"><b>⬆️ Back to Top</b></a>

</div>


