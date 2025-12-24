# Add project specific ProGuard rules here.

# Keep Gson classes
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep Room entities and DAOs
-keep class * extends androidx.room.RoomDatabase
-keep @androidx.room.Entity class *
-dontwarn androidx.room.paging.**

# Keep data classes
-keep class com.persiangames.gozar.data.** { *; }

# Keep VPN service
-keep class com.persiangames.gozar.XrayVpnService { *; }

# Keep ML Kit
-keep class com.google.mlkit.** { *; }

# Keep CameraX
-keep class androidx.camera.** { *; }
