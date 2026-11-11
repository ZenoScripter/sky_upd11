import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Firebase (accounts) is enabled only when google-services.json is present and
// only for release builds of the main package (com.wildan.skyfy). Debug and
// F-Droid builds use another package id that has no entry in that file, and
// the plugin would fail them.
val buildsRelease = gradle.startParameter.taskNames.any { task ->
    task.contains("release", ignoreCase = true) &&
        !task.contains("fdroid", ignoreCase = true)
}
if (file("google-services.json").exists() && buildsRelease) {
    apply(plugin = "com.google.gms.google-services")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader ->
        localProperties.load(reader)
    }
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { inputStream ->
        keystoreProperties.load(inputStream)
    }
}

// Release APKs are always signed with the permanent Skyfy key
// (android/app/key.jks + android/key.properties, created from GitHub secrets
// by CI or locally). There is no fallback to the debug key: a release build
// without the key fails with a clear message (see the end of this file).
val hasReleaseKey = file("key.jks").exists() && keystorePropertiesFile.exists()

android {
    namespace = "com.gokadzev.musify"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    defaultConfig {
        applicationId = "com.wildan.skyfy"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "flavor"

    productFlavors {
        create("github") {
            dimension = "flavor"
            applicationIdSuffix = ""
        }
        create("fdroid") {
            dimension = "flavor"
            applicationIdSuffix = ".fdroid"
        }
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKey) {
                // From decoded key
                storeFile = file("key.jks")

                // From key.properties
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildFeatures {
        buildConfig = true
    }

    dependenciesInfo {
        // Disables dependency metadata when building APKs.
        includeInApk = false
        // Disables dependency metadata when building Android App Bundles.
        includeInBundle = false
    }

    buildTypes {
        getByName("release") {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                null
            }
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
        getByName("debug") {
            applicationIdSuffix = ".debug"
        }
    }
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

afterEvaluate {
    apply(from = "../no-build-id.gradle")
}

gradle.taskGraph.whenReady {
    val signsRelease = allTasks.any { task ->
        (task.name.startsWith("assemble") || task.name.startsWith("bundle")) &&
            task.name.contains("Release")
    }
    if (signsRelease && !hasReleaseKey) {
        throw GradleException(
            "Release signing is not configured: android/app/key.jks and " +
                "android/key.properties (storePassword, keyPassword, keyAlias) " +
                "are required. In GitHub Actions add the secrets KEYSTORE_BASE64, " +
                "KEYSTORE_PASSWORD, KEY_PASSWORD and KEY_ALIAS (see GITHUB-SECRETS.md).",
        )
    }
}
