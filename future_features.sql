-- Add an is_admin flag to auth.users via metadata or create a separate table if preferred.
-- Here we're using a simple profile table example:

CREATE TABLE IF NOT EXISTS public.user_roles (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role text NOT NULL DEFAULT 'user'  -- 'admin' or 'user'
);

-- Optional seed: manually insert your admin's UUID after signing up
-- INSERT INTO public.user_roles (user_id, role) VALUES ('your-admin-uuid', 'admin');

-- Policy to allow only admins to manage products
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can manage products"
ON public.products
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_roles.user_id = auth.uid()
    AND user_roles.role = 'admin'
  )
);

-- Normal users can read products
CREATE POLICY "Anyone can read products"
ON public.products
FOR SELECT
USING (true);
