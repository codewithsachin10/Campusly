import { createServerFn } from '@tanstack/react-start'
import { createClient } from '@supabase/supabase-js'
import { Resend } from 'resend'

// Types
type CreateAdminData = {
  fullName: string
  email: string
  staffId: string
  department: string
  designation: string
  roleId: string
}

function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString()
}

function generatePassword() {
  return Math.random().toString(36).slice(-8) + Math.random().toString(36).slice(-8).toUpperCase() + "!"
}

// Security: Generate HMAC tokens for accept/reject links
const getSecretKey = async () => {
  const secret = process.env.VITE_SUPABASE_ANON_KEY || 'fallback_secret_campusly';
  const enc = new TextEncoder();
  return await crypto.subtle.importKey(
    'raw', enc.encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign', 'verify']
  );
};

export async function signInviteToken(userId: string) {
  const enc = new TextEncoder();
  const key = await getSecretKey();
  const signature = await crypto.subtle.sign('HMAC', key, enc.encode(userId));
  const hashArray = Array.from(new Uint8Array(signature));
  const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  return `${userId}.${hashHex}`;
}

export async function verifyInviteToken(token: string) {
  try {
    const [userId, hashHex] = token.split('.');
    if (!userId || !hashHex) return null;
    
    const expectedToken = await signInviteToken(userId);
    if (token === expectedToken) {
      return userId;
    }
    return null;
  } catch {
    return null;
  }
}

export const createAdminFn = createServerFn({ method: 'POST' })
  .validator((data: CreateAdminData) => data)
  .handler(async ({ data }) => {
    // 1. Initialize server-side clients
    const supabaseUrl = process.env.VITE_SUPABASE_URL
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
    const resendApiKey = process.env.RESEND_API_KEY

    if (!supabaseUrl || !supabaseServiceKey || !resendApiKey) {
      throw new Error("Missing server environment variables.")
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)
    const resend = new Resend(resendApiKey)

    // 2. Create user in auth.users
    const password = generatePassword()
    const { data: authData, error: authError } = await supabaseAdmin.auth.admin.createUser({
      email: data.email,
      password: password,
      email_confirm: true,
    })

    if (authError) throw new Error("Auth Error: " + authError.message)

    const userId = authData.user.id

    // 3. Insert into admin_profiles with 'Invited' status
    const { error: profileError } = await supabaseAdmin.from('admin_profiles').insert({
      id: userId,
      full_name: data.fullName,
      email: data.email,
      staff_id: data.staffId,
      department: data.department,
      designation: data.designation,
      status: 'Invited', // New status for step 1
    })

    if (profileError) {
      // rollback user creation
      await supabaseAdmin.auth.admin.deleteUser(userId)
      throw new Error("Profile Error: " + profileError.message)
    }

    // 4. Assign default scope and role
    await supabaseAdmin.from('admin_scopes').insert({
      admin_id: userId,
      scope_type: `Global`
    })

    // 5. Generate secure token for accept/reject links
    const token = await signInviteToken(userId)
    const baseUrl = process.env.VITE_APP_URL || 'http://localhost:3000' // Ensure this matches your dev port
    const acceptUrl = `${baseUrl}/invite/response?token=${token}&action=accept`
    const rejectUrl = `${baseUrl}/invite/response?token=${token}&action=reject`

    // 6. Send Invitation Email (without credentials)
    try {
      await resend.emails.send({
        from: 'Campusly Admin <admin_campusly@sachindigisolutions.me>',
        to: data.email,
        subject: 'Invitation to join Campusly Admin Dashboard',
        html: `
          <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 8px;">
            <h2 style="color: #1a1a1a;">Welcome ${data.fullName}!</h2>
            <p style="color: #4a4a4a; line-height: 1.5;">You have been invited to join the Campusly Admin Dashboard as a <strong>${data.designation}</strong>.</p>
            
            <p style="color: #4a4a4a; margin-top: 20px;">Please accept or reject this invitation by clicking one of the buttons below:</p>
            
            <div style="margin: 30px 0; display: flex; gap: 15px;">
              <a href="${acceptUrl}" style="background-color: #10b981; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">Accept Invitation</a>
              <a href="${rejectUrl}" style="background-color: #ef4444; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; margin-left: 15px;">Reject Invitation</a>
            </div>
            
            <p style="color: #666; font-size: 14px; border-top: 1px solid #eee; padding-top: 20px;">
              If you accept, your administrator will review and approve your account, after which you will receive your login credentials.
            </p>
          </div>
        `
      })
    } catch (e) {
      console.error("Resend Email Warning:", e)
    }

    return { success: true, userId }
  })

type UpdateAdminData = {
  adminId: string
  fullName: string
  phone: string
  staffId: string
  department: string
  designation: string
}

