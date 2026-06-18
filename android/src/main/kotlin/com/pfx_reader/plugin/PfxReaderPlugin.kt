package com.pfx_reader.plugin

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import java.security.cert.X509Certificate
import javax.security.auth.x500.X500Principal

private class WrongPasswordException : Exception("Incorrect password for the PFX file.")

class PfxReaderPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "pfx_reader")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "getCertificateInfoFromBytes" -> {
                    val pfxBytes = call.argument<ByteArray>("pfxBytes")
                        ?: return result.error("INVALID_ARG", "pfxBytes is required", null)
                    val password = call.argument<String>("password")
                        ?: return result.error("INVALID_ARG", "password is required", null)
                    result.success(getCertificateInfo(pfxBytes, password))
                }

                "getCertificateInfoFromFile" -> {
                    val filePath = call.argument<String>("filePath")
                        ?: return result.error("INVALID_ARG", "filePath is required", null)
                    val password = call.argument<String>("password")
                        ?: return result.error("INVALID_ARG", "password is required", null)
                    val file = File(filePath)
                    if (!file.exists()) {
                        return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                    }
                    result.success(getCertificateInfo(file.readBytes(), password))
                }

                "signWithBytes" -> {
                    val data = call.argument<ByteArray>("data")
                        ?: return result.error("INVALID_ARG", "data is required", null)
                    val pfxBytes = call.argument<ByteArray>("pfxBytes")
                        ?: return result.error("INVALID_ARG", "pfxBytes is required", null)
                    val password = call.argument<String>("password")
                        ?: return result.error("INVALID_ARG", "password is required", null)
                    val algorithm = call.argument<String>("algorithm") ?: "SHA256withRSA"
                    result.success(sign(data, pfxBytes, password, algorithm))
                }

                "signWithFile" -> {
                    val data = call.argument<ByteArray>("data")
                        ?: return result.error("INVALID_ARG", "data is required", null)
                    val filePath = call.argument<String>("filePath")
                        ?: return result.error("INVALID_ARG", "filePath is required", null)
                    val password = call.argument<String>("password")
                        ?: return result.error("INVALID_ARG", "password is required", null)
                    val algorithm = call.argument<String>("algorithm") ?: "SHA256withRSA"
                    val file = File(filePath)
                    if (!file.exists()) {
                        return result.error("FILE_NOT_FOUND", "File not found: $filePath", null)
                    }
                    result.success(sign(data, file.readBytes(), password, algorithm))
                }

                else -> result.notImplemented()
            }
        } catch (e: WrongPasswordException) {
            result.error("WRONG_PASSWORD", "Incorrect password for the PFX file.", null)
        } catch (e: Exception) {
            result.error("PFX_ERROR", e.message, e.stackTraceToString())
        }
    }

    // -------------------------------------------------------------------------
    // Certificate info
    // -------------------------------------------------------------------------

    private fun getCertificateInfo(pfxBytes: ByteArray, password: String): Map<String, Any?> {
        val ks = loadKeyStore(pfxBytes, password)
        val alias = ks.aliases().nextElement()
        val cert = ks.getCertificate(alias) as X509Certificate

        val subjectDN = cert.subjectX500Principal.getName(X500Principal.RFC2253)
        val issuerDN = cert.issuerX500Principal.getName(X500Principal.RFC2253)

        return mapOf(
            "subjectDN" to subjectDN,
            "issuerDN" to issuerDN,
            "notBefore" to cert.notBefore.time,
            "notAfter" to cert.notAfter.time,
            "serialNumber" to cert.serialNumber.toString(),
            "commonName" to extractRdnField(subjectDN, "CN"),
            "organization" to extractRdnField(subjectDN, "O"),
            "organizationalUnit" to extractRdnField(subjectDN, "OU"),
            "country" to extractRdnField(subjectDN, "C"),
            "email" to (extractRdnField(subjectDN, "E")
                ?: extractRdnField(subjectDN, "EMAILADDRESS")),
        )
    }

    // -------------------------------------------------------------------------
    // Signing
    // -------------------------------------------------------------------------

    private fun sign(
        data: ByteArray,
        pfxBytes: ByteArray,
        password: String,
        algorithm: String,
    ): ByteArray {
        val ks = loadKeyStore(pfxBytes, password)
        val alias = ks.aliases().nextElement()
        val privateKey = ks.getKey(alias, password.toCharArray()) as PrivateKey
        return Signature.getInstance(algorithm).run {
            initSign(privateKey)
            update(data)
            sign()
        }
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private fun loadKeyStore(pfxBytes: ByteArray, password: String): KeyStore {
        try {
            val ks = KeyStore.getInstance("PKCS12")
            ks.load(pfxBytes.inputStream(), password.toCharArray())
            return ks
        } catch (e: java.io.IOException) {
            // KeyStore throws IOException wrapping an UnrecoverableKeyException when
            // the password is wrong on most Android versions.
            val cause = e.cause
            if (cause is java.security.UnrecoverableKeyException ||
                e.message?.contains("password", ignoreCase = true) == true ||
                e.message?.contains("MAC", ignoreCase = false) == true) {
                throw WrongPasswordException()
            }
            throw e
        }
    }

    /**
     * Extracts a single RDN field value from an RFC-2253 DN string.
     * E.g. extractRdnField("CN=John Doe,O=Acme,C=BR", "CN") → "John Doe"
     */
    private fun extractRdnField(dn: String, field: String): String? {
        val regex = Regex("""(?:^|,)\s*${Regex.escape(field)}=([^,]+)""", RegexOption.IGNORE_CASE)
        return regex.find(dn)?.groupValues?.get(1)?.trim()
    }
}
