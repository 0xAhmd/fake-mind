# 🤖 Fake Mind

**Fake Mind** is a feature-rich AI-powered chat application built with Flutter, featuring offline-first architecture, real-time synchronization, and intelligent conversation management. Integrated with Google Gemini 2.0 Flash API and Firebase backend for a seamless chat experience.

<div align="center">
  <img src="https://img.shields.io/badge/Flutter-3.19-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-blue?logo=dart" />
  <img src="https://img.shields.io/badge/Gemini%202.0%20Flash-integrated-success" />
  <img src="https://img.shields.io/badge/Firebase-enabled-orange?logo=firebase" />
  <img src="https://img.shields.io/badge/SQLite-local%20storage-green?logo=sqlite" />
</div>

---

## ✨ Features

### 🤖 **AI-Powered Conversations**
- **Google Gemini 2.0 Flash API** integration for intelligent responses
- **Context-aware conversations** with conversation history
- **Message regeneration** - retry failed or unsatisfactory responses
- **Conversation export** to text format

### 💾 **Offline-First Architecture**
- **SQLite local database** for seamless offline functionality
- **Smart synchronization** when connection returns
- **Offline message storage** - never lose a conversation
- **Connection status indicators** with real-time updates

### ☁️ **Firebase Backend Integration**
- **Real-time chat synchronization** across devices
- **Anonymous authentication** for privacy-focused usage
- **Cloud Firestore** for persistent data storage
- **Automatic retry mechanism** for failed syncs

### 💬 **Advanced Chat Management**
- **Multiple conversation support** with chat history
- **Pin important chats** to keep them at the top
- **Search functionality** across all chats and messages
- **Chat renaming** and organization
- **Delete conversations** with confirmation dialogs

### 🎨 **Modern UI/UX**
- **Clean, dark-themed interface** with intuitive navigation
- **Responsive design** optimized for different screen sizes
- **Loading states and animations** for smooth user experience
- **Error handling** with user-friendly messages
- **Connection status banner** showing online/offline state

### 🏗️ **Clean Architecture**
- **MVVM pattern** with Bloc/Cubit state management
- **Repository pattern** for data abstraction
- **Use case layer** for business logic separation
- **Dependency injection** with factory pattern
- **Comprehensive error handling** and logging

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.19 or higher
- Dart 3.x
- Google Gemini API Key from [Google AI Studio](https://makersuite.google.com/app/apikey)
- Firebase project setup (optional for full functionality)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/0xAhmd/fake-mind.git
   cd fake-mind
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up environment variables**
   Create a `.env` file in the root directory:
   ```env
   API_KEY=your_gemini_api_key_here
   ```

4. **Configure Firebase (Optional)**
   - Create a Firebase project
   - Add your Android/iOS app to the project
   - Download and add `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
   - Enable Firestore and Authentication in Firebase Console

5. **Run the app**
   ```bash
   flutter run
   ```

---

## 🧩 Tech Stack

### **Frontend**
- **Flutter** - Cross-platform UI framework
- **Dart** - Programming language
- **flutter_bloc** - State management solution

### **Backend & Services**
- **Google Gemini 2.0 Flash API** - AI conversation engine
- **Firebase Firestore** - Cloud database
- **Firebase Authentication** - User authentication
- **SQLite** - Local data storage

### **Architecture & Patterns**
- **Clean Architecture** - Separation of concerns
- **Repository Pattern** - Data access abstraction
- **MVVM** - Presentation layer architecture
- **Dependency Injection** - Loose coupling

### **Additional Libraries**
- **connectivity_plus** - Network connectivity monitoring
- **sqflite** - SQLite database integration
- **uuid** - Unique identifier generation
- **google_fonts** - Typography
- **quickalert** - User-friendly dialogs

---

## 📂 Project Structure

```
lib/
├── main.dart                          # App entry point
├── constants.dart                     # App-wide constants
├── chat/
│   ├── data/
│   │   ├── model/                     # Data models (ChatModel, MessageModel)
│   │   ├── repo/                      # Repository implementations
│   │   └── services/
│   │       ├── firebase/              # Firebase & API services
│   │       └── offline/               # Local database & connectivity
│   ├── domain/
│   │   ├── repo/                      # Repository interfaces
│   │   └── usecases/                  # Business logic layer
│   └── presentation/
│       ├── cubit/                     # State management
│       ├── pages/                     # UI screens
│       └── widgets/                   # Reusable UI components
```

---

## 🔧 Key Components

### **State Management**
- **ChatCubit** - Main state management for chat functionality
- **ChatState** - Immutable state classes with proper equality
- **Real-time updates** - Reactive UI updates based on state changes

### **Data Layer**
- **ChatRepository** - Abstract data access interface
- **DatabaseHelper** - SQLite database operations
- **FirebaseService** - Cloud synchronization and real-time updates

### **Business Logic**
- **ChatManagementUseCase** - Chat CRUD operations
- **MessageUseCase** - Message handling and search
- **SyncUseCase** - Online/offline synchronization logic

---

## 🌟 App Features in Detail

### **Offline Functionality**
The app works seamlessly offline, storing all messages locally and syncing when connection returns. Users can:
- Send and receive messages without internet
- Browse chat history offline
- Create and manage chats locally
- Automatic sync when back online

### **Smart Synchronization**
- **Conflict resolution** for simultaneous edits
- **Failed message retry** with exponential backoff
- **Batch operations** for efficient sync
- **Real-time streams** when online

### **User Experience**
- **Intuitive navigation** between chat list and conversation
- **Search across all messages** with highlighting
- **Pin/unpin chats** for easy access
- **Export conversations** for backup or sharing

---

## 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you'd like to change.

### **Development Setup**
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 🐛 Known Issues

- Firebase authentication requires internet connectivity on first launch
- Large conversation exports may take time to generate
- iOS Firebase setup requires additional Xcode configuration

---

## 🔮 Future Enhancements

- [ ] **Image sharing** in conversations
- [ ] **Voice messages** support
- [ ] **Multi-language** AI responses
- [ ] **Theme customization** options
- [ ] **Desktop support** with responsive design
- [ ] **Group conversations** functionality
- [ ] **Message encryption** for enhanced privacy

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Google Gemini AI** for providing the powerful language model
- **Flutter team** for the amazing cross-platform framework
- **Firebase** for the robust backend infrastructure
- **Open source community** for the incredible packages and tools

---

> **Built with ❤️ using Flutter, Firebase, and Google Gemini AI**  
> *My first Flutter project - a journey of self-learning and AI collaboration*

<div align="center">
  <img src="https://img.shields.io/github/stars/0xAhmd/fake-mind?style=social" />
  <img src="https://img.shields.io/github/forks/0xAhmd/fake-mind?style=social" />
  <img src="https://img.shields.io/github/watchers/0xAhmd/fake-mind?style=social" />
</div>
