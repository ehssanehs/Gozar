package com.persiangames.gozar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.core.app.NotificationCompat
import com.persiangames.gozar.data.GozarDatabase
import com.persiangames.gozar.utils.XrayConfigBuilder
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class XrayVpnService : VpnService() {

    private var tunInterface: ParcelFileDescriptor? = null
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var isRunning = false

    companion object {
        private const val TAG = "XrayVpnService"
        private const val NOTIFICATION_ID = 1
        private const val CHANNEL_ID = "gozar_vpn_channel"
        const val ACTION_START = "com.persiangames.gozar.START_VPN"
        const val ACTION_STOP = "com.persiangames.gozar.STOP_VPN"
        const val EXTRA_CONNECTION_ID = "connection_id"
        
        private var currentConnectionId: Long? = null
        
        fun isConnected(): Boolean {
            return currentConnectionId != null
        }
        
        fun getCurrentConnectionId(): Long? {
            return currentConnectionId
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand: action=${intent?.action}")
        
        when (intent?.action) {
            ACTION_START -> {
                val connectionId = intent.getLongExtra(EXTRA_CONNECTION_ID, -1L)
                if (connectionId != -1L) {
                    startVpn(connectionId)
                } else {
                    Log.e(TAG, "No connection ID provided")
                    stopSelf()
                }
            }
            ACTION_STOP -> {
                stopVpn()
                stopSelf()
            }
            else -> {
                Log.w(TAG, "Unknown action: ${intent?.action}")
            }
        }
        
        return START_STICKY
    }

    private fun startVpn(connectionId: Long) {
        if (isRunning && currentConnectionId == connectionId) {
            Log.d(TAG, "VPN already running with connection $connectionId")
            return
        }
        
        // Stop current connection if different
        if (isRunning && currentConnectionId != connectionId) {
            Log.d(TAG, "Switching connection from $currentConnectionId to $connectionId")
            stopVpnCore()
        }
        
        serviceScope.launch {
            try {
                val db = GozarDatabase.getInstance(applicationContext)
                val connection = db.connectionDao().getConnectionById(connectionId)
                
                if (connection == null) {
                    Log.e(TAG, "Connection not found: $connectionId")
                    stopSelf()
                    return@launch
                }
                
                // Get all connections for config generation
                val allConnections = db.connectionDao().getAllConnections().value ?: emptyList()
                
                // Build Xray config
                val config = XrayConfigBuilder.buildConfig(allConnections, connectionId)
                Log.d(TAG, "Generated Xray config for connection: ${connection.name}")
                
                // Establish VPN tunnel
                val builder = Builder()
                builder.setSession("GOZAR VPN - ${connection.name}")
                builder.addAddress("10.0.0.2", 32)
                builder.addRoute("0.0.0.0", 0)
                builder.addDnsServer("1.1.1.1")
                builder.addDnsServer("8.8.8.8")
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    builder.setMetered(false)
                }
                
                // Allow apps to bypass VPN if needed
                builder.allowFamily(android.system.OsConstants.AF_INET)
                builder.allowFamily(android.system.OsConstants.AF_INET6)
                
                tunInterface?.close()
                tunInterface = builder.establish()
                
                if (tunInterface == null) {
                    Log.e(TAG, "Failed to establish VPN interface")
                    stopSelf()
                    return@launch
                }
                
                // TODO: Start Xray-core via gomobile with config
                // For now, just simulate running
                Log.d(TAG, "VPN tunnel established for ${connection.name}")
                
                currentConnectionId = connectionId
                isRunning = true
                
                // Start as foreground service
                startForeground(NOTIFICATION_ID, createNotification(connection.name, true))
                
                // Save connection state
                saveConnectionState(connectionId)
                
            } catch (e: Exception) {
                Log.e(TAG, "Error starting VPN", e)
                stopSelf()
            }
        }
    }

    private fun stopVpn() {
        Log.d(TAG, "Stopping VPN")
        stopVpnCore()
        clearConnectionState()
    }

    private fun stopVpnCore() {
        try {
            // TODO: Stop Xray-core via gomobile
            
            tunInterface?.close()
            tunInterface = null
            currentConnectionId = null
            isRunning = false
            
            Log.d(TAG, "VPN core stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping VPN core", e)
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "Service destroyed")
        stopVpnCore()
        serviceScope.cancel()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "VPN Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifications for VPN service status"
                setShowBadge(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(connectionName: String, isConnected: Boolean): Notification {
        val pendingIntentFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(this, 0, intent, pendingIntentFlags)
        
        val disconnectIntent = Intent(this, XrayVpnService::class.java).apply {
            action = ACTION_STOP
        }
        val disconnectPendingIntent = PendingIntent.getService(this, 0, disconnectIntent, pendingIntentFlags)
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("GOZAR VPN")
            .setContentText(if (isConnected) "Connected to $connectionName" else "Connecting...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Disconnect",
                disconnectPendingIntent
            )
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun saveConnectionState(connectionId: Long) {
        val prefs = getSharedPreferences("gozar_prefs", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putLong("selected_connection_id", connectionId)
            putBoolean("was_connected", true)
            apply()
        }
    }

    private fun clearConnectionState() {
        val prefs = getSharedPreferences("gozar_prefs", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putBoolean("was_connected", false)
            apply()
        }
    }
}
