const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host:   process.env.SMTP_HOST,
  port:   Number(process.env.SMTP_PORT) || 587,
  secure: process.env.SMTP_PORT === '465',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

async function sendOtpEmail(to, code) {
  await transporter.sendMail({
    from: `"Takım Arkadaşım" <${process.env.SMTP_USER}>`,
    to,
    subject: 'E-posta Doğrulama Kodunuz',
    text: `Doğrulama kodunuz: ${code}\n\nBu kod 10 dakika geçerlidir.`,
    html: `<p>Doğrulama kodunuz: <strong style="font-size:24px">${code}</strong></p><p>Bu kod 10 dakika geçerlidir.</p>`,
  });
}

function generateOtp() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

module.exports = { sendOtpEmail, generateOtp };
