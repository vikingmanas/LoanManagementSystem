import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''

    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const supabaseClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    })

    // Get the user calling the function
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized: Invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Verify if they are an admin
    const { data: profile, error: profileError } = await supabaseClient
      .from('users')
      .select('role')
      .eq('id', user.id)
      .single()

    if (profileError || !profile || profile.role !== 'admin') {
      return new Response(
        JSON.stringify({ error: 'Unauthorized: Only admins can manage staff accounts' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Parse payload
    const body = await req.json()
    const action = body.action || 'create'

    // Create Admin client
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    })

    if (action === 'delete') {
      const { userId } = body
      if (!userId) {
        return new Response(
          JSON.stringify({ error: 'Missing userId for delete action' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Delete from auth.users (cascades to public.users and role-specific tables)
      const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId)

      if (deleteError) {
        return new Response(
          JSON.stringify({ error: deleteError.message || 'Failed to delete user' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({ success: true, message: 'User deleted successfully' }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    } else {
      // Default: create action
      const {
        email,
        password,
        role,
        fullName,
        phoneNumber,
        branchId,
        employeeCode,
        designation, // loan officer only
        region, // manager only
      } = body

      if (!email || !password || !role || !fullName || !phoneNumber || !branchId || !employeeCode) {
        return new Response(
          JSON.stringify({ error: 'Missing required fields' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      if (role !== 'loan_officer' && role !== 'manager') {
        return new Response(
          JSON.stringify({ error: 'Invalid role' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Create the user in auth.users
      const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          full_name: fullName,
          role: role,
        }
      })

      if (createError || !newUser.user) {
        return new Response(
          JSON.stringify({ error: createError?.message || 'Failed to create user' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      const newUserId = newUser.user.id

      // Insert into public.users
      const { error: userInsertError } = await supabaseAdmin
        .from('users')
        .insert({
          id: newUserId,
          email,
          role,
          full_name: fullName,
          mobile_number: phoneNumber,
          status: 'active',
          created_by: user.id,
        })

      if (userInsertError) {
        // Cleanup auth user to maintain consistency
        await supabaseAdmin.auth.admin.deleteUser(newUserId)
        return new Response(
          JSON.stringify({ error: userInsertError.message || 'Failed to create user profile' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // Insert role specific details
      if (role === 'loan_officer') {
        const { error: officerInsertError } = await supabaseAdmin
          .from('loan_officers')
          .insert({
            user_id: newUserId,
            employee_code: employeeCode,
            branch_id: branchId,
            designation: designation || 'Loan Officer',
          })

        if (officerInsertError) {
          // Cleanup
          await supabaseAdmin.from('users').delete().eq('id', newUserId)
          await supabaseAdmin.auth.admin.deleteUser(newUserId)
          return new Response(
            JSON.stringify({ error: officerInsertError.message || 'Failed to create loan officer profile' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
      } else if (role === 'manager') {
        const { error: managerInsertError } = await supabaseAdmin
          .from('managers')
          .insert({
            user_id: newUserId,
            employee_code: employeeCode,
            branch_id: branchId,
            region: region || 'General',
          })

        if (managerInsertError) {
          // Cleanup
          await supabaseAdmin.from('users').delete().eq('id', newUserId)
          await supabaseAdmin.auth.admin.deleteUser(newUserId)
          return new Response(
            JSON.stringify({ error: managerInsertError.message || 'Failed to create manager profile' }),
            { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }
      }

      return new Response(
        JSON.stringify({ user: newUser.user }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
