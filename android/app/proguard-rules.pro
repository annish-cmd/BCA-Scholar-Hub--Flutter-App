# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.BuildConfig { *; }
-keep class io.flutter.embedding.** { *; }
-keep class androidx.lifecycle.LifecycleOwner { *; }

# AndroidX
-keep class androidx.lifecycle.DefaultLifecycleObserver { *; }

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Other
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugin.**
-dontwarn io.flutter.util.**
-dontwarn io.flutter.view.**