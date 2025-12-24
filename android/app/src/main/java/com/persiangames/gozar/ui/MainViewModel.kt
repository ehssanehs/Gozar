package com.persiangames.gozar.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.persiangames.gozar.GozarApplication
import com.persiangames.gozar.XrayVpnService
import com.persiangames.gozar.data.Connection
import com.persiangames.gozar.data.ConnectionRepository
import com.persiangames.gozar.utils.ConnectionParser
import kotlinx.coroutines.launch

class MainViewModel(application: Application) : AndroidViewModel(application) {
    
    private val repository: ConnectionRepository
    val allConnections: LiveData<List<Connection>>
    
    private val _selectedConnectionId = MutableLiveData<Long?>()
    val selectedConnectionId: LiveData<Long?> = _selectedConnectionId
    
    private val _isConnected = MutableLiveData<Boolean>()
    val isConnected: LiveData<Boolean> = _isConnected
    
    private val _errorMessage = MutableLiveData<String?>()
    val errorMessage: LiveData<String?> = _errorMessage
    
    private val _successMessage = MutableLiveData<String?>()
    val successMessage: LiveData<String?> = _successMessage
    
    init {
        val database = (application as GozarApplication).database
        repository = ConnectionRepository(database.connectionDao())
        allConnections = repository.allConnections
        
        // Restore selected connection from preferences
        val prefs = application.getSharedPreferences("gozar_prefs", android.content.Context.MODE_PRIVATE)
        val savedConnectionId = prefs.getLong("selected_connection_id", -1L)
        if (savedConnectionId != -1L) {
            _selectedConnectionId.value = savedConnectionId
        }
        
        // Check if VPN is currently connected
        _isConnected.value = XrayVpnService.isConnected()
    }
    
    fun selectConnection(connectionId: Long) {
        _selectedConnectionId.value = connectionId
        
        // Save to preferences
        val prefs = getApplication<GozarApplication>().getSharedPreferences(
            "gozar_prefs", 
            android.content.Context.MODE_PRIVATE
        )
        prefs.edit().putLong("selected_connection_id", connectionId).apply()
        
        // If already connected, reconnect with new connection
        if (_isConnected.value == true) {
            _successMessage.value = "Switching connection..."
        }
    }
    
    fun addConnectionFromLink(link: String) {
        viewModelScope.launch {
            try {
                val parsed = ConnectionParser.parseAndValidate(link)
                val connection = Connection(
                    name = parsed.name,
                    link = parsed.link,
                    protocol = parsed.protocol,
                    serverHost = parsed.serverHost,
                    serverPort = parsed.serverPort
                )
                repository.insertConnection(connection)
                _successMessage.value = "Connection added: ${parsed.name}"
            } catch (e: Exception) {
                _errorMessage.value = e.message ?: "Failed to add connection"
            }
        }
    }
    
    fun deleteConnection(connection: Connection) {
        viewModelScope.launch {
            // If this is the selected connection, clear selection
            if (_selectedConnectionId.value == connection.id) {
                _selectedConnectionId.value = null
                val prefs = getApplication<GozarApplication>().getSharedPreferences(
                    "gozar_prefs", 
                    android.content.Context.MODE_PRIVATE
                )
                prefs.edit().remove("selected_connection_id").apply()
            }
            repository.deleteConnection(connection)
            _successMessage.value = "Connection deleted"
        }
    }
    
    fun updateConnectionStatus(isConnected: Boolean) {
        _isConnected.value = isConnected
    }
    
    fun clearErrorMessage() {
        _errorMessage.value = null
    }
    
    fun clearSuccessMessage() {
        _successMessage.value = null
    }
}
