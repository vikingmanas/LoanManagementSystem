// ============================================================
// Email Service for LoanManagementSystem
// Uses Resend HTTP API instead of SMTP (Render blocks SMTP)
// ============================================================
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({ origin: process.env.FRONTEND_URL || '*' }));
app.use(express.json());

// Helper: Send email via Resend HTTP API
async function sendEmail({ to, subject, html }) {
    const apiKey = process.env.RESEND_API_KEY;
    if (!apiKey) {
        throw new Error('RESEND_API_KEY is not set in environment variables');
    }

    const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${apiKey}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            from: `Loan Management App <${process.env.RESEND_FROM || 'onboarding@resend.dev'}>`,
            to: [to],
            subject: subject,
            html: html
        })
    });

    const data = await response.json();

    if (!response.ok) {
        console.error('Resend API error:', data);
        throw new Error(data.message || 'Failed to send email via Resend');
    }

    return data;
}

// Verify configuration on startup
console.log('Email service starting...');
if (process.env.RESEND_API_KEY) {
    console.log('✅ RESEND_API_KEY is set — email sending is ready');
} else {
    console.log('⚠️  RESEND_API_KEY is NOT set — emails will fail');
}

// Send Email Route (Password Reset)
app.post('/api/send-reset-email', async (req, res) => {
    const { userEmail } = req.body;

    if (!userEmail) {
        return res.status(400).json({ error: 'userEmail is required' });
    }

    try {
        const templatePath = path.join(__dirname, '../LoanManagementSystem/reset-password.html');
        let htmlContent = '';
        if (fs.existsSync(templatePath)) {
            htmlContent = fs.readFileSync(templatePath, 'utf8');
        } else {
            htmlContent = `<b>Click the link below to reset your password.</b>`;
        }

        const result = await sendEmail({
            to: userEmail,
            subject: 'Password Reset Request',
            html: htmlContent
        });

        console.log('Reset email sent:', result.id);
        res.status(200).json({ message: 'Email sent successfully!', messageId: result.id });
    } catch (error) {
        console.error('Error sending email:', error.message);
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

        const result = await sendEmail({
            to: userEmail,
            subject: 'Your Login Verification Code',
            html: htmlContent
        });

        console.log('2FA OTP sent:', result.id);
        res.status(200).json({ message: '2FA OTP sent successfully!', messageId: result.id });
    } catch (error) {
        console.error('Error sending 2FA OTP email:', error.message);
        res.status(500).json({ error: 'Failed to send 2FA OTP' });
    }
});

// Start Server
app.listen(PORT, () => {
    console.log(`Email service running on http://localhost:${PORT}`);
});
