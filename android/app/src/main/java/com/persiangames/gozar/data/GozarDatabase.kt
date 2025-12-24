package com.persiangames.gozar.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [Connection::class], version = 1, exportSchema = false)
abstract class GozarDatabase : RoomDatabase() {
    abstract fun connectionDao(): ConnectionDao

    companion object {
        @Volatile
        private var INSTANCE: GozarDatabase? = null

        fun getInstance(context: Context): GozarDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    GozarDatabase::class.java,
                    "gozar_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}
