# PetPal 🐾

A **PetPal** egy modern, keresztplatformos (Flutter alapú) kisállat-gondozó és asszisztens alkalmazás. Célja, hogy segítse a gazdikat a napi feladatok (sétáltatás, etetés, állatorvos) szervezésében, a kutyák egészségügyi adatainak (testsúly, mérföldkövek) nyomon követésében, valamint a feladatok családon belüli (Household) megosztásában.

Az alkalmazás kiemelkedő funkciója az **OpenAI ChatGPT** által hajtott virtuális asszisztens, amely természetes nyelven segít a napi feladatok generálásában és kategorizálásában, valamint a generálható **vészhelyzeti QR kód**, amellyel egy elveszett kutya megtalálója azonnal, applikáció telepítése nélkül is értesítheti a gazdit.

## 🚀 Felhasznált technológiák

- **Frontend:** Flutter & Dart
- **Backend (BaaS):** Firebase (Authentication, Cloud Firestore, Cloud Storage)
- **Szerveroldali logika:** Firebase Cloud Functions (Node.js)
- **Mesterséges Intelligencia:** OpenAI API (GPT-4)

## 📋 Előfeltételek a futtatáshoz

A projekt helyi futtatásához és fejlesztéséhez az alábbi környezetek telepítése szükséges:

1. [Flutter SDK](https://docs.flutter.dev/get-started/install) (és Dart)
2. [Android Studio](https://developer.android.com/studio) vagy [Visual Studio Code](https://code.visualstudio.com/)
3. [Node.js](https://nodejs.org/) (A Cloud Functions teszteléséhez)
4. [Firebase CLI](https://firebase.google.com/docs/cli) eszköz

## 🛠️ Telepítés és Futtatás lépésről lépésre

### 1. Kódbázis letöltése (Clone)
Nyiss egy terminált, és klónozd le a GitHub repozitóriumot:
```bash
git clone https://github.com/leva5789/PetPal.git
cd PetPal
```

### 2. Függőségek telepítése
Töltsd le a Flutter csomagokat és könyvtárakat:
```bash
flutter pub get
```

### 3. Környezeti változók és API kulcsok (Fontos!)
Biztonsági okokból az **OpenAI API kulcs** nincs beégetve a kódba. A Cloud Functions megfelelő működéséhez be kell állítanod a kulcsodat környezeti változóként.

Navigálj a `functions` mappába, telepítsd a Node.js függőségeket, és állítsd be a kulcsot (helyi teszteléshez):
```bash
cd functions
npm install
```
*(Éles Firebase publikálás esetén a Google Secret Managert vagy a Firebase Functions Config-ot szükséges használni).*

### 4. Alkalmazás futtatása
Csatlakoztass egy fizikai teszteszközt (Android/iOS) vagy indíts el egy Emulátort, majd futtasd a projektet a gyökérmappából:
```bash
flutter run
```

---

## 🏗️ Kódbázis struktúrája (lib mappa)

- `lib/widgets/` - Újrafelhasználható UI komponensek (gombok, kártyák, beviteli mezők).
- `lib/app_theme.dart` - Az alkalmazás központi vizuális rendszere (színpaletta, betűtípusok).
- `lib/homepage.dart` - A fő navigációs képernyő és a feladatlista megjelenítése.
- `lib/chat.dart` - Az OpenAI asszisztens felülete.
- `lib/milestones_page.dart` - Emlékek, egészségügyi naplók és képek kezelése.
- `functions/index.js` - A szerveroldali mikroszolgáltatások (AI promptok, képproxy) kódja.

## 🔐 Biztonság és Adatvédelem
A projekt úgy lett felépítve, hogy a felhasználói jelszavakat és a külső API kulcsokat (OpenAI) is maximális biztonsággal kezeli, így a mobilkliensből nem nyerhetők ki érzékeny szerver-konfigurációk. A publikus vészhelyzeti profilok olvasását dedikált Firestore Rules szabályozza.

---
**Fejlesztette:** *Baráti Levente* | Szakdolgozati Projekt (2026)
