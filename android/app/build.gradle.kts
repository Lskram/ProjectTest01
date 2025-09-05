plugins {
    id "com.android.application"
    id "kotlin-android"
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id "dev.flutter.flutter-gradle-plugin"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader("UTF-8") { reader ->
        localProperties.load(reader)
    }
}

// Load keystore properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

def flutterVersionCode = localProperties.getProperty("flutter.versionCode")
if (flutterVersionCode == null) {
    flutterVersionCode = "1"
}

def flutterVersionName = localProperties.getProperty("flutter.versionName")
if (flutterVersionName == null) {
    flutterVersionName = "1.0"
}

android {
    namespace = "com.example.office_syndrome_helper"
    compileSdk = 34
    ndkVersion = "23.1.7779620"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId = "com.example.office_syndrome_helper"
        minSdk = 26  // Android 8.0+ for notification runtime permissions
        targetSdk = 34
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
        
        // For MultiDex support if needed
        multiDexEnabled true
        
        // ProGuard/R8 configuration
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }

    signingConfigs {
        debug {
            // Debug signing (auto-generated)
            storeFile file('debug.keystore')
        }
        
        release {
            if (keystorePropertiesFile.exists()) {
                keyAlias keystoreProperties['keyAlias']
                keyPassword keystoreProperties['keyPassword']
                storeFile file(keystoreProperties['storeFile'])
                storePassword keystoreProperties['storePassword']
            }
        }
    }

    buildTypes {
        debug {
            signingConfig signingConfigs.debug
            debuggable true
            minifyEnabled false
            shrinkResources false
            
            // Debug-specific build config fields
            buildConfigField "boolean", "DEBUG_MODE", "true"
            resValue "string", "app_name", "Office Syndrome Helper (Debug)"
        }
        
        profile {
            signingConfig signingConfigs.debug
            debuggable false
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            buildConfigField "boolean", "DEBUG_MODE", "false"
            resValue "string", "app_name", "Office Syndrome Helper (Profile)"
        }
        
        release {
            signingConfig signingConfigs.release
            debuggable false
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            buildConfigField "boolean", "DEBUG_MODE", "false"
            resValue "string", "app_name", "Office Syndrome Helper"
        }
    }

    // Android resource configurations
    resourceConfigurations = ['en', 'th']

    // Lint options
    lint {
        disable 'InvalidPackage'
        checkReleaseBuilds false
        abortOnError false
    }
    
    // PackagingOptions for duplicate files
    packagingOptions {
        pickFirst '**/libc++_shared.so'
        pickFirst '**/libjsc.so'
        exclude 'META-INF/DEPENDENCIES'
        exclude 'META-INF/LICENSE'
        exclude 'META-INF/LICENSE.txt'
        exclude 'META-INF/NOTICE'
        exclude 'META-INF/NOTICE.txt'
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Flutter Dependencies are managed by the Flutter Gradle Plugin
    
    // Additional Android dependencies if needed
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation 'androidx.work:work-runtime:2.8.1'
    implementation 'androidx.core:core-ktx:1.12.0'
}