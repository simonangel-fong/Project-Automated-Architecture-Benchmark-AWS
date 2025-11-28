-- 01_role.sql
\echo
\echo '######## creating roles ########'
\echo

-- app_owner: owns schema/tables, no direct login
DO
$do$
BEGIN
   IF EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE rolname = 'app_owner'
   ) THEN
      RAISE NOTICE 'Role "app_owner" already exists. Skipping.';
   ELSE
      CREATE ROLE app_owner NOLOGIN;
   END IF;
END
$do$;

-- app_user: application user
DO
$do$
BEGIN
   IF EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE rolname = 'app_user'
   ) THEN
      RAISE NOTICE 'Role "app_user" already exists. Skipping.';
   ELSE
      CREATE ROLE app_user
         LOGIN
         PASSWORD 'postgres'  -- TODO: replace with psql var / secret
         NOSUPERUSER
         NOCREATEDB
         NOCREATEROLE;
   END IF;
END
$do$;

-- app_readonly: optional read-only user/role
DO
$do$
BEGIN
   IF EXISTS (
      SELECT FROM pg_catalog.pg_roles
      WHERE rolname = 'app_readonly'
   ) THEN
      RAISE NOTICE 'Role "app_readonly" already exists. Skipping.';
   ELSE
      CREATE ROLE app_readonly
         LOGIN
         PASSWORD 'postgres'  -- TODO: replace with psql var / secret
         NOSUPERUSER
         NOCREATEDB
         NOCREATEROLE;
   END IF;
END
$do$;

-- confirm
SELECT
    rolname,
    rolcanlogin,
    rolsuper,
    rolcreaterole,
    rolcreatedb,
    rolinherit
FROM
    pg_roles
WHERE
    rolname IN ('app_owner', 'app_user', 'app_readonly');
