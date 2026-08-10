import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";
import { GoogleAuth } from 'npm:google-auth-library@9.0.0';

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { timetable_id, period_id, old_data, new_data, change_type, subject_name } = await req.json();
    
    if (!timetable_id || !period_id || !change_type) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      });
    }

    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "No authorization header" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }

    // Initialize Supabase Client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // 1. Verify user is admin
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401,
      });
    }
    
    // Note: Add strict RLS checking here or check if user has admin role
    // For now, assume if they have access to hit this, they are authenticated.

    // 2. Identify Affected Students
    // If it's a custom timetable, get students joined to this timetable.
    const { data: users, error: usersError } = await supabase
      .from('user_custom_timetables')
      .select('user_id')
      .eq('timetable_id', timetable_id);

    if (usersError) {
      throw new Error(`Failed to fetch affected students: ${usersError.message}`);
    }

    const affectedStudentIds = users.map((u: any) => u.user_id);
    
    // 3. Log Change Event
    const { data: changeEvent, error: changeError } = await supabase
      .from('timetable_change_events')
      .insert({
        timetable_id,
        timetable_entry_id: period_id,
        change_type,
        old_data,
        new_data,
        affected_student_count: affectedStudentIds.length,
        created_by: user.id,
        notification_status: 'PROCESSING'
      })
      .select()
      .single();

    if (changeError) {
      throw new Error(`Failed to log change event: ${changeError.message}`);
    }

    // 4. Create Notification Events (Inbox)
    let title = "🚨 Class Alert";
    let body = `Changes made to ${subject_name || 'a class'}`;
    
    if (change_type === 'VENUE_CHANGED') {
      title = "🚨 Class Venue Changed";
      body = `${subject_name || 'Class'} has moved from ${old_data.room || 'old room'} to ${new_data.room || 'new room'}.`;
    } else if (change_type === 'TIME_CHANGED') {
      title = "🚨 Class Time Changed";
      body = `${subject_name || 'Class'} time changed to ${new_data.start_time}.`;
    } else if (change_type === 'CANCELLED') {
      title = "🚨 Class Cancelled";
      body = `${subject_name || 'Class'} has been cancelled.`;
    } else if (change_type === 'FACULTY_CHANGED') {
      title = "🚨 Faculty Changed";
      body = `Faculty changed to ${new_data.faculty}.`;
    }

    // Broadcast to the global "Live Campus & Class Notices" feed
    const { error: broadcastError } = await supabase
      .from('notifications')
      .insert({
        title: title,
        body: body,
        priority: 'high',
        target: 'System Auto-Alert'
      });

    if (broadcastError) {
      console.error("Failed to insert into global notifications", broadcastError);
    }

    // If nobody affected, we can stop here
    if (affectedStudentIds.length === 0) {
      return new Response(JSON.stringify({ success: true, message: "No students affected, but broadcasted.", affected: 0 }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const notificationRecords = affectedStudentIds.map((userId: string) => ({
      user_id: userId,
      change_event_id: changeEvent.id,
      type: change_type,
      title: title,
      body: body,
      data: { old_data, new_data, timetable_id, period_id },
      priority: 'HIGH'
    }));

    const { error: notifError } = await supabase
      .from('notification_events')
      .insert(notificationRecords);

    if (notifError) {
      console.error("Failed to insert notification events", notifError);
    }

    // 5. Send Push Notifications via FCM
    // Fetch all active tokens for affected students
    const { data: devices, error: devicesError } = await supabase
      .from('user_devices')
      .select('push_token')
      .in('user_id', affectedStudentIds)
      .eq('is_active', true)
      .not('push_token', 'is', null);

    let sentCount = 0;
    
    if (devices && devices.length > 0) {
      const tokens = devices.map((d: any) => d.push_token);
      
      try {
        const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
        if (serviceAccountStr) {
          const serviceAccount = JSON.parse(serviceAccountStr);
          
          const auth = new GoogleAuth({
            credentials: {
              client_email: serviceAccount.client_email,
              private_key: serviceAccount.private_key,
            },
            scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
          });
          
          const client = await auth.getClient();
          const accessToken = await client.getAccessToken();

          const projectId = serviceAccount.project_id;
          const url = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

          // Send to each token
          // Note: In production with many users, batching via FCM topic or multiple sends is preferred.
          for (const token of tokens) {
            const fcmMessage = {
              message: {
                token: token,
                notification: {
                  title: title,
                  body: body,
                },
                data: {
                  change_type,
                  timetable_id,
                  period_id,
                  click_action: "FLUTTER_NOTIFICATION_CLICK"
                },
                android: {
                  priority: "high",
                  notification: {
                    channel_id: "campusly_class_alerts",
                    sound: "default"
                  }
                },
                apns: {
                  payload: {
                    aps: {
                      sound: "default"
                    }
                  }
                }
              }
            };

            const response = await fetch(url, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${accessToken.token}`,
              },
              body: JSON.stringify(fcmMessage),
            });

            if (response.ok) {
              sentCount++;
            } else {
              const errText = await response.text();
              console.error(`FCM error for token ${token}:`, errText);
              // Check if token is unregistered, if so, mark as inactive
              if (errText.includes('UNREGISTERED')) {
                await supabase.from('user_devices').update({ is_active: false }).eq('push_token', token);
              }
            }
          }
        } else {
          console.log("No FIREBASE_SERVICE_ACCOUNT_JSON found. Skipping push notifications.");
        }
      } catch (fcmError) {
        console.error("Failed to send FCM push", fcmError);
      }
    }

    // Update change event status
    await supabase
      .from('timetable_change_events')
      .update({ notification_status: 'SENT' })
      .eq('id', changeEvent.id);

    return new Response(JSON.stringify({ 
      success: true, 
      affected: affectedStudentIds.length,
      push_sent: sentCount
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });

  } catch (error: any) {
    console.error("Function error:", error);
    return new Response(JSON.stringify({ error: error.message, stack: error.stack }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500,
    });
  }
});
