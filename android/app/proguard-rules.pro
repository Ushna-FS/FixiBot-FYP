# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.google.android.play.core.**

# Google Maps & Location
-keep class com.google.android.gms.** { *; }
-keep class com.google.maps.** { *; }
-keep class com.google.android.libraries.places.** { *; }

# Geolocator & Geocoding
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.geocoding.** { *; }

# JSON and serialization
-keepattributes Signature
-keepattributes *Annotation*

# Preserve all Flutter plugin classes
-keep class * extends io.flutter.plugin.platform.PlatformPlugin { *; }
-keep class * implements io.flutter.plugin.common.PluginRegistry { *; }