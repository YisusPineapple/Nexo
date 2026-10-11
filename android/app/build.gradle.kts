import java.io.FileInputStream
import java.util.Properties

val releaseSigningPropertiesFile = rootProject.file("key.properties")
val releaseSigningProperties = Properties()
if (releaseSigningPropertiesFile.exists()) {
    FileInputStream(releaseSigningPropertiesFile).use {
        releaseSigningProperties.load(it)
    }
}

fun validateReleaseSigningConfiguration(file: java.io.File) {
    if (!file.exists()) {
        throw GradleException(
            "Release signing requires android/key.properties. Create it before running a release build."
        )
    }
    if (!file.isFile) {
        throw GradleException("Release signing key properties must be a file: ${file.path}")
    }

    val properties = Properties()
    FileInputStream(file).use {
        properties.load(it)
    }

    val missingProps = listOf("storePassword", "keyPassword", "keyAlias", "storeFile")
        .filter { properties.getProperty(it)?.trim().isNullOrBlank() }

    if (missingProps.isNotEmpty()) {
        throw GradleException(
            "Release signing requires non-empty values for: ${missingProps.joinToString()}."
        )
    }

    val storeFilePath = properties.getProperty("storeFile")?.trim()
    val storeFile = rootProject.file(storeFilePath ?: "")
    if (storeFilePath.isNullOrBlank()) {
        throw GradleException("Release signing requires a storeFile path in android/key.properties.")
    }
    if (!storeFile.exists()) {
        throw GradleException("Release signing keystore not found: ${storeFile.path}")
    }
    if (!storeFile.isFile) {
        throw GradleException("Release signing keystore must be a regular file: ${storeFile.path}")
    }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "io.github.yisus.nexo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "io.github.yisus.nexo"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = releaseSigningProperties.getProperty("keyAlias")
            keyPassword = releaseSigningProperties.getProperty("keyPassword")
            storePassword = releaseSigningProperties.getProperty("storePassword")

            val storeFilePath = releaseSigningProperties.getProperty("storeFile")?.trim()
            storeFile = if (!storeFilePath.isNullOrBlank()) {
                rootProject.file(storeFilePath)
            } else {
                null
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

tasks.register("validateReleaseSigning") {
    doLast {
        validateReleaseSigningConfiguration(releaseSigningPropertiesFile)
    }
}

tasks.matching {
    it.name == "packageRelease" ||
        it.name == "packageReleaseBundle" ||
        it.name == "packageReleaseUniversalApk" ||
        it.name == "bundleRelease"
}.configureEach {
    dependsOn("validateReleaseSigning")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
