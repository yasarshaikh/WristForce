plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.google.gms.google.services)
}

android {
    namespace = "com.epam.wristforce"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.epam.testappwear"
        minSdk = 30
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"

    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = "11"
    }
    buildFeatures {
        compose = true
    }
}

dependencies {

    implementation(libs.play.services.wearable)
    implementation(platform(libs.compose.bom))
    implementation(libs.ui)
    implementation(libs.ui.graphics)
    implementation(libs.ui.tooling.preview)
    implementation(libs.compose.material)
    implementation(libs.compose.foundation)
    implementation(libs.wear.tooling.preview)
    implementation(libs.activity.compose)
    implementation(libs.core.splashscreen)
    implementation(libs.material3.android)
    implementation(libs.firebase.messaging)
    implementation(libs.runtime.livedata)
    implementation(libs.firebase.firestore.ktx)
    implementation(libs.media3.common.ktx)
    androidTestImplementation(platform(libs.compose.bom))
    androidTestImplementation(libs.ui.test.junit4)
    debugImplementation(libs.ui.tooling)
    debugImplementation(libs.ui.test.manifest)
    implementation(libs.play.services.wearable)
    implementation(platform(libs.compose.bom))
    implementation(libs.ui)
    implementation(libs.ui.graphics)
    implementation(libs.ui.tooling.preview)
//    implementation(libs.material3)
    implementation(libs.activity.compose)
    // Material 3 for Button, TextField, etc.
    //implementation(libs.androidx.compose.material3)

    // Compose runtime & UI core
    implementation(libs.compose.bom)
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.wear.compose:compose-material:1.3.0")
    implementation ("androidx.lifecycle:lifecycle-viewmodel-compose:2.6.1")

    implementation (libs.wear.tooling.preview)
//    implementation(libs.kotlinx.coroutines.play.services)
    // AndroidX Wear Compose Material (already added correctly)
    implementation(libs.play.services.wearable)
// AndroidX Wear Compose Foundation (already added correctly)
    implementation ("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.6.1")


}