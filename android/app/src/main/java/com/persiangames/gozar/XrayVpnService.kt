package com.persiangames.gozar

import android.net.VpnService
import android.content.Intent
import android.os.Build
import android.os.ParcelFileDescriptor

class XrayVpnService : VpnService() {

    private var tunInterface: ParcelFileDescriptor? = null

    override fun onCreate() {
        super.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val builder = Builder()
        builder.setSession("GOZAR VPN")
        builder.addAddress("10.0.0.2", 32)
        builder.addDnsServer("1.1.1.1")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            builder.setMetered(false)
        }
        tunInterface = builder.establish()
        // TODO: Start Xray-core via gomobile with config
        return START_STICKY
    }

    override fun onDestroy() {
        tunInterface?.close()
        tunInterface = null
        // TODO: Stop Xray-core
        super.onDestroy()
    }
}
