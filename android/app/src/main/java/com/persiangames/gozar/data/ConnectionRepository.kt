package com.persiangames.gozar.data

import androidx.lifecycle.LiveData

class ConnectionRepository(private val connectionDao: ConnectionDao) {
    
    val allConnections: LiveData<List<Connection>> = connectionDao.getAllConnections()

    suspend fun getConnectionById(id: Long): Connection? {
        return connectionDao.getConnectionById(id)
    }

    suspend fun insertConnection(connection: Connection): Long {
        return connectionDao.insertConnection(connection)
    }

    suspend fun deleteConnection(connection: Connection) {
        connectionDao.deleteConnection(connection)
    }

    suspend fun deleteConnectionById(id: Long) {
        connectionDao.deleteConnectionById(id)
    }

    suspend fun deleteAllConnections() {
        connectionDao.deleteAllConnections()
    }
}