export const updateAdminProfileFn = createServerFn({ method: 'POST' })
  .validator((data: UpdateAdminData) => data)
  .handler(async ({ data }) => {
    const supabaseUrl = process.env.VITE_SUPABASE_URL
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing server environment variables.")
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

    const { error } = await supabaseAdmin
      .from('admin_profiles')
      .update({
        full_name: data.fullName,
        phone: data.phone,
        staff_id: data.staffId,
        department: data.department,
        designation: data.designation
      })
      .eq('id', data.adminId)

    if (error) {
      throw new Error("Failed to update profile: " + error.message)
    }

    return { success: true }
  })

type ResendWelcomeEmailData = {
  adminId: string
}

export const resendWelcomeEmailFn = createServerFn({ method: 'POST' })
  .validator((data: ResendWelcomeEmailData) => data)
  .handler(async ({ data }) => {
    const supabaseUrl = process.env.VITE_SUPABASE_URL
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
    const resendApiKey = process.env.RESEND_API_KEY

    if (!supabaseUrl || !supabaseServiceKey || !resendApiKey) {
      throw new Error("Missing server environment variables.")
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)
    const resend = new Resend(resendApiKey)

    // 1. Get user profile
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('admin_profiles')
      .select('email, full_name, designation')
      .eq('id', data.adminId)
      .single()

    if (profileError || !profile) {
      throw new Error("Failed to fetch admin profile")
    }

    // 2. Generate secure token for accept/reject links
    const token = await signInviteToken(data.adminId)
    const baseUrl = process.env.VITE_APP_URL || 'http://localhost:3000'
    const acceptUrl = `${baseUrl}/invite/response?token=${token}&action=accept`
    const rejectUrl = `${baseUrl}/invite/response?token=${token}&action=reject`

    // 3. Send Invitation Email
    try {
      await resend.emails.send({
        from: 'Campusly Admin <admin_campusly@sachindigisolutions.me>',
        to: profile.email,
        subject: 'Invitation to join Campusly Admin Dashboard (Resent)',
        html: `
          <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 8px;">
            <h2 style="color: #1a1a1a;">Welcome ${profile.full_name}!</h2>
            <p style="color: #4a4a4a; line-height: 1.5;">You have been invited to join the Campusly Admin Dashboard as a <strong>${profile.designation}</strong>.</p>
            
            <p style="color: #4a4a4a; margin-top: 20px;">Please accept or reject this invitation by clicking one of the buttons below:</p>
            
            <div style="margin: 30px 0; display: flex; gap: 15px;">
              <a href="${acceptUrl}" style="background-color: #10b981; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block;">Accept Invitation</a>
              <a href="${rejectUrl}" style="background-color: #ef4444; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-weight: bold; display: inline-block; margin-left: 15px;">Reject Invitation</a>
            </div>
            
            <p style="color: #666; font-size: 14px; border-top: 1px solid #eee; padding-top: 20px;">
              If you accept, your administrator will review and approve your account, after which you will receive your login credentials.
            </p>
          </div>
        `
      })
    } catch (e) {
      console.error("Resend Email Warning:", e)
    }

    return { success: true }
  })

type ResendInvitationData = {
  adminId: string
}

export const resendAdminInvitationFn = createServerFn({ method: 'POST' })
  .validator((data: ResendInvitationData) => data)
  .handler(async ({ data }) => {
    const supabaseUrl = process.env.VITE_SUPABASE_URL
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
    const resendApiKey = process.env.RESEND_API_KEY

    if (!supabaseUrl || !supabaseServiceKey || !resendApiKey) {
      throw new Error("Missing server environment variables.")
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)
    const resend = new Resend(resendApiKey)

    // 1. Get user profile
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('admin_profiles')
      .select('email, full_name, designation')
      .eq('id', data.adminId)
      .single()

    if (profileError || !profile) {
      throw new Error("Failed to fetch admin profile")
    }

    // 2. Generate new credentials
    const password = generatePassword()
    const otp = generateOTP()
    const expiresAt = new Date()
    expiresAt.setHours(expiresAt.getHours() + 24)

    // 3. Update auth password
    const { error: authError } = await supabaseAdmin.auth.admin.updateUserById(
      data.adminId,
      { password: password }
    )

    if (authError) {
      throw new Error("Failed to reset password: " + authError.message)
    }

    // 4. Update OTP in profile
    const { error: updateError } = await supabaseAdmin
      .from('admin_profiles')
      .update({
        otp_code: otp,
        otp_expires_at: expiresAt.toISOString()
      })
      .eq('id', data.adminId)

    if (updateError) {
      throw new Error("Failed to update OTP: " + updateError.message)
    }

    // 5. Resend email
    try {
      await resend.emails.send({
        from: 'Campusly Admin <admin_campusly@sachindigisolutions.me>',
        to: profile.email,
        subject: 'Welcome to Campusly Admin Dashboard (Resent)',
        html: `
          <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 8px;">
            <h2 style="color: #1a1a1a;">Welcome ${profile.full_name}!</h2>
            <p style="color: #4a4a4a; line-height: 1.5;">You have been invited to join the Campusly Admin Dashboard as a <strong>${profile.designation || 'Administrator'}</strong>.</p>
            
            <div style="background: #f9fafb; padding: 15px; border-radius: 6px; margin: 20px 0;">
              <p style="margin: 0 0 10px 0;"><strong>Your NEW login credentials:</strong></p>
              <p style="margin: 0; color: #1a1a1a;">Email: ${profile.email}</p>
              <p style="margin: 0; color: #1a1a1a;">Password: <code>${password}</code></p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
              <p style="color: #4a4a4a; margin-bottom: 10px;"><strong>Your NEW OTP Verification Code:</strong></p>
              <h1 style="background: #000; color: #fff; padding: 15px 30px; display: inline-block; letter-spacing: 8px; border-radius: 6px; margin: 0;">${otp}</h1>
            </div>
            
            <p style="color: #666; font-size: 14px; border-top: 1px solid #eee; padding-top: 20px;">
              Please login at your earliest convenience. You will be prompted to enter this OTP on your first login.
            </p>
          </div>
        `
      })
    } catch (e) {
      console.error("Resend Email Warning:", e)
    }

    return { success: true, testPassword: password, testOtp: otp }
  })

