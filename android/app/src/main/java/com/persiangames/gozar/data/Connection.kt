package com.persiangames.gozar.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "connections")
data class Connection(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val link: String,
    val protocol: String, // vmess, vless, trojan, ss
    val serverHost: String,
    val serverPort: Int,
    val addedAt: Long = System.currentTimeMillis()
)
