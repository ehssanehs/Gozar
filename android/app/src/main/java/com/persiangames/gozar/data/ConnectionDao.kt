package com.persiangames.gozar.data

import androidx.lifecycle.LiveData
import androidx.room.*

@Dao
interface ConnectionDao {
    @Query("SELECT * FROM connections ORDER BY addedAt DESC")
    fun getAllConnections(): LiveData<List<Connection>>

    @Query("SELECT * FROM connections WHERE id = :id")
    suspend fun getConnectionById(id: Long): Connection?

    @Insert
    suspend fun insertConnection(connection: Connection): Long

    @Delete
    suspend fun deleteConnection(connection: Connection)

    @Query("DELETE FROM connections WHERE id = :id")
    suspend fun deleteConnectionById(id: Long)

    @Query("DELETE FROM connections")
    suspend fun deleteAllConnections()
}
