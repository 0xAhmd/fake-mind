
# 🤖 Fake Mind

**Fake Mind** is a simple AI-powered chatbot app built with Flutter and integrated with the Gemini API. It provides intelligent, context-aware responses with support for Markdown-formatted output, all wrapped in a clean, minimal, and responsive UI.

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.19-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-blue?logo=dart" />
  <img src="https://img.shields.io/badge/Gemini%20API-integrated-success" />
</div>

---

## ✨ Features

- 💬 AI-powered interactive chatbot
- 🧠 Context-aware responses using **Gemini API**
- 📝 Supports **Markdown-formatted** output
- 🖼️ Clean and minimal **Flutter UI**
- 📱 Fully responsive and user-friendly design
- 🌙 Light & Dark mode ready (optional)

---

## 🚀 Getting Started

### Prerequisites

- Flutter 3.x
- Dart 3.x
- Gemini API Key from Google AI Studio

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/0xAhmd/fake-mind.git
   cd fake-mind
````

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Add your Gemini API key**

   Create a `.env` file or insert your API key in the appropriate service file:

   ```dart
   const String geminiApiKey = 'YOUR_API_KEY_HERE';
   ```

4. **Run the app**

   ```bash
   flutter run
   ```

---

## 🧩 Tech Stack

* **Flutter** – for cross-platform UI
* **Dart** – programming language
* **Gemini API** – AI responses
* **Markdown** – output formatting
* **Provider/BLoC/Riverpod** – (depends on what you're using for state management)

---

## 📂 Project Structure

```bash
lib/
├── main.dart
├── ui/            # UI widgets and screens
├── services/      # Gemini API integration
├── models/        # Data models
└── utils/         # Helpers, formatters
```
## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you’d like to change.

---

> Built with ❤️ using Flutter and Gemini AI

```
