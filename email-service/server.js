require('dotenv').config();
const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const dns = require('dns');

// NUCLEAR FIX: Monkey-patch dns.lookup to ALWAYS resolve IPv4
// Render's free tier cannot make outbound IPv6 connections,
// and Nodemailer ignores both dns.setDefaultResultOrder and family:4
const originalLookup = dns.lookup;
dns.lookup = function(hostname, options, callback) {
    if (typeof options === 'function') {
        callback = options;
        options = { family: 4 };
    } else if (typeof options === 'number') {
        options = { family: 4 };
    } else {
        options = Object.assign({}, options, { family: 4 });
    }
    return originalLookup.call(this, hostname, options, callback);
};

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({ origin: process.env.FRONTEND_URL || '*' }));
app.use(express.json());

// Set up Nodemailer Transporter
const transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 587,
    secure: false,
    auth: {
        user: process.env.EMAIL_USER,
        pass: (process.env.EMAIL_PASS || '').replace(/\s+/g, '')
    },
    connectionTimeout: 15000,
    greetingTimeout: 15000,
    socketTimeout: 20000
});

// Verify connection configuration
transporter.verify(function (error, success) {
    if (error) {
        console.log('Transporter configuration error:', error);
    } else {
        console.log('Server is ready to take our messages');
    }
});

// Send Email Route
app.post('/api/send-reset-email', async (req, res) => {
    const { userEmail } = req.body;

    if (!userEmail) {
        return res.status(400).json({ error: 'userEmail is required' });
    }

    try {
        // Option 1: Using a simple HTML string
        // const htmlContent = `<b>Click the link below to reset your password.</b>`;
        
        // Option 2: Using the reset-password.html file from your project
        const templatePath = path.join(__dirname, '../LoanManagementSystem/reset-password.html');
        let htmlContent = '';
        if (fs.existsSync(templatePath)) {
            htmlContent = fs.readFileSync(templatePath, 'utf8');
        } else {
            htmlContent = `<b>Click the link below to reset your password.</b>`;
        }

        const mailOptions = {
            from: `"Loan Management App" <${process.env.EMAIL_USER}>`, // sender address
            to: userEmail,                                              // list of receivers
            subject: 'Password Reset Request',                          // Subject line
            html: htmlContent                                           // HTML body
        };

        const info = await transporter.sendMail(mailOptions);
        console.log('Message sent: %s', info.messageId);
        
        res.status(200).json({ message: 'Email sent successfully!', messageId: info.messageId });
    } catch (error) {
        console.error('Error sending email:', error);
        res.status(500).json({ error: 'Failed to send email' });
    }
});

// Send 2FA OTP Route
app.post('/api/send-2fa-otp', async (req, res) => {
    const { userEmail, otp } = req.body;

    if (!userEmail || !otp) {
        return res.status(400).json({ error: 'userEmail and otp are required' });
    }

    try {
        const htmlContent = `
            <div style="font-family: sans-serif; max-width: 600px; margin: auto;">
                <h2>Your Login OTP</h2>
                <p>You requested to log in. Please use the following 6-digit code to complete your login:</p>
                <h1 style="background: #f4f4f4; padding: 10px; text-align: center; letter-spacing: 5px;">${otp}</h1>
                <p>This code will expire shortly. If you did not request this, please ignore this email.</p>
            </div>
        `;

        const mailOptions = {
            from: `"Loan Management App" <${process.env.EMAIL_USER}>`,
            to: userEmail,
            subject: 'Your Login Verification Code',
            html: htmlContent
        };

        const info = await transporter.sendMail(mailOptions);
        console.log('2FA Message sent: %s', info.messageId);
        
        res.status(200).json({ message: '2FA OTP sent successfully!', messageId: info.messageId });
    } catch (error) {
        console.error('Error sending 2FA OTP email:', error);
        res.status(500).json({ error: 'Failed to send 2FA OTP' });
    }
});

// Start Server
app.listen(PORT, () => {
    console.log(`Email service running on http://localhost:${PORT}`);
});
