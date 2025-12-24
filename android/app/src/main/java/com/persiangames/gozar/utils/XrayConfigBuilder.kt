package com.persiangames.gozar.utils

import android.util.Base64
import com.google.gson.Gson
import com.google.gson.JsonObject
import org.json.JSONObject

object XrayConfigBuilder {
    
    fun buildConfig(connections: List<com.persiangames.gozar.data.Connection>, selectedConnectionId: Long): String {
        val config = JSONObject()
        
        // Log settings
        config.put("log", JSONObject().apply {
            put("loglevel", "warning")
        })
        
        // DNS settings
        config.put("dns", JSONObject().apply {
            put("servers", org.json.JSONArray().apply {
                put("https://1.1.1.1/dns-query")
                put("https://8.8.8.8/dns-query")
            })
            put("queryStrategy", "UseIP")
        })
        
        // Routing rules
        config.put("routing", JSONObject().apply {
            put("domainStrategy", "AsIs")
            put("rules", org.json.JSONArray().apply {
                // Block ads
                put(JSONObject().apply {
                    put("type", "field")
                    put("domain", org.json.JSONArray().put("geosite:category-ads-all"))
                    put("outboundTag", "blocked")
                })
                // Direct for private IPs
                put(JSONObject().apply {
                    put("type", "field")
                    put("ip", org.json.JSONArray().put("geoip:private"))
                    put("outboundTag", "direct")
                })
                // Direct for local domains
                put(JSONObject().apply {
                    put("type", "field")
                    put("domain", org.json.JSONArray().apply {
                        put("geosite:private")
                        put("geosite:category-local")
                    })
                    put("outboundTag", "direct")
                })
                // Proxy for international sites
                put(JSONObject().apply {
                    put("type", "field")
                    put("domain", org.json.JSONArray().put("geosite:geolocation-!cn"))
                    put("outboundTag", "outbound_selected")
                })
                // Default to proxy
                put(JSONObject().apply {
                    put("type", "field")
                    put("outboundTag", "outbound_selected")
                })
            })
        })
        
        // Inbounds (SOCKS and HTTP proxy)
        config.put("inbounds", org.json.JSONArray().apply {
            put(JSONObject().apply {
                put("port", 10808)
                put("listen", "127.0.0.1")
                put("protocol", "socks")
                put("settings", JSONObject().apply {
                    put("auth", "noauth")
                    put("udp", true)
                })
                put("tag", "socks-in")
            })
            put(JSONObject().apply {
                put("port", 10809)
                put("listen", "127.0.0.1")
                put("protocol", "http")
                put("tag", "http-in")
            })
        })
        
        // Outbounds
        val outbounds = org.json.JSONArray()
        
        // Add direct and blocked outbounds
        outbounds.put(JSONObject().apply {
            put("protocol", "freedom")
            put("tag", "direct")
        })
        outbounds.put(JSONObject().apply {
            put("protocol", "blackhole")
            put("tag", "blocked")
        })
        
        // Generate outbounds for all connections
        connections.forEach { connection ->
            val tag = "outbound_${connection.id}"
            val outbound = generateOutbound(connection, tag)
            outbounds.put(outbound)
        }
        
        config.put("outbounds", outbounds)
        
        return config.toString(2)
    }
    
    private fun generateOutbound(connection: com.persiangames.gozar.data.Connection, tag: String): JSONObject {
        return when (connection.protocol) {
            "vmess" -> generateVmessOutbound(connection, tag)
            "vless" -> generateVlessOutbound(connection, tag)
            "trojan" -> generateTrojanOutbound(connection, tag)
            "ss" -> generateShadowsocksOutbound(connection, tag)
            else -> JSONObject().apply {
                put("protocol", "freedom")
                put("tag", tag)
            }
        }
    }
    
