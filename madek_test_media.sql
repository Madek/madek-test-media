--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.12
-- Dumped by pg_dump version 10.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: fuzzystrmatch; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;


--
-- Name: EXTENSION fuzzystrmatch; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION fuzzystrmatch IS 'determine similarities and distance between strings';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: collection_layout; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.collection_layout AS ENUM (
    'grid',
    'list',
    'miniature',
    'tiles'
);


--
-- Name: collection_sorting; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.collection_sorting AS ENUM (
    'created_at ASC',
    'created_at DESC',
    'title ASC',
    'title DESC',
    'last_change'
);


--
-- Name: check_collection_cover_uniqueness(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_collection_cover_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF
              (SELECT
                (SELECT COUNT(1)
                 FROM collection_media_entry_arcs
                 WHERE collection_media_entry_arcs.cover IS true
                 AND collection_media_entry_arcs.collection_id = NEW.collection_id)
              > 1)
              THEN RAISE EXCEPTION 'There exists already a cover for collection %.', NEW.collection_id;
            END IF;
            RETURN NEW;
          END;
          $$;


--
-- Name: check_collection_primary_uniqueness(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_collection_primary_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          IF
            (SELECT
              (SELECT COUNT(1)
               FROM custom_urls
               WHERE custom_urls.is_primary IS true
               AND custom_urls.collection_id = NEW.collection_id)
            > 1)
            THEN RAISE EXCEPTION 'There exists already a primary id for collection %.', NEW.collection_id;
          END IF;
          RETURN NEW;
        END;
        $$;


--
-- Name: check_filter_set_primary_uniqueness(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_filter_set_primary_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          IF
            (SELECT
              (SELECT COUNT(1)
               FROM custom_urls
               WHERE custom_urls.is_primary IS true
               AND custom_urls.filter_set_id = NEW.filter_set_id)
            > 1)
            THEN RAISE EXCEPTION 'There exists already a primary id for filter_set %.', NEW.filter_set_id;
          END IF;
          RETURN NEW;
        END;
        $$;


--
-- Name: check_madek_core_meta_key_immutability(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_madek_core_meta_key_immutability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF (TG_OP = 'DELETE') THEN
              IF (OLD.id ilike 'madek_core:%') THEN
                RAISE EXCEPTION 'The madek_core meta_key % may not be deleted', OLD.id;
              END IF;
            ELSIF  (TG_OP = 'UPDATE') THEN
              IF (OLD.id ilike 'madek_core:%') THEN
                RAISE EXCEPTION 'The madek_core meta_key % may not be modified', OLD.id;
              END IF;
              IF (NEW.id ilike 'madek_core:%') THEN
                RAISE EXCEPTION 'The madek_core meta_key namespace may not be extended by %', NEW.id;
              END IF;
            ELSIF  (TG_OP = 'INSERT') THEN
              IF (NEW.id ilike 'madek_core:%') THEN
                RAISE EXCEPTION 'The madek_core meta_key namespace may not be extended by %', NEW.id;
              END IF;
            END IF;
            RETURN NEW;
          END;
          $$;


--
-- Name: check_media_entry_primary_uniqueness(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_media_entry_primary_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
          IF
            (SELECT
              (SELECT COUNT(1)
               FROM custom_urls
               WHERE custom_urls.is_primary IS true
               AND custom_urls.media_entry_id = NEW.media_entry_id)
            > 1)
            THEN RAISE EXCEPTION 'There exists already a primary id for media_entry %.', NEW.media_entry_id;
          END IF;
          RETURN NEW;
        END;
        $$;


--
-- Name: check_meta_data_created_by(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_meta_data_created_by() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.created_by_id IS NULL THEN
    RAISE EXCEPTION 'created_by in table meta_data may not be null';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: check_meta_data_keywords_created_by(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_meta_data_keywords_created_by() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.created_by_id IS NULL THEN
    RAISE EXCEPTION 'created_by in table meta_data_keywords may not be null';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: check_meta_data_licenses_created_by(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_meta_data_licenses_created_by() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.created_by_id IS NULL THEN
    RAISE EXCEPTION 'created_by in table meta_data_licenses may not be null';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: check_meta_data_meta_key_type_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_meta_data_meta_key_type_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN

            IF EXISTS (SELECT 1 FROM meta_keys 
              JOIN meta_data ON meta_data.meta_key_id = meta_keys.id
              WHERE meta_data.id = NEW.id
              AND meta_keys.meta_datum_object_type <> meta_data.type) THEN
                RAISE EXCEPTION 'The types of related meta_data and meta_keys must be identical';
            END IF;

            RETURN NEW;
          END;
          $$;


--
-- Name: check_meta_data_people_created_by(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_meta_data_people_created_by() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NEW.created_by_id IS NULL THEN
    RAISE EXCEPTION 'created_by in table meta_data_people may not be null';
  END IF;
  RETURN NEW;
END;
$$;


--
-- Name: check_meta_key_id_consistency_for_keywords(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_meta_key_id_consistency_for_keywords() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN

            IF (SELECT meta_key_id
                FROM meta_data
                WHERE meta_data.id = NEW.meta_datum_id) <>
               (SELECT meta_key_id
                FROM keywords
                WHERE id = NEW.keyword_id)
            THEN
                RAISE EXCEPTION 'The meta_key_id for meta_data and keywords must be identical';
            END IF;

            RETURN NEW;
          END;
          $$;


--
-- Name: check_meta_key_meta_data_type_consistency(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_meta_key_meta_data_type_consistency() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN

            IF EXISTS (SELECT 1 FROM meta_keys 
              JOIN meta_data ON meta_data.meta_key_id = meta_keys.id
              WHERE meta_keys.id = NEW.id
              AND meta_keys.meta_datum_object_type <> meta_data.type) THEN
                RAISE EXCEPTION 'The types of related meta_data and meta_keys must be identical';
            END IF;

            RETURN NEW;
          END;
          $$;


--
-- Name: check_no_drafts_in_collections(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_no_drafts_in_collections() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF
              (SELECT is_published FROM media_entries WHERE id = NEW.media_entry_id) = false
              THEN RAISE EXCEPTION 'Incomplete MediaEntries can not be put into Collections!';
            END IF;
            RETURN NEW;
          END;
          $$;


--
-- Name: check_users_apiclients_login_uniqueness(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.check_users_apiclients_login_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
      BEGIN
        IF (EXISTS (SELECT 1 FROM users, api_clients
              WHERE api_clients.login = users.login
              AND api_clients.login = NEW.login)) THEN
          RAISE EXCEPTION 'The login % over users and api_clients must be unique.', NEW.login;
        END IF;
        RETURN NEW;
      END;
      $$;


--
-- Name: collection_may_not_be_its_own_parent(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.collection_may_not_be_its_own_parent() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF
              (SELECT
                (SELECT COUNT(1)
                 FROM collection_collection_arcs
                 WHERE NEW.parent_id = NEW.child_id
                )
              > 0)
              THEN RAISE EXCEPTION 'Collection may not be its own parent %.', NEW.collection_id;
            END IF;
            RETURN NEW;
          END;
          $$;


--
-- Name: delete_empty_group_after_delete_join(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_empty_group_after_delete_join() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF (EXISTS (SELECT 1 FROM groups WHERE groups.id = OLD.group_id)
                AND NOT EXISTS ( SELECT 1
                                 FROM groups_users
                                 JOIN groups ON groups.id = groups_users.group_id
                                 WHERE groups.id = OLD.group_id))
            THEN
              DELETE FROM groups WHERE groups.id = OLD.group_id;
            END IF;
            RETURN NEW;
          END;
          $$;


--
-- Name: delete_empty_meta_data_groups_after_delete_join(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_empty_meta_data_groups_after_delete_join() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF (EXISTS (SELECT 1 FROM meta_data WHERE meta_data.id = OLD.meta_datum_id)
                          AND NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN  meta_data_groups ON meta_data.id = meta_data_groups.meta_datum_id
                                            WHERE meta_data.id = OLD.meta_datum_id)
                            ) THEN
                        DELETE FROM meta_data WHERE meta_data.id = OLD.meta_datum_id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_groups_after_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_empty_meta_data_groups_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF ( NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN meta_data_groups ON meta_data.id = meta_data_groups.meta_datum_id
                                            WHERE meta_data.id = NEW.id)) THEN
                        DELETE FROM meta_data WHERE meta_data.id = NEW.id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_keywords_after_delete_join(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_empty_meta_data_keywords_after_delete_join() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF (EXISTS (SELECT 1 FROM meta_data WHERE meta_data.id = OLD.meta_datum_id)
                          AND NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN  meta_data_keywords ON meta_data.id = meta_data_keywords.meta_datum_id
                                            WHERE meta_data.id = OLD.meta_datum_id)
                            ) THEN
                        DELETE FROM meta_data WHERE meta_data.id = OLD.meta_datum_id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_keywords_after_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_empty_meta_data_keywords_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF ( NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN meta_data_keywords ON meta_data.id = meta_data_keywords.meta_datum_id
                                            WHERE meta_data.id = NEW.id)) THEN
                        DELETE FROM meta_data WHERE meta_data.id = NEW.id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_licenses_after_delete_join(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_empty_meta_data_licenses_after_delete_join() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF (EXISTS (SELECT 1 FROM meta_data WHERE meta_data.id = OLD.meta_datum_id)
                          AND NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN  meta_data_licenses ON meta_data.id = meta_data_licenses.meta_datum_id
                                            WHERE meta_data.id = OLD.meta_datum_id)
                            ) THEN
                        DELETE FROM meta_data WHERE meta_data.id = OLD.meta_datum_id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_licenses_after_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_empty_meta_data_licenses_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF ( NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN meta_data_licenses ON meta_data.id = meta_data_licenses.meta_datum_id
                                            WHERE meta_data.id = NEW.id)) THEN
                        DELETE FROM meta_data WHERE meta_data.id = NEW.id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_people_after_delete_join(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_empty_meta_data_people_after_delete_join() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF (EXISTS (SELECT 1 FROM meta_data WHERE meta_data.id = OLD.meta_datum_id)
                          AND NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN  meta_data_people ON meta_data.id = meta_data_people.meta_datum_id
                                            WHERE meta_data.id = OLD.meta_datum_id)
                            ) THEN
                        DELETE FROM meta_data WHERE meta_data.id = OLD.meta_datum_id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_empty_meta_data_people_after_insert(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_empty_meta_data_people_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
                    BEGIN
                      IF ( NOT EXISTS ( SELECT 1 FROM meta_data
                                            JOIN meta_data_people ON meta_data.id = meta_data_people.meta_datum_id
                                            WHERE meta_data.id = NEW.id)) THEN
                        DELETE FROM meta_data WHERE meta_data.id = NEW.id;
                      END IF;
                      RETURN NEW;
                    END;
                    $$;


--
-- Name: delete_meta_datum_text_string_null(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_meta_datum_text_string_null() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
          BEGIN
            IF ((NEW.type = 'MetaDatum::Text' OR NEW.type = 'MetaDatum::TextDate')
                AND NEW.string IS NULL) THEN
              DELETE FROM meta_data WHERE meta_data.id = NEW.id;
            END IF;
            RETURN NEW;
          END;
          $$;


--
-- Name: groups_update_searchable_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.groups_update_searchable_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.searchable = COALESCE(NEW.name::text, '') || ' ' || COALESCE(NEW.institutional_name::text, '') ;
   RETURN NEW;
END;
$$;


--
-- Name: licenses_update_searchable_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.licenses_update_searchable_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.searchable = COALESCE(NEW.label::text, '') || ' ' || COALESCE(NEW.usage::text, '') || ' ' || COALESCE(NEW.url::text, '') ;
   RETURN NEW;
END;
$$;


--
-- Name: people_update_searchable_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.people_update_searchable_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.searchable = COALESCE(NEW.first_name::text, '') || ' ' || COALESCE(NEW.last_name::text, '') || ' ' || COALESCE(NEW.pseudonym::text, '') ;
   RETURN NEW;
END;
$$;


--
-- Name: person_display_name(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.person_display_name(first_name character varying, last_name character varying, pseudonym character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
        BEGIN RETURN (CASE
                          WHEN ((first_name <> ''
                                 OR last_name <> '')
                                AND pseudonym <> '') THEN btrim(first_name || ' ' || last_name || ' ' || '(' || pseudonym || ')')
                          WHEN (first_name <> ''
                                OR last_name <> '') THEN btrim(first_name || ' ' || last_name)
                          ELSE btrim(pseudonym)
                      END);
        END;
      $$;


--
-- Name: propagate_edit_session_insert_to_collections(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.propagate_edit_session_insert_to_collections() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE collections SET edit_session_updated_at = now()
    FROM edit_sessions
    WHERE edit_sessions.id = NEW.id
    AND collections.id = edit_sessions.collection_id;
  RETURN NULL;
END;
$$;


--
-- Name: propagate_edit_session_insert_to_filter_sets(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.propagate_edit_session_insert_to_filter_sets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE filter_sets SET edit_session_updated_at = now()
    FROM edit_sessions
    WHERE edit_sessions.id = NEW.id
    AND filter_sets.id = edit_sessions.filter_set_id;
  RETURN NULL;
END;
$$;


--
-- Name: propagate_edit_session_insert_to_media_entries(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.propagate_edit_session_insert_to_media_entries() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE media_entries SET edit_session_updated_at = now()
    FROM edit_sessions
    WHERE edit_sessions.id = NEW.id
    AND media_entries.id = edit_sessions.media_entry_id;
  RETURN NULL;
END;
$$;


--
-- Name: propagate_keyword_updates_to_meta_data_keywords(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.propagate_keyword_updates_to_meta_data_keywords() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE meta_data_keywords
    SET meta_data_updated_at = now()
    WHERE keyword_id = NEW.id;
  RETURN NULL;
END;
$$;


--
-- Name: propagate_license_updates_to_meta_data_licenses(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.propagate_license_updates_to_meta_data_licenses() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE meta_data_licenses
    SET meta_data_updated_at = now()
    WHERE license_id = NEW.id;
  RETURN NULL;
END;
$$;


--
-- Name: propagate_meta_data_keyword_updates_to_meta_data(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.propagate_meta_data_keyword_updates_to_meta_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  md_id UUID;
BEGIN
  CASE
    WHEN TG_OP = 'DELETE' THEN
      md_id = OLD.meta_datum_id;
    ELSE
      md_id = NEW.meta_datum_id;
  END CASE;

  UPDATE meta_data
    SET meta_data_updated_at = now()
    WHERE meta_data.id = md_id;
  RETURN NULL;
END;
$$;


--
-- Name: propagate_meta_data_license_updates_to_meta_data(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.propagate_meta_data_license_updates_to_meta_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  md_id UUID;
BEGIN
  CASE
    WHEN TG_OP = 'DELETE' THEN
      md_id = OLD.meta_datum_id;
    ELSE
      md_id = NEW.meta_datum_id;
  END CASE;

  UPDATE meta_data
    SET meta_data_updated_at = now()
    WHERE meta_data.id = md_id;
  RETURN NULL;
END;
$$;


--
-- Name: propagate_meta_data_people_updates_to_meta_data(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.propagate_meta_data_people_updates_to_meta_data() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  md_id UUID;
BEGIN
  CASE
    WHEN TG_OP = 'DELETE' THEN
      md_id = OLD.meta_datum_id;
    ELSE
      md_id = NEW.meta_datum_id;
  END CASE;

  UPDATE meta_data
    SET meta_data_updated_at = now()
    WHERE meta_data.id = md_id;
  RETURN NULL;
END;
$$;


--
-- Name: propagate_meta_data_updates_to_media_resource(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.propagate_meta_data_updates_to_media_resource() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  md_id UUID;
BEGIN
  CASE
    WHEN TG_OP = 'DELETE' THEN
      md_id = OLD.id;
    ELSE
      md_id = NEW.id;
  END CASE;


  UPDATE media_entries SET meta_data_updated_at = now()
    FROM meta_data
    WHERE meta_data.media_entry_id = media_entries.id
    AND meta_data.id = md_id;

  UPDATE collections SET meta_data_updated_at = now()
    FROM meta_data
    WHERE meta_data.collection_id = collections.id
    AND meta_data.id = md_id;

  UPDATE filter_sets SET meta_data_updated_at = now()
    FROM meta_data
    WHERE meta_data.media_entry_id = filter_sets.id
    AND meta_data.id = md_id;


  RETURN NULL;
END;
$$;


--
-- Name: propagate_people_updates_to_meta_data_people(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.propagate_people_updates_to_meta_data_people() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE meta_data_people
    SET meta_data_updated_at = now()
    WHERE person_id = NEW.id;
  RETURN NULL;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.updated_at = now();
   RETURN NEW;
END;
$$;


--
-- Name: users_update_searchable_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.users_update_searchable_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   NEW.searchable = COALESCE(NEW.login::text, '') || ' ' || COALESCE(NEW.email::text, '') ;
   RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admins (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: api_clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_clients (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    login character varying NOT NULL,
    description text,
    password_digest character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT name_format CHECK (((login)::text ~ '^[a-z][a-z0-9\-\_]+$'::text))
);


--
-- Name: api_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(45) NOT NULL,
    token_part character varying(5) NOT NULL,
    revoked boolean DEFAULT false NOT NULL,
    scope_read boolean DEFAULT true NOT NULL,
    scope_write boolean DEFAULT false NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone DEFAULT (now() + '1 year'::interval) NOT NULL
);


--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_settings (
    id integer DEFAULT 0 NOT NULL,
    featured_set_id uuid,
    splashscreen_slideshow_set_id uuid,
    site_title character varying DEFAULT 'Media Archive'::character varying NOT NULL,
    support_url character varying,
    welcome_title character varying DEFAULT 'Powerful Global Information System'::character varying NOT NULL,
    welcome_text character varying DEFAULT '**“Academic information should be freely available to anyone”** — Tim Berners-Lee'::character varying NOT NULL,
    teaser_set_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    brand_logo_url character varying,
    brand_text character varying DEFAULT 'ACME, Inc.'::character varying NOT NULL,
    sitemap jsonb DEFAULT '[{"Medienarchiv ZHdK": "http://medienarchiv.zhdk.ch"}, {"Madek Project on Github": "https://github.com/Madek"}]'::jsonb NOT NULL,
    contexts_for_entry_extra text[] DEFAULT '{}'::text[] NOT NULL,
    contexts_for_list_details text[] DEFAULT '{}'::text[] NOT NULL,
    contexts_for_entry_validation text[] DEFAULT '{}'::text[] NOT NULL,
    contexts_for_dynamic_filters text[] DEFAULT '{}'::text[] NOT NULL,
    context_for_entry_summary text,
    context_for_collection_summary text,
    catalog_title character varying DEFAULT 'Catalog'::character varying NOT NULL,
    catalog_subtitle character varying DEFAULT 'Browse the catalog'::character varying NOT NULL,
    catalog_context_keys text[] DEFAULT '{}'::text[] NOT NULL,
    featured_set_title character varying DEFAULT 'Featured Content'::character varying,
    featured_set_subtitle character varying DEFAULT 'Highlights from this Archive'::character varying,
    contexts_for_entry_edit text[] DEFAULT '{}'::text[] NOT NULL,
    contexts_for_collection_edit text[] DEFAULT '{}'::text[] NOT NULL,
    contexts_for_collection_extra text[] DEFAULT '{}'::text[] NOT NULL,
    media_entry_default_license_id uuid,
    media_entry_default_license_meta_key text,
    media_entry_default_license_usage_text text,
    media_entry_default_license_usage_meta_key text,
    ignored_keyword_keys_for_browsing text,
    default_locale character varying DEFAULT 'de'::character varying,
    available_locales character varying[] DEFAULT '{}'::character varying[],
    about_page character varying DEFAULT ''::character varying,
    CONSTRAINT oneandonly CHECK ((id = 0))
);


--
-- Name: collection_api_client_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_api_client_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    edit_metadata_and_relations boolean DEFAULT false NOT NULL,
    collection_id uuid NOT NULL,
    api_client_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: collection_collection_arcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_collection_arcs (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    child_id uuid NOT NULL,
    parent_id uuid NOT NULL,
    highlight boolean DEFAULT false
);


--
-- Name: collection_filter_set_arcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_filter_set_arcs (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    filter_set_id uuid NOT NULL,
    collection_id uuid NOT NULL,
    highlight boolean DEFAULT false
);


--
-- Name: collection_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_group_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    edit_metadata_and_relations boolean DEFAULT false NOT NULL,
    collection_id uuid NOT NULL,
    group_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: collection_media_entry_arcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_media_entry_arcs (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    media_entry_id uuid NOT NULL,
    collection_id uuid NOT NULL,
    highlight boolean DEFAULT false,
    cover boolean
);


--
-- Name: collection_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collection_user_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    edit_metadata_and_relations boolean DEFAULT false NOT NULL,
    edit_permissions boolean DEFAULT false NOT NULL,
    collection_id uuid NOT NULL,
    user_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.collections (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    layout public.collection_layout DEFAULT 'grid'::public.collection_layout NOT NULL,
    responsible_user_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    sorting public.collection_sorting DEFAULT 'created_at DESC'::public.collection_sorting NOT NULL,
    edit_session_updated_at timestamp with time zone DEFAULT now() NOT NULL,
    meta_data_updated_at timestamp with time zone DEFAULT now() NOT NULL,
    clipboard_user_id character varying
);


--
-- Name: confidential_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.confidential_links (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    resource_id uuid,
    resource_type character varying,
    token character varying(45) NOT NULL,
    revoked boolean DEFAULT false NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone
);


--
-- Name: context_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.context_keys (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    description text,
    hint text,
    label text,
    context_id character varying NOT NULL,
    meta_key_id character varying NOT NULL,
    is_required boolean DEFAULT false NOT NULL,
    length_max integer,
    length_min integer,
    "position" integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    admin_comment text,
    labels public.hstore DEFAULT ''::public.hstore NOT NULL,
    descriptions public.hstore DEFAULT ''::public.hstore NOT NULL,
    hints public.hstore DEFAULT ''::public.hstore NOT NULL,
    CONSTRAINT check_description_not_blank CHECK ((description !~ '^\s*$'::text)),
    CONSTRAINT check_hint_not_blank CHECK ((hint !~ '^\s*$'::text)),
    CONSTRAINT check_label_not_blank CHECK ((label !~ '^\s*$'::text))
);


--
-- Name: contexts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contexts (
    id character varying NOT NULL,
    label character varying DEFAULT ''::character varying NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    admin_comment text,
    labels public.hstore DEFAULT ''::public.hstore NOT NULL,
    descriptions public.hstore DEFAULT ''::public.hstore NOT NULL,
    CONSTRAINT context_id_chars CHECK (((id)::text ~* '^[a-z0-9\-\_]+$'::text))
);


--
-- Name: custom_urls; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_urls (
    id character varying NOT NULL,
    is_primary boolean DEFAULT false NOT NULL,
    creator_id uuid NOT NULL,
    updator_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    media_entry_id uuid,
    collection_id uuid,
    filter_set_id uuid,
    CONSTRAINT custom_url_is_related CHECK ((((media_entry_id IS NULL) AND (collection_id IS NULL) AND (filter_set_id IS NOT NULL)) OR ((media_entry_id IS NULL) AND (collection_id IS NOT NULL) AND (filter_set_id IS NULL)) OR ((media_entry_id IS NOT NULL) AND (collection_id IS NULL) AND (filter_set_id IS NULL)))),
    CONSTRAINT custom_urls_id_format CHECK (((id)::text ~ '^[a-z][a-z0-9\-\_]+$'::text)),
    CONSTRAINT custom_urls_id_is_not_uuid CHECK ((NOT ((id)::text ~* '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'::text)))
);


--
-- Name: edit_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.edit_sessions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    media_entry_id uuid,
    collection_id uuid,
    filter_set_id uuid,
    CONSTRAINT edit_sessions_is_related CHECK ((((media_entry_id IS NULL) AND (collection_id IS NULL) AND (filter_set_id IS NOT NULL)) OR ((media_entry_id IS NULL) AND (collection_id IS NOT NULL) AND (filter_set_id IS NULL)) OR ((media_entry_id IS NOT NULL) AND (collection_id IS NULL) AND (filter_set_id IS NULL))))
);


--
-- Name: favorite_collections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorite_collections (
    user_id uuid NOT NULL,
    collection_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: favorite_filter_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorite_filter_sets (
    user_id uuid NOT NULL,
    filter_set_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: favorite_media_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorite_media_entries (
    user_id uuid NOT NULL,
    media_entry_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: filter_set_api_client_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.filter_set_api_client_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    edit_metadata_and_filter boolean DEFAULT false NOT NULL,
    filter_set_id uuid NOT NULL,
    api_client_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: filter_set_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.filter_set_group_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    filter_set_id uuid NOT NULL,
    group_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: filter_set_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.filter_set_user_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    edit_metadata_and_filter boolean DEFAULT false NOT NULL,
    edit_permissions boolean DEFAULT false NOT NULL,
    filter_set_id uuid NOT NULL,
    user_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: filter_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.filter_sets (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    definition jsonb DEFAULT '{}'::jsonb NOT NULL,
    responsible_user_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    edit_session_updated_at timestamp with time zone DEFAULT now() NOT NULL,
    meta_data_updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: full_texts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.full_texts (
    media_resource_id uuid NOT NULL,
    text text
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    name text NOT NULL,
    institutional_id character varying,
    institutional_name character varying,
    type character varying DEFAULT 'Group'::character varying NOT NULL,
    person_id uuid,
    searchable text DEFAULT ''::text NOT NULL,
    CONSTRAINT check_valid_type CHECK (((type)::text = ANY (ARRAY[('AuthenticationGroup'::character varying)::text, ('InstitutionalGroup'::character varying)::text, ('Group'::character varying)::text])))
);


--
-- Name: groups_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups_users (
    group_id uuid NOT NULL,
    user_id uuid NOT NULL
);


--
-- Name: io_interfaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.io_interfaces (
    id character varying NOT NULL,
    description character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: io_mappings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.io_mappings (
    io_interface_id character varying NOT NULL,
    meta_key_id character varying NOT NULL,
    key_map character varying,
    key_map_type character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    id uuid DEFAULT public.gen_random_uuid() NOT NULL
);


--
-- Name: keywords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.keywords (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    term character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    creator_id uuid,
    meta_key_id character varying NOT NULL,
    "position" integer,
    rdf_class character varying DEFAULT 'Keyword'::character varying NOT NULL,
    description text,
    external_uris character varying[] DEFAULT '{}'::character varying[]
);


--
-- Name: media_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_entries (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    get_full_size boolean DEFAULT false NOT NULL,
    responsible_user_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    is_published boolean DEFAULT false,
    edit_session_updated_at timestamp with time zone DEFAULT now() NOT NULL,
    meta_data_updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: media_entry_api_client_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_entry_api_client_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    get_full_size boolean DEFAULT false NOT NULL,
    media_entry_id uuid NOT NULL,
    api_client_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: media_entry_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_entry_group_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    get_full_size boolean DEFAULT false NOT NULL,
    edit_metadata boolean DEFAULT false NOT NULL,
    media_entry_id uuid NOT NULL,
    group_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: media_entry_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_entry_user_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    get_metadata_and_previews boolean DEFAULT false NOT NULL,
    get_full_size boolean DEFAULT false NOT NULL,
    edit_metadata boolean DEFAULT false NOT NULL,
    edit_permissions boolean DEFAULT false NOT NULL,
    media_entry_id uuid NOT NULL,
    user_id uuid NOT NULL,
    updator_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: media_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_files (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    height integer,
    size bigint,
    width integer,
    access_hash text,
    meta_data text,
    content_type character varying NOT NULL,
    filename character varying,
    guid character varying,
    extension character varying,
    media_type character varying,
    media_entry_id uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    uploader_id uuid NOT NULL,
    conversion_profiles character varying[] DEFAULT '{}'::character varying[]
);


--
-- Name: meta_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meta_data (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    meta_key_id character varying NOT NULL,
    type character varying,
    string text,
    media_entry_id uuid,
    collection_id uuid,
    filter_set_id uuid,
    created_by_id uuid,
    meta_data_updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT check_valid_type CHECK (((type)::text = ANY (ARRAY[('MetaDatum::Licenses'::character varying)::text, ('MetaDatum::Text'::character varying)::text, ('MetaDatum::TextDate'::character varying)::text, ('MetaDatum::Groups'::character varying)::text, ('MetaDatum::Keywords'::character varying)::text, ('MetaDatum::Vocables'::character varying)::text, ('MetaDatum::People'::character varying)::text, ('MetaDatum::Users'::character varying)::text, ('MetaDatum::Roles'::character varying)::text]))),
    CONSTRAINT meta_data_is_related CHECK ((((media_entry_id IS NULL) AND (collection_id IS NULL) AND (filter_set_id IS NOT NULL)) OR ((media_entry_id IS NULL) AND (collection_id IS NOT NULL) AND (filter_set_id IS NULL)) OR ((media_entry_id IS NOT NULL) AND (collection_id IS NULL) AND (filter_set_id IS NULL))))
);


--
-- Name: meta_data_keywords; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meta_data_keywords (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    created_by_id uuid,
    meta_datum_id uuid NOT NULL,
    keyword_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    meta_data_updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: meta_data_meta_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meta_data_meta_terms (
    meta_datum_id uuid NOT NULL,
    meta_term_id uuid NOT NULL
);


--
-- Name: meta_data_people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meta_data_people (
    meta_datum_id uuid NOT NULL,
    person_id uuid NOT NULL,
    created_by_id uuid,
    meta_data_updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT public.gen_random_uuid() NOT NULL
);


--
-- Name: meta_data_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meta_data_roles (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    meta_datum_id uuid,
    person_id uuid NOT NULL,
    role_id uuid,
    created_by_id uuid,
    "position" integer DEFAULT 0 NOT NULL
);


--
-- Name: meta_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.meta_keys (
    id character varying NOT NULL,
    is_extensible_list boolean DEFAULT false NOT NULL,
    meta_datum_object_type text DEFAULT 'MetaDatum::Text'::text NOT NULL,
    keywords_alphabetical_order boolean DEFAULT true NOT NULL,
    label text,
    description text,
    hint text,
    "position" integer DEFAULT 0 NOT NULL,
    is_enabled_for_media_entries boolean DEFAULT false NOT NULL,
    is_enabled_for_collections boolean DEFAULT false NOT NULL,
    is_enabled_for_filter_sets boolean DEFAULT false NOT NULL,
    vocabulary_id character varying NOT NULL,
    admin_comment text,
    allowed_people_subtypes text[],
    text_type text DEFAULT 'line'::text NOT NULL,
    allowed_rdf_class character varying,
    labels public.hstore DEFAULT ''::public.hstore NOT NULL,
    descriptions public.hstore DEFAULT ''::public.hstore NOT NULL,
    hints public.hstore DEFAULT ''::public.hstore NOT NULL,
    CONSTRAINT check_allowed_people_subtypes_not_empty_for_meta_datum_people CHECK ((((allowed_people_subtypes IS NOT NULL) AND (COALESCE(array_length(allowed_people_subtypes, 1), 0) > 0)) OR (meta_datum_object_type <> 'MetaDatum::People'::text))),
    CONSTRAINT check_description_not_blank CHECK ((description !~ '^\s*$'::text)),
    CONSTRAINT check_hint_not_blank CHECK ((hint !~ '^\s*$'::text)),
    CONSTRAINT check_is_extensible_list_is_boolean_for_meta_datum_keywords CHECK (((((is_extensible_list = true) OR (is_extensible_list = false)) AND (meta_datum_object_type = 'MetaDatum::Keywords'::text)) OR (meta_datum_object_type <> 'MetaDatum::Keywords'::text))),
    CONSTRAINT check_keywords_alphabetical_order_is_boolean_for_meta_datum_key CHECK (((((keywords_alphabetical_order = true) OR (keywords_alphabetical_order = false)) AND (meta_datum_object_type = 'MetaDatum::Keywords'::text)) OR (meta_datum_object_type <> 'MetaDatum::Keywords'::text))),
    CONSTRAINT check_label_not_blank CHECK ((label !~ '^\s*$'::text)),
    CONSTRAINT check_valid_meta_datum_object_type CHECK ((meta_datum_object_type = ANY (ARRAY['MetaDatum::Licenses'::text, 'MetaDatum::Text'::text, 'MetaDatum::TextDate'::text, 'MetaDatum::Groups'::text, 'MetaDatum::Keywords'::text, 'MetaDatum::Vocables'::text, 'MetaDatum::People'::text, 'MetaDatum::Users'::text, 'MetaDatum::Roles'::text]))),
    CONSTRAINT check_valid_text_type CHECK ((text_type = ANY (ARRAY['line'::text, 'block'::text]))),
    CONSTRAINT meta_key_id_chars CHECK (((id)::text ~* '^[a-z0-9\-\_\:]+$'::text)),
    CONSTRAINT start_id_like_vocabulary_id CHECK (((id)::text ~~ ((vocabulary_id)::text || ':%'::text)))
);


--
-- Name: people; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.people (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    first_name character varying,
    last_name character varying,
    pseudonym character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    searchable text DEFAULT ''::text NOT NULL,
    institutional_id text,
    subtype text NOT NULL,
    description text,
    external_uris character varying[] DEFAULT '{}'::character varying[],
    CONSTRAINT check_presence_of_first_name_or_last_name_or_pseudonym CHECK (((first_name IS NOT NULL) OR (last_name IS NOT NULL) OR (pseudonym IS NOT NULL))),
    CONSTRAINT check_valid_people_subtype CHECK ((subtype = ANY (ARRAY['Person'::text, 'PeopleGroup'::text, 'PeopleInstitutionalGroup'::text]))),
    CONSTRAINT first_name_is_not_blank CHECK (((first_name)::text !~ '^\s*$'::text)),
    CONSTRAINT institutional_id_is_not_blank CHECK ((institutional_id !~ '^\s*$'::text)),
    CONSTRAINT last_name_is_not_blank CHECK (((last_name)::text !~ '^\s*$'::text)),
    CONSTRAINT pseudonym_is_not_blank CHECK (((pseudonym)::text !~ '^\s*$'::text))
);


--
-- Name: previews; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.previews (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    media_file_id uuid NOT NULL,
    height integer,
    width integer,
    content_type character varying,
    filename character varying,
    thumbnail character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    media_type character varying NOT NULL,
    conversion_profile character varying
);


--
-- Name: rdf_classes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rdf_classes (
    id character varying NOT NULL,
    description text,
    admin_comment text,
    "position" integer DEFAULT 0 NOT NULL,
    CONSTRAINT rdf_class_id_chars CHECK (((id)::text ~* '^[A-Za-z0-9]+$'::text)),
    CONSTRAINT rdf_class_id_start_uppercase CHECK (((id)::text ~ '^[A-Z]'::text))
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    labels public.hstore DEFAULT ''::public.hstore NOT NULL,
    meta_key_id character varying NOT NULL,
    creator_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT labels_non_blank CHECK ((array_to_string(public.avals(labels), ''::text) !~ '^ *$'::text))
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: usage_terms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usage_terms (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    title character varying,
    version character varying,
    intro text,
    body text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    email character varying,
    login text,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    password_digest character varying,
    person_id uuid NOT NULL,
    institutional_id text,
    autocomplete text DEFAULT ''::text NOT NULL,
    searchable text DEFAULT ''::text NOT NULL,
    accepted_usage_terms_id uuid,
    last_signed_in_at timestamp with time zone,
    settings jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_deactivated boolean DEFAULT false,
    CONSTRAINT email_format CHECK ((((email)::text ~ '\S+@\S+'::text) OR (email IS NULL))),
    CONSTRAINT users_login_simple CHECK ((login ~* '^[a-z0-9\.\-\_]+$'::text))
);


--
-- Name: visualizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.visualizations (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    resource_identifier character varying NOT NULL,
    control_settings text,
    layout text
);


--
-- Name: vocabularies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vocabularies (
    id character varying NOT NULL,
    label text,
    description text,
    enabled_for_public_view boolean DEFAULT true NOT NULL,
    enabled_for_public_use boolean DEFAULT true NOT NULL,
    admin_comment text,
    "position" integer NOT NULL,
    labels public.hstore DEFAULT ''::public.hstore NOT NULL,
    descriptions public.hstore DEFAULT ''::public.hstore NOT NULL,
    CONSTRAINT positive_position CHECK (("position" >= 0)),
    CONSTRAINT vocabulary_id_chars CHECK (((id)::text ~* '^[a-z0-9\-\_]+$'::text))
);


--
-- Name: vocabulary_api_client_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vocabulary_api_client_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    api_client_id uuid NOT NULL,
    vocabulary_id character varying NOT NULL,
    use boolean DEFAULT false NOT NULL,
    view boolean DEFAULT true NOT NULL
);


--
-- Name: vocabulary_group_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vocabulary_group_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    group_id uuid NOT NULL,
    vocabulary_id character varying NOT NULL,
    use boolean DEFAULT false NOT NULL,
    view boolean DEFAULT true NOT NULL
);


--
-- Name: vocabulary_user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vocabulary_user_permissions (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    vocabulary_id character varying NOT NULL,
    use boolean DEFAULT false NOT NULL,
    view boolean DEFAULT true NOT NULL
);


--
-- Name: vw_media_resources; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_media_resources AS
 SELECT media_entries.id,
    media_entries.get_metadata_and_previews,
    media_entries.responsible_user_id,
    media_entries.creator_id,
    media_entries.created_at,
    media_entries.updated_at,
    'MediaEntry'::text AS type
   FROM public.media_entries
UNION
 SELECT collections.id,
    collections.get_metadata_and_previews,
    collections.responsible_user_id,
    collections.creator_id,
    collections.created_at,
    collections.updated_at,
    'Collection'::text AS type
   FROM public.collections
UNION
 SELECT filter_sets.id,
    filter_sets.get_metadata_and_previews,
    filter_sets.responsible_user_id,
    filter_sets.creator_id,
    filter_sets.created_at,
    filter_sets.updated_at,
    'FilterSet'::text AS type
   FROM public.filter_sets;


--
-- Name: zencoder_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zencoder_jobs (
    id uuid DEFAULT public.gen_random_uuid() NOT NULL,
    media_file_id uuid NOT NULL,
    zencoder_id integer,
    comment text,
    state character varying DEFAULT 'initialized'::character varying NOT NULL,
    error text,
    notification text,
    request text,
    response text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    progress double precision DEFAULT 0.0,
    conversion_profiles character varying[] DEFAULT '{}'::character varying[]
);


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.admins VALUES ('fb38ee5b-3f7f-4184-9218-11ae7fe71ef0', '299d734b-3c3d-403c-a2d7-85df91dba1d9', '2017-03-16 17:16:35.817124+01', '2017-03-16 17:16:35.817124+01');
INSERT INTO public.admins VALUES ('acf493e3-7e45-44f0-acbc-2d2a01ec51cf', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-16 17:33:27.797992+01', '2017-03-16 17:33:27.797992+01');


--
-- Data for Name: api_clients; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: api_tokens; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: app_settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.app_settings VALUES (0, NULL, NULL, '** Name des Systems **', NULL, '** Wilkommen zum System **', '** Informationen zum System **', NULL, '2017-03-16 17:14:52.463276+01', '2019-04-12 16:56:45.040103+02', NULL, '** Name des Anbieters **', '[{"Software Madek": "https://zhdk.ch/madek"}, {"Madek Project on Github": "https://github.com/Madek"}]', '{}', '{metadata}', '{mandatory}', '{metadata}', 'media_entry_summary', 'set_summary', '** Katalog **', '** Erkunden Sie den Katalog. **', '{73a90d45-63af-4e1a-bb1b-d4284147c710}', '** Sehenswerte Inhalte **', '** Höhepunkte aus diesem Archiv. **', '{mandatory,media_entry_summary}', '{set_summary}', '{}', NULL, NULL, NULL, 'madek_core:copyright_notice', NULL, 'de', '{de,en}', '');


--
-- Data for Name: collection_api_client_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: collection_collection_arcs; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: collection_filter_set_arcs; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: collection_group_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: collection_media_entry_arcs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.collection_media_entry_arcs VALUES ('7f551f19-b184-400f-ac9c-66c5e2cbe2e7', '29b7522c-84eb-4abd-89e0-9285075813ac', 'dce2c8f5-2456-4e7d-8b33-2d694c539f49', false, NULL);
INSERT INTO public.collection_media_entry_arcs VALUES ('ec6e3a0a-b2ed-4def-8905-e2fb3cffffb3', '5798661c-7423-43e4-bb98-3c2b6dfd6d92', 'dce2c8f5-2456-4e7d-8b33-2d694c539f49', false, NULL);
INSERT INTO public.collection_media_entry_arcs VALUES ('93b8f731-13a3-4b01-85c5-f8199f13323e', '865e9a13-7190-4221-ac8a-f9a681063745', 'dce2c8f5-2456-4e7d-8b33-2d694c539f49', false, NULL);
INSERT INTO public.collection_media_entry_arcs VALUES ('bbf6b2ae-ec6c-4f39-aa41-949fc18a9734', '103034cd-badd-4299-aef0-d414a606d4e5', 'dce2c8f5-2456-4e7d-8b33-2d694c539f49', false, NULL);


--
-- Data for Name: collection_user_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: collections; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.collections VALUES ('dce2c8f5-2456-4e7d-8b33-2d694c539f49', false, '2017-03-22 13:36:50.677551+01', '2017-03-22 13:36:50.677551+01', 'grid', 'd68ab096-158b-4632-b7f0-672c08f425cc', 'd68ab096-158b-4632-b7f0-672c08f425cc', 'created_at DESC', '2017-03-22 13:36:50.677551+01', '2017-03-22 13:36:50.677551+01', 'd68ab096-158b-4632-b7f0-672c08f425cc');


--
-- Data for Name: confidential_links; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: context_keys; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.context_keys VALUES ('0054feb3-f383-4582-a419-c7a0ac21aed7', NULL, NULL, NULL, 'metadata', 'madek_core:portrayed_object_date', false, NULL, NULL, 3, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('10f8c4f0-b707-4f29-a43e-39c9409a2916', NULL, NULL, NULL, 'metadata', 'madek_core:description', false, NULL, NULL, 5, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('13ccb885-33d4-48c6-bcae-33adaf340292', NULL, NULL, NULL, 'metadata', 'madek_core:copyright_notice', false, NULL, NULL, 6, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('1ca3c950-48d8-49af-9508-1a176211946a', NULL, NULL, NULL, 'mandatory', 'madek_core:copyright_notice', true, NULL, NULL, 1, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('32338a46-9071-4172-80a3-91b9f2549f48', NULL, NULL, NULL, 'set_summary', 'madek_core:title', false, NULL, NULL, 0, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('3739b2e1-1460-4660-8e15-3bc78e70c116', NULL, NULL, NULL, 'set_summary', 'madek_core:copyright_notice', false, NULL, NULL, 6, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('6566e867-02c6-4761-a903-c671a03822d4', NULL, NULL, NULL, 'metadata', 'madek_core:subtitle', false, NULL, NULL, 1, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('6a2076f9-123c-4335-b24e-4b97ab74925e', NULL, NULL, NULL, 'set_summary', 'madek_core:authors', false, NULL, NULL, 2, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('73a90d45-63af-4e1a-bb1b-d4284147c710', NULL, NULL, NULL, 'metadata', 'madek_core:keywords', false, NULL, NULL, 4, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('7aaa149e-2b1a-4aaa-87df-22913c2c7ab1', NULL, NULL, NULL, 'media_entry_summary', 'madek_core:description', false, NULL, NULL, 5, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('7f62b958-fee8-49c4-a365-a154195ade10', NULL, NULL, NULL, 'media_entry_summary', 'madek_core:portrayed_object_date', false, NULL, NULL, 3, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('8e6f84e1-7b04-4859-baf3-cc48895abebb', NULL, NULL, NULL, 'media_entry_summary', 'madek_core:keywords', false, NULL, NULL, 4, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('93566ad1-41ae-4e79-add1-76851a5159d8', NULL, NULL, NULL, 'set_summary', 'madek_core:portrayed_object_date', false, NULL, NULL, 3, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('94f82b9d-5707-45df-b725-cd54165c00d8', NULL, NULL, NULL, 'metadata', 'madek_core:title', false, NULL, NULL, 0, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('9d984d4a-bbd5-4bfa-8985-0096f5374e62', NULL, NULL, NULL, 'set_summary', 'madek_core:subtitle', false, NULL, NULL, 1, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('bb198f60-f0ac-42ec-ad1b-1a89f969ea58', NULL, NULL, NULL, 'mandatory', 'madek_core:title', true, NULL, NULL, 0, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('c86ef1b5-065b-4059-b867-5e4583b993e5', NULL, NULL, NULL, 'media_entry_summary', 'madek_core:subtitle', false, NULL, NULL, 1, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('ca398dc5-d625-4619-90d3-76d74ecf46cf', NULL, NULL, NULL, 'media_entry_summary', 'madek_core:title', false, NULL, NULL, 0, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('cea74941-93b2-4982-b9cb-3de8c6d9f153', NULL, NULL, NULL, 'set_summary', 'madek_core:keywords', false, NULL, NULL, 4, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('d066c7dd-a0db-41fa-81b6-15a277a25115', NULL, NULL, NULL, 'set_summary', 'madek_core:description', false, NULL, NULL, 5, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('ebadc9ed-1a8f-4ad6-8af4-cbcad5a88911', NULL, NULL, NULL, 'media_entry_summary', 'madek_core:authors', false, NULL, NULL, 2, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('f397add4-3b2d-4899-95fc-7a6ec623a88a', NULL, NULL, NULL, 'media_entry_summary', 'madek_core:copyright_notice', false, NULL, NULL, 6, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');
INSERT INTO public.context_keys VALUES ('fa3bf8be-67ce-46f5-a77a-512e38ba0b4c', NULL, NULL, NULL, 'metadata', 'madek_core:authors', false, NULL, NULL, 2, '2017-03-16 17:16:56.19348+01', '2019-04-12 16:56:44.929382+02', NULL, '"de"=>NULL', '"de"=>NULL', '"de"=>NULL');


--
-- Data for Name: contexts; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.contexts VALUES ('mandatory', 'Pflichtfelder', '', 'Metakeys, die in diesem Kontext als required festgelegt sind, werden im System als Pflichtfelder für Medieneinträge behandelt. Sie dürfen keine leere Werte enthalten.', '"de"=>"Pflichtfelder"', '"de"=>""');
INSERT INTO public.contexts VALUES ('media_entry_summary', 'Medieneintrag', '', 'Dieser Kontext fasst die wichtigsten Metakeys für einen Medieneintrag zusammen. Er wird auf der Medieneintrag-Detailansicht links neben dem Thumbnail angezeigt. Die Metakeys dieses Kontext sollten Madek Core entsprechen.', '"de"=>"Medieneintrag"', '"de"=>""');
INSERT INTO public.contexts VALUES ('metadata', 'Metadaten', '', 'Dieser Kontext enthält initial alle MetaKeys aus dem Core-Vokabular.', '"de"=>"Metadaten"', '"de"=>""');
INSERT INTO public.contexts VALUES ('set_summary', 'Set', '', 'Dieser Kontext fasst die Metakeys für ein Set zusammen und wird als erstes Tab auf der Set-Detailseite angezeigt. Auch beim Editieren der Metadaten eines Sets wird dieser Kontext als erster Tab angezeigt.', '"de"=>"Set"', '"de"=>""');


--
-- Data for Name: custom_urls; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: edit_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.edit_sessions VALUES ('628b6d08-e704-41ed-8d24-6edbdcdb99ab', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-16 17:38:23.099748+01', '29b7522c-84eb-4abd-89e0-9285075813ac', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('9b64bf86-989c-409a-8573-a73fc2806729', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-16 17:39:05.731607+01', '29b7522c-84eb-4abd-89e0-9285075813ac', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('b71d5d64-fb98-4905-8a9f-6c1f4ff9a47b', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-16 18:05:09.331527+01', '29b7522c-84eb-4abd-89e0-9285075813ac', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('dd7bad49-48fb-4be0-b82c-090d68bf1966', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:08:47.280851+01', '103034cd-badd-4299-aef0-d414a606d4e5', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('4df3ed50-76b2-471b-9515-e876f60e8852', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:10:31.797314+01', '103034cd-badd-4299-aef0-d414a606d4e5', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('a0ecd3f4-b1eb-4c5a-88a7-f5afe32e0776', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:14:14.787488+01', '5798661c-7423-43e4-bb98-3c2b6dfd6d92', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('f079d5bc-f887-4c55-8e1c-9d82e99dbe3a', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:14:38.320359+01', '5798661c-7423-43e4-bb98-3c2b6dfd6d92', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('804653f4-b94d-41eb-9d28-1fd6fb103e88', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:15:11.377011+01', '5798661c-7423-43e4-bb98-3c2b6dfd6d92', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('62d30e28-a79f-4e78-8768-e02880497afe', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:15:43.114945+01', '865e9a13-7190-4221-ac8a-f9a681063745', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('7c6e6939-ec5d-4d48-b0b4-005d02a4dc4c', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:15:57.421297+01', '865e9a13-7190-4221-ac8a-f9a681063745', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('91dcbaa6-b091-446e-b4b7-e38146beb736', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:16:42.961583+01', '5798661c-7423-43e4-bb98-3c2b6dfd6d92', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('8f7b97a0-3dd3-4d20-aa56-92e6ec72807a', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:16:58.305337+01', '865e9a13-7190-4221-ac8a-f9a681063745', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('b85dce9c-ec21-45ff-a0c7-748a7c2012f2', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:17:12.683523+01', '5798661c-7423-43e4-bb98-3c2b6dfd6d92', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('2e042674-feeb-4e66-aae0-3e2d92290ba8', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:37:36.238038+01', '29b7522c-84eb-4abd-89e0-9285075813ac', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('30e19c94-1e77-4bbe-a30b-15bfaa38536d', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:37:36.251702+01', '5798661c-7423-43e4-bb98-3c2b6dfd6d92', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('3a970719-7b7d-47e1-b850-98e72292edd3', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:37:36.265407+01', '103034cd-badd-4299-aef0-d414a606d4e5', NULL, NULL);
INSERT INTO public.edit_sessions VALUES ('f876744a-10d4-43c2-8f54-2b90edf8447c', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:37:36.286878+01', '865e9a13-7190-4221-ac8a-f9a681063745', NULL, NULL);


--
-- Data for Name: favorite_collections; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: favorite_filter_sets; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: favorite_media_entries; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: filter_set_api_client_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: filter_set_group_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: filter_set_user_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: filter_sets; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: full_texts; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: groups; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.groups VALUES ('efbfca9f-4191-5d27-8c94-618be5a125f5', 'ZHdK (Zürcher Hochschule der Künste)', NULL, NULL, 'AuthenticationGroup', NULL, 'ZHdK (Zürcher Hochschule der Künste) ');
INSERT INTO public.groups VALUES ('8ffe3710-088c-5b31-ad23-573335c9017a', 'Beta-Tester "Metadaten-Stapelverarbeitung"', 'beta_test_quick_edit', NULL, 'InstitutionalGroup', NULL, 'Beta-Tester "Metadaten-Stapelverarbeitung" ');


--
-- Data for Name: groups_users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.groups_users VALUES ('efbfca9f-4191-5d27-8c94-618be5a125f5', 'd68ab096-158b-4632-b7f0-672c08f425cc');


--
-- Data for Name: io_interfaces; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: io_mappings; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: keywords; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: media_entries; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.media_entries VALUES ('29b7522c-84eb-4abd-89e0-9285075813ac', '2017-03-16 17:37:52.48173+01', '2017-03-22 13:37:36.238038+01', true, true, 'd68ab096-158b-4632-b7f0-672c08f425cc', 'd68ab096-158b-4632-b7f0-672c08f425cc', true, '2017-03-22 13:37:36.238038+01', '2017-03-16 17:39:05.431893+01');
INSERT INTO public.media_entries VALUES ('5798661c-7423-43e4-bb98-3c2b6dfd6d92', '2017-03-22 13:10:54.581366+01', '2017-03-22 13:37:36.251702+01', true, true, 'd68ab096-158b-4632-b7f0-672c08f425cc', 'd68ab096-158b-4632-b7f0-672c08f425cc', true, '2017-03-22 13:37:36.251702+01', '2017-03-22 13:16:42.782693+01');
INSERT INTO public.media_entries VALUES ('103034cd-badd-4299-aef0-d414a606d4e5', '2017-03-22 13:08:03.541613+01', '2017-03-22 13:37:36.265407+01', true, true, 'd68ab096-158b-4632-b7f0-672c08f425cc', 'd68ab096-158b-4632-b7f0-672c08f425cc', true, '2017-03-22 13:37:36.265407+01', '2017-03-22 13:37:35.788629+01');
INSERT INTO public.media_entries VALUES ('865e9a13-7190-4221-ac8a-f9a681063745', '2017-03-22 13:10:45.331143+01', '2017-03-22 13:37:36.286878+01', true, true, 'd68ab096-158b-4632-b7f0-672c08f425cc', 'd68ab096-158b-4632-b7f0-672c08f425cc', true, '2017-03-22 13:37:36.286878+01', '2017-03-22 13:16:58.168044+01');


--
-- Data for Name: media_entry_api_client_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: media_entry_group_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: media_entry_user_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: media_files; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.media_files VALUES ('3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', NULL, 1190633, NULL, '71aa02e6-cd0e-4ef1-abb5-886a7a965307', '---
SourceFile: "/var/local/madek-file-storage/originals/c/cb8c0a46f2744c3891ff5bd893581d21"
ExifTool:ExifToolVersion: 10.23
System:FileName: cb8c0a46f2744c3891ff5bd893581d21
System:Directory: "/var/local/madek-file-storage/originals/c"
System:FileSize: 1163 kB
System:FileModifyDate: 2017-03-16 16:37:52.000000000 +00:00
System:FileAccessDate: 2017-03-16 16:37:52.000000000 +00:00
System:FileInodeChangeDate: 2017-03-16 16:37:52.000000000 +00:00
System:FilePermissions: rw----r--
File:FileType: MP4
File:FileTypeExtension: mp4
File:MIMEType: video/mp4
QuickTime:MajorBrand: MP4 v2 [ISO 14496-14]
QuickTime:MinorVersion: 0.0.0
QuickTime:CompatibleBrands:
- mp42
- mp41
QuickTime:MovieHeaderVersion: 0
QuickTime:CreateDate: 2017:03:14 15:58:45
QuickTime:ModifyDate: 2017:03:14 15:58:45
QuickTime:TimeScale: 90000
QuickTime:Duration: 5.06 s
QuickTime:PreferredRate: 1
QuickTime:PreferredVolume: 100.00%
QuickTime:MatrixStructure: 1 0 0 0 1 0 0 0 1
QuickTime:PreviewTime: 0 s
QuickTime:PreviewDuration: 0 s
QuickTime:PosterTime: 0 s
QuickTime:SelectionTime: 0 s
QuickTime:SelectionDuration: 0 s
QuickTime:CurrentTime: 0 s
QuickTime:NextTrackID: 3
QuickTime:UserData_TIM: 00;00;00;00
QuickTime:UserData_TSC: 30000
QuickTime:UserData_TSZ: 1001
QuickTime:MovieDataSize: 1174196
QuickTime:MovieDataOffset: 16437
QuickTime:MovieData: "(Binary data 1174196 bytes, use -b option to extract)"
Track1:TrackHeaderVersion: 0
Track1:TrackCreateDate: 2017:03:14 15:58:45
Track1:TrackModifyDate: 2017:03:14 15:58:45
Track1:TrackID: 1
Track1:TrackDuration: 5.00 s
Track1:TrackLayer: 0
Track1:TrackVolume: 0.00%
Track1:MatrixStructure: 1 0 0 0 1 0 0 0 1
Track1:ImageWidth: 1920
Track1:ImageHeight: 1080
Track1:Unknown_edts: "(Binary data 28 bytes, use -b option to extract)"
Track1:MediaHeaderVersion: 0
Track1:MediaCreateDate: 2017:03:14 15:58:45
Track1:MediaModifyDate: 2017:03:14 15:58:45
Track1:MediaTimeScale: 30000
Track1:MediaDuration: 5.00 s
Track1:MediaLanguageCode: eng
Track1:HandlerType: Video Track
Track1:HandlerDescription: Mainconcept Video Media Handler
Track1:GraphicsMode: srcCopy
Track1:OpColor: 0 0 0
Track1:CompressorID: avc1
Track1:SourceImageWidth: 1920
Track1:SourceImageHeight: 1080
Track1:XResolution: 72
Track1:YResolution: 72
Track1:CompressorName: AVC Coding
Track1:BitDepth: 24
Track1:Unknown_avcC: "(Binary data 39 bytes, use -b option to extract)"
Track1:VideoFrameRate: 29.97
Track1:SyncSampleTable: "(Binary data 32 bytes, use -b option to extract)"
Track1:IdependentAndDisposableSamples: "(Binary data 154 bytes, use -b option to extract)"
Track1:SampleToChunk: "(Binary data 20 bytes, use -b option to extract)"
Track1:SampleSizes: "(Binary data 612 bytes, use -b option to extract)"
Track1:ChunkOffset: "(Binary data 68 bytes, use -b option to extract)"
Track1:CompositionTimeToSample: "(Binary data 632 bytes, use -b option to extract)"
Track2:TrackHeaderVersion: 0
Track2:TrackCreateDate: 2017:03:14 15:58:45
Track2:TrackModifyDate: 2017:03:14 15:58:45
Track2:TrackID: 2
Track2:TrackDuration: 5.00 s
Track2:TrackLayer: 0
Track2:TrackVolume: 100.00%
Track2:MatrixStructure: 1 0 0 0 1 0 0 0 1
Track2:Unknown_edts: "(Binary data 28 bytes, use -b option to extract)"
Track2:MediaHeaderVersion: 0
Track2:MediaCreateDate: 2017:03:14 15:58:45
Track2:MediaModifyDate: 2017:03:14 15:58:45
Track2:MediaTimeScale: 48000
Track2:MediaDuration: 5.06 s
Track2:MediaLanguageCode: eng
Track2:Balance: 0
Track2:HandlerType: Alias Data
Track2:HandlerDescription: Alias Data Handler
Track2:AudioFormat: mp4a
Track2:AudioChannels: 2
Track2:AudioBitsPerSample: 16
Track2:AudioSampleRate: 48000
Track2:Unknown_esds: "(Binary data 40 bytes, use -b option to extract)"
Track2:TimeToSampleTable: "(Binary data 16 bytes, use -b option to extract)"
Track2:SampleToChunk: "(Binary data 140 bytes, use -b option to extract)"
Track2:SampleSizes: "(Binary data 960 bytes, use -b option to extract)"
Track2:ChunkOffset: "(Binary data 68 bytes, use -b option to extract)"
XMP-x:XMPToolkit: ''Adobe XMP Core 5.6-c111 79.158325, 2015/09/10-01:10:20        ''
XMP-xmp:CreateDate: 2017-03-14 15:58:45.000000000 +00:00
XMP-xmp:ModifyDate: 2017-03-14 15:58:45.000000000 +00:00
XMP-xmp:MetadataDate: 2017-03-14 15:58:45.000000000 +00:00
XMP-xmp:CreatorTool: Adobe After Effects CC 2015 (Macintosh)
XMP-xmpDM:VideoFrameRate: 29.97003
XMP-xmpDM:VideoFieldOrder: Progressive
XMP-xmpDM:VideoPixelAspectRatio: 1
XMP-xmpDM:AudioSampleRate: 48000
XMP-xmpDM:AudioSampleType: 16-bit integer
XMP-xmpDM:AudioChannelType: Stereo
XMP-xmpDM:StartTimeScale: 30000
XMP-xmpDM:StartTimeSampleSize: 1001
XMP-xmpDM:DurationValue: 455040
XMP-xmpDM:DurationScale: 1.11111111111111e-05
XMP-xmpDM:StartTimecodeTimeFormat: 29.97 fps (drop)
XMP-xmpDM:StartTimecodeTimeValue: 00;00;00;00
XMP-xmpDM:VideoFrameSizeW: 1920
XMP-xmpDM:VideoFrameSizeH: 1080
XMP-xmpDM:VideoFrameSizeUnit: pixel
XMP-xmpDM:AltTimecodeTimeValue: 00;00;00;00
XMP-xmpDM:AltTimecodeTimeFormat: 29.97 fps (drop)
XMP-xmpMM:InstanceID: xmp.iid:0be86f64-36c1-4ab0-ba8a-1b328f2f8cbd
XMP-xmpMM:DocumentID: 3bb9251e-d4d0-6eab-b7d0-376900000059
XMP-xmpMM:OriginalDocumentID: xmp.did:78cb4904-b7c0-4c2a-98a0-c9a78cb9401d
XMP-xmpMM:HistoryAction:
- saved
- created
- saved
- saved
- derived
- saved
- saved
- saved
XMP-xmpMM:HistoryInstanceID:
- 52692039-877a-7a94-9c53-c4d500000086
- xmp.iid:6dbee995-4f44-4d52-b606-54ac346070c3
- xmp.iid:66d70143-e0fb-41dd-8d46-b38bd642c251
- xmp.iid:4748cba8-4d56-4c3c-bcd1-b3f8527607cf
- xmp.iid:2c279ea0-2f36-4bfe-b899-3069c0679f1b
- xmp.iid:7362a513-43f1-4456-ba62-ccadc938d1af
- xmp.iid:0be86f64-36c1-4ab0-ba8a-1b328f2f8cbd
XMP-xmpMM:HistoryWhen:
- 2017:03:14 16:58:45+01:00
- 2017:03:14 16:02:52+01:00
- 2017:03:14 16:16:56+01:00
- 2017:03:14 16:46:50+01:00
- 2017:03:14 16:47:51+01:00
- 2017:03:14 16:58:45+01:00
- 2017:03:14 16:58:45+01:00
XMP-xmpMM:HistorySoftwareAgent:
- Adobe Adobe Media Encoder CC (Macintosh)
- Adobe After Effects CC 2015 (Macintosh)
- Adobe After Effects CC 2015 (Macintosh)
- Adobe After Effects CC 2015 (Macintosh)
- Adobe After Effects CC 2015 (Macintosh)
- Adobe Adobe Media Encoder CC (Macintosh)
- Adobe Adobe Media Encoder CC (Macintosh)
XMP-xmpMM:HistoryChanged:
- "/"
- "/content"
- "/content"
- "/"
- "/"
- "/metadata"
XMP-xmpMM:HistoryParameters: saved to new location
XMP-xmpMM:DerivedFromInstanceID: xmp.iid:87804f8d-a6d7-437a-a631-aac5246a437d
XMP-xmpMM:DerivedFromDocumentID: xmp.did:87804f8d-a6d7-437a-a631-aac5246a437d
XMP-xmpMM:DerivedFromOriginalDocumentID: xmp.did:6dbee995-4f44-4d52-b606-54ac346070c3
XMP-xmpMM:IngredientsInstanceID: xmp.iid:e25315b2-f2d3-4e22-9e3a-f72368742851
XMP-xmpMM:IngredientsFromPart: time:0d3603600f240000
XMP-xmpMM:IngredientsToPart: time:0d3603600f240000
XMP-xmpMM:IngredientsMaskMarkers: None
XMP-xmpMM:PantryCreateDate: 2017-03-14 15:15:45.000000000 Z
XMP-xmpMM:PantryModifyDate: 2017-03-14 15:15:48.000000000 Z
XMP-xmpMM:PantryMetadataDate: 2017-03-14 15:15:48.000000000 +00:00
XMP-xmpMM:PantryCreatorTool: Adobe Premiere Pro CC (Macintosh)
XMP-xmpMM:PantryStartTimeScale: 30000
XMP-xmpMM:PantryStartTimeSampleSize: 1001
XMP-xmpMM:PantryVideoFrameRate: 29.97003
XMP-xmpMM:PantryVideoFieldOrder: Progressive
XMP-xmpMM:PantryVideoPixelAspectRatio: 1
XMP-xmpMM:PantryAudioSampleRate: 48000
XMP-xmpMM:PantryAudioSampleType: 16-bit integer
XMP-xmpMM:PantryAudioChannelType: Stereo
XMP-xmpMM:PantryDocumentID: bd2842cb-9326-122c-6774-697800000067
XMP-xmpMM:PantryOriginalDocumentID: xmp.did:eee8739b-5d0d-44ec-ac38-083ebf6c76ac
XMP-xmpMM:PantryAltTimecodeTimeValue: 00;00;00;00
XMP-xmpMM:PantryAltTimecodeTimeFormat: 29.97 fps (drop)
XMP-xmpMM:PantryProjectRefType: Movie
XMP-xmpMM:PantryVideoFrameSizeW: 1920
XMP-xmpMM:PantryVideoFrameSizeH: 1080
XMP-xmpMM:PantryVideoFrameSizeUnit: pixel
XMP-xmpMM:PantryStartTimecodeTimeFormat: 29.97 fps (drop)
XMP-xmpMM:PantryStartTimecodeTimeValue: 00;00;00;00
XMP-xmpMM:PantryDurationValue: 599599
XMP-xmpMM:PantryDurationScale: 3.33333333333333e-05
XMP-xmpMM:PantryHistoryAction: saved
XMP-xmpMM:PantryHistoryInstanceID: xmp.iid:246184f2-048e-4e48-9e58-17d32fa8671e
XMP-xmpMM:PantryHistoryWhen: 2017:03:14 16:15:48+01:00
XMP-xmpMM:PantryHistorySoftwareAgent: Adobe Premiere Pro CC (Macintosh)
XMP-xmpMM:PantryHistoryChanged: "/metadata"
XMP-xmpMM:PantryDerivedFromInstanceID: xmp.iid:c8fc8a9d-10de-4f6b-bc42-6457549b3926
XMP-xmpMM:PantryDerivedFromDocumentID: xmp.did:c8fc8a9d-10de-4f6b-bc42-6457549b3926
XMP-xmpMM:PantryDerivedFromOriginalDocumentID: xmp.did:c8fc8a9d-10de-4f6b-bc42-6457549b3926
XMP-xmpMM:PantryWindowsAtomExtension: ".prproj"
XMP-xmpMM:PantryWindowsAtomInvocationFlags: "/L"
XMP-xmpMM:PantryMacAtomApplicationCode: 1347449455
XMP-xmpMM:PantryMacAtomInvocationAppleEvent: 1129468018
XMP-xmpMM:PantryMacAtomPosixProjectPath: "/Users/ma/Documents/madek-test-media/video/madek-test-video.prproj"
XMP-xmpMM:PantryIngredientsDocumentID: bd2842cb-9326-122c-6774-697800000067
XMP-xmpMM:PantryFormat: application/vnd.adobe.aftereffects.comp
XMP-xmpMM:PantryInstanceID: xmp.iid:e25315b2-f2d3-4e22-9e3a-f72368742851
XMP-xmpMM:PantryTitle: madek-test-video
XMP-xmpMM:PantryIngredientsInstanceID: xmp.iid:da6fdc35-5212-4fa0-acee-c6eca1f2deb1
XMP-xmpMM:PantryIngredientsFromPart: time:0d3603600f240000
XMP-xmpMM:PantryIngredientsToPart: time:0d3603600f240000
XMP-xmpMM:PantryIngredientsMaskMarkers: None
XMP-dc:Format: H.264
Composite:AvgBitrate: 1.86 Mbps
Composite:ImageSize: 1920x1080
Composite:Megapixels: 2.1
Composite:Rotation: 0
', 'video/mp4', 'madek-test-video-5s.mp4', 'cb8c0a46f2744c3891ff5bd893581d21', 'mp4', 'video', '29b7522c-84eb-4abd-89e0-9285075813ac', '2017-03-16 17:37:52.48173+01', '2017-03-16 17:38:30.715409+01', 'd68ab096-158b-4632-b7f0-672c08f425cc', '{mp4,mp4_HD,webm,webm_HD}');
INSERT INTO public.media_files VALUES ('e481363f-5277-4336-85aa-841899c39e9b', NULL, 318996, NULL, '36e3898a-8a27-4354-a758-e9f24fd287bb', '---
SourceFile: "/var/local/madek-file-storage/originals/f/f7df90537cd547f2a82127229a52b452"
ExifTool:ExifToolVersion: 10.23
System:FileName: f7df90537cd547f2a82127229a52b452
System:Directory: "/var/local/madek-file-storage/originals/f"
System:FileSize: 312 kB
System:FileModifyDate: 2017-03-22 12:10:54.000000000 +00:00
System:FileAccessDate: 2017-03-22 12:10:54.000000000 +00:00
System:FileInodeChangeDate: 2017-03-22 12:10:54.000000000 +00:00
System:FilePermissions: rw----r--
File:FileType: TIFF
File:FileTypeExtension: tif
File:MIMEType: image/tiff
File:ExifByteOrder: Little-endian (Intel, II)
File:CurrentIPTCDigest: cdcffa7da8c7be09057076aeaf05c34e
IFD0:SubfileType: Full-resolution Image
IFD0:ImageWidth: 1535
IFD0:ImageHeight: 1063
IFD0:BitsPerSample: 8 8 8
IFD0:Compression: LZW
IFD0:PhotometricInterpretation: RGB
IFD0:StripOffsets: "(Binary data 119 bytes, use -b option to extract)"
IFD0:Orientation: Horizontal (normal)
IFD0:SamplesPerPixel: 3
IFD0:RowsPerStrip: 56
IFD0:StripByteCounts: "(Binary data 93 bytes, use -b option to extract)"
IFD0:XResolution: 300
IFD0:YResolution: 300
IFD0:PlanarConfiguration: Chunky
IFD0:ResolutionUnit: inches
IFD0:Software: Adobe Photoshop CC 2015 (Macintosh)
IFD0:ModifyDate: 2017:03:22 12:20:28
IFD0:Predictor: Horizontal differencing
IFD0:ImageSourceData: "(Binary data 180788 bytes, use -b option to extract)"
XMP-x:XMPToolkit: ''Adobe XMP Core 5.6-c111 79.158325, 2015/09/10-01:10:20        ''
XMP-xmp:CreatorTool: Adobe Photoshop CC 2015 (Macintosh)
XMP-xmp:CreateDate: 2017-03-22 11:09:30.000000000 +00:00
XMP-xmp:MetadataDate: 2017-03-22 11:20:28.000000000 +00:00
XMP-xmp:ModifyDate: 2017-03-22 11:20:28.000000000 +00:00
XMP-photoshop:ColorMode: RGB
XMP-photoshop:ICCProfileName: ProPhoto RGB
XMP-photoshop:TextLayerName:
- Madek Test Image
- Madek Test Image
- Madek Test Image
XMP-photoshop:TextLayerText:
- Madek Test Image
- Madek Test Image
- Madek Test Image
XMP-dc:Format: image/tiff
XMP-xmpMM:InstanceID: xmp.iid:215c7793-cea7-4546-b02f-e2e792b08f9c
XMP-xmpMM:DocumentID: adobe:docid:photoshop:81dde291-4f7f-117a-88fb-b93868bec799
XMP-xmpMM:OriginalDocumentID: xmp.did:7d88ec59-84c0-49df-8ae9-e58715db1822
XMP-xmpMM:HistoryAction:
- created
- saved
- converted
- derived
- saved
XMP-xmpMM:HistoryInstanceID:
- xmp.iid:7d88ec59-84c0-49df-8ae9-e58715db1822
- xmp.iid:6d9a894e-e20e-40e1-9acd-d1b39327ff9e
- xmp.iid:215c7793-cea7-4546-b02f-e2e792b08f9c
XMP-xmpMM:HistoryWhen:
- 2017:03:22 12:09:30+01:00
- 2017:03:22 12:20:28+01:00
- 2017:03:22 12:20:28+01:00
XMP-xmpMM:HistorySoftwareAgent:
- Adobe Photoshop CC 2015 (Macintosh)
- Adobe Photoshop CC 2015 (Macintosh)
- Adobe Photoshop CC 2015 (Macintosh)
XMP-xmpMM:HistoryChanged:
- "/"
- "/"
XMP-xmpMM:HistoryParameters:
- from application/vnd.adobe.photoshop to image/tiff
- converted from application/vnd.adobe.photoshop to image/tiff
XMP-xmpMM:DerivedFromInstanceID: xmp.iid:6d9a894e-e20e-40e1-9acd-d1b39327ff9e
XMP-xmpMM:DerivedFromDocumentID: xmp.did:7d88ec59-84c0-49df-8ae9-e58715db1822
XMP-xmpMM:DerivedFromOriginalDocumentID: xmp.did:7d88ec59-84c0-49df-8ae9-e58715db1822
IPTC:CodedCharacterSet: UTF8
IPTC:ApplicationRecordVersion: 0
Photoshop:IPTCDigest: cdcffa7da8c7be09057076aeaf05c34e
Photoshop:PrintInfo2: !binary |-
  AAAAEAAAAAEAAAAAAAtwcmludE91dHB1dAAAAAUAAAAAUHN0U2Jvb2wBAAAA
  AEludGVlbnVtAAAAAEludGUAAAAAQ2xybQAAAA9wcmludFNpeHRlZW5CaXRi
  b29sAAAAAAtwcmludGVyTmFtZVRFWFQAAAABAAAAAAAPcHJpbnRQcm9vZlNl
  dHVwT2JqYwAAABIAUAByAG8AbwBmAC0ARQBpAG4AcwB0AGUAbABsAHUAbgBn
  AAAAAAAKcHJvb2ZTZXR1cAAAAAEAAAAAQmx0bmVudW0AAAAMYnVpbHRpblBy
  b29mAAAACXByb29mQ01ZSw==
Photoshop:XResolution: 300
Photoshop:DisplayedUnitsX: inches
Photoshop:YResolution: 300
Photoshop:DisplayedUnitsY: inches
Photoshop:PrintStyle: Centered
Photoshop:PrintPosition: 0 0
Photoshop:PrintScale: 1
Photoshop:BackgroundColor: !binary |-
  AAA/Pz8/Pz8AAA==
Photoshop:GlobalAngle: 90
Photoshop:GlobalAltitude: 30
Photoshop:PrintFlags: 0 0 0 0 0 0 0 0 1
Photoshop:PrintFlagsInfo: !binary |-
  AAEAAAAAAAAAAg==
Photoshop:ColorHalftoningInfo: !binary |-
  AC9mZgABAGxmZgAGAAAAAAABAC9mZgABAD8/PwAGAAAAAAABADIAAAABAFoA
  AAAGAAAAAAABADUAAAABAC0AAAAGAAAAAAAB
Photoshop:ColorTransferFuncs: !binary |-
  AAA/Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/Az8AAAAAPz8/Pz8/Pz8/Pz8/Pz8/
  Pz8/Pz8/PwM/AAAAAD8/Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/Pz8DPwAAAAA/Pz8/
  Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/Az8AAA==
Photoshop:TargetLayerID: 5
Photoshop:LayersGroupInfo: 0 0 0 0 0 0 0
Photoshop:LayerGroupsEnabledID: 1 1 1 1 1 1 1
Photoshop:LayerSelectionIDs: 7
Photoshop:GridGuidesInfo: !binary |-
  AAAAAQAAAkAAAAJAAAAAAA==
Photoshop:URL_List: []
Photoshop:SlicesGroupName: ''''
Photoshop:NumSlices: 1
Photoshop:PixelAspectRatio: 1
Photoshop:IDsBaseValue: 15
Photoshop:PhotoshopThumbnail: "(Binary data 5650 bytes, use -b option to extract)"
Photoshop:HasRealMergedData: ''Yes''
Photoshop:WriterName: Adobe Photoshop
Photoshop:ReaderName: Adobe Photoshop CC 2015
ExifIFD:ColorSpace: Uncalibrated
ExifIFD:ExifImageWidth: 1535
ExifIFD:ExifImageHeight: 1063
ICC-header:ProfileCMMType: KCMS
ICC-header:ProfileVersion: 2.1.0
ICC-header:ProfileClass: Display Device Profile
ICC-header:ColorSpaceData: ''RGB ''
ICC-header:ProfileConnectionSpace: ''XYZ ''
ICC-header:ProfileDateTime: 1998:12:01 18:58:21
ICC-header:ProfileFileSignature: acsp
ICC-header:PrimaryPlatform: Microsoft Corporation
ICC-header:CMMFlags: Not Embedded, Independent
ICC-header:DeviceManufacturer: KODA
ICC-header:DeviceModel: ROMM
ICC-header:DeviceAttributes: Reflective, Glossy, Positive, Color
ICC-header:RenderingIntent: Media-Relative Colorimetric
ICC-header:ConnectionSpaceIlluminant: 0.9642 1 0.82487
ICC-header:ProfileCreator: KODA
ICC-header:ProfileID: 0
ICC_Profile:ProfileCopyright: Copyright (c) Eastman Kodak Company, 1999, all rights reserved.
ICC_Profile:ProfileDescription: ProPhoto RGB
ICC_Profile:MediaWhitePoint: 0.9642 1 0.82489
ICC_Profile:RedTRC: "(Binary data 14 bytes, use -b option to extract)"
ICC_Profile:GreenTRC: "(Binary data 14 bytes, use -b option to extract)"
ICC_Profile:BlueTRC: "(Binary data 14 bytes, use -b option to extract)"
ICC_Profile:RedMatrixColumn: 0.79767 0.28804 0
ICC_Profile:GreenMatrixColumn: 0.13519 0.71188 0
ICC_Profile:BlueMatrixColumn: 0.03134 9e-05 0.82491
ICC_Profile:DeviceMfgDesc: KODAK
ICC_Profile:DeviceModelDesc: ''Reference Output Medium Metric(ROMM)  ''
ICC_Profile:MakeAndModel: "(Binary data 40 bytes, use -b option to extract)"
Composite:ImageSize: 1535x1063
Composite:Megapixels: 1.6
', 'image/tiff', 'test-image-wide.tif', 'f7df90537cd547f2a82127229a52b452', 'tif', 'image', '5798661c-7423-43e4-bb98-3c2b6dfd6d92', '2017-03-22 13:10:54.581366+01', '2017-03-22 13:10:56.95814+01', 'd68ab096-158b-4632-b7f0-672c08f425cc', '{}');
INSERT INTO public.media_files VALUES ('25f76d98-afad-4e4c-a383-77ea8bebe3ed', NULL, 51441, NULL, 'b72edb2c-2e21-4c7e-ac7a-c625beff4b22', '---
SourceFile: "/var/local/madek-file-storage/originals/1/137698174e13418cb5d8e960caaf3407"
ExifTool:ExifToolVersion: 10.23
ExifTool:Error: Unknown file type
System:FileName: 137698174e13418cb5d8e960caaf3407
System:Directory: "/var/local/madek-file-storage/originals/1"
System:FileSize: 50 kB
System:FileModifyDate: 2017-03-22 12:08:03.000000000 +00:00
System:FileAccessDate: 2017-03-22 12:08:03.000000000 +00:00
System:FileInodeChangeDate: 2017-03-22 12:08:03.000000000 +00:00
System:FilePermissions: rw----r--
', 'audio/aac', 'test-audio.aac', '137698174e13418cb5d8e960caaf3407', 'aac', 'audio', '103034cd-badd-4299-aef0-d414a606d4e5', '2017-03-22 13:08:03.541613+01', '2017-03-22 13:08:19.327966+01', 'd68ab096-158b-4632-b7f0-672c08f425cc', '{mp3,vorbis}');
INSERT INTO public.media_files VALUES ('8ae5dc2b-ac90-4f34-b49f-634060b81bf2', NULL, 327516, NULL, '7674c885-3f6f-4c1c-ace1-33d4e21858d1', '---
SourceFile: "/var/local/madek-file-storage/originals/1/16bb9f7f388e4b4eb4908f9d457718dc"
ExifTool:ExifToolVersion: 10.23
System:FileName: 16bb9f7f388e4b4eb4908f9d457718dc
System:Directory: "/var/local/madek-file-storage/originals/1"
System:FileSize: 320 kB
System:FileModifyDate: 2017-03-22 12:10:45.000000000 +00:00
System:FileAccessDate: 2017-03-22 12:10:45.000000000 +00:00
System:FileInodeChangeDate: 2017-03-22 12:10:45.000000000 +00:00
System:FilePermissions: rw----r--
File:FileType: TIFF
File:FileTypeExtension: tif
File:MIMEType: image/tiff
File:ExifByteOrder: Little-endian (Intel, II)
File:CurrentIPTCDigest: cdcffa7da8c7be09057076aeaf05c34e
IFD0:SubfileType: Full-resolution Image
IFD0:ImageWidth: 1063
IFD0:ImageHeight: 1535
IFD0:BitsPerSample: 8 8 8
IFD0:Compression: LZW
IFD0:PhotometricInterpretation: RGB
IFD0:StripOffsets: "(Binary data 118 bytes, use -b option to extract)"
IFD0:Orientation: Horizontal (normal)
IFD0:SamplesPerPixel: 3
IFD0:RowsPerStrip: 82
IFD0:StripByteCounts: "(Binary data 98 bytes, use -b option to extract)"
IFD0:XResolution: 300
IFD0:YResolution: 300
IFD0:PlanarConfiguration: Chunky
IFD0:ResolutionUnit: inches
IFD0:Software: Adobe Photoshop CC 2015 (Macintosh)
IFD0:ModifyDate: 2017:03:22 12:20:54
IFD0:Predictor: Horizontal differencing
IFD0:ImageSourceData: "(Binary data 191944 bytes, use -b option to extract)"
XMP-x:XMPToolkit: ''Adobe XMP Core 5.6-c111 79.158325, 2015/09/10-01:10:20        ''
XMP-xmp:CreatorTool: Adobe Photoshop CC 2015 (Macintosh)
XMP-xmp:CreateDate: 2017-03-22 11:18:12.000000000 +00:00
XMP-xmp:MetadataDate: 2017-03-22 11:20:54.000000000 +00:00
XMP-xmp:ModifyDate: 2017-03-22 11:20:54.000000000 +00:00
XMP-photoshop:ColorMode: RGB
XMP-photoshop:ICCProfileName: ProPhoto RGB
XMP-photoshop:TextLayerName:
- Madek Test Image
- Madek Test Image
- Madek Test Image
XMP-photoshop:TextLayerText:
- Madek Test Image
- Madek Test Image
- Madek Test Image
XMP-dc:Format: image/tiff
XMP-xmpMM:InstanceID: xmp.iid:a795b1f0-9cff-482f-a73e-a3055350ac71
XMP-xmpMM:DocumentID: adobe:docid:photoshop:9e817721-4f7f-117a-88fb-b93868bec799
XMP-xmpMM:OriginalDocumentID: xmp.did:6edb024d-ae77-4bdd-9af8-6abf8620b6e5
XMP-xmpMM:HistoryAction:
- created
- saved
- converted
- derived
- saved
XMP-xmpMM:HistoryInstanceID:
- xmp.iid:6edb024d-ae77-4bdd-9af8-6abf8620b6e5
- xmp.iid:74f76a9e-5b6d-4c0b-87e9-d3c0df7b814b
- xmp.iid:a795b1f0-9cff-482f-a73e-a3055350ac71
XMP-xmpMM:HistoryWhen:
- 2017:03:22 12:18:12+01:00
- 2017:03:22 12:20:54+01:00
- 2017:03:22 12:20:54+01:00
XMP-xmpMM:HistorySoftwareAgent:
- Adobe Photoshop CC 2015 (Macintosh)
- Adobe Photoshop CC 2015 (Macintosh)
- Adobe Photoshop CC 2015 (Macintosh)
XMP-xmpMM:HistoryChanged:
- "/"
- "/"
XMP-xmpMM:HistoryParameters:
- from application/vnd.adobe.photoshop to image/tiff
- converted from application/vnd.adobe.photoshop to image/tiff
XMP-xmpMM:DerivedFromInstanceID: xmp.iid:74f76a9e-5b6d-4c0b-87e9-d3c0df7b814b
XMP-xmpMM:DerivedFromDocumentID: xmp.did:6edb024d-ae77-4bdd-9af8-6abf8620b6e5
XMP-xmpMM:DerivedFromOriginalDocumentID: xmp.did:6edb024d-ae77-4bdd-9af8-6abf8620b6e5
IPTC:CodedCharacterSet: UTF8
IPTC:ApplicationRecordVersion: 0
Photoshop:IPTCDigest: cdcffa7da8c7be09057076aeaf05c34e
Photoshop:PrintInfo2: !binary |-
  AAAAEAAAAAEAAAAAAAtwcmludE91dHB1dAAAAAUAAAAAUHN0U2Jvb2wBAAAA
  AEludGVlbnVtAAAAAEludGUAAAAAQ2xybQAAAA9wcmludFNpeHRlZW5CaXRi
  b29sAAAAAAtwcmludGVyTmFtZVRFWFQAAAABAAAAAAAPcHJpbnRQcm9vZlNl
  dHVwT2JqYwAAABIAUAByAG8AbwBmAC0ARQBpAG4AcwB0AGUAbABsAHUAbgBn
  AAAAAAAKcHJvb2ZTZXR1cAAAAAEAAAAAQmx0bmVudW0AAAAMYnVpbHRpblBy
  b29mAAAACXByb29mQ01ZSw==
Photoshop:XResolution: 300
Photoshop:DisplayedUnitsX: inches
Photoshop:YResolution: 300
Photoshop:DisplayedUnitsY: inches
Photoshop:PrintStyle: Centered
Photoshop:PrintPosition: 0 0
Photoshop:PrintScale: 1
Photoshop:BackgroundColor: !binary |-
  AAA/Pz8/Pz8AAA==
Photoshop:GlobalAngle: 90
Photoshop:GlobalAltitude: 30
Photoshop:PrintFlags: 0 0 0 0 0 0 0 0 1
Photoshop:PrintFlagsInfo: !binary |-
  AAEAAAAAAAAAAg==
Photoshop:ColorHalftoningInfo: !binary |-
  AC9mZgABAGxmZgAGAAAAAAABAC9mZgABAD8/PwAGAAAAAAABADIAAAABAFoA
  AAAGAAAAAAABADUAAAABAC0AAAAGAAAAAAAB
Photoshop:ColorTransferFuncs: !binary |-
  AAA/Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/Az8AAAAAPz8/Pz8/Pz8/Pz8/Pz8/
  Pz8/Pz8/PwM/AAAAAD8/Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/Pz8DPwAAAAA/Pz8/
  Pz8/Pz8/Pz8/Pz8/Pz8/Pz8/Az8AAA==
Photoshop:TargetLayerID: 6
Photoshop:LayersGroupInfo: 0 0 0 0 0 0 0
Photoshop:LayerGroupsEnabledID: 1 1 1 1 1 1 1
Photoshop:LayerSelectionIDs: 7
Photoshop:GridGuidesInfo: !binary |-
  AAAAAQAAAkAAAAJAAAAAAA==
Photoshop:URL_List: []
Photoshop:SlicesGroupName: ''''
Photoshop:NumSlices: 1
Photoshop:PixelAspectRatio: 1
Photoshop:IDsBaseValue: 13
Photoshop:PhotoshopThumbnail: "(Binary data 5678 bytes, use -b option to extract)"
Photoshop:HasRealMergedData: ''Yes''
Photoshop:WriterName: Adobe Photoshop
Photoshop:ReaderName: Adobe Photoshop CC 2015
ExifIFD:ColorSpace: Uncalibrated
ExifIFD:ExifImageWidth: 1063
ExifIFD:ExifImageHeight: 1535
ICC-header:ProfileCMMType: KCMS
ICC-header:ProfileVersion: 2.1.0
ICC-header:ProfileClass: Display Device Profile
ICC-header:ColorSpaceData: ''RGB ''
ICC-header:ProfileConnectionSpace: ''XYZ ''
ICC-header:ProfileDateTime: 1998:12:01 18:58:21
ICC-header:ProfileFileSignature: acsp
ICC-header:PrimaryPlatform: Microsoft Corporation
ICC-header:CMMFlags: Not Embedded, Independent
ICC-header:DeviceManufacturer: KODA
ICC-header:DeviceModel: ROMM
ICC-header:DeviceAttributes: Reflective, Glossy, Positive, Color
ICC-header:RenderingIntent: Media-Relative Colorimetric
ICC-header:ConnectionSpaceIlluminant: 0.9642 1 0.82487
ICC-header:ProfileCreator: KODA
ICC-header:ProfileID: 0
ICC_Profile:ProfileCopyright: Copyright (c) Eastman Kodak Company, 1999, all rights reserved.
ICC_Profile:ProfileDescription: ProPhoto RGB
ICC_Profile:MediaWhitePoint: 0.9642 1 0.82489
ICC_Profile:RedTRC: "(Binary data 14 bytes, use -b option to extract)"
ICC_Profile:GreenTRC: "(Binary data 14 bytes, use -b option to extract)"
ICC_Profile:BlueTRC: "(Binary data 14 bytes, use -b option to extract)"
ICC_Profile:RedMatrixColumn: 0.79767 0.28804 0
ICC_Profile:GreenMatrixColumn: 0.13519 0.71188 0
ICC_Profile:BlueMatrixColumn: 0.03134 9e-05 0.82491
ICC_Profile:DeviceMfgDesc: KODAK
ICC_Profile:DeviceModelDesc: ''Reference Output Medium Metric(ROMM)  ''
ICC_Profile:MakeAndModel: "(Binary data 40 bytes, use -b option to extract)"
Composite:ImageSize: 1063x1535
Composite:Megapixels: 1.6
', 'image/tiff', 'test-image-high.tif', '16bb9f7f388e4b4eb4908f9d457718dc', 'tif', 'image', '865e9a13-7190-4221-ac8a-f9a681063745', '2017-03-22 13:10:45.331143+01', '2017-03-22 13:10:48.089934+01', 'd68ab096-158b-4632-b7f0-672c08f425cc', '{}');


--
-- Data for Name: meta_data; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.meta_data VALUES ('66585d94-a433-4ea6-9384-ab56822e1486', 'madek_core:title', 'MetaDatum::Text', 'madek-test-video', '29b7522c-84eb-4abd-89e0-9285075813ac', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-16 17:38:22.504318+01');
INSERT INTO public.meta_data VALUES ('ce7f6940-3c1f-4a95-8f30-56a2a32503ad', 'madek_core:copyright_notice', 'MetaDatum::Text', 'Public Domain', '29b7522c-84eb-4abd-89e0-9285075813ac', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-16 17:38:22.504318+01');
INSERT INTO public.meta_data VALUES ('aa8a1924-7a01-4a33-bbed-7de423f97028', 'madek_core:authors', 'MetaDatum::People', NULL, '29b7522c-84eb-4abd-89e0-9285075813ac', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-16 17:39:05.431893+01');
INSERT INTO public.meta_data VALUES ('8d915d16-5333-4131-909a-7a4d2ee714ed', 'madek_core:title', 'MetaDatum::Text', 'madek-test-audio', '103034cd-badd-4299-aef0-d414a606d4e5', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:08:46.663323+01');
INSERT INTO public.meta_data VALUES ('87ff46c3-8f48-48c4-8e51-1380cb8047ee', 'madek_core:authors', 'MetaDatum::People', NULL, '103034cd-badd-4299-aef0-d414a606d4e5', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:08:46.663323+01');
INSERT INTO public.meta_data VALUES ('c5bad0b8-6250-4d58-8af3-6b34d7494e69', 'madek_core:authors', 'MetaDatum::People', NULL, '5798661c-7423-43e4-bb98-3c2b6dfd6d92', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:14:14.498968+01');
INSERT INTO public.meta_data VALUES ('e6aa5e40-4744-49ea-bdd7-1cb77b214618', 'madek_core:copyright_notice', 'MetaDatum::Text', 'Public Domain', '5798661c-7423-43e4-bb98-3c2b6dfd6d92', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:14:14.498968+01');
INSERT INTO public.meta_data VALUES ('50a01bb6-07dc-44a4-92ad-8468a2d617e6', 'madek_core:authors', 'MetaDatum::People', NULL, '865e9a13-7190-4221-ac8a-f9a681063745', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:15:42.879742+01');
INSERT INTO public.meta_data VALUES ('4436fe96-129d-44de-b3e6-bfe92a2931e7', 'madek_core:copyright_notice', 'MetaDatum::Text', 'Public Domain', '865e9a13-7190-4221-ac8a-f9a681063745', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:15:42.879742+01');
INSERT INTO public.meta_data VALUES ('5b73c4fc-3199-4780-b754-43051db56c92', 'madek_core:title', 'MetaDatum::Text', 'madek-test-image-landscape', '5798661c-7423-43e4-bb98-3c2b6dfd6d92', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:14:14.498968+01');
INSERT INTO public.meta_data VALUES ('e7babef8-e380-4a25-9e87-cdfa96f429e7', 'madek_core:title', 'MetaDatum::Text', 'madek-test-image-portrait', '865e9a13-7190-4221-ac8a-f9a681063745', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:15:42.879742+01');
INSERT INTO public.meta_data VALUES ('7de1fbbc-8797-49e0-8726-5bd0ee19cb6a', 'madek_core:copyright_notice', 'MetaDatum::Text', 'Public Domain', '103034cd-badd-4299-aef0-d414a606d4e5', NULL, NULL, 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:08:46.663323+01');


--
-- Data for Name: meta_data_keywords; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: meta_data_meta_terms; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: meta_data_people; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.meta_data_people VALUES ('aa8a1924-7a01-4a33-bbed-7de423f97028', '4d5dcea5-5113-47b5-818f-502830e2839b', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-16 17:39:05.431893+01', '3979c941-69d9-4892-ace3-0391452e967d');
INSERT INTO public.meta_data_people VALUES ('87ff46c3-8f48-48c4-8e51-1380cb8047ee', '4d5dcea5-5113-47b5-818f-502830e2839b', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:08:46.663323+01', 'a53f02ba-5c1c-43da-9243-75afb5c32341');
INSERT INTO public.meta_data_people VALUES ('c5bad0b8-6250-4d58-8af3-6b34d7494e69', '4d5dcea5-5113-47b5-818f-502830e2839b', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:14:14.498968+01', '03010a79-c346-477f-b474-5805a8dd9edf');
INSERT INTO public.meta_data_people VALUES ('50a01bb6-07dc-44a4-92ad-8468a2d617e6', '4d5dcea5-5113-47b5-818f-502830e2839b', 'd68ab096-158b-4632-b7f0-672c08f425cc', '2017-03-22 13:15:42.879742+01', '1e6d51cd-d7aa-4969-8515-73ea12bb77c4');


--
-- Data for Name: meta_data_roles; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: meta_keys; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.meta_keys VALUES ('madek_core:title', false, 'MetaDatum::Text', true, 'Titel', NULL, NULL, 1, true, true, true, 'madek_core', NULL, NULL, 'line', NULL, '"de"=>"Titel", "en"=>"Title"', '"de"=>NULL, "en"=>NULL', '"de"=>NULL, "en"=>NULL');
INSERT INTO public.meta_keys VALUES ('madek_core:subtitle', false, 'MetaDatum::Text', true, 'Untertitel', NULL, NULL, 2, true, true, true, 'madek_core', NULL, NULL, 'line', NULL, '"de"=>"Untertitel", "en"=>"Subtitle"', '"de"=>NULL, "en"=>NULL', '"de"=>NULL, "en"=>NULL');
INSERT INTO public.meta_keys VALUES ('madek_core:authors', false, 'MetaDatum::People', true, 'Autor/in', NULL, NULL, 3, true, true, false, 'madek_core', NULL, '{Person,PeopleGroup}', 'line', NULL, '"de"=>"Autor/in", "en"=>"Author"', '"de"=>NULL, "en"=>NULL', '"de"=>NULL, "en"=>NULL');
INSERT INTO public.meta_keys VALUES ('madek_core:portrayed_object_date', false, 'MetaDatum::TextDate', true, 'Datierung', NULL, NULL, 4, true, true, false, 'madek_core', NULL, NULL, 'line', NULL, '"de"=>"Datierung", "en"=>"Date"', '"de"=>NULL, "en"=>NULL', '"de"=>NULL, "en"=>NULL');
INSERT INTO public.meta_keys VALUES ('madek_core:keywords', true, 'MetaDatum::Keywords', true, 'Schlagworte', NULL, NULL, 5, true, true, true, 'madek_core', NULL, NULL, 'line', NULL, '"de"=>"Schlagworte", "en"=>"Keywords"', '"de"=>NULL, "en"=>NULL', '"de"=>NULL, "en"=>NULL');
INSERT INTO public.meta_keys VALUES ('madek_core:description', false, 'MetaDatum::Text', true, 'Beschreibung', NULL, NULL, 6, true, true, true, 'madek_core', NULL, NULL, 'block', NULL, '"de"=>"Beschreibung", "en"=>"Description"', '"de"=>NULL, "en"=>NULL', '"de"=>NULL, "en"=>NULL');
INSERT INTO public.meta_keys VALUES ('madek_core:copyright_notice', false, 'MetaDatum::Text', true, 'Rechteinhaber/in', NULL, NULL, 7, true, true, false, 'madek_core', NULL, NULL, 'line', NULL, '"de"=>"Rechteinhaber/in", "en"=>"Copyright Notice"', '"de"=>NULL, "en"=>NULL', '"de"=>NULL, "en"=>NULL');


--
-- Data for Name: people; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.people VALUES ('17363c5b-c7ef-4386-9e0e-5c75b49f8448', NULL, NULL, 'Admin', '2017-03-16 17:16:35.317937+01', '2017-03-16 17:16:35.317937+01', '  Admin', NULL, 'Person', NULL, '{}');
INSERT INTO public.people VALUES ('ce6b7dde-6f76-49ba-abe1-9f254d6db68f', 'Max', 'Albrecht', NULL, '2017-03-16 17:33:27.142901+01', '2017-03-16 17:33:27.142901+01', 'Max Albrecht ', NULL, 'Person', NULL, '{}');
INSERT INTO public.people VALUES ('4d5dcea5-5113-47b5-818f-502830e2839b', 'Madek Team', NULL, NULL, '2017-03-16 17:39:05.431893+01', '2017-03-16 17:39:05.431893+01', 'Madek Team  ', NULL, 'PeopleGroup', NULL, '{}');


--
-- Data for Name: previews; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.previews VALUES ('92730aa7-e33f-4de3-8149-7d3b1618190a', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', 348, 620, 'image/jpeg', 'cb8c0a46f2744c3891ff5bd893581d21_0000.jpg', 'large', '2017-03-16 17:38:25.811537+01', '2017-03-16 17:38:25.811537+01', 'image', NULL);
INSERT INTO public.previews VALUES ('24bff923-dfd5-4eb5-9773-7aed20a920de', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', NULL, NULL, 'image/jpeg', 'cb8c0a46f2744c3891ff5bd893581d21_0000_maximum.jpg', 'maximum', '2017-03-16 17:38:26.111098+01', '2017-03-16 17:38:26.111098+01', 'image', NULL);
INSERT INTO public.previews VALUES ('736f63d0-c79c-492b-8915-c5a20bd1ec15', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', 768, 1024, 'image/jpeg', 'cb8c0a46f2744c3891ff5bd893581d21_0000_x_large.jpg', 'x_large', '2017-03-16 17:38:26.353855+01', '2017-03-16 17:38:26.353855+01', 'image', NULL);
INSERT INTO public.previews VALUES ('47861034-4449-41b3-8635-adef2459e743', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', 300, 300, 'image/jpeg', 'cb8c0a46f2744c3891ff5bd893581d21_0000_medium.jpg', 'medium', '2017-03-16 17:38:26.507146+01', '2017-03-16 17:38:26.507146+01', 'image', NULL);
INSERT INTO public.previews VALUES ('574a19b3-b3e8-42a8-b103-6b430e8f03ab', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', 125, 125, 'image/jpeg', 'cb8c0a46f2744c3891ff5bd893581d21_0000_small_125.jpg', 'small_125', '2017-03-16 17:38:26.623572+01', '2017-03-16 17:38:26.623572+01', 'image', NULL);
INSERT INTO public.previews VALUES ('0441acd4-fade-40f2-b13a-ee7067bb2c31', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', 100, 100, 'image/jpeg', 'cb8c0a46f2744c3891ff5bd893581d21_0000_small.jpg', 'small', '2017-03-16 17:38:26.76104+01', '2017-03-16 17:38:26.76104+01', 'image', NULL);
INSERT INTO public.previews VALUES ('0f7f2dcd-12fa-49b0-b92a-e76ee45e804f', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', 348, 620, 'video/mp4', 'cb8c0a46f2744c3891ff5bd893581d21_620.mp4', 'large', '2017-03-16 17:38:27.604145+01', '2017-03-16 17:38:27.604145+01', 'video', 'mp4');
INSERT INTO public.previews VALUES ('7999f5ba-bcdb-4816-ae05-fc756d0c0e14', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', 1080, 1920, 'video/webm', 'cb8c0a46f2744c3891ff5bd893581d21_1920.webm', 'large', '2017-03-16 17:38:28.771259+01', '2017-03-16 17:38:28.771259+01', 'video', 'webm_HD');
INSERT INTO public.previews VALUES ('5b10b9cd-c76f-4840-acc8-24610dc47453', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', 1080, 1920, 'video/mp4', 'cb8c0a46f2744c3891ff5bd893581d21_1920.mp4', 'large', '2017-03-16 17:38:29.791344+01', '2017-03-16 17:38:29.791344+01', 'video', 'mp4_HD');
INSERT INTO public.previews VALUES ('a2fee665-08ab-4176-8f6d-16d93c36f009', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', 348, 620, 'video/webm', 'cb8c0a46f2744c3891ff5bd893581d21_620.webm', 'large', '2017-03-16 17:38:30.715409+01', '2017-03-16 17:38:30.715409+01', 'video', 'webm');
INSERT INTO public.previews VALUES ('abde7e89-7a98-4113-b2d5-97c58ce3d805', '25f76d98-afad-4e4c-a383-77ea8bebe3ed', NULL, NULL, 'audio/mpeg', '137698174e13418cb5d8e960caaf3407.mp3', NULL, '2017-03-22 13:08:18.72275+01', '2017-03-22 13:08:18.72275+01', 'audio', 'mp3');
INSERT INTO public.previews VALUES ('742024da-3dd2-446a-aec6-6644ca1efa3e', '25f76d98-afad-4e4c-a383-77ea8bebe3ed', NULL, NULL, 'audio/ogg', '137698174e13418cb5d8e960caaf3407.ogg', NULL, '2017-03-22 13:08:19.327966+01', '2017-03-22 13:08:19.327966+01', 'audio', 'vorbis');
INSERT INTO public.previews VALUES ('75597dbf-3eee-4257-a224-b326328a73e7', '8ae5dc2b-ac90-4f34-b49f-634060b81bf2', NULL, NULL, 'image/jpeg', '16bb9f7f388e4b4eb4908f9d457718dc_maximum.jpg', 'maximum', '2017-03-22 13:10:45.331143+01', '2017-03-22 13:10:45.331143+01', 'image', NULL);
INSERT INTO public.previews VALUES ('efe8cc29-5258-491e-966f-37dc938de92a', '8ae5dc2b-ac90-4f34-b49f-634060b81bf2', 768, 1024, 'image/jpeg', '16bb9f7f388e4b4eb4908f9d457718dc_x_large.jpg', 'x_large', '2017-03-22 13:10:45.331143+01', '2017-03-22 13:10:45.331143+01', 'image', NULL);
INSERT INTO public.previews VALUES ('6731e6e7-a602-4062-bcb2-7e592f952850', '8ae5dc2b-ac90-4f34-b49f-634060b81bf2', 500, 620, 'image/jpeg', '16bb9f7f388e4b4eb4908f9d457718dc_large.jpg', 'large', '2017-03-22 13:10:45.331143+01', '2017-03-22 13:10:45.331143+01', 'image', NULL);
INSERT INTO public.previews VALUES ('8480dbe8-7c92-469d-9763-34d09d6becaa', '8ae5dc2b-ac90-4f34-b49f-634060b81bf2', 300, 300, 'image/jpeg', '16bb9f7f388e4b4eb4908f9d457718dc_medium.jpg', 'medium', '2017-03-22 13:10:45.331143+01', '2017-03-22 13:10:45.331143+01', 'image', NULL);
INSERT INTO public.previews VALUES ('5ce6ae09-06a8-4fbf-9b46-dcca5d4a32fd', '8ae5dc2b-ac90-4f34-b49f-634060b81bf2', 125, 125, 'image/jpeg', '16bb9f7f388e4b4eb4908f9d457718dc_small_125.jpg', 'small_125', '2017-03-22 13:10:45.331143+01', '2017-03-22 13:10:45.331143+01', 'image', NULL);
INSERT INTO public.previews VALUES ('9ec51a1a-7eaf-419d-9739-2ab278ef6d53', '8ae5dc2b-ac90-4f34-b49f-634060b81bf2', 100, 100, 'image/jpeg', '16bb9f7f388e4b4eb4908f9d457718dc_small.jpg', 'small', '2017-03-22 13:10:45.331143+01', '2017-03-22 13:10:45.331143+01', 'image', NULL);
INSERT INTO public.previews VALUES ('636fee4b-3ed4-475d-8c24-f4981c2f795c', 'e481363f-5277-4336-85aa-841899c39e9b', NULL, NULL, 'image/jpeg', 'f7df90537cd547f2a82127229a52b452_maximum.jpg', 'maximum', '2017-03-22 13:10:54.581366+01', '2017-03-22 13:10:54.581366+01', 'image', NULL);
INSERT INTO public.previews VALUES ('df2e03e1-6938-4f39-a493-405a53170777', 'e481363f-5277-4336-85aa-841899c39e9b', 768, 1024, 'image/jpeg', 'f7df90537cd547f2a82127229a52b452_x_large.jpg', 'x_large', '2017-03-22 13:10:54.581366+01', '2017-03-22 13:10:54.581366+01', 'image', NULL);
INSERT INTO public.previews VALUES ('78752177-27e3-491f-adb3-e51bd836d0a1', 'e481363f-5277-4336-85aa-841899c39e9b', 500, 620, 'image/jpeg', 'f7df90537cd547f2a82127229a52b452_large.jpg', 'large', '2017-03-22 13:10:54.581366+01', '2017-03-22 13:10:54.581366+01', 'image', NULL);
INSERT INTO public.previews VALUES ('f3044273-9d33-4d8f-97b6-d71de06f9351', 'e481363f-5277-4336-85aa-841899c39e9b', 300, 300, 'image/jpeg', 'f7df90537cd547f2a82127229a52b452_medium.jpg', 'medium', '2017-03-22 13:10:54.581366+01', '2017-03-22 13:10:54.581366+01', 'image', NULL);
INSERT INTO public.previews VALUES ('256b8030-1c7b-47ee-a31e-b17318a4824b', 'e481363f-5277-4336-85aa-841899c39e9b', 125, 125, 'image/jpeg', 'f7df90537cd547f2a82127229a52b452_small_125.jpg', 'small_125', '2017-03-22 13:10:54.581366+01', '2017-03-22 13:10:54.581366+01', 'image', NULL);
INSERT INTO public.previews VALUES ('b977aec4-118d-4b4e-91f1-474b60db0242', 'e481363f-5277-4336-85aa-841899c39e9b', 100, 100, 'image/jpeg', 'f7df90537cd547f2a82127229a52b452_small.jpg', 'small', '2017-03-22 13:10:54.581366+01', '2017-03-22 13:10:54.581366+01', 'image', NULL);


--
-- Data for Name: rdf_classes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.rdf_classes VALUES ('Keyword', NULL, NULL, 0);
INSERT INTO public.rdf_classes VALUES ('License', NULL, NULL, 0);


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.schema_migrations VALUES ('0');
INSERT INTO public.schema_migrations VALUES ('1');
INSERT INTO public.schema_migrations VALUES ('2');
INSERT INTO public.schema_migrations VALUES ('3');
INSERT INTO public.schema_migrations VALUES ('4');
INSERT INTO public.schema_migrations VALUES ('5');
INSERT INTO public.schema_migrations VALUES ('6');
INSERT INTO public.schema_migrations VALUES ('7');
INSERT INTO public.schema_migrations VALUES ('8');
INSERT INTO public.schema_migrations VALUES ('9');
INSERT INTO public.schema_migrations VALUES ('10');
INSERT INTO public.schema_migrations VALUES ('11');
INSERT INTO public.schema_migrations VALUES ('12');
INSERT INTO public.schema_migrations VALUES ('13');
INSERT INTO public.schema_migrations VALUES ('14');
INSERT INTO public.schema_migrations VALUES ('15');
INSERT INTO public.schema_migrations VALUES ('16');
INSERT INTO public.schema_migrations VALUES ('17');
INSERT INTO public.schema_migrations VALUES ('18');
INSERT INTO public.schema_migrations VALUES ('19');
INSERT INTO public.schema_migrations VALUES ('20');
INSERT INTO public.schema_migrations VALUES ('21');
INSERT INTO public.schema_migrations VALUES ('22');
INSERT INTO public.schema_migrations VALUES ('23');
INSERT INTO public.schema_migrations VALUES ('24');
INSERT INTO public.schema_migrations VALUES ('25');
INSERT INTO public.schema_migrations VALUES ('26');
INSERT INTO public.schema_migrations VALUES ('27');
INSERT INTO public.schema_migrations VALUES ('28');
INSERT INTO public.schema_migrations VALUES ('29');
INSERT INTO public.schema_migrations VALUES ('30');
INSERT INTO public.schema_migrations VALUES ('31');
INSERT INTO public.schema_migrations VALUES ('32');
INSERT INTO public.schema_migrations VALUES ('33');
INSERT INTO public.schema_migrations VALUES ('34');
INSERT INTO public.schema_migrations VALUES ('35');
INSERT INTO public.schema_migrations VALUES ('100');
INSERT INTO public.schema_migrations VALUES ('101');
INSERT INTO public.schema_migrations VALUES ('102');
INSERT INTO public.schema_migrations VALUES ('103');
INSERT INTO public.schema_migrations VALUES ('104');
INSERT INTO public.schema_migrations VALUES ('105');
INSERT INTO public.schema_migrations VALUES ('107');
INSERT INTO public.schema_migrations VALUES ('108');
INSERT INTO public.schema_migrations VALUES ('109');
INSERT INTO public.schema_migrations VALUES ('110');
INSERT INTO public.schema_migrations VALUES ('111');
INSERT INTO public.schema_migrations VALUES ('112');
INSERT INTO public.schema_migrations VALUES ('113');
INSERT INTO public.schema_migrations VALUES ('114');
INSERT INTO public.schema_migrations VALUES ('115');
INSERT INTO public.schema_migrations VALUES ('117');
INSERT INTO public.schema_migrations VALUES ('118');
INSERT INTO public.schema_migrations VALUES ('119');
INSERT INTO public.schema_migrations VALUES ('120');
INSERT INTO public.schema_migrations VALUES ('121');
INSERT INTO public.schema_migrations VALUES ('122');
INSERT INTO public.schema_migrations VALUES ('123');
INSERT INTO public.schema_migrations VALUES ('124');
INSERT INTO public.schema_migrations VALUES ('125');
INSERT INTO public.schema_migrations VALUES ('126');
INSERT INTO public.schema_migrations VALUES ('127');
INSERT INTO public.schema_migrations VALUES ('128');
INSERT INTO public.schema_migrations VALUES ('129');
INSERT INTO public.schema_migrations VALUES ('130');
INSERT INTO public.schema_migrations VALUES ('131');
INSERT INTO public.schema_migrations VALUES ('132');
INSERT INTO public.schema_migrations VALUES ('133');
INSERT INTO public.schema_migrations VALUES ('134');
INSERT INTO public.schema_migrations VALUES ('135');
INSERT INTO public.schema_migrations VALUES ('136');
INSERT INTO public.schema_migrations VALUES ('137');
INSERT INTO public.schema_migrations VALUES ('138');
INSERT INTO public.schema_migrations VALUES ('139');
INSERT INTO public.schema_migrations VALUES ('140');
INSERT INTO public.schema_migrations VALUES ('141');
INSERT INTO public.schema_migrations VALUES ('142');
INSERT INTO public.schema_migrations VALUES ('143');
INSERT INTO public.schema_migrations VALUES ('144');
INSERT INTO public.schema_migrations VALUES ('145');
INSERT INTO public.schema_migrations VALUES ('146');
INSERT INTO public.schema_migrations VALUES ('147');
INSERT INTO public.schema_migrations VALUES ('148');
INSERT INTO public.schema_migrations VALUES ('149');
INSERT INTO public.schema_migrations VALUES ('150');
INSERT INTO public.schema_migrations VALUES ('151');
INSERT INTO public.schema_migrations VALUES ('152');
INSERT INTO public.schema_migrations VALUES ('153');
INSERT INTO public.schema_migrations VALUES ('154');
INSERT INTO public.schema_migrations VALUES ('156');
INSERT INTO public.schema_migrations VALUES ('157');
INSERT INTO public.schema_migrations VALUES ('165');
INSERT INTO public.schema_migrations VALUES ('166');
INSERT INTO public.schema_migrations VALUES ('168');
INSERT INTO public.schema_migrations VALUES ('169');
INSERT INTO public.schema_migrations VALUES ('171');
INSERT INTO public.schema_migrations VALUES ('175');
INSERT INTO public.schema_migrations VALUES ('176');
INSERT INTO public.schema_migrations VALUES ('177');
INSERT INTO public.schema_migrations VALUES ('178');
INSERT INTO public.schema_migrations VALUES ('180');
INSERT INTO public.schema_migrations VALUES ('181');
INSERT INTO public.schema_migrations VALUES ('182');
INSERT INTO public.schema_migrations VALUES ('183');
INSERT INTO public.schema_migrations VALUES ('184');
INSERT INTO public.schema_migrations VALUES ('185');
INSERT INTO public.schema_migrations VALUES ('186');
INSERT INTO public.schema_migrations VALUES ('187');
INSERT INTO public.schema_migrations VALUES ('188');
INSERT INTO public.schema_migrations VALUES ('189');
INSERT INTO public.schema_migrations VALUES ('190');
INSERT INTO public.schema_migrations VALUES ('191');
INSERT INTO public.schema_migrations VALUES ('192');
INSERT INTO public.schema_migrations VALUES ('193');
INSERT INTO public.schema_migrations VALUES ('194');
INSERT INTO public.schema_migrations VALUES ('199');
INSERT INTO public.schema_migrations VALUES ('200');
INSERT INTO public.schema_migrations VALUES ('201');
INSERT INTO public.schema_migrations VALUES ('202');
INSERT INTO public.schema_migrations VALUES ('203');
INSERT INTO public.schema_migrations VALUES ('204');
INSERT INTO public.schema_migrations VALUES ('205');
INSERT INTO public.schema_migrations VALUES ('206');
INSERT INTO public.schema_migrations VALUES ('207');
INSERT INTO public.schema_migrations VALUES ('208');
INSERT INTO public.schema_migrations VALUES ('209');
INSERT INTO public.schema_migrations VALUES ('210');
INSERT INTO public.schema_migrations VALUES ('211');
INSERT INTO public.schema_migrations VALUES ('212');
INSERT INTO public.schema_migrations VALUES ('213');
INSERT INTO public.schema_migrations VALUES ('214');
INSERT INTO public.schema_migrations VALUES ('215');
INSERT INTO public.schema_migrations VALUES ('299');
INSERT INTO public.schema_migrations VALUES ('300');
INSERT INTO public.schema_migrations VALUES ('301');
INSERT INTO public.schema_migrations VALUES ('302');
INSERT INTO public.schema_migrations VALUES ('303');
INSERT INTO public.schema_migrations VALUES ('304');
INSERT INTO public.schema_migrations VALUES ('305');
INSERT INTO public.schema_migrations VALUES ('306');
INSERT INTO public.schema_migrations VALUES ('310');
INSERT INTO public.schema_migrations VALUES ('311');
INSERT INTO public.schema_migrations VALUES ('312');
INSERT INTO public.schema_migrations VALUES ('313');
INSERT INTO public.schema_migrations VALUES ('314');
INSERT INTO public.schema_migrations VALUES ('315');
INSERT INTO public.schema_migrations VALUES ('316');
INSERT INTO public.schema_migrations VALUES ('317');
INSERT INTO public.schema_migrations VALUES ('318');
INSERT INTO public.schema_migrations VALUES ('319');
INSERT INTO public.schema_migrations VALUES ('320');
INSERT INTO public.schema_migrations VALUES ('321');
INSERT INTO public.schema_migrations VALUES ('322');
INSERT INTO public.schema_migrations VALUES ('323');
INSERT INTO public.schema_migrations VALUES ('324');
INSERT INTO public.schema_migrations VALUES ('325');
INSERT INTO public.schema_migrations VALUES ('326');
INSERT INTO public.schema_migrations VALUES ('327');
INSERT INTO public.schema_migrations VALUES ('328');
INSERT INTO public.schema_migrations VALUES ('329');
INSERT INTO public.schema_migrations VALUES ('330');
INSERT INTO public.schema_migrations VALUES ('331');
INSERT INTO public.schema_migrations VALUES ('332');
INSERT INTO public.schema_migrations VALUES ('333');
INSERT INTO public.schema_migrations VALUES ('334');
INSERT INTO public.schema_migrations VALUES ('335');
INSERT INTO public.schema_migrations VALUES ('336');
INSERT INTO public.schema_migrations VALUES ('337');
INSERT INTO public.schema_migrations VALUES ('338');
INSERT INTO public.schema_migrations VALUES ('339');
INSERT INTO public.schema_migrations VALUES ('340');
INSERT INTO public.schema_migrations VALUES ('341');
INSERT INTO public.schema_migrations VALUES ('342');
INSERT INTO public.schema_migrations VALUES ('343');
INSERT INTO public.schema_migrations VALUES ('344');
INSERT INTO public.schema_migrations VALUES ('345');
INSERT INTO public.schema_migrations VALUES ('346');
INSERT INTO public.schema_migrations VALUES ('347');
INSERT INTO public.schema_migrations VALUES ('348');
INSERT INTO public.schema_migrations VALUES ('349');
INSERT INTO public.schema_migrations VALUES ('350');
INSERT INTO public.schema_migrations VALUES ('351');
INSERT INTO public.schema_migrations VALUES ('352');
INSERT INTO public.schema_migrations VALUES ('353');
INSERT INTO public.schema_migrations VALUES ('354');
INSERT INTO public.schema_migrations VALUES ('355');
INSERT INTO public.schema_migrations VALUES ('356');
INSERT INTO public.schema_migrations VALUES ('357');
INSERT INTO public.schema_migrations VALUES ('358');
INSERT INTO public.schema_migrations VALUES ('359');
INSERT INTO public.schema_migrations VALUES ('360');
INSERT INTO public.schema_migrations VALUES ('361');
INSERT INTO public.schema_migrations VALUES ('362');
INSERT INTO public.schema_migrations VALUES ('363');
INSERT INTO public.schema_migrations VALUES ('364');
INSERT INTO public.schema_migrations VALUES ('365');
INSERT INTO public.schema_migrations VALUES ('366');
INSERT INTO public.schema_migrations VALUES ('367');
INSERT INTO public.schema_migrations VALUES ('368');
INSERT INTO public.schema_migrations VALUES ('369');
INSERT INTO public.schema_migrations VALUES ('370');
INSERT INTO public.schema_migrations VALUES ('371');
INSERT INTO public.schema_migrations VALUES ('372');
INSERT INTO public.schema_migrations VALUES ('373');
INSERT INTO public.schema_migrations VALUES ('374');
INSERT INTO public.schema_migrations VALUES ('375');
INSERT INTO public.schema_migrations VALUES ('376');
INSERT INTO public.schema_migrations VALUES ('377');
INSERT INTO public.schema_migrations VALUES ('378');
INSERT INTO public.schema_migrations VALUES ('379');


--
-- Data for Name: usage_terms; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users VALUES ('299d734b-3c3d-403c-a2d7-85df91dba1d9', 'admin@nowhere', 'admin', NULL, '2017-03-16 17:16:35.735056+01', '2017-03-16 17:16:35.735056+01', '$2a$10$/g09WTHdKhjyrcRzBcV7b.w77LSS2srYBl1tOqdrNf6NrK7DPe3ci', '17363c5b-c7ef-4386-9e0e-5c75b49f8448', NULL, '', 'admin admin@nowhere', NULL, NULL, '{}', false);
INSERT INTO public.users VALUES ('d68ab096-158b-4632-b7f0-672c08f425cc', 'max.albrecht@zhdk.ch', 'malbrech', NULL, '2017-03-16 17:33:27.371634+01', '2017-03-22 13:36:36.783139+01', '$2a$10$nT1z4N47bXvZAujasb6sA.XYEshkDw85n5TV54cuCKatDIqQPXsmu', 'ce6b7dde-6f76-49ba-abe1-9f254d6db68f', '196200', '', 'malbrech max.albrecht@zhdk.ch', NULL, '2017-03-22 13:36:36.748+01', '{}', false);


--
-- Data for Name: visualizations; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: vocabularies; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.vocabularies VALUES ('madek_core', 'Madek Core', 'Das Core-Vokabular ist fester Bestandteil der Software Madek. Es enthält die wichtigsten Metadaten für die Verwaltung von Medieninhalten und ist vordefiniert und unveränderbar.', true, true, NULL, 0, '"de"=>"Madek Core"', '"de"=>"Das Core-Vokabular ist fester Bestandteil der Software Madek. Es enthält die wichtigsten Metadaten für die Verwaltung von Medieninhalten und ist vordefiniert und unveränderbar."');


--
-- Data for Name: vocabulary_api_client_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: vocabulary_group_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: vocabulary_user_permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: zencoder_jobs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.zencoder_jobs VALUES ('eb44cc11-a397-40dd-a694-57c908570e21', '3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8', 356047839, NULL, 'finished', NULL, '{"job"=>{"created_at"=>"2017-03-16T16:37:53Z", "finished_at"=>"2017-03-16T16:38:19Z", "id"=>356047839, "pass_through"=>nil, "privacy"=>false, "state"=>"finished", "submitted_at"=>"2017-03-16T16:37:53Z", "test"=>true, "updated_at"=>"2017-03-16T16:38:19Z", "input_media_file"=>{"audio_bitrate_in_kbps"=>317, "audio_codec"=>"aac", "audio_sample_rate"=>48000, "audio_tracks"=>nil, "channels"=>"2", "created_at"=>"2017-03-16T16:37:53Z", "duration_in_ms"=>5005, "error_class"=>nil, "error_message"=>nil, "file_size_bytes"=>1190633, "finished_at"=>"2017-03-16T16:37:57Z", "format"=>"mpeg4", "frame_rate"=>29.97, "height"=>1080, "id"=>356018779, "md5_checksum"=>nil, "privacy"=>false, "state"=>"finished", "test"=>true, "updated_at"=>"2017-03-16T16:37:57Z", "video_bitrate_in_kbps"=>1556, "video_codec"=>"h264", "width"=>1920, "total_bitrate_in_kbps"=>1873, "url"=>"http://test-blank.madek.zhdk.ch/files/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8?access_hash=71aa02e6-cd0e-4ef1-abb5-886a7a965307"}, "output_media_files"=>[{"audio_bitrate_in_kbps"=>52, "audio_codec"=>"aac", "audio_sample_rate"=>48000, "channels"=>"2", "created_at"=>"2017-03-16T16:37:54Z", "duration_in_ms"=>5000, "error_class"=>nil, "error_message"=>nil, "file_size_bytes"=>68693, "finished_at"=>"2017-03-16T16:38:19Z", "format"=>"mpeg4", "fragment_duration_in_ms"=>nil, "frame_rate"=>29.97, "height"=>348, "id"=>1250996726, "md5_checksum"=>nil, "privacy"=>false, "rfc_6381_audio_codec"=>"mp4a.40.2", "rfc_6381_video_codec"=>"avc1.42001e", "state"=>"finished", "test"=>true, "updated_at"=>"2017-03-16T16:38:19Z", "video_bitrate_in_kbps"=>52, "video_codec"=>"h264", "width"=>620, "label"=>"mp4", "total_bitrate_in_kbps"=>104, "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170316/9eea4c8300506c0b51e542806975ce91/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_mp4.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170316%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170316T163824Z&X-Amz-Expires=86394&X-Amz-SignedHeaders=host&X-Amz-Signature=c4b50a282d883bccc83f77ffb5e28994f66ed6f32245f69eca619200b768576b"}, {"audio_bitrate_in_kbps"=>112, "audio_codec"=>"vorbis", "audio_sample_rate"=>48000, "channels"=>"2", "created_at"=>"2017-03-16T16:37:54Z", "duration_in_ms"=>5000, "error_class"=>nil, "error_message"=>nil, "file_size_bytes"=>223761, "finished_at"=>"2017-03-16T16:38:15Z", "format"=>"webm", "fragment_duration_in_ms"=>nil, "frame_rate"=>29.97, "height"=>1080, "id"=>1250996727, "md5_checksum"=>nil, "privacy"=>false, "rfc_6381_audio_codec"=>"vorbis", "rfc_6381_video_codec"=>"vp8", "state"=>"finished", "test"=>true, "updated_at"=>"2017-03-16T16:38:15Z", "video_bitrate_in_kbps"=>222, "video_codec"=>"vp8", "width"=>1920, "label"=>"webm_HD", "total_bitrate_in_kbps"=>334, "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170316/730b5035174577f8bda3d7ecffa287bb/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_webm_HD.webm?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170316%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170316T163824Z&X-Amz-Expires=86390&X-Amz-SignedHeaders=host&X-Amz-Signature=c3f1d46f3da429a607352ab4ebb4d8c618ec550f940113796984b8f7a9e538fa"}, {"audio_bitrate_in_kbps"=>52, "audio_codec"=>"aac", "audio_sample_rate"=>48000, "channels"=>"2", "created_at"=>"2017-03-16T16:37:54Z", "duration_in_ms"=>5000, "error_class"=>nil, "error_message"=>nil, "file_size_bytes"=>123239, "finished_at"=>"2017-03-16T16:38:08Z", "format"=>"mpeg4", "fragment_duration_in_ms"=>nil, "frame_rate"=>29.97, "height"=>1080, "id"=>1250996728, "md5_checksum"=>nil, "privacy"=>false, "rfc_6381_audio_codec"=>"mp4a.40.2", "rfc_6381_video_codec"=>"avc1.420028", "state"=>"finished", "test"=>true, "updated_at"=>"2017-03-16T16:38:08Z", "video_bitrate_in_kbps"=>140, "video_codec"=>"h264", "width"=>1920, "label"=>"mp4_HD", "total_bitrate_in_kbps"=>192, "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170316/8bf705e8d96a6d92520e103f9af6621d/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_mp4_HD.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170316%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170316T163824Z&X-Amz-Expires=86383&X-Amz-SignedHeaders=host&X-Amz-Signature=0c89d2faccefe33cef42cc9abbe0001ce4c4e753042bccea1d332cc9d69ff1dc"}, {"audio_bitrate_in_kbps"=>112, "audio_codec"=>"vorbis", "audio_sample_rate"=>48000, "channels"=>"2", "created_at"=>"2017-03-16T16:37:54Z", "duration_in_ms"=>5000, "error_class"=>nil, "error_message"=>nil, "file_size_bytes"=>112356, "finished_at"=>"2017-03-16T16:38:05Z", "format"=>"webm", "fragment_duration_in_ms"=>nil, "frame_rate"=>29.97, "height"=>348, "id"=>1250996729, "md5_checksum"=>nil, "privacy"=>false, "rfc_6381_audio_codec"=>"vorbis", "rfc_6381_video_codec"=>"vp8", "state"=>"finished", "test"=>true, "updated_at"=>"2017-03-16T16:38:05Z", "video_bitrate_in_kbps"=>51, "video_codec"=>"vp8", "width"=>620, "label"=>"webm", "total_bitrate_in_kbps"=>163, "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170316/bc3083e3ac4acbf4bb39504f48b2eb9c/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_webm.webm?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170316%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170316T163824Z&X-Amz-Expires=86380&X-Amz-SignedHeaders=host&X-Amz-Signature=e265325a0f09895f9a5cadea33e4227b98885920f1f40b5744ab128ab9eaead9"}], "thumbnails"=>[{"created_at"=>"2017-03-16T16:38:05Z", "file_size_bytes"=>25268, "format"=>"jpg", "group_label"=>nil, "height"=>348, "id"=>2136623574, "updated_at"=>"2017-03-16T16:38:05Z", "width"=>620, "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/t/20170316/14fe2b0796942999dfb61b843dcb43cd/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8_0000.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170316%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170316T163824Z&X-Amz-Expires=86380&X-Amz-SignedHeaders=host&X-Amz-Signature=778fae8c434a57c651a1ce10fad0d711569abc60ef79e55f7ac97b96af2f8d62"}]}}', '{:input=>"http://test-blank.madek.zhdk.ch/files/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8?access_hash=71aa02e6-cd0e-4ef1-abb5-886a7a965307", :notifications=>["http://test-blank.madek.zhdk.ch/zencoder_jobs/eb44cc11-a397-40dd-a694-57c908570e21/notification"], :test=>true, :label=>"Default", :quality=>4, :speed=>2, :width=>620, :outputs=>[{:video_codec=>"h264", :format=>"mp4", :width=>620, :label=>"mp4", :filename=>"3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_mp4.mp4"}, {:format=>"webm", :skip=>#<Pojo min_size="775x580">, :height=>1080, :label=>"webm_HD", :quality=>4, :speed=>2, :filename=>"3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_webm_HD.webm"}, {:video_codec=>"h264", :format=>"mp4", :label=>"mp4_HD", :skip=>#<Pojo min_size="775x580">, :height=>1080, :filename=>"3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_mp4_HD.mp4"}, {:thumbnails=>{:width=>620, :interval=>60, :format=>"jpg", :prefix=>"3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8"}, :format=>"webm", :speed=>2, :label=>"webm", :width=>620, :quality=>4, :filename=>"3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_webm.webm"}]}', '{"id"=>356047839, "outputs"=>[{"id"=>1250996726, "label"=>"mp4", "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170316/9eea4c8300506c0b51e542806975ce91/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_mp4.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170316%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170316T163754Z&X-Amz-Expires=86399&X-Amz-SignedHeaders=host&X-Amz-Signature=1cbac329c07d7f374d424928753a822306ce795d97f9794413b0bb39022dffdf"}, {"id"=>1250996727, "label"=>"webm_HD", "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170316/730b5035174577f8bda3d7ecffa287bb/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_webm_HD.webm?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170316%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170316T163754Z&X-Amz-Expires=86399&X-Amz-SignedHeaders=host&X-Amz-Signature=0b04a170d0056427288b7c01196da46a0c2b416ebde920caa61cb09e14ce416f"}, {"id"=>1250996728, "label"=>"mp4_HD", "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170316/8bf705e8d96a6d92520e103f9af6621d/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_mp4_HD.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170316%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170316T163754Z&X-Amz-Expires=86399&X-Amz-SignedHeaders=host&X-Amz-Signature=c1e99a4829667ac73c56b58c0210c6b7d7317a956c61f08a28889f6053b23c7c"}, {"id"=>1250996729, "label"=>"webm", "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170316/bc3083e3ac4acbf4bb39504f48b2eb9c/3b9ba56e-75c9-48c0-8b3d-a3ca0af12bf8.profile_webm.webm?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170316%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170316T163754Z&X-Amz-Expires=86399&X-Amz-SignedHeaders=host&X-Amz-Signature=ac2fdad2f7fe77f143c3e5c27ec7259d602511f6f69a6194ae4cb04bb69fe08b"}], "test"=>true}', '2017-03-16 17:37:52.48173+01', '2017-03-16 17:38:30.760362+01', 100, '{mp4,mp4_HD,webm,webm_HD}');
INSERT INTO public.zencoder_jobs VALUES ('2affcbf2-af1b-48e6-b425-65130e3a9eb3', '25f76d98-afad-4e4c-a383-77ea8bebe3ed', 357590507, NULL, 'finished', NULL, '{"job"=>{"created_at"=>"2017-03-22T12:08:04Z", "finished_at"=>"2017-03-22T12:08:15Z", "id"=>357590507, "pass_through"=>nil, "privacy"=>false, "state"=>"finished", "submitted_at"=>"2017-03-22T12:08:04Z", "test"=>true, "updated_at"=>"2017-03-22T12:08:15Z", "input_media_file"=>{"audio_bitrate_in_kbps"=>33, "audio_codec"=>"aac", "audio_sample_rate"=>22050, "audio_tracks"=>nil, "channels"=>"1", "created_at"=>"2017-03-22T12:08:04Z", "duration_in_ms"=>12260, "error_class"=>nil, "error_message"=>nil, "file_size_bytes"=>51441, "finished_at"=>"2017-03-22T12:08:07Z", "format"=>"adts", "frame_rate"=>nil, "height"=>nil, "id"=>357561447, "md5_checksum"=>nil, "privacy"=>false, "state"=>"finished", "test"=>true, "updated_at"=>"2017-03-22T12:08:07Z", "video_bitrate_in_kbps"=>nil, "video_codec"=>nil, "width"=>nil, "total_bitrate_in_kbps"=>nil, "url"=>"http://test-blank.madek.zhdk.ch/files/25f76d98-afad-4e4c-a383-77ea8bebe3ed?access_hash=b72edb2c-2e21-4c7e-ac7a-c625beff4b22"}, "output_media_files"=>[{"audio_bitrate_in_kbps"=>30, "audio_codec"=>"mp3", "audio_sample_rate"=>22050, "channels"=>"1", "created_at"=>"2017-03-22T12:08:04Z", "duration_in_ms"=>5000, "error_class"=>nil, "error_message"=>nil, "file_size_bytes"=>19299, "finished_at"=>"2017-03-22T12:08:15Z", "format"=>"mpeg audio", "fragment_duration_in_ms"=>nil, "frame_rate"=>nil, "height"=>nil, "id"=>1257316198, "md5_checksum"=>nil, "privacy"=>false, "rfc_6381_audio_codec"=>"mp4a.40.34", "rfc_6381_video_codec"=>nil, "state"=>"finished", "test"=>true, "updated_at"=>"2017-03-22T12:08:15Z", "video_bitrate_in_kbps"=>nil, "video_codec"=>nil, "width"=>nil, "label"=>"mp3", "total_bitrate_in_kbps"=>30, "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170322/27be68435cd5355a233229f6be05cbbd/25f76d98-afad-4e4c-a383-77ea8bebe3ed.profile_mp3.mp3?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170322%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170322T120817Z&X-Amz-Expires=86398&X-Amz-SignedHeaders=host&X-Amz-Signature=d722e4c60cd682944b2e44fc35381f90315af91644d4146db92f47563e1d4903"}, {"audio_bitrate_in_kbps"=>34, "audio_codec"=>"vorbis", "audio_sample_rate"=>22050, "channels"=>"1", "created_at"=>"2017-03-22T12:08:04Z", "duration_in_ms"=>5000, "error_class"=>nil, "error_message"=>nil, "file_size_bytes"=>25038, "finished_at"=>"2017-03-22T12:08:11Z", "format"=>"ogg", "fragment_duration_in_ms"=>nil, "frame_rate"=>nil, "height"=>nil, "id"=>1257316199, "md5_checksum"=>nil, "privacy"=>false, "rfc_6381_audio_codec"=>"vorbis", "rfc_6381_video_codec"=>nil, "state"=>"finished", "test"=>true, "updated_at"=>"2017-03-22T12:08:11Z", "video_bitrate_in_kbps"=>nil, "video_codec"=>nil, "width"=>nil, "label"=>"vorbis", "total_bitrate_in_kbps"=>34, "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170322/6b337b84c3333dfbfdd001fb29dda390/25f76d98-afad-4e4c-a383-77ea8bebe3ed.profile_vorbis.ogg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170322%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170322T120817Z&X-Amz-Expires=86393&X-Amz-SignedHeaders=host&X-Amz-Signature=2a5dd7c2e38ee3b8f836349653932bf073df23f80e0b6413dc1f16acd1e5892e"}], "thumbnails"=>[]}}', '{:input=>"http://test-blank.madek.zhdk.ch/files/25f76d98-afad-4e4c-a383-77ea8bebe3ed?access_hash=b72edb2c-2e21-4c7e-ac7a-c625beff4b22", :notifications=>["http://test-blank.madek.zhdk.ch/zencoder_jobs/2affcbf2-af1b-48e6-b425-65130e3a9eb3/notification"], :test=>true, :label=>"Default", :quality=>4, :speed=>2, :width=>620, :outputs=>[{:skip_video=>true, :audio_codec=>"mp3", :format=>"mp3", :label=>"mp3", :filename=>"25f76d98-afad-4e4c-a383-77ea8bebe3ed.profile_mp3.mp3"}, {:skip_video=>true, :audio_codec=>"vorbis", :format=>"ogg", :label=>"vorbis", :filename=>"25f76d98-afad-4e4c-a383-77ea8bebe3ed.profile_vorbis.ogg"}]}', '{"id"=>357590507, "outputs"=>[{"id"=>1257316198, "label"=>"mp3", "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170322/27be68435cd5355a233229f6be05cbbd/25f76d98-afad-4e4c-a383-77ea8bebe3ed.profile_mp3.mp3?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170322%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170322T120804Z&X-Amz-Expires=86399&X-Amz-SignedHeaders=host&X-Amz-Signature=fb8df0f8b6a5cee32f32450e3b261d9746f30118cc3a261e67ef269b38a80c5c"}, {"id"=>1257316199, "label"=>"vorbis", "url"=>"https://zencoder-temp-storage-us-east-1.s3.amazonaws.com/o/20170322/6b337b84c3333dfbfdd001fb29dda390/25f76d98-afad-4e4c-a383-77ea8bebe3ed.profile_vorbis.ogg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAI456JQ76GBU7FECA%2F20170322%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20170322T120804Z&X-Amz-Expires=86399&X-Amz-SignedHeaders=host&X-Amz-Signature=b9878ed0ffd2338e98e56d7cec4698fb027172f89a54727c9949009305060d34"}], "test"=>true}', '2017-03-22 13:08:03.541613+01', '2017-03-22 13:08:19.356932+01', 100, '{mp3,vorbis}');


--
-- Name: admins admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: api_clients api_clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_clients
    ADD CONSTRAINT api_clients_pkey PRIMARY KEY (id);


--
-- Name: api_tokens api_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_tokens
    ADD CONSTRAINT api_tokens_pkey PRIMARY KEY (id);


--
-- Name: api_tokens api_tokens_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_tokens
    ADD CONSTRAINT api_tokens_token_hash_key UNIQUE (token_hash);


--
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (id);


--
-- Name: collection_api_client_permissions collection_api_client_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_api_client_permissions
    ADD CONSTRAINT collection_api_client_permissions_pkey PRIMARY KEY (id);


--
-- Name: collection_collection_arcs collection_collection_arcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_collection_arcs
    ADD CONSTRAINT collection_collection_arcs_pkey PRIMARY KEY (id);


--
-- Name: collection_filter_set_arcs collection_filter_set_arcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_filter_set_arcs
    ADD CONSTRAINT collection_filter_set_arcs_pkey PRIMARY KEY (id);


--
-- Name: collection_group_permissions collection_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_group_permissions
    ADD CONSTRAINT collection_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: collection_media_entry_arcs collection_media_entry_arcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_media_entry_arcs
    ADD CONSTRAINT collection_media_entry_arcs_pkey PRIMARY KEY (id);


--
-- Name: collection_user_permissions collection_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_user_permissions
    ADD CONSTRAINT collection_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: collections collections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_pkey PRIMARY KEY (id);


--
-- Name: confidential_links confidential_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confidential_links
    ADD CONSTRAINT confidential_links_pkey PRIMARY KEY (id);


--
-- Name: contexts contexts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contexts
    ADD CONSTRAINT contexts_pkey PRIMARY KEY (id);


--
-- Name: custom_urls custom_urls_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_urls
    ADD CONSTRAINT custom_urls_pkey PRIMARY KEY (id);


--
-- Name: edit_sessions edit_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edit_sessions
    ADD CONSTRAINT edit_sessions_pkey PRIMARY KEY (id);


--
-- Name: filter_set_api_client_permissions filter_set_api_client_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_api_client_permissions
    ADD CONSTRAINT filter_set_api_client_permissions_pkey PRIMARY KEY (id);


--
-- Name: filter_set_group_permissions filter_set_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_group_permissions
    ADD CONSTRAINT filter_set_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: filter_set_user_permissions filter_set_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_user_permissions
    ADD CONSTRAINT filter_set_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: filter_sets filter_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_sets
    ADD CONSTRAINT filter_sets_pkey PRIMARY KEY (id);


--
-- Name: full_texts full_texts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.full_texts
    ADD CONSTRAINT full_texts_pkey PRIMARY KEY (media_resource_id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: io_interfaces io_interfaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.io_interfaces
    ADD CONSTRAINT io_interfaces_pkey PRIMARY KEY (id);


--
-- Name: io_mappings io_mappings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.io_mappings
    ADD CONSTRAINT io_mappings_pkey PRIMARY KEY (id);


--
-- Name: keywords keyword_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.keywords
    ADD CONSTRAINT keyword_terms_pkey PRIMARY KEY (id);


--
-- Name: meta_data_keywords keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_keywords
    ADD CONSTRAINT keywords_pkey PRIMARY KEY (id);


--
-- Name: media_entries media_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entries
    ADD CONSTRAINT media_entries_pkey PRIMARY KEY (id);


--
-- Name: media_entry_api_client_permissions media_entry_api_client_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_api_client_permissions
    ADD CONSTRAINT media_entry_api_client_permissions_pkey PRIMARY KEY (id);


--
-- Name: media_entry_group_permissions media_entry_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_group_permissions
    ADD CONSTRAINT media_entry_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: media_entry_user_permissions media_entry_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_user_permissions
    ADD CONSTRAINT media_entry_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: media_files media_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT media_files_pkey PRIMARY KEY (id);


--
-- Name: meta_data_people meta_data_people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_people
    ADD CONSTRAINT meta_data_people_pkey PRIMARY KEY (id);


--
-- Name: meta_data meta_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data
    ADD CONSTRAINT meta_data_pkey PRIMARY KEY (id);


--
-- Name: meta_data_roles meta_data_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_roles
    ADD CONSTRAINT meta_data_roles_pkey PRIMARY KEY (id);


--
-- Name: context_keys meta_key_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_keys
    ADD CONSTRAINT meta_key_definitions_pkey PRIMARY KEY (id);


--
-- Name: meta_keys meta_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_keys
    ADD CONSTRAINT meta_keys_pkey PRIMARY KEY (id);


--
-- Name: people people_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.people
    ADD CONSTRAINT people_pkey PRIMARY KEY (id);


--
-- Name: previews previews_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.previews
    ADD CONSTRAINT previews_pkey PRIMARY KEY (id);


--
-- Name: rdf_classes rdf_classes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rdf_classes
    ADD CONSTRAINT rdf_classes_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: usage_terms usage_terms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usage_terms
    ADD CONSTRAINT usage_terms_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: visualizations visualizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visualizations
    ADD CONSTRAINT visualizations_pkey PRIMARY KEY (id);


--
-- Name: vocabularies vocabularies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabularies
    ADD CONSTRAINT vocabularies_pkey PRIMARY KEY (id);


--
-- Name: vocabulary_api_client_permissions vocabulary_api_client_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_api_client_permissions
    ADD CONSTRAINT vocabulary_api_client_permissions_pkey PRIMARY KEY (id);


--
-- Name: vocabulary_group_permissions vocabulary_group_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_group_permissions
    ADD CONSTRAINT vocabulary_group_permissions_pkey PRIMARY KEY (id);


--
-- Name: vocabulary_user_permissions vocabulary_user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_user_permissions
    ADD CONSTRAINT vocabulary_user_permissions_pkey PRIMARY KEY (id);


--
-- Name: zencoder_jobs zencoder_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zencoder_jobs
    ADD CONSTRAINT zencoder_jobs_pkey PRIMARY KEY (id);


--
-- Name: full_texts_text_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX full_texts_text_idx ON public.full_texts USING gin (text public.gin_trgm_ops);


--
-- Name: full_texts_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX full_texts_to_tsvector_idx ON public.full_texts USING gin (to_tsvector('english'::regconfig, text));


--
-- Name: groups_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_searchable_idx ON public.groups USING gin (searchable public.gin_trgm_ops);


--
-- Name: groups_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX groups_to_tsvector_idx ON public.groups USING gin (to_tsvector('english'::regconfig, searchable));


--
-- Name: idx_colgrpp_edit_mdata_and_relations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colgrpp_edit_mdata_and_relations ON public.collection_group_permissions USING btree (edit_metadata_and_relations);


--
-- Name: idx_colgrpp_get_mdata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colgrpp_get_mdata_and_previews ON public.collection_group_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_colgrpp_on_collection_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_colgrpp_on_collection_id_and_group_id ON public.collection_group_permissions USING btree (collection_id, group_id);


--
-- Name: idx_colgrpp_on_filter_set_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_colgrpp_on_filter_set_id_and_group_id ON public.filter_set_group_permissions USING btree (filter_set_id, group_id);


--
-- Name: idx_collapiclp_edit_mdata_and_relations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collapiclp_edit_mdata_and_relations ON public.collection_api_client_permissions USING btree (edit_metadata_and_relations);


--
-- Name: idx_collapiclp_get_mdata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_collapiclp_get_mdata_and_previews ON public.collection_api_client_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_collapiclp_on_collection_id_and_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_collapiclp_on_collection_id_and_api_client_id ON public.collection_api_client_permissions USING btree (collection_id, api_client_id);


--
-- Name: idx_collection_user_permission; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_collection_user_permission ON public.collection_user_permissions USING btree (collection_id, user_id);


--
-- Name: idx_colluserperm_edit_metadata_and_relations; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colluserperm_edit_metadata_and_relations ON public.collection_user_permissions USING btree (edit_metadata_and_relations);


--
-- Name: idx_colluserperm_edit_permissions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colluserperm_edit_permissions ON public.collection_user_permissions USING btree (edit_permissions);


--
-- Name: idx_colluserperm_get_metadata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_colluserperm_get_metadata_and_previews ON public.collection_user_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_fsetapiclp_edit_mdata_and_filter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fsetapiclp_edit_mdata_and_filter ON public.filter_set_api_client_permissions USING btree (edit_metadata_and_filter);


--
-- Name: idx_fsetapiclp_get_mdata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fsetapiclp_get_mdata_and_previews ON public.filter_set_api_client_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_fsetapiclp_on_filter_set_id_and_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_fsetapiclp_on_filter_set_id_and_api_client_id ON public.filter_set_api_client_permissions USING btree (filter_set_id, api_client_id);


--
-- Name: idx_fsetusrp_on_filter_set_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_fsetusrp_on_filter_set_id_and_user_id ON public.filter_set_user_permissions USING btree (filter_set_id, user_id);


--
-- Name: idx_me_apicl_get_mdata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_me_apicl_get_mdata_and_previews ON public.media_entry_api_client_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_media_entry_user_permission; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_media_entry_user_permission ON public.media_entry_user_permissions USING btree (media_entry_id, user_id);


--
-- Name: idx_megrpp_get_full_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_megrpp_get_full_size ON public.media_entry_api_client_permissions USING btree (get_full_size);


--
-- Name: idx_megrpp_get_mdata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_megrpp_get_mdata_and_previews ON public.media_entry_group_permissions USING btree (get_metadata_and_previews);


--
-- Name: idx_megrpp_on_media_entry_id_and_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_megrpp_on_media_entry_id_and_api_client_id ON public.media_entry_api_client_permissions USING btree (media_entry_id, api_client_id);


--
-- Name: idx_megrpp_on_media_entry_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_megrpp_on_media_entry_id_and_group_id ON public.media_entry_group_permissions USING btree (media_entry_id, group_id);


--
-- Name: idx_vocabulary_api_client; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_vocabulary_api_client ON public.vocabulary_api_client_permissions USING btree (api_client_id, vocabulary_id);


--
-- Name: idx_vocabulary_group; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_vocabulary_group ON public.vocabulary_group_permissions USING btree (group_id, vocabulary_id);


--
-- Name: idx_vocabulary_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_vocabulary_user ON public.vocabulary_user_permissions USING btree (user_id, vocabulary_id);


--
-- Name: index_admins_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_admins_on_user_id ON public.admins USING btree (user_id);


--
-- Name: index_api_clients_on_login; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_api_clients_on_login ON public.api_clients USING btree (login);


--
-- Name: index_collection_api_client_permissions_on_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_api_client_permissions_on_api_client_id ON public.collection_api_client_permissions USING btree (api_client_id);


--
-- Name: index_collection_api_client_permissions_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_api_client_permissions_on_collection_id ON public.collection_api_client_permissions USING btree (collection_id);


--
-- Name: index_collection_api_client_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_api_client_permissions_on_updator_id ON public.collection_api_client_permissions USING btree (updator_id);


--
-- Name: index_collection_collection_arcs_on_child_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_collection_arcs_on_child_id ON public.collection_collection_arcs USING btree (child_id);


--
-- Name: index_collection_collection_arcs_on_child_id_and_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_collection_arcs_on_child_id_and_parent_id ON public.collection_collection_arcs USING btree (child_id, parent_id);


--
-- Name: index_collection_collection_arcs_on_parent_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_collection_arcs_on_parent_id ON public.collection_collection_arcs USING btree (parent_id);


--
-- Name: index_collection_collection_arcs_on_parent_id_and_child_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collection_collection_arcs_on_parent_id_and_child_id ON public.collection_collection_arcs USING btree (parent_id, child_id);


--
-- Name: index_collection_filter_set_arcs_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_filter_set_arcs_on_collection_id ON public.collection_filter_set_arcs USING btree (collection_id);


--
-- Name: index_collection_filter_set_arcs_on_collection_id_and_filter_se; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collection_filter_set_arcs_on_collection_id_and_filter_se ON public.collection_filter_set_arcs USING btree (collection_id, filter_set_id);


--
-- Name: index_collection_filter_set_arcs_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_filter_set_arcs_on_filter_set_id ON public.collection_filter_set_arcs USING btree (filter_set_id);


--
-- Name: index_collection_filter_set_arcs_on_filter_set_id_and_collectio; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_filter_set_arcs_on_filter_set_id_and_collectio ON public.collection_filter_set_arcs USING btree (filter_set_id, collection_id);


--
-- Name: index_collection_group_permissions_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_group_permissions_on_collection_id ON public.collection_group_permissions USING btree (collection_id);


--
-- Name: index_collection_group_permissions_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_group_permissions_on_group_id ON public.collection_group_permissions USING btree (group_id);


--
-- Name: index_collection_group_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_group_permissions_on_updator_id ON public.collection_group_permissions USING btree (updator_id);


--
-- Name: index_collection_media_entry_arcs_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_media_entry_arcs_on_collection_id ON public.collection_media_entry_arcs USING btree (collection_id);


--
-- Name: index_collection_media_entry_arcs_on_collection_id_and_media_en; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collection_media_entry_arcs_on_collection_id_and_media_en ON public.collection_media_entry_arcs USING btree (collection_id, media_entry_id);


--
-- Name: index_collection_media_entry_arcs_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_media_entry_arcs_on_media_entry_id ON public.collection_media_entry_arcs USING btree (media_entry_id);


--
-- Name: index_collection_media_entry_arcs_on_media_entry_id_and_collect; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_media_entry_arcs_on_media_entry_id_and_collect ON public.collection_media_entry_arcs USING btree (media_entry_id, collection_id);


--
-- Name: index_collection_user_permissions_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_user_permissions_on_collection_id ON public.collection_user_permissions USING btree (collection_id);


--
-- Name: index_collection_user_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_user_permissions_on_updator_id ON public.collection_user_permissions USING btree (updator_id);


--
-- Name: index_collection_user_permissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collection_user_permissions_on_user_id ON public.collection_user_permissions USING btree (user_id);


--
-- Name: index_collections_on_clipboard_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_collections_on_clipboard_user_id ON public.collections USING btree (clipboard_user_id);


--
-- Name: index_collections_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_created_at ON public.collections USING btree (created_at);


--
-- Name: index_collections_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_creator_id ON public.collections USING btree (creator_id);


--
-- Name: index_collections_on_edit_session_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_edit_session_updated_at ON public.collections USING btree (edit_session_updated_at);


--
-- Name: index_collections_on_meta_data_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_meta_data_updated_at ON public.collections USING btree (meta_data_updated_at);


--
-- Name: index_collections_on_responsible_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_responsible_user_id ON public.collections USING btree (responsible_user_id);


--
-- Name: index_collections_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_collections_on_updated_at ON public.collections USING btree (updated_at);


--
-- Name: index_confidential_links_on_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_confidential_links_on_resource_type_and_resource_id ON public.confidential_links USING btree (resource_type, resource_id);


--
-- Name: index_context_keys_on_context_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_keys_on_context_id ON public.context_keys USING btree (context_id);


--
-- Name: index_context_keys_on_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_context_keys_on_meta_key_id ON public.context_keys USING btree (meta_key_id);


--
-- Name: index_custom_urls_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_urls_on_creator_id ON public.custom_urls USING btree (creator_id);


--
-- Name: index_custom_urls_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_urls_on_updator_id ON public.custom_urls USING btree (updator_id);


--
-- Name: index_edit_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_edit_sessions_on_user_id ON public.edit_sessions USING btree (user_id);


--
-- Name: index_favorite_collections_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_collections_on_collection_id ON public.favorite_collections USING btree (collection_id);


--
-- Name: index_favorite_collections_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_collections_on_user_id ON public.favorite_collections USING btree (user_id);


--
-- Name: index_favorite_collections_on_user_id_and_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorite_collections_on_user_id_and_collection_id ON public.favorite_collections USING btree (user_id, collection_id);


--
-- Name: index_favorite_filter_sets_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_filter_sets_on_filter_set_id ON public.favorite_filter_sets USING btree (filter_set_id);


--
-- Name: index_favorite_filter_sets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_filter_sets_on_user_id ON public.favorite_filter_sets USING btree (user_id);


--
-- Name: index_favorite_filter_sets_on_user_id_and_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorite_filter_sets_on_user_id_and_filter_set_id ON public.favorite_filter_sets USING btree (user_id, filter_set_id);


--
-- Name: index_favorite_media_entries_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_media_entries_on_media_entry_id ON public.favorite_media_entries USING btree (media_entry_id);


--
-- Name: index_favorite_media_entries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favorite_media_entries_on_user_id ON public.favorite_media_entries USING btree (user_id);


--
-- Name: index_favorite_media_entries_on_user_id_and_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favorite_media_entries_on_user_id_and_media_entry_id ON public.favorite_media_entries USING btree (user_id, media_entry_id);


--
-- Name: index_filter_set_api_client_permissions_on_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_api_client_permissions_on_api_client_id ON public.filter_set_api_client_permissions USING btree (api_client_id);


--
-- Name: index_filter_set_api_client_permissions_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_api_client_permissions_on_filter_set_id ON public.filter_set_api_client_permissions USING btree (filter_set_id);


--
-- Name: index_filter_set_api_client_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_api_client_permissions_on_updator_id ON public.filter_set_api_client_permissions USING btree (updator_id);


--
-- Name: index_filter_set_group_permissions_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_group_permissions_on_filter_set_id ON public.filter_set_group_permissions USING btree (filter_set_id);


--
-- Name: index_filter_set_group_permissions_on_get_metadata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_group_permissions_on_get_metadata_and_previews ON public.filter_set_group_permissions USING btree (get_metadata_and_previews);


--
-- Name: index_filter_set_group_permissions_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_group_permissions_on_group_id ON public.filter_set_group_permissions USING btree (group_id);


--
-- Name: index_filter_set_group_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_group_permissions_on_updator_id ON public.filter_set_group_permissions USING btree (updator_id);


--
-- Name: index_filter_set_user_permissions_on_edit_metadata_and_filter; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_edit_metadata_and_filter ON public.filter_set_user_permissions USING btree (edit_metadata_and_filter);


--
-- Name: index_filter_set_user_permissions_on_edit_permissions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_edit_permissions ON public.filter_set_user_permissions USING btree (edit_permissions);


--
-- Name: index_filter_set_user_permissions_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_filter_set_id ON public.filter_set_user_permissions USING btree (filter_set_id);


--
-- Name: index_filter_set_user_permissions_on_get_metadata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_get_metadata_and_previews ON public.filter_set_user_permissions USING btree (get_metadata_and_previews);


--
-- Name: index_filter_set_user_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_updator_id ON public.filter_set_user_permissions USING btree (updator_id);


--
-- Name: index_filter_set_user_permissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_set_user_permissions_on_user_id ON public.filter_set_user_permissions USING btree (user_id);


--
-- Name: index_filter_sets_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_sets_on_created_at ON public.filter_sets USING btree (created_at);


--
-- Name: index_filter_sets_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_sets_on_creator_id ON public.filter_sets USING btree (creator_id);


--
-- Name: index_filter_sets_on_edit_session_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_sets_on_edit_session_updated_at ON public.filter_sets USING btree (edit_session_updated_at);


--
-- Name: index_filter_sets_on_meta_data_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_sets_on_meta_data_updated_at ON public.filter_sets USING btree (meta_data_updated_at);


--
-- Name: index_filter_sets_on_responsible_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_sets_on_responsible_user_id ON public.filter_sets USING btree (responsible_user_id);


--
-- Name: index_filter_sets_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_filter_sets_on_updated_at ON public.filter_sets USING btree (updated_at);


--
-- Name: index_groups_on_institutional_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_institutional_id ON public.groups USING btree (institutional_id);


--
-- Name: index_groups_on_institutional_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_institutional_name ON public.groups USING btree (institutional_name);


--
-- Name: index_groups_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_name ON public.groups USING btree (name);


--
-- Name: index_groups_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_on_type ON public.groups USING btree (type);


--
-- Name: index_groups_users_on_group_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_groups_users_on_group_id_and_user_id ON public.groups_users USING btree (group_id, user_id);


--
-- Name: index_groups_users_on_user_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_users_on_user_id_and_group_id ON public.groups_users USING btree (user_id, group_id);


--
-- Name: index_keywords_on_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_keywords_on_meta_key_id ON public.keywords USING btree (meta_key_id);


--
-- Name: index_keywords_on_meta_key_id_and_term; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_keywords_on_meta_key_id_and_term ON public.keywords USING btree (meta_key_id, term);


--
-- Name: index_keywords_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_keywords_on_position ON public.keywords USING btree ("position");


--
-- Name: index_md_people_on_md_id_and_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_md_people_on_md_id_and_person_id ON public.meta_data_people USING btree (meta_datum_id, person_id);


--
-- Name: index_md_users_on_md_id_and_keyword_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_md_users_on_md_id_and_keyword_id ON public.meta_data_keywords USING btree (meta_datum_id, keyword_id);


--
-- Name: index_media_entries_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_created_at ON public.media_entries USING btree (created_at);


--
-- Name: index_media_entries_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_creator_id ON public.media_entries USING btree (creator_id);


--
-- Name: index_media_entries_on_edit_session_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_edit_session_updated_at ON public.media_entries USING btree (edit_session_updated_at);


--
-- Name: index_media_entries_on_is_published; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_is_published ON public.media_entries USING btree (is_published);


--
-- Name: index_media_entries_on_meta_data_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_meta_data_updated_at ON public.media_entries USING btree (meta_data_updated_at);


--
-- Name: index_media_entries_on_responsible_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_responsible_user_id ON public.media_entries USING btree (responsible_user_id);


--
-- Name: index_media_entries_on_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entries_on_updated_at ON public.media_entries USING btree (updated_at);


--
-- Name: index_media_entry_api_client_permissions_on_api_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_api_client_permissions_on_api_client_id ON public.media_entry_api_client_permissions USING btree (api_client_id);


--
-- Name: index_media_entry_api_client_permissions_on_get_full_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_api_client_permissions_on_get_full_size ON public.media_entry_api_client_permissions USING btree (get_full_size);


--
-- Name: index_media_entry_api_client_permissions_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_api_client_permissions_on_media_entry_id ON public.media_entry_api_client_permissions USING btree (media_entry_id);


--
-- Name: index_media_entry_api_client_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_api_client_permissions_on_updator_id ON public.media_entry_api_client_permissions USING btree (updator_id);


--
-- Name: index_media_entry_group_permissions_on_edit_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_group_permissions_on_edit_metadata ON public.media_entry_group_permissions USING btree (edit_metadata);


--
-- Name: index_media_entry_group_permissions_on_get_full_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_group_permissions_on_get_full_size ON public.media_entry_group_permissions USING btree (get_full_size);


--
-- Name: index_media_entry_group_permissions_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_group_permissions_on_group_id ON public.media_entry_group_permissions USING btree (group_id);


--
-- Name: index_media_entry_group_permissions_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_group_permissions_on_media_entry_id ON public.media_entry_group_permissions USING btree (media_entry_id);


--
-- Name: index_media_entry_group_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_group_permissions_on_updator_id ON public.media_entry_group_permissions USING btree (updator_id);


--
-- Name: index_media_entry_user_permissions_on_edit_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_edit_metadata ON public.media_entry_user_permissions USING btree (edit_metadata);


--
-- Name: index_media_entry_user_permissions_on_edit_permissions; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_edit_permissions ON public.media_entry_user_permissions USING btree (edit_permissions);


--
-- Name: index_media_entry_user_permissions_on_get_full_size; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_get_full_size ON public.media_entry_user_permissions USING btree (get_full_size);


--
-- Name: index_media_entry_user_permissions_on_get_metadata_and_previews; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_get_metadata_and_previews ON public.media_entry_user_permissions USING btree (get_metadata_and_previews);


--
-- Name: index_media_entry_user_permissions_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_media_entry_id ON public.media_entry_user_permissions USING btree (media_entry_id);


--
-- Name: index_media_entry_user_permissions_on_updator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_updator_id ON public.media_entry_user_permissions USING btree (updator_id);


--
-- Name: index_media_entry_user_permissions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_entry_user_permissions_on_user_id ON public.media_entry_user_permissions USING btree (user_id);


--
-- Name: index_media_files_on_extension; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_files_on_extension ON public.media_files USING btree (extension);


--
-- Name: index_media_files_on_filename; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_files_on_filename ON public.media_files USING btree (filename);


--
-- Name: index_media_files_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_files_on_media_entry_id ON public.media_files USING btree (media_entry_id);


--
-- Name: index_media_files_on_media_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_files_on_media_type ON public.media_files USING btree (media_type);


--
-- Name: index_meta_data_keywords_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_keywords_on_created_at ON public.meta_data_keywords USING btree (created_at);


--
-- Name: index_meta_data_keywords_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_keywords_on_created_by_id ON public.meta_data_keywords USING btree (created_by_id);


--
-- Name: index_meta_data_keywords_on_keyword_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_keywords_on_keyword_id ON public.meta_data_keywords USING btree (keyword_id);


--
-- Name: index_meta_data_keywords_on_meta_datum_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_keywords_on_meta_datum_id ON public.meta_data_keywords USING btree (meta_datum_id);


--
-- Name: index_meta_data_meta_terms_on_meta_datum_id_and_meta_term_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_meta_data_meta_terms_on_meta_datum_id_and_meta_term_id ON public.meta_data_meta_terms USING btree (meta_datum_id, meta_term_id);


--
-- Name: index_meta_data_on_collection_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_on_collection_id ON public.meta_data USING btree (collection_id);


--
-- Name: index_meta_data_on_collection_id_and_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_meta_data_on_collection_id_and_meta_key_id ON public.meta_data USING btree (collection_id, meta_key_id);


--
-- Name: index_meta_data_on_filter_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_on_filter_set_id ON public.meta_data USING btree (filter_set_id);


--
-- Name: index_meta_data_on_filter_set_id_and_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_meta_data_on_filter_set_id_and_meta_key_id ON public.meta_data USING btree (filter_set_id, meta_key_id);


--
-- Name: index_meta_data_on_media_entry_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_on_media_entry_id ON public.meta_data USING btree (media_entry_id);


--
-- Name: index_meta_data_on_media_entry_id_and_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_meta_data_on_media_entry_id_and_meta_key_id ON public.meta_data USING btree (media_entry_id, meta_key_id);


--
-- Name: index_meta_data_on_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_on_meta_key_id ON public.meta_data USING btree (meta_key_id);


--
-- Name: index_meta_data_on_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_on_type ON public.meta_data USING btree (type);


--
-- Name: index_meta_data_roles_on_meta_datum_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_roles_on_meta_datum_id ON public.meta_data_roles USING btree (meta_datum_id);


--
-- Name: index_meta_data_roles_on_person_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_roles_on_person_id ON public.meta_data_roles USING btree (person_id);


--
-- Name: index_meta_data_roles_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_roles_on_position ON public.meta_data_roles USING btree ("position");


--
-- Name: index_meta_data_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_meta_data_roles_on_role_id ON public.meta_data_roles USING btree (role_id);


--
-- Name: index_people_on_first_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_people_on_first_name ON public.people USING btree (first_name);


--
-- Name: index_people_on_institutional_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_people_on_institutional_id ON public.people USING btree (institutional_id);


--
-- Name: index_people_on_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_people_on_last_name ON public.people USING btree (last_name);


--
-- Name: index_previews_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_previews_on_created_at ON public.previews USING btree (created_at);


--
-- Name: index_previews_on_media_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_previews_on_media_file_id ON public.previews USING btree (media_file_id);


--
-- Name: index_previews_on_media_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_previews_on_media_type ON public.previews USING btree (media_type);


--
-- Name: index_roles_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_creator_id ON public.roles USING btree (creator_id);


--
-- Name: index_roles_on_meta_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_meta_key_id ON public.roles USING btree (meta_key_id);


--
-- Name: index_roles_on_meta_key_id_and_labels; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_roles_on_meta_key_id_and_labels ON public.roles USING btree (meta_key_id, labels);


--
-- Name: index_users_on_autocomplete; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_autocomplete ON public.users USING btree (autocomplete);


--
-- Name: index_users_on_institutional_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_institutional_id ON public.users USING btree (institutional_id);


--
-- Name: index_users_on_login; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_login ON public.users USING btree (login);


--
-- Name: index_vocabularies_on_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_vocabularies_on_position ON public.vocabularies USING btree ("position");


--
-- Name: index_zencoder_jobs_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zencoder_jobs_on_created_at ON public.zencoder_jobs USING btree (created_at);


--
-- Name: index_zencoder_jobs_on_media_file_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zencoder_jobs_on_media_file_id ON public.zencoder_jobs USING btree (media_file_id);


--
-- Name: index_zencoder_jobs_on_request; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zencoder_jobs_on_request ON public.zencoder_jobs USING btree (request);


--
-- Name: index_zencoder_jobs_on_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_zencoder_jobs_on_state ON public.zencoder_jobs USING btree (state);


--
-- Name: keyword_terms_term_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX keyword_terms_term_idx ON public.keywords USING gin (term public.gin_trgm_ops);


--
-- Name: keyword_terms_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX keyword_terms_to_tsvector_idx ON public.keywords USING gin (to_tsvector('english'::regconfig, (term)::text));


--
-- Name: meta_data_string_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meta_data_string_idx ON public.meta_data USING gin (string public.gin_trgm_ops);


--
-- Name: meta_data_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX meta_data_to_tsvector_idx ON public.meta_data USING gin (to_tsvector('english'::regconfig, string));


--
-- Name: people_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX people_searchable_idx ON public.people USING gin (searchable public.gin_trgm_ops);


--
-- Name: people_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX people_to_tsvector_idx ON public.people USING gin (to_tsvector('english'::regconfig, searchable));


--
-- Name: unique_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_email_idx ON public.users USING btree (lower((email)::text));


--
-- Name: unique_login_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_login_idx ON public.users USING btree (login);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: users_searchable_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_searchable_idx ON public.users USING gin (searchable public.gin_trgm_ops);


--
-- Name: users_to_tsvector_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX users_to_tsvector_idx ON public.users USING gin (to_tsvector('english'::regconfig, searchable));


--
-- Name: edit_sessions propagate_edit_session_insert_to_collections; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER propagate_edit_session_insert_to_collections AFTER INSERT ON public.edit_sessions FOR EACH ROW EXECUTE PROCEDURE public.propagate_edit_session_insert_to_collections();


--
-- Name: edit_sessions propagate_edit_session_insert_to_filter_sets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER propagate_edit_session_insert_to_filter_sets AFTER INSERT ON public.edit_sessions FOR EACH ROW EXECUTE PROCEDURE public.propagate_edit_session_insert_to_filter_sets();


--
-- Name: edit_sessions propagate_edit_session_insert_to_media_entries; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER propagate_edit_session_insert_to_media_entries AFTER INSERT ON public.edit_sessions FOR EACH ROW EXECUTE PROCEDURE public.propagate_edit_session_insert_to_media_entries();


--
-- Name: keywords propagate_keyword_updates_to_meta_data_keywords; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER propagate_keyword_updates_to_meta_data_keywords AFTER INSERT OR UPDATE ON public.keywords FOR EACH ROW EXECUTE PROCEDURE public.propagate_keyword_updates_to_meta_data_keywords();


--
-- Name: meta_data_keywords propagate_meta_data_keyword_updates_to_meta_data; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER propagate_meta_data_keyword_updates_to_meta_data AFTER INSERT OR DELETE OR UPDATE ON public.meta_data_keywords FOR EACH ROW EXECUTE PROCEDURE public.propagate_meta_data_keyword_updates_to_meta_data();


--
-- Name: meta_data_people propagate_meta_data_people_updates_to_meta_data; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER propagate_meta_data_people_updates_to_meta_data AFTER INSERT OR DELETE OR UPDATE ON public.meta_data_people FOR EACH ROW EXECUTE PROCEDURE public.propagate_meta_data_people_updates_to_meta_data();


--
-- Name: meta_data propagate_meta_data_updates_to_media_resource; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER propagate_meta_data_updates_to_media_resource AFTER INSERT OR DELETE OR UPDATE ON public.meta_data FOR EACH ROW EXECUTE PROCEDURE public.propagate_meta_data_updates_to_media_resource();


--
-- Name: people propagate_people_updates_to_meta_data_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER propagate_people_updates_to_meta_data_people AFTER INSERT OR UPDATE ON public.people FOR EACH ROW EXECUTE PROCEDURE public.propagate_people_updates_to_meta_data_people();


--
-- Name: collection_media_entry_arcs trigger_check_collection_cover_uniqueness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_collection_cover_uniqueness AFTER INSERT OR UPDATE ON public.collection_media_entry_arcs DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_collection_cover_uniqueness();


--
-- Name: custom_urls trigger_check_collection_primary_uniqueness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_collection_primary_uniqueness AFTER INSERT OR UPDATE ON public.custom_urls DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_collection_primary_uniqueness();


--
-- Name: custom_urls trigger_check_filter_set_primary_uniqueness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_filter_set_primary_uniqueness AFTER INSERT OR UPDATE ON public.custom_urls DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_filter_set_primary_uniqueness();


--
-- Name: custom_urls trigger_check_media_entry_primary_uniqueness; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_media_entry_primary_uniqueness AFTER INSERT OR UPDATE ON public.custom_urls DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_media_entry_primary_uniqueness();


--
-- Name: meta_data trigger_check_meta_data_created_by; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_check_meta_data_created_by AFTER INSERT ON public.meta_data FOR EACH ROW EXECUTE PROCEDURE public.check_meta_data_created_by();


--
-- Name: meta_data_keywords trigger_check_meta_data_keywords_created_by; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_check_meta_data_keywords_created_by AFTER INSERT ON public.meta_data_keywords FOR EACH ROW EXECUTE PROCEDURE public.check_meta_data_keywords_created_by();


--
-- Name: meta_data_people trigger_check_meta_data_people_created_by; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_check_meta_data_people_created_by AFTER INSERT ON public.meta_data_people FOR EACH ROW EXECUTE PROCEDURE public.check_meta_data_people_created_by();


--
-- Name: collection_media_entry_arcs trigger_check_no_drafts_in_collections; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_no_drafts_in_collections AFTER INSERT OR UPDATE ON public.collection_media_entry_arcs DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_no_drafts_in_collections();


--
-- Name: api_clients trigger_check_users_apiclients_login_uniqueness_on_apiclients; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_users_apiclients_login_uniqueness_on_apiclients AFTER INSERT OR UPDATE ON public.api_clients DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_users_apiclients_login_uniqueness();


--
-- Name: users trigger_check_users_apiclients_login_uniqueness_on_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_check_users_apiclients_login_uniqueness_on_users AFTER INSERT OR UPDATE ON public.users DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_users_apiclients_login_uniqueness();


--
-- Name: collection_collection_arcs trigger_collection_may_not_be_its_own_parent; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_collection_may_not_be_its_own_parent AFTER INSERT OR UPDATE ON public.collection_collection_arcs DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.collection_may_not_be_its_own_parent();


--
-- Name: groups_users trigger_delete_empty_group_after_delete_join; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_group_after_delete_join AFTER DELETE ON public.groups_users DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.delete_empty_group_after_delete_join();


--
-- Name: meta_data trigger_delete_empty_meta_data_groups_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_groups_after_insert AFTER INSERT ON public.meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (((new.type)::text = 'MetaDatum::Groups'::text)) EXECUTE PROCEDURE public.delete_empty_meta_data_groups_after_insert();


--
-- Name: meta_data_keywords trigger_delete_empty_meta_data_keywords_after_delete_join; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_keywords_after_delete_join AFTER DELETE ON public.meta_data_keywords DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.delete_empty_meta_data_keywords_after_delete_join();


--
-- Name: meta_data trigger_delete_empty_meta_data_keywords_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_keywords_after_insert AFTER INSERT ON public.meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (((new.type)::text = 'MetaDatum::Keywords'::text)) EXECUTE PROCEDURE public.delete_empty_meta_data_keywords_after_insert();


--
-- Name: meta_data trigger_delete_empty_meta_data_licenses_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_licenses_after_insert AFTER INSERT ON public.meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (((new.type)::text = 'MetaDatum::Licenses'::text)) EXECUTE PROCEDURE public.delete_empty_meta_data_licenses_after_insert();


--
-- Name: meta_data_people trigger_delete_empty_meta_data_people_after_delete_join; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_people_after_delete_join AFTER DELETE ON public.meta_data_people DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.delete_empty_meta_data_people_after_delete_join();


--
-- Name: meta_data trigger_delete_empty_meta_data_people_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_empty_meta_data_people_after_insert AFTER INSERT ON public.meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW WHEN (((new.type)::text = 'MetaDatum::People'::text)) EXECUTE PROCEDURE public.delete_empty_meta_data_people_after_insert();


--
-- Name: meta_data trigger_delete_meta_datum_text_string_null; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_delete_meta_datum_text_string_null AFTER INSERT OR UPDATE ON public.meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.delete_meta_datum_text_string_null();


--
-- Name: meta_keys trigger_madek_core_meta_key_immutability; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_madek_core_meta_key_immutability AFTER INSERT OR DELETE OR UPDATE ON public.meta_keys DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_madek_core_meta_key_immutability();


--
-- Name: meta_data trigger_meta_data_meta_key_type_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_meta_data_meta_key_type_consistency AFTER INSERT OR UPDATE ON public.meta_data DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_meta_data_meta_key_type_consistency();


--
-- Name: meta_data_keywords trigger_meta_key_id_for_keyword_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_meta_key_id_for_keyword_consistency AFTER INSERT OR UPDATE ON public.meta_data_keywords DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_meta_key_id_consistency_for_keywords();


--
-- Name: meta_keys trigger_meta_key_meta_data_type_consistency; Type: TRIGGER; Schema: public; Owner: -
--

CREATE CONSTRAINT TRIGGER trigger_meta_key_meta_data_type_consistency AFTER INSERT OR UPDATE ON public.meta_keys DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE public.check_meta_key_meta_data_type_consistency();


--
-- Name: groups update_searchable_column_of_groups; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_searchable_column_of_groups BEFORE INSERT OR UPDATE ON public.groups FOR EACH ROW EXECUTE PROCEDURE public.groups_update_searchable_column();


--
-- Name: people update_searchable_column_of_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_searchable_column_of_people BEFORE INSERT OR UPDATE ON public.people FOR EACH ROW EXECUTE PROCEDURE public.people_update_searchable_column();


--
-- Name: users update_searchable_column_of_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_searchable_column_of_users BEFORE INSERT OR UPDATE ON public.users FOR EACH ROW EXECUTE PROCEDURE public.users_update_searchable_column();


--
-- Name: admins update_updated_at_column_of_admins; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_admins BEFORE UPDATE ON public.admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: api_clients update_updated_at_column_of_api_clients; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_api_clients BEFORE UPDATE ON public.api_clients FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: api_tokens update_updated_at_column_of_api_tokens; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_api_tokens BEFORE UPDATE ON public.api_tokens FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: app_settings update_updated_at_column_of_app_settings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_app_settings BEFORE UPDATE ON public.app_settings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: collection_api_client_permissions update_updated_at_column_of_collection_api_client_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_collection_api_client_permissions BEFORE UPDATE ON public.collection_api_client_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: collection_group_permissions update_updated_at_column_of_collection_group_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_collection_group_permissions BEFORE UPDATE ON public.collection_group_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: collection_user_permissions update_updated_at_column_of_collection_user_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_collection_user_permissions BEFORE UPDATE ON public.collection_user_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: collections update_updated_at_column_of_collections; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_collections BEFORE UPDATE ON public.collections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: confidential_links update_updated_at_column_of_confidential_links; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_confidential_links BEFORE UPDATE ON public.confidential_links FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: context_keys update_updated_at_column_of_context_keys; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_context_keys BEFORE UPDATE ON public.context_keys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: custom_urls update_updated_at_column_of_custom_urls; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_custom_urls BEFORE UPDATE ON public.custom_urls FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: favorite_collections update_updated_at_column_of_favorite_collections; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_favorite_collections BEFORE UPDATE ON public.favorite_collections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: favorite_filter_sets update_updated_at_column_of_favorite_filter_sets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_favorite_filter_sets BEFORE UPDATE ON public.favorite_filter_sets FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: favorite_media_entries update_updated_at_column_of_favorite_media_entries; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_favorite_media_entries BEFORE UPDATE ON public.favorite_media_entries FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: filter_set_api_client_permissions update_updated_at_column_of_filter_set_api_client_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_filter_set_api_client_permissions BEFORE UPDATE ON public.filter_set_api_client_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: filter_set_group_permissions update_updated_at_column_of_filter_set_group_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_filter_set_group_permissions BEFORE UPDATE ON public.filter_set_group_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: filter_set_user_permissions update_updated_at_column_of_filter_set_user_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_filter_set_user_permissions BEFORE UPDATE ON public.filter_set_user_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: filter_sets update_updated_at_column_of_filter_sets; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_filter_sets BEFORE UPDATE ON public.filter_sets FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: io_interfaces update_updated_at_column_of_io_interfaces; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_io_interfaces BEFORE UPDATE ON public.io_interfaces FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: io_mappings update_updated_at_column_of_io_mappings; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_io_mappings BEFORE UPDATE ON public.io_mappings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: keywords update_updated_at_column_of_keywords; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_keywords BEFORE UPDATE ON public.keywords FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: media_entries update_updated_at_column_of_media_entries; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_entries BEFORE UPDATE ON public.media_entries FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: media_entry_api_client_permissions update_updated_at_column_of_media_entry_api_client_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_entry_api_client_permissions BEFORE UPDATE ON public.media_entry_api_client_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: media_entry_group_permissions update_updated_at_column_of_media_entry_group_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_entry_group_permissions BEFORE UPDATE ON public.media_entry_group_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: media_entry_user_permissions update_updated_at_column_of_media_entry_user_permissions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_entry_user_permissions BEFORE UPDATE ON public.media_entry_user_permissions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: media_files update_updated_at_column_of_media_files; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_media_files BEFORE UPDATE ON public.media_files FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: meta_data_keywords update_updated_at_column_of_meta_data_keywords; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_meta_data_keywords BEFORE UPDATE ON public.meta_data_keywords FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: people update_updated_at_column_of_people; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_people BEFORE UPDATE ON public.people FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: previews update_updated_at_column_of_previews; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_previews BEFORE UPDATE ON public.previews FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: usage_terms update_updated_at_column_of_usage_terms; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_usage_terms BEFORE UPDATE ON public.usage_terms FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: users update_updated_at_column_of_users; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_users BEFORE UPDATE ON public.users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: zencoder_jobs update_updated_at_column_of_zencoder_jobs; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_updated_at_column_of_zencoder_jobs BEFORE UPDATE ON public.zencoder_jobs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE public.update_updated_at_column();


--
-- Name: admins admins_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_users_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: collection_api_client_permissions collection-api-client-permissions_api-clients_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_api_client_permissions
    ADD CONSTRAINT "collection-api-client-permissions_api-clients_fkey" FOREIGN KEY (api_client_id) REFERENCES public.api_clients(id) ON DELETE CASCADE;


--
-- Name: collection_api_client_permissions collection-api-client-permissions_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_api_client_permissions
    ADD CONSTRAINT "collection-api-client-permissions_collections_fkey" FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: collection_api_client_permissions collection-api-client-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_api_client_permissions
    ADD CONSTRAINT "collection-api-client-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES public.users(id);


--
-- Name: collection_collection_arcs collection-collection-arcs_children_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_collection_arcs
    ADD CONSTRAINT "collection-collection-arcs_children_fkey" FOREIGN KEY (child_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: collection_collection_arcs collection-collection-arcs_parents_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_collection_arcs
    ADD CONSTRAINT "collection-collection-arcs_parents_fkey" FOREIGN KEY (parent_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: collection_filter_set_arcs collection-filter-set-arcs_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_filter_set_arcs
    ADD CONSTRAINT "collection-filter-set-arcs_collections_fkey" FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: collection_filter_set_arcs collection-filter-set-arcs_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_filter_set_arcs
    ADD CONSTRAINT "collection-filter-set-arcs_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES public.filter_sets(id) ON DELETE CASCADE;


--
-- Name: collection_group_permissions collection-group-permissions_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_group_permissions
    ADD CONSTRAINT "collection-group-permissions_collections_fkey" FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: collection_group_permissions collection-group-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_group_permissions
    ADD CONSTRAINT "collection-group-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES public.users(id);


--
-- Name: collection_media_entry_arcs collection-media-entry-arcs_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_media_entry_arcs
    ADD CONSTRAINT "collection-media-entry-arcs_collections_fkey" FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: collection_media_entry_arcs collection-media-entry-arcs_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_media_entry_arcs
    ADD CONSTRAINT "collection-media-entry-arcs_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES public.media_entries(id) ON DELETE CASCADE;


--
-- Name: collection_user_permissions collection-user-permissions-updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_user_permissions
    ADD CONSTRAINT "collection-user-permissions-updators_fkey" FOREIGN KEY (updator_id) REFERENCES public.users(id);


--
-- Name: collection_user_permissions collection-user-permissions_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_user_permissions
    ADD CONSTRAINT "collection-user-permissions_collections_fkey" FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: collection_user_permissions collection-user-permissions_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_user_permissions
    ADD CONSTRAINT "collection-user-permissions_users_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: collections collections_creators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT collections_creators_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: collections collections_responsible-users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collections
    ADD CONSTRAINT "collections_responsible-users_fkey" FOREIGN KEY (responsible_user_id) REFERENCES public.users(id);


--
-- Name: custom_urls custom-urls_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_urls
    ADD CONSTRAINT "custom-urls_collections_fkey" FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: custom_urls custom-urls_creators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_urls
    ADD CONSTRAINT "custom-urls_creators_fkey" FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: custom_urls custom-urls_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_urls
    ADD CONSTRAINT "custom-urls_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES public.filter_sets(id) ON DELETE CASCADE;


--
-- Name: custom_urls custom-urls_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_urls
    ADD CONSTRAINT "custom-urls_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES public.media_entries(id) ON DELETE CASCADE;


--
-- Name: custom_urls custom-urls_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_urls
    ADD CONSTRAINT "custom-urls_updators_fkey" FOREIGN KEY (updator_id) REFERENCES public.users(id);


--
-- Name: edit_sessions edit-sessions_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edit_sessions
    ADD CONSTRAINT "edit-sessions_collections_fkey" FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: edit_sessions edit-sessions_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edit_sessions
    ADD CONSTRAINT "edit-sessions_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES public.filter_sets(id) ON DELETE CASCADE;


--
-- Name: edit_sessions edit-sessions_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edit_sessions
    ADD CONSTRAINT "edit-sessions_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES public.media_entries(id) ON DELETE CASCADE;


--
-- Name: edit_sessions edit-sessions_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.edit_sessions
    ADD CONSTRAINT "edit-sessions_users_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: favorite_collections favorite-collections_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_collections
    ADD CONSTRAINT "favorite-collections_collections_fkey" FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: favorite_collections favorite-collections_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_collections
    ADD CONSTRAINT "favorite-collections_users_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: favorite_filter_sets favorite-filter-sets_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_filter_sets
    ADD CONSTRAINT "favorite-filter-sets_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES public.filter_sets(id) ON DELETE CASCADE;


--
-- Name: favorite_filter_sets favorite-filter-sets_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_filter_sets
    ADD CONSTRAINT "favorite-filter-sets_users_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: favorite_media_entries favorite-media-entries_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_media_entries
    ADD CONSTRAINT "favorite-media-entries_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES public.media_entries(id) ON DELETE CASCADE;


--
-- Name: favorite_media_entries favorite-media-entries_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorite_media_entries
    ADD CONSTRAINT "favorite-media-entries_users_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: filter_set_api_client_permissions filter-set-api-client-permissions-updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_api_client_permissions
    ADD CONSTRAINT "filter-set-api-client-permissions-updators_fkey" FOREIGN KEY (updator_id) REFERENCES public.users(id);


--
-- Name: filter_set_api_client_permissions filter-set-api-client-permissions_api-clients_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_api_client_permissions
    ADD CONSTRAINT "filter-set-api-client-permissions_api-clients_fkey" FOREIGN KEY (api_client_id) REFERENCES public.api_clients(id) ON DELETE CASCADE;


--
-- Name: filter_set_api_client_permissions filter-set-api-client-permissions_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_api_client_permissions
    ADD CONSTRAINT "filter-set-api-client-permissions_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES public.filter_sets(id) ON DELETE CASCADE;


--
-- Name: filter_set_group_permissions filter-set-group-permissions_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_group_permissions
    ADD CONSTRAINT "filter-set-group-permissions_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES public.filter_sets(id) ON DELETE CASCADE;


--
-- Name: filter_set_group_permissions filter-set-group-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_group_permissions
    ADD CONSTRAINT "filter-set-group-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES public.users(id);


--
-- Name: filter_set_user_permissions filter-set-user-permissions_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_user_permissions
    ADD CONSTRAINT "filter-set-user-permissions_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES public.filter_sets(id) ON DELETE CASCADE;


--
-- Name: filter_set_user_permissions filter-set-user-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_user_permissions
    ADD CONSTRAINT "filter-set-user-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES public.users(id);


--
-- Name: filter_set_user_permissions filter-set-user-permissions_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_user_permissions
    ADD CONSTRAINT "filter-set-user-permissions_users_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: filter_sets filter-sets_creators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_sets
    ADD CONSTRAINT "filter-sets_creators_fkey" FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: filter_sets filter-sets_responsible-users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_sets
    ADD CONSTRAINT "filter-sets_responsible-users_fkey" FOREIGN KEY (responsible_user_id) REFERENCES public.users(id);


--
-- Name: context_keys fk_rails_2957e036b5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_keys
    ADD CONSTRAINT fk_rails_2957e036b5 FOREIGN KEY (meta_key_id) REFERENCES public.meta_keys(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: api_clients fk_rails_45043d2037; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_clients
    ADD CONSTRAINT fk_rails_45043d2037 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: groups_users fk_rails_4e63edbd27; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_users
    ADD CONSTRAINT fk_rails_4e63edbd27 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: vocabulary_group_permissions fk_rails_8550647b84; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_group_permissions
    ADD CONSTRAINT fk_rails_8550647b84 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: confidential_links fk_rails_8c2cb96882; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.confidential_links
    ADD CONSTRAINT fk_rails_8c2cb96882 FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: roles fk_rails_973fbfab62; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT fk_rails_973fbfab62 FOREIGN KEY (meta_key_id) REFERENCES public.meta_keys(id);


--
-- Name: filter_set_group_permissions fk_rails_9cf683b9d3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.filter_set_group_permissions
    ADD CONSTRAINT fk_rails_9cf683b9d3 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: meta_data_roles fk_rails_b1e57448c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_roles
    ADD CONSTRAINT fk_rails_b1e57448c0 FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: context_keys fk_rails_b297363c89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.context_keys
    ADD CONSTRAINT fk_rails_b297363c89 FOREIGN KEY (context_id) REFERENCES public.contexts(id);


--
-- Name: collection_group_permissions fk_rails_b88fcbe505; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.collection_group_permissions
    ADD CONSTRAINT fk_rails_b88fcbe505 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: media_entry_group_permissions fk_rails_c5e91a50bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_group_permissions
    ADD CONSTRAINT fk_rails_c5e91a50bb FOREIGN KEY (group_id) REFERENCES public.groups(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: io_mappings fk_rails_dbf6e7c067; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.io_mappings
    ADD CONSTRAINT fk_rails_dbf6e7c067 FOREIGN KEY (meta_key_id) REFERENCES public.meta_keys(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: meta_data fk_rails_ee76aad01f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data
    ADD CONSTRAINT fk_rails_ee76aad01f FOREIGN KEY (meta_key_id) REFERENCES public.meta_keys(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: api_tokens fk_rails_f16b5e0447; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_tokens
    ADD CONSTRAINT fk_rails_f16b5e0447 FOREIGN KEY (user_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: keywords fk_rails_f3e1612c9e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.keywords
    ADD CONSTRAINT fk_rails_f3e1612c9e FOREIGN KEY (meta_key_id) REFERENCES public.meta_keys(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: groups_users groups-users_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups_users
    ADD CONSTRAINT "groups-users_users_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: io_mappings io-mappings_io-interfaces_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.io_mappings
    ADD CONSTRAINT "io-mappings_io-interfaces_fkey" FOREIGN KEY (io_interface_id) REFERENCES public.io_interfaces(id) ON DELETE CASCADE;


--
-- Name: keywords keywords_rdf_class_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.keywords
    ADD CONSTRAINT keywords_rdf_class_fkey FOREIGN KEY (rdf_class) REFERENCES public.rdf_classes(id) ON UPDATE CASCADE;


--
-- Name: media_entries media-entries_creators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entries
    ADD CONSTRAINT "media-entries_creators_fkey" FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: media_entries media-entries_responsible-users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entries
    ADD CONSTRAINT "media-entries_responsible-users_fkey" FOREIGN KEY (responsible_user_id) REFERENCES public.users(id);


--
-- Name: media_entry_api_client_permissions media-entry-api-client-permissions_api-clients_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_api_client_permissions
    ADD CONSTRAINT "media-entry-api-client-permissions_api-clients_fkey" FOREIGN KEY (api_client_id) REFERENCES public.api_clients(id) ON DELETE CASCADE;


--
-- Name: media_entry_api_client_permissions media-entry-api-client-permissions_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_api_client_permissions
    ADD CONSTRAINT "media-entry-api-client-permissions_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES public.media_entries(id) ON DELETE CASCADE;


--
-- Name: media_entry_api_client_permissions media-entry-api-client-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_api_client_permissions
    ADD CONSTRAINT "media-entry-api-client-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES public.users(id);


--
-- Name: media_entry_group_permissions media-entry-group-permissions_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_group_permissions
    ADD CONSTRAINT "media-entry-group-permissions_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES public.media_entries(id) ON DELETE CASCADE;


--
-- Name: media_entry_group_permissions media-entry-group-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_group_permissions
    ADD CONSTRAINT "media-entry-group-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES public.users(id);


--
-- Name: media_entry_user_permissions media-entry-user-permissions_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_user_permissions
    ADD CONSTRAINT "media-entry-user-permissions_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES public.media_entries(id) ON DELETE CASCADE;


--
-- Name: media_entry_user_permissions media-entry-user-permissions_updators_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_user_permissions
    ADD CONSTRAINT "media-entry-user-permissions_updators_fkey" FOREIGN KEY (updator_id) REFERENCES public.users(id);


--
-- Name: media_entry_user_permissions media-entry-user-permissions_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_entry_user_permissions
    ADD CONSTRAINT "media-entry-user-permissions_users_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: media_files media-files_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT "media-files_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES public.media_entries(id);


--
-- Name: media_files media-files_uploaders_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_files
    ADD CONSTRAINT "media-files_uploaders_fkey" FOREIGN KEY (uploader_id) REFERENCES public.users(id);


--
-- Name: meta_data_keywords meta-data-keywords_keywords_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_keywords
    ADD CONSTRAINT "meta-data-keywords_keywords_fkey" FOREIGN KEY (keyword_id) REFERENCES public.keywords(id) ON DELETE CASCADE;


--
-- Name: meta_data_keywords meta-data-keywords_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_keywords
    ADD CONSTRAINT "meta-data-keywords_users_fkey" FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: meta_data_meta_terms meta-data-meta-terms_meta-data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_meta_terms
    ADD CONSTRAINT "meta-data-meta-terms_meta-data_fkey" FOREIGN KEY (meta_datum_id) REFERENCES public.meta_data(id) ON DELETE CASCADE;


--
-- Name: meta_data_people meta-data-people_meta-data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_people
    ADD CONSTRAINT "meta-data-people_meta-data_fkey" FOREIGN KEY (meta_datum_id) REFERENCES public.meta_data(id) ON DELETE CASCADE;


--
-- Name: meta_data_people meta-data-people_people_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_people
    ADD CONSTRAINT "meta-data-people_people_fkey" FOREIGN KEY (person_id) REFERENCES public.people(id);


--
-- Name: meta_data_people meta-data-people_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_people
    ADD CONSTRAINT "meta-data-people_users_fkey" FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: meta_data meta-data_collections_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data
    ADD CONSTRAINT "meta-data_collections_fkey" FOREIGN KEY (collection_id) REFERENCES public.collections(id) ON DELETE CASCADE;


--
-- Name: meta_data meta-data_filter-sets_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data
    ADD CONSTRAINT "meta-data_filter-sets_fkey" FOREIGN KEY (filter_set_id) REFERENCES public.filter_sets(id) ON DELETE CASCADE;


--
-- Name: meta_data meta-data_media-entries_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data
    ADD CONSTRAINT "meta-data_media-entries_fkey" FOREIGN KEY (media_entry_id) REFERENCES public.media_entries(id) ON DELETE CASCADE;


--
-- Name: meta_data meta-data_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data
    ADD CONSTRAINT "meta-data_users_fkey" FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: meta_keys meta-keys_vocabularies_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_keys
    ADD CONSTRAINT "meta-keys_vocabularies_fkey" FOREIGN KEY (vocabulary_id) REFERENCES public.vocabularies(id) ON DELETE CASCADE;


--
-- Name: meta_data_keywords meta_data_keywords_meta-data_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_data_keywords
    ADD CONSTRAINT "meta_data_keywords_meta-data_fkey" FOREIGN KEY (meta_datum_id) REFERENCES public.meta_data(id) ON DELETE CASCADE;


--
-- Name: meta_keys meta_keys_allowed_rdf_class_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.meta_keys
    ADD CONSTRAINT meta_keys_allowed_rdf_class_fkey FOREIGN KEY (allowed_rdf_class) REFERENCES public.rdf_classes(id) ON UPDATE CASCADE;


--
-- Name: previews previews_media-files_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.previews
    ADD CONSTRAINT "previews_media-files_fkey" FOREIGN KEY (media_file_id) REFERENCES public.media_files(id) ON DELETE CASCADE;


--
-- Name: roles roles_creator_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: users users_people_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_people_fkey FOREIGN KEY (person_id) REFERENCES public.people(id);


--
-- Name: visualizations visualizations_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.visualizations
    ADD CONSTRAINT visualizations_users_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: vocabulary_api_client_permissions vocabulary-api-client-permissions_api-clients_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_api_client_permissions
    ADD CONSTRAINT "vocabulary-api-client-permissions_api-clients_fkey" FOREIGN KEY (api_client_id) REFERENCES public.api_clients(id) ON DELETE CASCADE;


--
-- Name: vocabulary_api_client_permissions vocabulary-api-client-permissions_vocabularies_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_api_client_permissions
    ADD CONSTRAINT "vocabulary-api-client-permissions_vocabularies_fkey" FOREIGN KEY (vocabulary_id) REFERENCES public.vocabularies(id) ON DELETE CASCADE;


--
-- Name: vocabulary_group_permissions vocabulary-group-permissions_vocabularies_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_group_permissions
    ADD CONSTRAINT "vocabulary-group-permissions_vocabularies_fkey" FOREIGN KEY (vocabulary_id) REFERENCES public.vocabularies(id) ON DELETE CASCADE;


--
-- Name: vocabulary_user_permissions vocabulary-user-permissions_users_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_user_permissions
    ADD CONSTRAINT "vocabulary-user-permissions_users_fkey" FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: vocabulary_user_permissions vocabulary-user-permissions_vocabularies_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vocabulary_user_permissions
    ADD CONSTRAINT "vocabulary-user-permissions_vocabularies_fkey" FOREIGN KEY (vocabulary_id) REFERENCES public.vocabularies(id) ON DELETE CASCADE;


--
-- Name: zencoder_jobs zencoder-jobs_media-files_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zencoder_jobs
    ADD CONSTRAINT "zencoder-jobs_media-files_fkey" FOREIGN KEY (media_file_id) REFERENCES public.media_files(id);


--
-- PostgreSQL database dump complete
--

