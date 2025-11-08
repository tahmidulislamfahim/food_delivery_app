-- Supabase schema for food_delivery_app
-- Includes tables, RLS policies, RPC functions, and storage policy examples.
-- Run this in Supabase SQL editor as a project owner.

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ======================================================
-- Tables
-- ======================================================

-- Products table
CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  subtitle text,
  price numeric(10,2) NOT NULL DEFAULT 0,
  image_url text,
  calories integer,
  cook_time_minutes integer,
  category text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Favorites: link between users and products
CREATE TABLE IF NOT EXISTS public.favorites (
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, product_id)
);

-- Carts and cart_items
CREATE TABLE IF NOT EXISTS public.carts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'active', -- 'active', 'ordered', 'cancelled'
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id uuid NOT NULL REFERENCES public.carts(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  quantity integer NOT NULL DEFAULT 1 CHECK (quantity > 0),
  unit_price numeric(10,2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Orders and order_items (created when cart is placed)
CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  total numeric(12,2) NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending', -- e.g., pending/paid/fulfilled
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  quantity integer NOT NULL CHECK (quantity > 0),
  unit_price numeric(10,2) NOT NULL
);

-- Simple admins table: list of user_ids who have admin rights
CREATE TABLE IF NOT EXISTS public.admins (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ======================================================
-- Indexes
-- ======================================================
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products (category);
CREATE INDEX IF NOT EXISTS idx_cart_items_cart_id ON public.cart_items (cart_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders (user_id);

-- ======================================================
-- Row Level Security (RLS) policies
-- ======================================================

-- PRODUCTS: public read, only admins can insert/update/delete
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Allow everyone to read products (USE with caution; this app expects product listing public)
CREATE POLICY products_select_public ON public.products
  FOR SELECT USING (true);

-- Allow admins to insert products
CREATE POLICY products_insert_admin ON public.products
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid())
  );

-- Allow admins to update products
CREATE POLICY products_update_admin ON public.products
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid())
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid())
  );

-- Allow admins to delete products
CREATE POLICY products_delete_admin ON public.products
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid())
  );

-- FAVORITES: users can only read/insert/delete their own favorites
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY favorites_select_owner ON public.favorites
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND user_id = auth.uid()
  );

CREATE POLICY favorites_insert_owner ON public.favorites
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND user_id = auth.uid()
  );

CREATE POLICY favorites_delete_owner ON public.favorites
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND user_id = auth.uid()
  );

-- CARTS: user can only access their carts
ALTER TABLE public.carts ENABLE ROW LEVEL SECURITY;

CREATE POLICY carts_select_owner ON public.carts
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND user_id = auth.uid()
  );

CREATE POLICY carts_insert_owner ON public.carts
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND user_id = auth.uid()
  );

CREATE POLICY carts_update_owner ON public.carts
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND user_id = auth.uid()
  ) WITH CHECK (
    auth.uid() IS NOT NULL AND user_id = auth.uid()
  );

-- CART_ITEMS: allow actions only for items belonging to carts owned by the user
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY cart_items_select_owner ON public.cart_items
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND cart_id IN (
      SELECT id FROM public.carts WHERE user_id = auth.uid()
    )
  );

CREATE POLICY cart_items_insert_owner ON public.cart_items
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL AND cart_id IN (
      SELECT id FROM public.carts WHERE user_id = auth.uid()
    )
  );

CREATE POLICY cart_items_update_owner ON public.cart_items
  FOR UPDATE USING (
    auth.uid() IS NOT NULL AND cart_id IN (
      SELECT id FROM public.carts WHERE user_id = auth.uid()
    )
  ) WITH CHECK (
    auth.uid() IS NOT NULL AND cart_id IN (
      SELECT id FROM public.carts WHERE user_id = auth.uid()
    )
  );

CREATE POLICY cart_items_delete_owner ON public.cart_items
  FOR DELETE USING (
    auth.uid() IS NOT NULL AND cart_id IN (
      SELECT id FROM public.carts WHERE user_id = auth.uid()
    )
  );

