// filepath: c:\dev\realityapp\frontend\lib\core\config\supabase_config.dart

//const String supabaseUrl = 'http://127.0.0.1:54321';
//const String supabaseKey =
//    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU";

//const String supabaseUrl = 'https://ngulrgezwqzmvziimikh.supabase.co';
//const String supabaseKey = 'sb_publishable_V66bRZCvYKvZOEZuZDoxOg_7aXyi6gb';

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseKey = String.fromEnvironment('SUPABASE_KEY');