    private fun generateVmessOutbound(connection: com.persiangames.gozar.data.Connection, tag: String): JSONObject {
        val link = connection.link
        val base64 = link.substring("vmess://".length)
        val jsonStr = String(Base64.decode(base64, Base64.NO_WRAP or Base64.URL_SAFE))
        val vmessConfig = Gson().fromJson(jsonStr, JsonObject::class.java)
        
        return JSONObject().apply {
            put("protocol", "vmess")
            put("tag", tag)
            put("settings", JSONObject().apply {
                put("vnext", org.json.JSONArray().apply {
                    put(JSONObject().apply {
                        put("address", vmessConfig.get("add")?.asString ?: connection.serverHost)
                        put("port", vmessConfig.get("port")?.asInt ?: connection.serverPort)
                        put("users", org.json.JSONArray().apply {
                            put(JSONObject().apply {
                                put("id", vmessConfig.get("id")?.asString ?: "")
                                put("alterId", vmessConfig.get("aid")?.asInt ?: 0)
                                put("security", vmessConfig.get("scy")?.asString ?: "auto")
                            })
                        })
                    })
                })
            })
            put("streamSettings", JSONObject().apply {
                put("network", vmessConfig.get("net")?.asString ?: "tcp")
                if (vmessConfig.has("tls") && vmessConfig.get("tls")?.asString == "tls") {
                    put("security", "tls")
                    put("tlsSettings", JSONObject().apply {
                        if (vmessConfig.has("sni")) {
                            put("serverName", vmessConfig.get("sni")?.asString)
                        }
                    })
                }
            })
        }
    }
    
    private fun generateVlessOutbound(connection: com.persiangames.gozar.data.Connection, tag: String): JSONObject {
        val uri = java.net.URI(connection.link)
        val uuid = uri.userInfo ?: ""
        val params = uri.query?.split("&")?.associate {
            val parts = it.split("=")
            parts[0] to (parts.getOrNull(1) ?: "")
        } ?: emptyMap()
        
        return JSONObject().apply {
            put("protocol", "vless")
            put("tag", tag)
            put("settings", JSONObject().apply {
                put("vnext", org.json.JSONArray().apply {
                    put(JSONObject().apply {
                        put("address", connection.serverHost)
                        put("port", connection.serverPort)
                        put("users", org.json.JSONArray().apply {
                            put(JSONObject().apply {
                                put("id", uuid)
                                put("encryption", params["encryption"] ?: "none")
                                put("flow", params["flow"] ?: "")
                            })
                        })
                    })
                })
            })
            put("streamSettings", JSONObject().apply {
                put("network", params["type"] ?: "tcp")
                if (params["security"] == "tls" || params["security"] == "reality") {
                    put("security", params["security"])
                    put("tlsSettings", JSONObject().apply {
                        put("serverName", params["sni"] ?: connection.serverHost)
                    })
                }
            })
        }
    }
    
    private fun generateTrojanOutbound(connection: com.persiangames.gozar.data.Connection, tag: String): JSONObject {
        val uri = java.net.URI(connection.link)
        val password = uri.userInfo ?: ""
        val params = uri.query?.split("&")?.associate {
            val parts = it.split("=")
            parts[0] to (parts.getOrNull(1) ?: "")
        } ?: emptyMap()
        
        return JSONObject().apply {
            put("protocol", "trojan")
            put("tag", tag)
            put("settings", JSONObject().apply {
                put("servers", org.json.JSONArray().apply {
                    put(JSONObject().apply {
                        put("address", connection.serverHost)
                        put("port", connection.serverPort)
                        put("password", password)
                    })
                })
            })
            put("streamSettings", JSONObject().apply {
                put("network", params["type"] ?: "tcp")
                put("security", "tls")
                put("tlsSettings", JSONObject().apply {
                    put("serverName", params["sni"] ?: connection.serverHost)
                })
            })
        }
    }
    
    private fun generateShadowsocksOutbound(connection: com.persiangames.gozar.data.Connection, tag: String): JSONObject {
        val uri = java.net.URI(connection.link)
        var method = ""
        var password = ""
        
        // Parse ss:// link
        if (uri.userInfo != null) {
            // Format: ss://method:password@host:port
            method = uri.userInfo.split(":")[0]
            password = uri.userInfo.split(":").getOrNull(1) ?: ""
        } else {
            // Format: ss://base64
            val base64 = connection.link.substring("ss://".length).split("#")[0]
            val decoded = String(Base64.decode(base64, Base64.NO_WRAP or Base64.URL_SAFE))
            val atIndex = decoded.lastIndexOf('@')
            if (atIndex != -1) {
                val methodPassword = decoded.substring(0, atIndex)
                val parts = methodPassword.split(':')
                method = parts[0]
                password = parts.getOrNull(1) ?: ""
            }
        }
        
        return JSONObject().apply {
            put("protocol", "shadowsocks")
            put("tag", tag)
            put("settings", JSONObject().apply {
                put("servers", org.json.JSONArray().apply {
                    put(JSONObject().apply {
                        put("address", connection.serverHost)
                        put("port", connection.serverPort)
                        put("method", method.ifEmpty { "aes-256-gcm" })
                        put("password", password)
                    })
                })
            })
        }
    }
}