-- ORDERS: users can only read their own orders; creation is done via RPC (place_order_from_cart)
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY orders_select_owner ON public.orders
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND user_id = auth.uid()
  );

-- ORDER_ITEMS: owner via orders
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY order_items_select_owner ON public.order_items
  FOR SELECT USING (
    auth.uid() IS NOT NULL AND order_id IN (
      SELECT id FROM public.orders WHERE user_id = auth.uid()
    )
  );

-- ======================================================
-- RPC / Functions (PL/pgSQL)
-- ======================================================

-- Helper: is_current_user_admin()
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid());
$$;

-- RPC: get_products(p_category text) - returns rows from products (public read)
CREATE OR REPLACE FUNCTION public.get_products(p_category text DEFAULT NULL)
RETURNS SETOF public.products
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.products
  WHERE (p_category IS NULL OR p_category = '' OR category = p_category)
  ORDER BY created_at DESC;
$$;

-- RPC: search_products(p_q text) - simple ILIKE search on title/subtitle
CREATE OR REPLACE FUNCTION public.search_products(p_q text)
RETURNS SETOF public.products
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.products
  WHERE (p_q IS NULL OR p_q = '' 
         OR title ILIKE ('%'||p_q||'%') 
         OR subtitle ILIKE ('%'||p_q||'%'))
  ORDER BY created_at DESC;
$$;

