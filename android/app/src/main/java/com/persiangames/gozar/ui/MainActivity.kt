package com.persiangames.gozar.ui

import android.Manifest
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.lifecycle.ViewModelProvider
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.android.material.snackbar.Snackbar
import com.persiangames.gozar.R
import com.persiangames.gozar.XrayVpnService
import com.persiangames.gozar.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding
    private lateinit var viewModel: MainViewModel
    private lateinit var adapter: ConnectionAdapter
    
    private var pendingConnectionId: Long? = null

    private val vpnPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            pendingConnectionId?.let { connectionId ->
                startVpnService(connectionId)
                pendingConnectionId = null
            }
        } else {
            Toast.makeText(this, "VPN permission denied", Toast.LENGTH_SHORT).show()
            pendingConnectionId = null
        }
    }

    private val notificationPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (!isGranted && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Toast.makeText(
                this,
                "Notification permission is recommended for VPN status updates",
                Toast.LENGTH_LONG
            ).show()
        }
    }

    private val qrScanLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == RESULT_OK) {
            val link = result.data?.getStringExtra("scanned_link")
            if (link != null) {
                viewModel.addConnectionFromLink(link)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setSupportActionBar(binding.toolbar)
        
        viewModel = ViewModelProvider(this)[MainViewModel::class.java]
        
        setupRecyclerView()
        setupObservers()
        setupClickListeners()
        
        // Request notification permission on Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) 
                != PackageManager.PERMISSION_GRANTED) {
                notificationPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        
        // Auto-reconnect if VPN was connected before
        checkAndAutoReconnect()
    }
    
    private fun checkAndAutoReconnect() {
        val prefs = getSharedPreferences("gozar_prefs", Context.MODE_PRIVATE)
        val wasConnected = prefs.getBoolean("was_connected", false)
        val selectedConnectionId = prefs.getLong("selected_connection_id", -1L)
        
        if (wasConnected && selectedConnectionId != -1L) {
            // Check VPN permission
            val intent = VpnService.prepare(this)
            if (intent == null) {
                // Permission already granted, auto-reconnect
                startVpnService(selectedConnectionId)
            }
            // If permission not granted, user will need to manually connect
        }
    }

    private fun setupRecyclerView() {
        adapter = ConnectionAdapter(
            onConnectionClick = { connection ->
                viewModel.selectConnection(connection.id)
            },
            onDeleteClick = { connection ->
                showDeleteConfirmation(connection)
            }
        )
        
        binding.recyclerView.layoutManager = LinearLayoutManager(this)
        binding.recyclerView.adapter = adapter
    }

    private fun setupObservers() {
        viewModel.allConnections.observe(this) { connections ->
            adapter.submitList(connections)
            updateEmptyState(connections.isEmpty())
        }
        
        viewModel.selectedConnectionId.observe(this) { connectionId ->
            adapter.setSelectedId(connectionId)
            updateConnectButton()
            
            // Auto-reconnect if VPN is currently connected
            if (viewModel.isConnected.value == true && connectionId != null) {
                val currentConnectionId = XrayVpnService.getCurrentConnectionId()
                if (currentConnectionId != null && currentConnectionId != connectionId) {
                    // Connection changed while VPN is active, reconnect
                    startVpnService(connectionId)
                }
            }
        }
        
        viewModel.isConnected.observe(this) { isConnected ->
            updateConnectButton()
        }
        
        viewModel.errorMessage.observe(this) { message ->
            message?.let {
                Snackbar.make(binding.root, it, Snackbar.LENGTH_LONG).show()
                viewModel.clearErrorMessage()
            }
        }
        
        viewModel.successMessage.observe(this) { message ->
            message?.let {
                Snackbar.make(binding.root, it, Snackbar.LENGTH_SHORT).show()
                viewModel.clearSuccessMessage()
            }
        }
    }

    private fun setupClickListeners() {
        binding.connectButton.setOnClickListener {
            handleConnectButtonClick()
        }
        
        binding.fabAddLink.setOnClickListener {
            showAddLinkDialog()
        }
        
        binding.fabScanQr.setOnClickListener {
            val intent = Intent(this, QrScanActivity::class.java)
            qrScanLauncher.launch(intent)
        }
        
        binding.fabPasteClipboard.setOnClickListener {
            pasteFromClipboard()
        }
    }

    private fun updateConnectButton() {
        val isConnected = viewModel.isConnected.value ?: false
        val hasSelection = viewModel.selectedConnectionId.value != null
        
        if (isConnected) {
            binding.connectButton.text = "Disconnect"
            binding.connectButton.isEnabled = true
        } else if (hasSelection) {
            binding.connectButton.text = "Connect"
            binding.connectButton.isEnabled = true
        } else {
            binding.connectButton.text = "Connect"
            binding.connectButton.isEnabled = false
        }
    }

    private fun updateEmptyState(isEmpty: Boolean) {
        if (isEmpty) {
            binding.emptyStateText.visibility = android.view.View.VISIBLE
            binding.recyclerView.visibility = android.view.View.GONE
        } else {
            binding.emptyStateText.visibility = android.view.View.GONE
            binding.recyclerView.visibility = android.view.View.VISIBLE
        }
    }

    private fun handleConnectButtonClick() {
        val isConnected = viewModel.isConnected.value ?: false
        
        if (isConnected) {
            // Disconnect
            stopVpnService()
        } else {
            val connectionId = viewModel.selectedConnectionId.value
            if (connectionId == null) {
                Snackbar.make(binding.root, "Select a connection first", Snackbar.LENGTH_SHORT).show()
                return
            }
            
            // Check VPN permission
            val intent = VpnService.prepare(this)
            if (intent != null) {
                pendingConnectionId = connectionId
                vpnPermissionLauncher.launch(intent)
            } else {
                startVpnService(connectionId)
            }
        }
    }

    private fun startVpnService(connectionId: Long) {
        val intent = Intent(this, XrayVpnService::class.java).apply {
            action = XrayVpnService.ACTION_START
            putExtra(XrayVpnService.EXTRA_CONNECTION_ID, connectionId)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        
        viewModel.updateConnectionStatus(true)
        Snackbar.make(binding.root, "Connecting...", Snackbar.LENGTH_SHORT).show()
    }

    private fun stopVpnService() {
        val intent = Intent(this, XrayVpnService::class.java).apply {
            action = XrayVpnService.ACTION_STOP
        }
        startService(intent)
        
        viewModel.updateConnectionStatus(false)
        Snackbar.make(binding.root, "Disconnected", Snackbar.LENGTH_SHORT).show()
    }

    private fun showAddLinkDialog() {
        val input = android.widget.EditText(this)
        input.hint = "vmess://, vless://, trojan://, or ss://"
        input.setPadding(50, 30, 50, 30)
        
        AlertDialog.Builder(this)
            .setTitle("Add Connection Link")
            .setView(input)
            .setPositiveButton("Add") { _, _ ->
                val link = input.text.toString().trim()
                if (link.isNotEmpty()) {
                    viewModel.addConnectionFromLink(link)
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun pasteFromClipboard() {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clipData = clipboard.primaryClip
        
        if (clipData != null && clipData.itemCount > 0) {
            val text = clipData.getItemAt(0).text?.toString()
            if (text != null && text.isNotEmpty()) {
                // Validate clipboard content before processing
                if (text.length > 10000) {
                    Toast.makeText(this, "Clipboard content too long", Toast.LENGTH_SHORT).show()
                    return
                }
                // Only allow valid protocol prefixes
                if (!text.startsWith("vmess://") && 
                    !text.startsWith("vless://") && 
                    !text.startsWith("trojan://") && 
                    !text.startsWith("ss://")) {
                    Toast.makeText(this, "Invalid connection link format", Toast.LENGTH_SHORT).show()
                    return
                }
                viewModel.addConnectionFromLink(text)
            } else {
                Toast.makeText(this, "Clipboard is empty", Toast.LENGTH_SHORT).show()
            }
        } else {
            Toast.makeText(this, "Clipboard is empty", Toast.LENGTH_SHORT).show()
        }
    }

    private fun showDeleteConfirmation(connection: com.persiangames.gozar.data.Connection) {
        AlertDialog.Builder(this)
            .setTitle("Delete Connection")
            .setMessage("Are you sure you want to delete '${connection.name}'?")
            .setPositiveButton("Delete") { _, _ ->
                viewModel.deleteConnection(connection)
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menuInflater.inflate(R.menu.main_menu, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_settings -> {
                // TODO: Open settings activity
                Toast.makeText(this, "Settings (coming soon)", Toast.LENGTH_SHORT).show()
                true
            }
            R.id.action_about -> {
                showAboutDialog()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    private fun showAboutDialog() {
        AlertDialog.Builder(this)
            .setTitle("GOZAR VPN")
            .setMessage("Version 1.0.0\n\nCross-platform VPN client powered by Xray-core.\n\nOnly accepts connections from persiangames.online domain.")
            .setPositiveButton("OK", null)
            .show()
    }

    override fun onResume() {
        super.onResume()
        // Update connection status
        viewModel.updateConnectionStatus(XrayVpnService.isConnected())
    }
}
