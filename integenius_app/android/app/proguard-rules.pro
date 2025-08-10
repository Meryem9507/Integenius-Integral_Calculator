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



