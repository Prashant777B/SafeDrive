// SafeDrive — Email Notification Edge Function
// Triggered by Supabase Database Webhooks on:
//   • policies INSERT  → "Policy Activated" email
//   • claims   INSERT  → "Claim Received"   email

import { serve } from "std/http/server.ts";

const RESEND_API_KEY  = Deno.env.get('RESEND_API_KEY')!;
const SUPABASE_URL    = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY     = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FROM_EMAIL      = 'SafeDrive <onboarding@resend.dev>';
const APP_URL         = Deno.env.get('APP_URL') ?? 'https://safe-drive.vercel.app';

// resend.dev can only deliver to the Resend account owner's email.
// DEMO_EMAIL overrides the recipient so notifications land in the demo inbox.
// Set via: supabase secrets set DEMO_EMAIL=your@email.com
const DEMO_EMAIL = Deno.env.get('DEMO_EMAIL') ?? null;

// ── HTML email templates ─────────────────────────────────────

function policyEmail(record: Record<string, string>): { subject: string; html: string } {
  const name          = record.insured_name   ?? 'Valued Customer';
  const policyNumber  = record.policy_number  ?? '';
  const coverType     = record.cover_type     ?? 'Comprehensive';
  const annualPremium = record.annual_premium ?? '0';
  const startDate     = record.start_date     ?? '';
  const endDate       = record.end_date       ?? '';
  const vehicle       = [record.car_year, record.car_make, record.car_model]
                          .filter(Boolean).join(' ');

  return {
    subject: `Your SafeDrive Policy is Active — ${policyNumber}`,
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8"/>
  <style>
    body { font-family: Arial, sans-serif; background: #F2F5FB; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 40px auto; background: #fff;
                 border-radius: 16px; overflow: hidden;
                 box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #1A73E8, #0D47A1);
              padding: 36px 32px; text-align: center; }
    .header h1 { color: #fff; margin: 0; font-size: 24px; }
    .header p  { color: rgba(255,255,255,0.8); margin: 8px 0 0; }
    .body      { padding: 32px; }
    .policy-card { background: #F2F5FB; border-radius: 12px;
                   padding: 20px; margin: 20px 0; }
    .policy-number { font-size: 22px; font-weight: bold;
                     color: #1A73E8; letter-spacing: 2px; }
    .row { display: flex; justify-content: space-between;
           padding: 8px 0; border-bottom: 1px solid #e8ecf3; }
    .row:last-child { border-bottom: none; }
    .label { color: #6B7280; font-size: 13px; }
    .value { font-weight: 600; font-size: 13px; }
    .badge { display: inline-block; background: #34A853;
             color: #fff; padding: 4px 12px; border-radius: 20px; font-size: 12px; }
    .cta { text-align: center; margin: 28px 0; }
    .cta a { background: #1A73E8; color: #fff; padding: 14px 32px;
             border-radius: 10px; text-decoration: none;
             font-weight: bold; font-size: 15px; }
    .footer { background: #F2F5FB; padding: 20px 32px;
              text-align: center; color: #6B7280; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🛡️ You're Covered!</h1>
      <p>Your SafeDrive policy is now active</p>
    </div>
    <div class="body">
      <p>Hi <strong>${name}</strong>,</p>
      <p>Great news — your car insurance policy has been successfully activated.
         You are now protected. Here's a summary of your cover:</p>

      <div class="policy-card">
        <div style="text-align:center; margin-bottom:16px;">
          <span class="badge">✓ Active</span>
        </div>
        <div style="text-align:center; margin-bottom:16px;">
          <div style="color:#6B7280; font-size:12px;">POLICY NUMBER</div>
          <div class="policy-number">${policyNumber}</div>
        </div>
        <div class="row">
          <span class="label">Cover Type</span>
          <span class="value">${coverType}</span>
        </div>
        <div class="row">
          <span class="label">Vehicle</span>
          <span class="value">${vehicle}</span>
        </div>
        <div class="row">
          <span class="label">Annual Premium</span>
          <span class="value">£${parseFloat(annualPremium).toFixed(2)}</span>
        </div>
        <div class="row">
          <span class="label">Cover Starts</span>
          <span class="value">${startDate}</span>
        </div>
        <div class="row">
          <span class="label">Cover Ends</span>
          <span class="value">${endDate}</span>
        </div>
      </div>

      <div class="cta">
        <a href="${APP_URL}">View My Policy</a>
      </div>

      <p style="color:#6B7280; font-size:12px;">
        <strong>Need to make a claim?</strong> Log in to SafeDrive and go to
        My Policies → Make a Claim. Our team reviews claims within 2–5 business days.
      </p>
    </div>
    <div class="footer">
      <p>SafeDrive · UK Car Insurance · For illustrative purposes only</p>
      <p>This is an automated message. Please do not reply to this email.</p>
    </div>
  </div>
</body>
</html>`,
  };
}

function claimEmail(record: Record<string, string>): { subject: string; html: string } {
  const claimNumber  = record.claim_number  ?? '';
  const claimType    = record.claim_type    ?? '';
  const incidentDate = record.incident_date ?? '';
  const description  = record.description  ?? '';

  return {
    subject: `Claim Received — ${claimNumber}`,
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8"/>
  <style>
    body { font-family: Arial, sans-serif; background: #F2F5FB; margin: 0; padding: 0; }
    .container { max-width: 600px; margin: 40px auto; background: #fff;
                 border-radius: 16px; overflow: hidden;
                 box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
    .header { background: linear-gradient(135deg, #FFA726, #F57C00);
              padding: 36px 32px; text-align: center; }
    .header h1 { color: #fff; margin: 0; font-size: 24px; }
    .header p  { color: rgba(255,255,255,0.85); margin: 8px 0 0; }
    .body      { padding: 32px; }
    .claim-card { background: #FFF8F0; border-left: 4px solid #FFA726;
                  border-radius: 8px; padding: 20px; margin: 20px 0; }
    .claim-number { font-size: 20px; font-weight: bold;
                    color: #F57C00; letter-spacing: 1.5px; }
    .steps { counter-reset: step; margin: 20px 0; }
    .step { display: flex; align-items: flex-start;
            margin-bottom: 14px; }
    .step-num { background: #FFA726; color: #fff; border-radius: 50%;
                width: 26px; height: 26px; display: flex; align-items: center;
                justify-content: center; font-weight: bold; font-size: 13px;
                flex-shrink: 0; margin-right: 12px; margin-top: 2px; }
    .cta { text-align: center; margin: 28px 0; }
    .cta a { background: #FFA726; color: #fff; padding: 14px 32px;
             border-radius: 10px; text-decoration: none;
             font-weight: bold; font-size: 15px; }
    .footer { background: #F2F5FB; padding: 20px 32px;
              text-align: center; color: #6B7280; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📋 Claim Received</h1>
      <p>We've received your claim and are reviewing it</p>
    </div>
    <div class="body">
      <p>Thank you for submitting your claim. Here are your reference details:</p>

      <div class="claim-card">
        <div style="color:#6B7280; font-size:12px; margin-bottom:4px;">CLAIM REFERENCE</div>
        <div class="claim-number">${claimNumber}</div>
        <div style="margin-top:12px; font-size:13px;">
          <strong>Type:</strong> ${claimType}<br/>
          <strong>Incident Date:</strong> ${incidentDate}<br/>
          <strong>Details:</strong> ${description.substring(0, 120)}${description.length > 120 ? '…' : ''}
        </div>
      </div>

      <p><strong>What happens next?</strong></p>
      <div class="steps">
        <div class="step">
          <div class="step-num">1</div>
          <div><strong>Under Review</strong> — A claims handler will review your
               submission within 2–5 business days.</div>
        </div>
        <div class="step">
          <div class="step-num">2</div>
          <div><strong>Assessment</strong> — We may contact you for additional
               information or documentation.</div>
        </div>
        <div class="step">
          <div class="step-num">3</div>
          <div><strong>Decision</strong> — You'll be notified by email once a
               decision has been made.</div>
        </div>
      </div>

      <div class="cta">
        <a href="${APP_URL}">Track My Claim</a>
      </div>
    </div>
    <div class="footer">
      <p>SafeDrive · UK Car Insurance · For illustrative purposes only</p>
      <p>Please keep your claim reference number: <strong>${claimNumber}</strong></p>
    </div>
  </div>
</body>
</html>`,
  };
}

// ── Main handler ─────────────────────────────────────────────

serve(async (req: Request) => {
  try {
    const payload = await req.json();
    const { table, type, record } = payload;

    // Only handle INSERT events
    if (type !== 'INSERT') {
      return new Response('Ignored', { status: 200 });
    }

    let toEmail: string | null = null;
    let emailContent: { subject: string; html: string } | null = null;

    if (table === 'policies' || table === 'claims') {
      const userRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${record.user_id}`, {
        headers: { 'apikey': SERVICE_KEY, 'Authorization': `Bearer ${SERVICE_KEY}` },
      });
      const userData = await userRes.json();
      toEmail = userData?.email ?? null;
      if (toEmail) emailContent = table === 'policies' ? policyEmail(record) : claimEmail(record);
    }

    if (!toEmail || !emailContent) {
      return new Response('No email to send', { status: 200 });
    }

    // Use DEMO_EMAIL override if set (required when using resend.dev sender domain,
    // which can only deliver to the Resend account owner's address).
    const recipient = DEMO_EMAIL ?? toEmail;

    // Send via Resend
    const emailRes = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: FROM_EMAIL,
        to: [recipient],
        subject: emailContent.subject,
        html: emailContent.html,
      }),
    });

    const emailData = await emailRes.json();

    if (!emailRes.ok) {
      console.error('Resend error:', emailData);
      return new Response(JSON.stringify({ error: emailData }), { status: 500 });
    }

    console.log(`Email sent to ${recipient} (original: ${toEmail}):`, emailData.id);
    return new Response(JSON.stringify({ success: true, id: emailData.id }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (err) {
    console.error('Function error:', err);
    return new Response(JSON.stringify({ error: String(err) }), { status: 500 });
  }
});
