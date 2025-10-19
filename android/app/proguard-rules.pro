# Keep Google ML Kit classes
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.face.** { *; }
-keep class com.google.mlkit.vision.objects.** { *; }
-keep class com.google.mlkit.common.** { *; }

# Keep only Latin text recognition (ignore other languages to avoid missing class errors)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep camera classes
-keep class androidx.camera.** { *; }

# Keep Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google_mlkit_face_detection.** { *; }
-keep class com.google_mlkit_object_detection.** { *; }
-keep class com.google_mlkit_commons.** { *; }

# Keep image picker classes
-keep class io.flutter.plugins.imagepicker.** { *; }

# Disable obfuscation for debugging
-dontobfuscate