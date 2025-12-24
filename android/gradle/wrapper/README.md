# Gradle Wrapper JAR

The `gradle-wrapper.jar` file is required for the Gradle wrapper to function but is not included in this repository due to download restrictions.

## How to Obtain gradle-wrapper.jar

### Option 1: Generate with System Gradle

If you have Gradle installed:

```bash
cd android
gradle wrapper --gradle-version 8.2.2
```

This will download and set up the wrapper JAR automatically.

### Option 2: Download Manually

1. Download Gradle 8.2.2:
   ```bash
   wget https://services.gradle.org/distributions/gradle-8.2.2-bin.zip
   ```

2. Extract the archive:
   ```bash
   unzip gradle-8.2.2-bin.zip
   ```

3. Copy the wrapper JAR:
   ```bash
   cp gradle-8.2.2/lib/gradle-wrapper-8.2.2.jar android/gradle/wrapper/gradle-wrapper.jar
   ```

### Option 3: Use the Build Script

The build script will attempt to generate it automatically:

```bash
cd scripts
./build_android_native.sh
# Select option 1: Install all prerequisites
```

## Verification

After obtaining the JAR, verify it:

```bash
file android/gradle/wrapper/gradle-wrapper.jar
# Should show: Java archive data (JAR)

ls -lh android/gradle/wrapper/gradle-wrapper.jar
# Should be approximately 60-70 KB
```

## Why Not Committed?

Binary files can bloat the repository, and the wrapper JAR is easily regenerated. Most Android projects follow this pattern or regenerate the wrapper as part of their build process.
