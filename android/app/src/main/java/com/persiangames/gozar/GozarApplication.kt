package com.persiangames.gozar

import android.app.Application
import com.persiangames.gozar.data.GozarDatabase

class GozarApplication : Application() {
    
    val database: GozarDatabase by lazy { 
        GozarDatabase.getInstance(this) 
    }
    
    override fun onCreate() {
        super.onCreate()
    }
}
