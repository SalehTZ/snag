# youtubedl-android loads its Python/ffmpeg runtime and parses JSON via
# reflection; shrinking or renaming these classes breaks init() in release.
-keep class com.yausername.** { *; }
-keep class org.apache.commons.compress.archivers.zip.** { *; }
-keep class com.fasterxml.jackson.** { *; }
-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod
-dontwarn com.fasterxml.jackson.**
-dontwarn org.apache.commons.compress.**

# Readable stack traces in bug reports.
-keepattributes SourceFile,LineNumberTable
-keep class ir.salehtz.snag.** { *; }
