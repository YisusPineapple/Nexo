# Nexo Music Player 🎵

An oasis of local music for older hardware. Nexo is a beautiful, 100% offline, and ultra-lightweight music player built with Flutter, designed to run flawlessly on everything from a 2010 Pentium PC to a low-end Android device.

![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)
![Flutter](https://img.shields.io/badge/Built_with-Flutter-02569B?logo=flutter)
![Platforms](https://img.shields.io/badge/Platforms-Android%20|%20Linux%20|%20Windows-success)

## ✨ Features

* **Ultra-Lightweight:** Strictly designed to consume less than 120MB RAM on Android and 250MB on Desktop.
* **100% Offline & Private:** No tracking, no cloud sync, no accounts. Your music, your device.
* **Pro Audio Engine:** Gapless playback, Constant-Power Crossfade, AutoMix, and ReplayGain support.
* **Format Support:** MP3, FLAC, AAC, Opus, Vorbis, WAV, and more.
* **Adaptive Warmth UI:** A gorgeous Material You interface with a warm terracotta/cream palette that adapts to your device's performance (Vivo/Eco modes).
* **Advanced Library Management:** Multiple artist delimiters, folder exclusion, and smart playlists.
* **Nexo "For You":** On-device, offline generation of Daily Mixes and listening statistics.

## 🚀 Hardware Requirements

Nexo is built with extreme pragmatism. It doesn't just claim to be lightweight; it is architected for it.
* **Android:** Helio G85 (or equivalent) / 2GB RAM minimum.
* **Desktop:** Intel Pentium E5800 (2010) / 4GB RAM minimum.

## 🛠️ Building from Source

Make sure you have [Flutter](https://flutter.dev/docs/get-started/install) installed (Version 3.24+).

```bash
git clone https://github.com/YisusPineapple/Nexo.git
cd Nexo
flutter pub get
flutter run --release
```

## 🔐 Release signing

Release builds require a persisted Android signing keystore configured in the ignored file `android/key.properties` relative to the repository root. The file is not committed to the repository and is expected to contain the following values:

```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=app/nexo-release.jks
```

The `storeFile` value is resolved relative to the Android Gradle project directory (`android/`), so `app/nexo-release.jks` resolves to `android/app/nexo-release.jks`. Real signing credentials must never be committed to Git.

For GitHub Actions, the repository uses the secrets `RELEASE_KEYSTORE_BASE64`, `RELEASE_KEYSTORE_PASSWORD`, `RELEASE_KEY_ALIAS`, and `RELEASE_KEY_PASSWORD`. The CI workflow validates these inputs by decoding the keystore and verifying its integrity (password and alias) using `keytool` before proceeding with the build. If the keystore is missing, empty, or invalid, the workflow fails immediately. Debug signing is not a release fallback.
