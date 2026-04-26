<p align="center">
  <img src="landing_page/favicon.png" width="100" alt="SpellIt Logo" style="border-radius: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.1);">
</p>

# SpellIt | Conquer the Grid 🛡️⚡

**SpellIt** is a fast-paced, real-time multiplayer word battle game built with Flutter and Firebase. Challenge your vocabulary, use strategic power-ups, and climb the global leaderboard in 2-minute PvP duels.

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

---

## 🎮 Gameplay Features

### ⚔️ Real-Time PvP Battles
Engage in intense 2-minute word duels. Tap letters on the grid to form words and damage your opponent. The more complex the word, the higher the damage!

### 🧪 Strategic Power-ups
Turn the tide of battle with unique power-ups:
- **Freeze**: Lock your opponent's grid for a few seconds.
- **Shield**: Protect yourself from incoming damage.
- **Bonus**: Double your score for the next word.

### 🏆 Ranked Seasons
Compete in the live Global Leaderboard. Earn exclusive badges and climb from Bronze to Legend each season.

---

## 📸 Screenshots

<p align="center">
  <img src="landing_page/assets/images/screenshots/IMG_1682.PNG" width="250" alt="Main Menu">
  <img src="landing_page/assets/images/screenshots/IMG_1683.PNG" width="250" alt="Word Battle">
  <img src="landing_page/assets/images/screenshots/IMG_1684.PNG" width="250" alt="Power-up Shop">
</p>
<p align="center">
  <img src="landing_page/assets/images/screenshots/IMG_1685.PNG" width="250" alt="Leaderboard">
  <img src="landing_page/assets/images/screenshots/IMG_1686.PNG" width="250" alt="Profile Stats">
  <img src="landing_page/assets/images/screenshots/IMG_1687.PNG" width="250" alt="Daily Rewards">
</p>

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0.0+)
- [Firebase Account](https://console.firebase.google.com/)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/misterbrown3404/spellit.git
   cd spellit
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
   - Create a new Firebase project.
   - Run `flutterfire configure` to set up your environment.

4. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📦 Production & Signing

This project is pre-configured for Android release signing.

1. Generate your keystore:
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Update `android/key.properties` with your credentials.
3. Build the App Bundle:
   ```bash
   flutter build appbundle
   ```

---

## 🌐 Landing Page
The project includes a fully responsive premium landing page located in the `/landing_page` directory. It's built with modern HSL colors, glassmorphism, and mobile-ready navigation.

---

## 👨‍💻 Built By
Developed with ❤️ by **NureHub Studios**. 

- [Website](https://spellit.infinityfree.me)
- [Support](mailto:annurdevelopers@gmail.com)

----


## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
