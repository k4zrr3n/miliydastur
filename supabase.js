
const SUPABASE_URL = 'https://dmemeqieevcvdmnumgfq.supabase.co';
const SUPABASE_KEY = 'sb_publishable_dqtJy7RMrZ6T5oWNjjONRA_Mnrziwkc';

if (!window.supabase || typeof window.supabase.createClient !== 'function') {
  console.error('Supabase SDK не загружен. Проверь подключение библиотеки в index.html.');
} else {
  const supabaseClient = window.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_KEY
  );

  window.supabaseClient = supabaseClient;

  console.log('Supabase client создан:', !!window.supabaseClient);

  async function testSupabaseConnection() {
    const { data, error } = await window.supabaseClient
      .from('site_settings')
      .select('*')
      .limit(1);

    if (error) {
      console.error('Ошибка Supabase:', error.message);
    } else {
      console.log('Supabase: связь с базой работает!', data);
    }
  }

  testSupabaseConnection();
}
