# Flutter ve Dart kodlarının minify sonrası çalışmaya devam etmesi için:
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }

# Flutter MethodChannel ve platform kanalları için
-keepclassmembers class * {
    @androidx.annotation.Keep *;
}

# Firebase veya başka üçüncü parti kütüphane kullanıyorsan, onlar için de kurallar eklemelisin
# Örneğin Firebase için tipik kurallar:
#-keep class com.google.firebase.** { *; }
#-dontwarn com.google.firebase.**

# Genel olarak model sınıflarını, verileri koru (örn. JSON parser kullanıyorsan)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# (Opsiyonel) Loglamayı kaldırmak için:
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# R8 uyarılarını önlemek için Google Play Core ile ilgili sınıflar:
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task



