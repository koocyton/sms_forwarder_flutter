package com.bobog.n.sms_forwarder

import java.util.Properties
import javax.activation.CommandMap
import javax.activation.MailcapCommandMap
import javax.mail.Message
import javax.mail.Session
import javax.mail.internet.InternetAddress
import javax.mail.internet.MimeMessage

object NativeSmtpSender {

    init {
        val mc = CommandMap.getDefaultCommandMap() as MailcapCommandMap
        mc.addMailcap("text/html;; x-java-content-handler=com.sun.mail.handlers.text_html")
        mc.addMailcap("text/xml;; x-java-content-handler=com.sun.mail.handlers.text_xml")
        mc.addMailcap("text/plain;; x-java-content-handler=com.sun.mail.handlers.text_plain")
        mc.addMailcap("multipart/*;; x-java-content-handler=com.sun.mail.handlers.multipart_mixed")
        mc.addMailcap("message/rfc822;; x-java-content-handler=com.sun.mail.handlers.message_rfc822")
        CommandMap.setDefaultCommandMap(mc)
    }

    fun sendSync(
        host: String,
        port: Int,
        useSsl: Boolean,
        username: String?,
        password: String?,
        from: String,
        toList: List<String>,
        subject: String,
        body: String
    ) {
        val isSsl = port == 465 || useSsl
        val protocol = if (isSsl) "smtps" else "smtp"

        val props = Properties().apply {
            put("mail.transport.protocol", protocol)
            put("mail.$protocol.host", host)
            put("mail.$protocol.port", port.toString())
            put("mail.$protocol.connectiontimeout", "30000")
            put("mail.$protocol.timeout", "30000")
            put("mail.$protocol.writetimeout", "30000")
            put("mail.$protocol.ssl.trust", "*")

            if (!username.isNullOrBlank()) {
                put("mail.$protocol.auth", "true")
            }

            if (isSsl) {
                put("mail.smtps.ssl.enable", "true")
                put("mail.smtps.socketFactory.port", port.toString())
                put("mail.smtps.socketFactory.class", "javax.net.ssl.SSLSocketFactory")
                put("mail.smtps.socketFactory.fallback", "false")
            } else {
                put("mail.smtp.starttls.enable", "true")
                put("mail.smtp.starttls.required", "true")
            }
        }

        val session = Session.getInstance(props)

        val message = MimeMessage(session).apply {
            setFrom(InternetAddress(from, "SMS Forwarder", "UTF-8"))
            setRecipients(
                Message.RecipientType.TO,
                toList.map { InternetAddress(it) }.toTypedArray()
            )
            setSubject(subject, "UTF-8")
            setText(body, "UTF-8")
        }

        val transport = session.getTransport(protocol)
        try {
            transport.connect(host, port, username ?: "", password ?: "")
            transport.sendMessage(message, message.allRecipients)
        } finally {
            transport.close()
        }
    }
}
