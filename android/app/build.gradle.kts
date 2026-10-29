import java.io.FileInputStream
import java.util.Properties

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()

if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use(keystoreProperties::load)
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.gadidost.play"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.gadidost.play"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "Missing android/key.properties. Restore the Play upload key before building a release.",
                )
            }
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.core:core:1.13.1")
    // Flutter's plugin loader resolves empty API jars for these plugins with
    // the current AGP setup. Their release runtime variants contain the plugin
    // entry points referenced by GeneratedPluginRegistrant.
    add(
        "releaseImplementation",
        project(path = ":jni_flutter", configuration = "releaseRuntimeElements"),
    )
    add(
        "releaseImplementation",
        project(path = ":package_info_plus", configuration = "releaseRuntimeElements"),
    )
    add(
        "releaseCompileOnly",
        files(
            rootProject.layout.buildDirectory.file(
                "jni_flutter/intermediates/runtime_library_classes_jar/release/bundleLibRuntimeToJarRelease/classes.jar",
            ),
        ),
    )
    add(
        "releaseCompileOnly",
        files(
            rootProject.layout.buildDirectory.file(
                "package_info_plus/intermediates/runtime_library_classes_jar/release/bundleLibRuntimeToJarRelease/classes.jar",
            ),
        ),
    )
}

tasks.matching { it.name == "preReleaseBuild" }.configureEach {
    dependsOn(
        ":jni_flutter:bundleLibRuntimeToJarRelease",
        ":package_info_plus:bundleLibRuntimeToJarRelease",
    )
}
