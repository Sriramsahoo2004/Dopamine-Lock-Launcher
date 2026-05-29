package com.dopaminelock.launcher

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {

    private val channelName = "com.dopaminelock/launcher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    result.success(getInstalledApps())
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        launchApp(packageName, result)
                    } else {
                        result.error("INVALID_ARG", "Package name is required", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm: PackageManager = packageManager
        val apps = mutableListOf<Map<String, Any>>()

        val intent = Intent(Intent.ACTION_MAIN, null).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
        }

        val packages = pm.queryIntentActivities(intent, 0)

        for (resolveInfo in packages) {
            val packageName = resolveInfo.activityInfo.packageName
            val appName = resolveInfo.loadLabel(pm).toString()

            if (packageName == applicationContext.packageName || shouldHidePackage(packageName)) {
                continue
            }

            try {
                val icon = resolveInfo.loadIcon(pm)
                val stream = ByteArrayOutputStream()
                drawableToBitmap(icon).compress(Bitmap.CompressFormat.PNG, 100, stream)
                val iconBytes = stream.toByteArray()

                apps.add(mapOf(
                    "packageName" to packageName,
                    "appName" to appName,
                    "icon" to iconBytes
                ))
            } catch (e: Exception) {
                // Skip apps we can't get icon for
            }
        }
        return apps.sortedBy { (it["appName"] as String).lowercase() }
    }

    private fun launchApp(packageName: String, result: MethodChannel.Result) {
        try {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launchIntent)
                result.success(true)
            } else {
                result.error("LAUNCH_FAILED", "Could not launch app", null)
            }
        } catch (e: Exception) {
            result.error("LAUNCH_ERROR", e.message, null)
        }
    }

    private fun shouldHidePackage(packageName: String): Boolean {
        val allowedGoogleApps = setOf(
            "com.android.chrome",
            "com.google.android.youtube",
            "com.google.android.apps.youtube.music",
            "com.google.android.gm",
            "com.google.android.apps.maps",
            "com.google.android.apps.photos"
        )

        return (packageName.startsWith("com.android.") && packageName !in allowedGoogleApps) ||
            (packageName.startsWith("com.google.android.") && packageName !in allowedGoogleApps)
    }

    private fun drawableToBitmap(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }

        val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: 96
        val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: 96
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }
}
