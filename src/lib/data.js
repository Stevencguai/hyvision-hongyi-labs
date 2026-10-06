import { supabase, supabaseReady } from './supabase';

const contentFromRow = row => ({
  studioName: row.studio_name, eyebrow: row.eyebrow, heroTitle: row.hero_title,
  heroImage: row.hero_image, introTitle: row.intro_title, intro: row.intro,
  photographer: row.photographer, address: row.address, phone: row.phone,
  email: row.email, lineId: row.line_id, lineUrl: row.line_url, instagram: row.instagram
});

const contentToRow = content => ({
  studio_name: content.studioName, eyebrow: content.eyebrow, hero_title: content.heroTitle,
  hero_image: content.heroImage, intro_title: content.introTitle, intro: content.intro,
  photographer: content.photographer, address: content.address, phone: content.phone,
  email: content.email, line_id: content.lineId, line_url: content.lineUrl, instagram: content.instagram,
  updated_at: new Date().toISOString()
});

const photoFromRow = row => ({ id: row.id, title: row.title, category: row.category, url: row.url, storagePath: row.storage_path });

export async function loadContent(fallback) {
  if (!supabaseReady) return fallback;
  const { data, error } = await supabase.from('site_content').select('*').limit(1).maybeSingle();
  return error || !data ? fallback : contentFromRow(data);
}

export async function saveContent(content) {
  if (!supabaseReady) return content;
  const { data: current } = await supabase.from('site_content').select('id').limit(1).maybeSingle();
  const query = current
    ? supabase.from('site_content').update(contentToRow(content)).eq('id', current.id)
    : supabase.from('site_content').insert(contentToRow(content));
  const { error } = await query;
  if (error) throw error;
  return content;
}

export async function loadPhotos(fallback) {
  if (!supabaseReady) return fallback;
  const { data, error } = await supabase.from('photos').select('*').order('created_at', { ascending: true });
  if (error) return fallback;
  if (!data.length) {
    const { data: seeded } = await supabase.from('photos').insert(fallback.map(({ title, category, url }) => ({ title, category, url }))).select('*');
    return seeded?.map(photoFromRow) || fallback;
  }
  return data.map(photoFromRow);
}

export async function savePhoto(draft, editingId) {
  let url = draft.url;
  let storagePath = draft.storagePath || null;
  if (draft.file) {
    storagePath = `${crypto.randomUUID()}-${draft.file.name.replace(/[^a-zA-Z0-9._-]/g, '-')}`;
    const { error: uploadError } = await supabase.storage.from('portfolio').upload(storagePath, draft.file, { upsert: true, contentType: draft.file.type });
    if (uploadError) throw uploadError;
    const { data } = supabase.storage.from('portfolio').getPublicUrl(storagePath);
    url = data.publicUrl;
  }
  const payload = { title: draft.title, category: draft.category, url, storage_path: storagePath };
  if (editingId) {
    const { data, error } = await supabase.from('photos').update(payload).eq('id', editingId).select('*').single();
    if (error) throw error;
    return photoFromRow(data);
  }
  const { data, error } = await supabase.from('photos').insert(payload).select('*').single();
  if (error) throw error;
  return photoFromRow(data);
}

export async function deletePhoto(photo) {
  if (photo.storagePath) await supabase.storage.from('portfolio').remove([photo.storagePath]);
  const { error } = await supabase.from('photos').delete().eq('id', photo.id);
  if (error) throw error;
}
