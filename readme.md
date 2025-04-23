# 🚀 Flutter Fast Deploy - Build Binaries Script 🛠️

Welcome to **Flutter Fast Deploy**! This script is your all-in-one solution for building, distributing, and managing your Flutter app binaries for Android and iOS. Whether you're targeting Firebase, the Play Store, or the App Store, this script makes deployment a breeze. Let's get started! 🌟

---

## 📜 What Does `build.sh` Do?

Think of this script as your deployment sidekick. Here's what it handles:

1. **Version Management**:  
   Automatically reads the current version and build number from `pubspec.yaml` and increments it after a successful build. No manual edits required!

2. **Changelog Generation**:  
   Fetches the latest Git commit messages and formats them into a clean changelog for your release.

3. **Build Automation**:  
   - Builds Android APKs or App Bundles (`.aab`) and iOS IPAs (`.ipa`) based on your selected mode (`--release` or `--debug`).
   - Ensures all output directories are ready to go.

4. **Distribution**:  
   - **Android**:  
     - Uses **Fastlane** to upload builds to the Play Store (Internal App Sharing or Production).  
     - Optionally distributes builds via **Firebase App Distribution**.
   - **iOS**:  
     - Uses **xcrun altool** to upload `.ipa` files to the App Store.

5. **Error Handling**:  
   Logs all errors and ensures the build process halts gracefully if something goes wrong. No more guesswork!

---

## 🛠️ Tools Required

Before you start, make sure you have the following tools installed:

1. **Flutter SDK**:  
   Install Flutter from [flutter.dev](https://flutter.dev/docs/get-started/install).

2. **Fastlane** (for Android distribution):  
   Install Fastlane by following the guide at [fastlane.tools](https://docs.fastlane.tools/getting-started/ios/setup/).

3. **Firebase CLI** (optional, for Firebase App Distribution):  
   Install Firebase CLI by running:  
   ```bash
   npm install -g firebase-tools
   ```

4. **Xcode Command Line Tools** (for iOS builds):  
   Install Xcode and ensure `xcrun` is available.

5. **Git**:  
   Ensure Git is installed and configured for changelog generation.

6. **Google Cloud Service Account Key** (for Fastlane):  
   Download the JSON key file for your Google Cloud service account. This is required for Fastlane to upload your Android builds to the Play Store.

---

## 🛠️ How to Use

### 1. Set Up Your Environment  

Create a `.distribution.env` file in the root directory with the following structure:

```env
# Android Configuration
ANDROID_BUILD=true
ANDROID_PACKAGE_NAME=
ANDROID_FIREBASE_APP_ID=
ANDROID_FIREBASE_GROUPS=

# iOS Configuration
IOS_BUILD=true
IOS_DISTRIBUTION_USER=
IOS_DISTRIBUTION_PASSWORD=

# Distribution Options
USE_FASTLANE=true
USE_FIREBASE=true
```

#### Filling the `.distribution.env` File:

1. **ANDROID_BUILD**:  
   Set to `true` if you want to build Android binaries.

2. **ANDROID_PACKAGE_NAME**:  
   Provide your app's package name (e.g., `com.example.app`).

3. **ANDROID_FIREBASE_APP_ID**:  
   If using Firebase App Distribution, provide your Firebase App ID. Leave blank if not using Firebase.

4. **ANDROID_FIREBASE_GROUPS**:  
   Specify Firebase tester groups (comma-separated) for distribution. Leave blank if not using Firebase.

5. **IOS_BUILD**:  
   Set to `true` if you want to build iOS binaries.

6. **IOS_DISTRIBUTION_USER**:  
   Provide your Apple ID for App Store distribution.

7. **IOS_DISTRIBUTION_PASSWORD**:  
   Provide your app-specific password for App Store distribution. Generate it from [Apple ID settings](https://support.apple.com/en-us/HT204397).

8. **USE_FASTLANE**:  
   Set to `true` to enable Fastlane for Android distribution.

9. **USE_FIREBASE**:  
   Set to `true` to enable Firebase App Distribution.

#### Placing the `distribution/fastlane.json` File:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Navigate to **IAM & Admin > Service Accounts**.
3. Select or create a service account with **Editor** or **Release Manager** permissions for your Play Store project.
4. Generate a JSON key for the service account and download it.
5. Place the JSON key file in the `distribution` directory and name it `fastlane.json`.

Put it on your project directory, same level as `lib`, Your directory structure should look like this:

```
your_project_directory
  ├── lib
  ├── distribution
      ├── fastlane.json
```

---

### 2. Run the Script  

Run the script with your desired mode:

```bash
./build.sh --release
```

Or, for debug mode:

```bash
./build.sh --debug
```

---

## 🌟 Key Features

### Android Distribution  
- **Fastlane Integration**:  
  Automatically uploads your `.aab` files to the Play Store.  
  If metadata is missing, it downloads it for you.  
  Optionally, distribute builds via **Firebase App Distribution** for internal testing.

### iOS Distribution  
- **xcrun altool**:  
  Uploads `.ipa` files directly to the App Store. Just provide your Apple ID and app-specific password in `.distribution.env`.

---

## 📝 Pro Tips

- **Changelogs**:  
  The script generates changelogs from your Git commit messages. Keep your commit messages meaningful!

- **Environment Variables**:  
  Keep your `.distribution.env` file secure. It contains sensitive credentials.

- **Error Logs**:  
  Check `builds.log` for detailed error messages if something goes wrong.

---

Deploy your Flutter app like a pro with **Flutter Fast Deploy**! 🚀✨
