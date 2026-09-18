import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore =
    keystorePropertiesFile.exists().also { exists ->
        if (exists) {
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))
        }
    }

android {
    namespace = "com.zoti321.hentailibrary"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.zoti321.hentailibrary"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    // Local release builds without key.properties still use debug keys.
                    signingConfigs.getByName("debug")
                }
        }
    }
}

val syncLauncherIcons =
    tasks.register("syncLauncherIcons") {
        doLast {
            val appRoot = file("../../")
            val assetsRoot = appRoot.resolve("assets/icons/android")
            val resRoot = file("src/main/res")
            listOf(
                "mipmap-mdpi",
                "mipmap-hdpi",
                "mipmap-xhdpi",
                "mipmap-xxhdpi",
                "mipmap-xxxhdpi",
            ).forEach { density ->
                copy {
                    from(assetsRoot.resolve("$density/ic_launcher.png"))
                    into(resRoot.resolve(density))
                }
            }
        }
    }

tasks.named("preBuild").configure { dependsOn(syncLauncherIcons) }

flutter {
    source = "../.."
}
