package com.persiangames.gozar

import com.persiangames.gozar.utils.ConnectionParser
import org.junit.Test
import org.junit.Assert.*

class ConnectionParserTest {

    @Test
    fun testValidVmessLink() {
        // Valid vmess link with persiangames.online domain
        val vmessLink = "vmess://eyJhZGQiOiJzZXJ2ZXIucGVyc2lhbmdhbWVzLm9ubGluZSIsInBvcnQiOjQ0MywiYWlkIjowLCJpZCI6InRlc3QtdXVpZCIsInBzIjoiVGVzdCBDb25uZWN0aW9uIn0="
        
        val result = ConnectionParser.parseAndValidate(vmessLink)
        assertEquals("vmess", result.protocol)
        assertEquals("server.persiangames.online", result.serverHost)
        assertEquals(443, result.serverPort)
        assertEquals("Test Connection", result.name)
    }

    @Test(expected = IllegalArgumentException::class)
    fun testInvalidVmessLink_WrongDomain() {
        // vmess link with invalid domain
        val vmessLink = "vmess://eyJhZGQiOiJzZXJ2ZXIuZXhhbXBsZS5jb20iLCJwb3J0Ijo0NDMsImFpZCI6MCwiaWQiOiJ0ZXN0LXV1aWQiLCJwcyI6IlRlc3QgQ29ubmVjdGlvbiJ9"
        
        ConnectionParser.parseAndValidate(vmessLink)
    }

    @Test
    fun testValidVlessLink() {
        val vlessLink = "vless://uuid@server.persiangames.online:443?encryption=none&security=tls#Test%20VLESS"
        
        val result = ConnectionParser.parseAndValidate(vlessLink)
        assertEquals("vless", result.protocol)
        assertEquals("server.persiangames.online", result.serverHost)
        assertEquals(443, result.serverPort)
        assertEquals("Test VLESS", result.name)
    }

    @Test(expected = IllegalArgumentException::class)
    fun testInvalidVlessLink_WrongDomain() {
        val vlessLink = "vless://uuid@example.com:443?encryption=none&security=tls#Test"
        
        ConnectionParser.parseAndValidate(vlessLink)
    }

    @Test
    fun testValidTrojanLink() {
        val trojanLink = "trojan://password@server.persiangames.online:443?security=tls#Test%20Trojan"
        
        val result = ConnectionParser.parseAndValidate(trojanLink)
        assertEquals("trojan", result.protocol)
        assertEquals("server.persiangames.online", result.serverHost)
        assertEquals(443, result.serverPort)
        assertEquals("Test Trojan", result.name)
    }

    @Test(expected = IllegalArgumentException::class)
    fun testInvalidProtocol() {
        val invalidLink = "http://example.com"
        
        ConnectionParser.parseAndValidate(invalidLink)
    }

    @Test
    fun testValidSubscriptionUrl() {
        val validUrl = "https://persiangames.online/subscription"
        assertTrue(ConnectionParser.isValidSubscriptionUrl(validUrl))
    }

    @Test
    fun testInvalidSubscriptionUrl_WrongDomain() {
        val invalidUrl = "https://example.com/subscription"
        assertFalse(ConnectionParser.isValidSubscriptionUrl(invalidUrl))
    }

    @Test
    fun testInvalidSubscriptionUrl_WrongScheme() {
        val invalidUrl = "ftp://persiangames.online/subscription"
        assertFalse(ConnectionParser.isValidSubscriptionUrl(invalidUrl))
    }

    @Test
    fun testSubdomainAllowed() {
        // Subdomain should be allowed
        val vlessLink = "vless://uuid@sub.persiangames.online:443#Test"
        
        val result = ConnectionParser.parseAndValidate(vlessLink)
        assertEquals("sub.persiangames.online", result.serverHost)
    }

    @Test
    fun testExactDomainAllowed() {
        // Exact domain should be allowed
        val vlessLink = "vless://uuid@persiangames.online:443#Test"
        
        val result = ConnectionParser.parseAndValidate(vlessLink)
        assertEquals("persiangames.online", result.serverHost)
    }
}
