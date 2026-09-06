// Supabase Edge Function: send-task-reminders
// Triggered every minute via pg_cron.
// Queries tasks whose reminder is due, fetches FCM tokens, and sends push via FCM HTTP v1 API.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleAuth } from "https://esm.sh/google-auth-library@9";

const FIREBASE_PROJECT_ID = "focusflow-22c22";
const FCM_ENDPOINT = `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`;

// Service account key stored as a Supabase secret
const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

async function getFcmAccessToken(): Promise<string> {
  const serviceAccount = JSON.parse(serviceAccountJson!);
  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const client = await auth.getClient();
  const tokenResponse = await client.getAccessToken();
  return tokenResponse.token!;
}

async function sendFcmNotification(
  fcmToken: string,
  taskId: string,
  taskTitle: string,
  accessToken: string
) {
  const message = {
    message: {
      token: fcmToken,
      notification: {
        title: "FocusFlow",
        body: `Time to start: ${taskTitle}`,
      },
      data: {
        task_id: taskId,
        type: "task_reminder",
      },
      android: {
        priority: "high",
        notification: {
          channel_id: "focusflow_reminders_v2",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
    },
  };

  const res = await fetch(FCM_ENDPOINT, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(message),
  });

  if (!res.ok) {
    const err = await res.text();
    console.error(`FCM send failed for token ${fcmToken.substring(0, 20)}...: ${err}`);
  } else {
    console.log(`FCM sent for task: ${taskId}`);
  }
}

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const now = new Date().toISOString();

    // Query tasks whose reminder is due:
    // status = notYet, start_date <= now,
    // and (last_reminder_at IS NULL OR last_reminder_at + interval is <= now)
    const { data: tasks, error: tasksError } = await supabase.rpc(
      "get_due_reminder_tasks"
    );

    if (tasksError) {
      console.error("Error fetching due tasks:", tasksError.message);
      return new Response(JSON.stringify({ error: tasksError.message }), {
        status: 500,
      });
    }

    if (!tasks || tasks.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
    }

    // Get FCM access token once, reuse for all sends
    const accessToken = await getFcmAccessToken();
    let sentCount = 0;

    for (const task of tasks) {
      const { fcm_token, task_id, task_title, user_id } = task;
      if (!fcm_token) continue;

      await sendFcmNotification(fcm_token, task_id, task_title, accessToken);

      // Update last_reminder_at to prevent duplicate sends
      await supabase
        .from("tasks")
        .update({ last_reminder_at: now, updated_at: now })
        .eq("id", task_id);

      sentCount++;
    }

    return new Response(JSON.stringify({ sent: sentCount }), { status: 200 });
  } catch (e) {
    console.error("Edge function error:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
