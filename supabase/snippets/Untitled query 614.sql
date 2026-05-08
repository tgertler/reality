
UPDATE public.profiles
SET is_premium = false, premium_until = null, updated_at = now()
WHERE id = 'c4db52cc-14af-4fa5-80c6-02e3af8c4ecc';