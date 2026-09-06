# Add project-specific ProGuard rules here.
# By default, the flags in this file are applied to the release build.

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift / SQLite
-keep class com.tekartik.sqflite.** { *; }
-keep class org.sqlite.** { *; }

# Supabase / Postgrest / Realtime
-keep class io.supabase.** { *; }
-keep class com.supabase.** { *; }
-dontwarn io.supabase.**

# OkHttp (used by Supabase)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# WorkManager
-keep class androidx.work.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# Keep app models (Dart/Flutter generated code)
-keep class com.focusflow.app.** { *; }

# Remove logging in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Google Play Core - Split Install (referenced by Flutter engine for Deferred Components)
# Not used by this app - safe to ignore
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Firebase / Google Play Services (optional classes)
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Dart / Flutter JNI bridge
-dontwarn io.flutter.embedding.**

# Ktor / Supabase networking
-dontwarn io.ktor.**
-dontwarn kotlinx.serialization.**
-keep class kotlinx.serialization.** { *; }

# Suppress misc generated class warnings
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
