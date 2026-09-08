import { supabase } from "./supabase.js";

export const $ = (selector) => document.querySelector(selector);

export function esc(value = "") {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

export function avatar(url, name = "User") {
  if (url) return url;

  const letter = encodeURIComponent(
    String(name).trim().charAt(0).toUpperCase() || "U"
  );

  return `https://ui-avatars.com/api/?name=${letter}&background=11111b&color=ffffff&bold=true`;
}

export function timeAgo(date) {
  const diff = Math.floor((Date.now() - new Date(date).getTime()) / 1000);

  if (diff < 60) return "just now";
  if (diff < 3600) return `${Math.floor(diff / 60)}m`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h`;
  if (diff < 604800) return `${Math.floor(diff / 86400)}d`;

  return new Date(date).toLocaleDateString();
}

export async function getUser() {
  const { data } = await supabase.auth.getUser();
  return data?.user || null;
}

export async function requireUser() {
  const user = await getUser();

  if (!user) {
    location.href = "login.html";
    return null;
  }

  return user;
}

export async function getProfile(userId) {
  const { data, error } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .maybeSingle();

  if (error) {
    console.error(error);
    return null;
  }

  return data;
}

export async function uploadMedia(file, folder = "media") {
  if (!file) return null;

  const extension =
    file.name.split(".").pop()?.toLowerCase() || "bin";

  const fileName =
    `${folder}/${crypto.randomUUID()}.${extension}`;

  const { error } = await supabase.storage
    .from("media")
    .upload(fileName, file, {
      cacheControl: "3600",
      upsert: false,
      contentType: file.type
    });

  if (error) {
    throw error;
  }

  const { data } = supabase.storage
    .from("media")
    .getPublicUrl(fileName);

  return data.publicUrl;
}

export async function logout() {
  await supabase.auth.signOut();
  location.href = "login.html";
}

export async function notify(
  receiverId,
  type,
  postId = null
) {
  const user = await getUser();

  if (!user || receiverId === user.id) return;

  await supabase.from("notifications").insert({
    user_id: receiverId,
    actor_id: user.id,
    type,
    post_id: postId
  });
}

export function showMessage(message, type = "error") {
  const box = document.createElement("div");

  box.textContent = message;

  box.style.position = "fixed";
  box.style.top = "80px";
  box.style.right = "18px";
  box.style.zIndex = "9999";
  box.style.padding = "13px 18px";
  box.style.borderRadius = "14px";
  box.style.background = "#11111b";
  box.style.color = "#fff";
  box.style.border =
    type === "success"
      ? "1px solid #00eaff"
      : "1px solid #ff0055";

  box.style.boxShadow =
    type === "success"
      ? "0 0 15px rgba(0,234,255,.35)"
      : "0 0 15px rgba(255,0,85,.35)";

  document.body.appendChild(box);

  setTimeout(() => box.remove(), 3000);
}
