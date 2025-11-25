# qlnh_nhan_vien

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Troubleshooting

### Android build errors (Jetifier / BouncyCastle / Java version)

If you see an error like:

```
Failed to transform bcprov-jdk18on-1.78.1.jar ... Unsupported class file major version 65
```

It usually means a dependency (e.g., BouncyCastle that Robolectric uses as a transitive dependency) was compiled using a newer Java (for example Java 21) that the Gradle/Jetty transformation tools cannot process.

Solutions (try in order):

1. Preferable — use JDK 17 for Gradle (recommended)

	 - Install JDK 17 and configure Gradle to use it.
		 Example (PowerShell):

		 ```powershell
		 setx -m JAVA_HOME "C:\\Program Files\\Java\\jdk-17"
		 $env:JAVA_HOME = 'C:\\Program Files\\Java\\jdk-17'
		 $env:Path = $env:JAVA_HOME + '\\bin;' + $env:Path
		 cd android
		 ./gradlew --version
		 cd ..
		 fvm flutter clean
		 fvm flutter pub get
		 fvm flutter build apk
		 ```

	 - Alternatively add the path to `android/gradle.properties`:
		 ```properties
		 org.gradle.java.home=C:\\Program Files\\Java\\jdk-17
		 ```

2. If you cannot install JDK 17, a short-term workaround is to disable Jetifier — only do this if all libraries are already AndroidX-compliant.

	 Open `android/gradle.properties` and set:
	 ```properties
	 android.enableJetifier=false
	 ```

3. Avoid forcing arbitrary BouncyCastle versions globally. This can break resolution. Instead, prefer the JDK change above or targeted dependency resolution in the plugin that's actually using it.

If the build continues to fail, run Gradle with a stacktrace from `android/` and share the logs:

```powershell
cd android
./gradlew assembleRelease --stacktrace
```