-- RPC: create_product(...) - only allowed for admins
CREATE OR REPLACE FUNCTION public.create_product(
  p_title text,
  p_subtitle text,
  p_price numeric,
  p_image_url text,
  p_category text,
  p_calories integer,
  p_cook_time_minutes integer
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id uuid := gen_random_uuid();
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  INSERT INTO public.products (id, title, subtitle, price, image_url, category, calories, cook_time_minutes, created_at, updated_at)
  VALUES (v_id, p_title, p_subtitle, p_price, p_image_url, p_category, p_calories, p_cook_time_minutes, now(), now());

  RETURN v_id;
END;
$$;

-- RPC: update_product(...)
CREATE OR REPLACE FUNCTION public.update_product(
  p_id uuid,
  p_title text,
  p_subtitle text,
  p_price numeric,
  p_image_url text,
  p_category text,
  p_calories integer,
  p_cook_time_minutes integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  UPDATE public.products
  SET title = p_title,
      subtitle = p_subtitle,
      price = p_price,
      image_url = p_image_url,
      category = p_category,
      calories = p_calories,
      cook_time_minutes = p_cook_time_minutes,
      updated_at = now()
  WHERE id = p_id;
END;
$$;

-- RPC: delete_product(p_id)
CREATE OR REPLACE FUNCTION public.delete_product(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid()) THEN
    RAISE EXCEPTION 'Not authorized';
  END IF;

  -- delete favorites referencing this product
  DELETE FROM public.favorites WHERE product_id = p_id;

  -- delete cart_items referencing this product
  DELETE FROM public.cart_items WHERE product_id = p_id;

  -- delete order_items referencing this product (optional caution)
  DELETE FROM public.order_items WHERE product_id = p_id;

  -- delete the product itself
  DELETE FROM public.products WHERE id = p_id;
END;
$$;

-- RPC: get_active_cart() -> returns json with cart_id, items array, total
CREATE OR REPLACE FUNCTION public.get_active_cart()
RETURNS json
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_cart_id uuid;
  v_items json;
  v_total numeric := 0;
BEGIN
  IF v_user IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT id INTO v_cart_id
  FROM public.carts
  WHERE user_id = v_user AND status = 'active'
  LIMIT 1;

  IF v_cart_id IS NULL THEN
    -- No active cart yet: return NULL (frontend treats as empty)
    RETURN NULL;
  END IF;

  SELECT COALESCE(
    json_agg(json_build_object(
      'product_id', ci.product_id,
      'title', p.title,
      'image_url', p.image_url,
      'quantity', ci.quantity,
      'unit_price', ci.unit_price
    ) ORDER BY ci.created_at),
    '[]'::json
  ) INTO v_items
  FROM public.cart_items ci
  LEFT JOIN public.products p ON p.id = ci.product_id
  WHERE ci.cart_id = v_cart_id;

  SELECT COALESCE(SUM(ci.quantity * ci.unit_price),0) INTO v_total
  FROM public.cart_items ci WHERE ci.cart_id = v_cart_id;

  RETURN json_build_object(
    'cart_id', v_cart_id::text,
    'items', v_items,
    'total', v_total
  );
END;
$$;

-- RPC: add_item_to_cart(p_product_id, p_quantity)
CREATE OR REPLACE FUNCTION public.add_item_to_cart(p_product_id uuid, p_quantity integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_cart uuid;
  v_price numeric;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- get product price
  SELECT price INTO v_price FROM public.products WHERE id = p_product_id;
  IF v_price IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  -- get or create active cart
  SELECT id INTO v_cart FROM public.carts WHERE user_id = v_user AND status = 'active' LIMIT 1;
  IF v_cart IS NULL THEN
    INSERT INTO public.carts (user_id, status, created_at, updated_at) VALUES (v_user, 'active', now(), now())
    RETURNING id INTO v_cart;
  END IF;

  -- upsert cart item
  LOOP
    -- try update existing
    UPDATE public.cart_items
    SET quantity = cart_items.quantity + p_quantity,
        unit_price = v_price
    WHERE cart_id = v_cart AND product_id = p_product_id;

    IF FOUND THEN
      -- updated existing; nothing else to do
      EXIT;
    ELSE
      -- insert new item
      INSERT INTO public.cart_items (cart_id, product_id, quantity, unit_price, created_at)
      VALUES (v_cart, p_product_id, GREATEST(p_quantity,1), v_price, now());
      EXIT;
    END IF;
  END LOOP;

  -- update cart updated_at
  UPDATE public.carts SET updated_at = now() WHERE id = v_cart;
END;
$$;

-- RPC: set_cart_item_quantity(p_product_id, p_quantity)
CREATE OR REPLACE FUNCTION public.set_cart_item_quantity(p_product_id uuid, p_quantity integer)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_cart uuid;
  v_price numeric;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT id INTO v_cart FROM public.carts WHERE user_id = v_user AND status = 'active' LIMIT 1;
  IF v_cart IS NULL THEN
    RAISE EXCEPTION 'No active cart';
  END IF;

  SELECT price INTO v_price FROM public.products WHERE id = p_product_id;
  IF v_price IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  IF p_quantity <= 0 THEN
    DELETE FROM public.cart_items WHERE cart_id = v_cart AND product_id = p_product_id;
  ELSE
    UPDATE public.cart_items
    SET quantity = p_quantity, unit_price = v_price
    WHERE cart_id = v_cart AND product_id = p_product_id;
  END IF;

  UPDATE public.carts SET updated_at = now() WHERE id = v_cart;
END;
$$;

-- RPC: remove_item_from_cart(p_product_id)
CREATE OR REPLACE FUNCTION public.remove_item_from_cart(p_product_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_cart uuid;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT id INTO v_cart FROM public.carts WHERE user_id = v_user AND status = 'active' LIMIT 1;
  IF v_cart IS NULL THEN
    RETURN;
  END IF;

  DELETE FROM public.cart_items WHERE cart_id = v_cart AND product_id = p_product_id;
  UPDATE public.carts SET updated_at = now() WHERE id = v_cart;
END;
$$;

-- RPC: place_order_from_cart() -> returns order_id (text)
CREATE OR REPLACE FUNCTION public.place_order_from_cart()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user uuid := auth.uid();
  v_cart uuid;
  v_order uuid := gen_random_uuid();
  v_total numeric := 0;
  rec record;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT id INTO v_cart FROM public.carts WHERE user_id = v_user AND status = 'active' LIMIT 1;
  IF v_cart IS NULL THEN
    RAISE EXCEPTION 'No active cart';
  END IF;

  -- compute total
  SELECT COALESCE(SUM(quantity * unit_price),0) INTO v_total
  FROM public.cart_items WHERE cart_id = v_cart;

  IF v_total <= 0 THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;

  -- create order
  INSERT INTO public.orders (id, user_id, total, status, created_at)
  VALUES (v_order, v_user, v_total, 'pending', now());

  -- move items
  FOR rec IN SELECT * FROM public.cart_items WHERE cart_id = v_cart
  LOOP
    INSERT INTO public.order_items (order_id, product_id, quantity, unit_price)
    VALUES (v_order, rec.product_id, rec.quantity, rec.unit_price);
  END LOOP;

  -- mark cart as ordered
  UPDATE public.carts SET status = 'ordered', updated_at = now() WHERE id = v_cart;

  -- optionally clear cart_items (we left them for historical records; uncomment to delete)
  DELETE FROM public.cart_items WHERE cart_id = v_cart;

  RETURN v_order::text;
END;
$$;

-- ======================================================
-- Storage bucket guidance & policy examples
-- ======================================================

-- NOTE: Storage buckets are usually created via the Supabase Dashboard or the Storage API using the service_role key.
-- Create the bucket named 'product-images' and choose public=true if you want public URLs.

-- Example: try to create via SQL (works only if storage extension is enabled)
-- SELECT storage.create_bucket('product-images', true);

-- If you keep the bucket public, client code can call getPublicUrl() and no extra RLS is required for reads.

-- If you want the bucket to be private and allow authenticated users to upload and read their objects, use policies like the ones below.
-- These policies assume the storage schema exposes a table storage.objects (it usually does in Supabase projects).

-- Allow authenticated users to INSERT (upload) objects to product-images
-- (Run this AFTER you create the bucket)

-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- CREATE POLICY IF NOT EXISTS storage_insert_product_images_authenticated
--   ON storage.objects
--   FOR INSERT
--   USING (
--     auth.role() = 'authenticated' AND bucket_id = 'product-images'
--   )
--   WITH CHECK (
--     auth.role() = 'authenticated' AND bucket_id = 'product-images'
--   );

-- Allow owners (uploader) or admins to delete/update their objects
-- CREATE POLICY IF NOT EXISTS storage_delete_product_images_owner_or_admin
--   ON storage.objects
--   FOR DELETE
--   USING (
--     (auth.uid() IS NOT NULL AND owner = auth.uid() AND bucket_id = 'product-images')
--     OR EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid())
--   );

-- Allow authenticated users to SELECT object metadata for their uploads
-- CREATE POLICY IF NOT EXISTS storage_select_product_images_owner
--   ON storage.objects
--   FOR SELECT
--   USING (
--     bucket_id = 'product-images' AND (
--       auth.role() = 'authenticated' OR EXISTS (SELECT 1 FROM public.admins a WHERE a.user_id = auth.uid())
--     )
--   );

-- If you want to restrict downloads for private buckets, use signed URLs from the client via the Storage API.

-- ======================================================
-- Helpful initial admin setup (run as a privileged user / using service_role key)
-- ======================================================
-- Insert an admin user (replace '<USER_UUID>' with the actual auth.uid() of the admin)
-- Example:
-- INSERT INTO public.admins (user_id) VALUES ('00000000-0000-0000-0000-000000000000');

-- ======================================================
-- Optional seed example (create a sample product)
-- ======================================================
-- INSERT INTO public.products (id, title, subtitle, price, image_url, category, calories, cook_time_minutes)
-- VALUES (gen_random_uuid(), 'Test Pizza', 'A delicious test pizza', 9.99, 'https://example.com/test.jpg', 'Pizza', 400, 15);

-- End of file
