package com.persiangames.gozar

import android.app.Application
import android.util.Log
import com.persiangames.gozar.data.GozarDatabase
import java.io.File
import java.io.FileOutputStream

class GozarApplication : Application() {
    
    val database: GozarDatabase by lazy { 
        GozarDatabase.getInstance(this) 
    }
    
    override fun onCreate() {
        super.onCreate()
        installXrayAssets()
    }

    /**
     * Copies geosite.dat and geoip.dat from src/main/assets/xray into filesDir/xray
     * so Xray-core can load them by file path at runtime.
     */
    private fun installXrayAssets() {
        val targetDir = File(filesDir, "xray")
        if (!targetDir.exists() && !targetDir.mkdirs()) {
            Log.w(TAG, "Failed to create xray dir: ${targetDir.absolutePath}")
            return
        }

        val names = listOf("geosite.dat", "geoip.dat")
        names.forEach { name ->
            val outFile = File(targetDir, name)
            if (!outFile.exists() || (outFile.exists() && outFile.length() == 0L)) {
                try {
                    assets.open("xray/$name").use { input ->
                        FileOutputStream(outFile).use { output ->
                            input.copyTo(output)
                        }
                    }
                    Log.i(TAG, "Installed $name to ${outFile.absolutePath}")
                } catch (e: Exception) {
                    Log.e(TAG, "Missing asset xray/$name; add it under src/main/assets/xray/", e)
                    // Don't create a placeholder - Xray expects valid binary data
                    // The absence of the file will be clear from the error log above
                }
            }
        }
    }

    companion object {
        private const val TAG = "GozarApplication"
    }
}