type InvitationResponseData = {
  token: string
  action: 'accept' | 'reject'
}

export const processInvitationResponseFn = createServerFn({ method: 'POST' })
  .validator((data: InvitationResponseData) => data)
  .handler(async ({ data }) => {
    const userId = await verifyInviteToken(data.token)
    if (!userId) {
      throw new Error("Invalid or expired invitation token.")
    }

    const supabaseUrl = process.env.VITE_SUPABASE_URL
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
    if (!supabaseUrl || !supabaseServiceKey) throw new Error("Missing env")
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)

    const newStatus = data.action === 'accept' ? 'Accepted' : 'Rejected'

    const { error } = await supabaseAdmin
      .from('admin_profiles')
      .update({ status: newStatus })
      .eq('id', userId)

    if (error) {
      throw new Error("Failed to update status: " + error.message)
    }

    return { success: true, status: newStatus }
  })

type ApproveAdminData = {
  adminId: string
}

export const approveAdminFn = createServerFn({ method: 'POST' })
  .validator((data: ApproveAdminData) => data)
  .handler(async ({ data }) => {
    const supabaseUrl = process.env.VITE_SUPABASE_URL
    const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY
    const resendApiKey = process.env.RESEND_API_KEY
    if (!supabaseUrl || !supabaseServiceKey || !resendApiKey) throw new Error("Missing env")

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey)
    const resend = new Resend(resendApiKey)

    // 1. Get profile
    const { data: profile, error: profileError } = await supabaseAdmin
      .from('admin_profiles')
      .select('email, full_name, designation')
      .eq('id', data.adminId)
      .single()

    if (profileError || !profile) throw new Error("Admin not found.")

    // 2. Generate credentials
    const password = generatePassword()
    const otp = generateOTP()
    const expiresAt = new Date()
    expiresAt.setHours(expiresAt.getHours() + 24)

    // 3. Update auth user
    const { error: authError } = await supabaseAdmin.auth.admin.updateUserById(
      data.adminId,
      { password: password }
    )
    if (authError) throw new Error("Failed to set user password.")

    // 4. Update profile status and OTP
    const { error: updateError } = await supabaseAdmin
      .from('admin_profiles')
      .update({
        status: 'Pending_Verification',
        otp_code: otp,
        otp_expires_at: expiresAt.toISOString()
      })
      .eq('id', data.adminId)

    if (updateError) throw new Error("Failed to approve admin.")

    // 5. Send Credentials Email
    try {
      await resend.emails.send({
        from: 'Campusly Admin <admin_campusly@sachindigisolutions.me>',
        to: profile.email,
        subject: 'Your Campusly Admin Account is Approved',
        html: `
          <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 8px;">
            <h2 style="color: #1a1a1a;">Welcome to the team, ${profile.full_name}!</h2>
            <p style="color: #4a4a4a; line-height: 1.5;">Your account as a <strong>${profile.designation}</strong> has been approved.</p>
            
            <div style="background: #f9fafb; padding: 15px; border-radius: 6px; margin: 20px 0;">
              <p style="margin: 0 0 10px 0;"><strong>Your login credentials:</strong></p>
              <p style="margin: 0; color: #1a1a1a;">Email: ${profile.email}</p>
              <p style="margin: 0; color: #1a1a1a;">Password: <code>${password}</code></p>
            </div>
            
            <div style="text-align: center; margin: 30px 0;">
              <p style="color: #4a4a4a; margin-bottom: 10px;"><strong>Your OTP Verification Code:</strong></p>
              <h1 style="background: #000; color: #fff; padding: 15px 30px; display: inline-block; letter-spacing: 8px; border-radius: 6px; margin: 0;">${otp}</h1>
            </div>
            
            <p style="color: #666; font-size: 14px; border-top: 1px solid #eee; padding-top: 20px;">
              Please login at your earliest convenience. You will be prompted to enter this OTP on your first login.
            </p>
          </div>
        `
      })
    } catch (e) {
      console.error("Resend Email Warning:", e)
    }

    return { success: true, testPassword: password, testOtp: otp }
  })
