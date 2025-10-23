# vivaya

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Java (JDK) requirement for Android builds

This project requires JDK 21 for Android builds. The project is configured
to request Java 21 via Gradle toolchains and Kotlin JVM toolchain. On macOS
you can install and configure JDK 21 as follows.

1. Install JDK 21 via Homebrew (recommended):

```bash
brew update
brew tap homebrew/cask-versions
brew install --cask temurin21
```

1. Set JAVA_HOME (zsh):

```bash
# Temporarily for current session
export JAVA_HOME=$(/usr/libexec/java_home -v 21)

# Persist in ~/.zshrc
echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 21)' >> ~/.zshrc
source ~/.zshrc
```

1. Verify Java and Gradle are using JDK 21:

```bash
java -version
javac -version

# From repo root, verify Gradle and run a quick build
cd android
./gradlew -v
./gradlew assembleDebug --no-daemon
```

Notes:

- The Android Gradle Plugin and Gradle wrapper in this repo are set to
  versions compatible with modern JDKs (AGP 8.9.1, Gradle 8.12). If you
  upgrade AGP or Gradle in future, verify compatibility with Java 21.
- Android Studio: set the IDE JDK to the installed JDK 21 in
  Preferences → Build, Execution, Deployment → Build Tools → Gradle
  (or Settings → Build Tools → Gradle) and set Gradle JVM to Java 21 if
  desired.

If you need help running the build or see compatibility errors, paste the
Gradle output here and I'll help diagnose.

### Troubleshooting (Android/Gradle)

- Ensure JDK 21 is active:

```bash
java -version
```

If Kotlin daemon fails to connect:

```bash
cd android
./gradlew --stop
./gradlew clean assembleDebug
```

In Android Studio, set Gradle JDK = 21 (Preferences → Build Tools → Gradle).

To see deprecations:

```bash
./gradlew --warning-mode all
```

## Next steps (local)

These steps require local access (git and the Flutter toolchain) and may
require you to sign in to Firebase during `flutterfire configure`.

Run these commands from the project root:

```bash
# Create branch and lock gradle wrapper
git checkout -b hardening/java21-toolchains
./gradlew wrapper --gradle-version 8.12 --distribution-type all

# Install flutterfire CLI and run configure (you will authenticate when prompted)
dart pub global activate flutterfire_cli
flutter pub get
flutterfire configure --project-name vivaya --platforms=android,ios

# Commit and push changes
git add .
git commit -m "chore(build): lock Gradle 8.12 wrapper & start hardening"
git push -u origin hardening/java21-toolchains
```

After `flutterfire configure` completes it will add `google-services.json` and
`GoogleService-Info.plist` and update native build files; re-run the Android
build to verify everything works.

