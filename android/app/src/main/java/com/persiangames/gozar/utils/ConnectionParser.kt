package com.persiangames.gozar.utils

import android.util.Base64
import com.google.gson.Gson
import com.google.gson.JsonObject
import java.net.URI

object ConnectionParser {
    private const val ALLOWED_DOMAIN = "persiangames.online"

    data class ParsedConnection(
        val protocol: String,
        val serverHost: String,
        val serverPort: Int,
        val link: String,
        val name: String
    )

    fun parseAndValidate(link: String): ParsedConnection {
        val trimmedLink = link.trim()
        
        return when {
            trimmedLink.startsWith("vmess://") -> parseVmess(trimmedLink)
            trimmedLink.startsWith("vless://") -> parseVless(trimmedLink)
            trimmedLink.startsWith("trojan://") -> parseTrojan(trimmedLink)
            trimmedLink.startsWith("ss://") -> parseShadowsocks(trimmedLink)
            else -> throw IllegalArgumentException("Unsupported protocol. Only vmess://, vless://, trojan://, and ss:// are supported.")
        }
    }

    private fun parseVmess(link: String): ParsedConnection {
        val base64 = link.substring("vmess://".length)
        val jsonStr = String(Base64.decode(base64, Base64.NO_WRAP or Base64.URL_SAFE))
        val json = Gson().fromJson(jsonStr, JsonObject::class.java)
        
        val host = json.get("add")?.asString ?: throw IllegalArgumentException("Invalid vmess: missing 'add' field")
        val port = json.get("port")?.asInt ?: throw IllegalArgumentException("Invalid vmess: missing 'port' field")
        val name = json.get("ps")?.asString ?: "VMess Connection"
        
        validateHost(host)
        
        return ParsedConnection(
            protocol = "vmess",
            serverHost = host,
            serverPort = port,
            link = link,
            name = name
        )
    }

    private fun parseVless(link: String): ParsedConnection {
        val uri = URI(link)
        val host = uri.host ?: throw IllegalArgumentException("Invalid vless: missing host")
        val port = if (uri.port > 0) uri.port else 443
        
        validateHost(host)
        
        // Extract name from fragment or use default
        val name = uri.fragment?.let { 
            java.net.URLDecoder.decode(it, "UTF-8") 
        } ?: "VLESS Connection"
        
        return ParsedConnection(
            protocol = "vless",
            serverHost = host,
            serverPort = port,
            link = link,
            name = name
        )
    }

    private fun parseTrojan(link: String): ParsedConnection {
        val uri = URI(link)
        val host = uri.host ?: throw IllegalArgumentException("Invalid trojan: missing host")
        val port = if (uri.port > 0) uri.port else 443
        
        validateHost(host)
        
        val name = uri.fragment?.let { 
            java.net.URLDecoder.decode(it, "UTF-8") 
        } ?: "Trojan Connection"
        
        return ParsedConnection(
            protocol = "trojan",
            serverHost = host,
            serverPort = port,
            link = link,
            name = name
        )
    }

    private fun parseShadowsocks(link: String): ParsedConnection {
        val uri = URI(link)
        var host = uri.host
        var port = uri.port
        
        // Handle ss:// links with base64-encoded server info
        if (host.isNullOrEmpty()) {
            val base64 = link.substring("ss://".length).split("#")[0]
            val decoded = String(Base64.decode(base64, Base64.NO_WRAP or Base64.URL_SAFE))
            val atIndex = decoded.lastIndexOf('@')
            if (atIndex != -1) {
                val serverInfo = decoded.substring(atIndex + 1)
                val parts = serverInfo.split(':')
                host = parts[0]
                port = parts.getOrNull(1)?.toIntOrNull() ?: 8388
            }
        }
        
        if (host.isNullOrEmpty()) {
            throw IllegalArgumentException("Invalid shadowsocks: missing host")
        }
        
        if (port <= 0) port = 8388
        
        validateHost(host)
        
        val name = uri.fragment?.let { 
            java.net.URLDecoder.decode(it, "UTF-8") 
        } ?: "Shadowsocks Connection"
        
        return ParsedConnection(
            protocol = "ss",
            serverHost = host,
            serverPort = port,
            link = link,
            name = name
        )
    }

    private fun validateHost(host: String) {
        if (host != ALLOWED_DOMAIN && !host.endsWith(".$ALLOWED_DOMAIN")) {
            throw IllegalArgumentException("Connection host must be $ALLOWED_DOMAIN or a subdomain of it. Got: $host")
        }
    }

    fun isValidSubscriptionUrl(url: String): Boolean {
        return try {
            val uri = URI(url)
            // Only allow HTTPS for security
            // Accept both exact domain and subdomains (same as connection validation)
            uri.scheme == "https" && (uri.host == ALLOWED_DOMAIN || uri.host.endsWith(".$ALLOWED_DOMAIN"))
        } catch (e: Exception) {
            false
        }
    }
}
