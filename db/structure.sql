--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2 (Homebrew)
-- Dumped by pg_dump version 17.2 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: migration_versions; Type: TABLE; Schema: public; Owner: crimsonknight
--

CREATE TABLE public.migration_versions (
    version character varying(17) NOT NULL
);


ALTER TABLE public.migration_versions OWNER TO crimsonknight;

--
-- Name: personas; Type: TABLE; Schema: public; Owner: crimsonknight
--

CREATE TABLE public.personas (
    id bigint NOT NULL,
    email character varying(254) NOT NULL,
    password_digest character varying(254) NOT NULL,
    type character varying(254) DEFAULT 'User'::character varying NOT NULL,
    api_key character varying(254) DEFAULT ''::character varying NOT NULL,
    api_secret character varying(254) DEFAULT ''::character varying NOT NULL,
    last_login_at date,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.personas OWNER TO crimsonknight;

--
-- Name: personas_id_seq; Type: SEQUENCE; Schema: public; Owner: crimsonknight
--

CREATE SEQUENCE public.personas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.personas_id_seq OWNER TO crimsonknight;

--
-- Name: personas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: crimsonknight
--

ALTER SEQUENCE public.personas_id_seq OWNED BY public.personas.id;


--
-- Name: personas id; Type: DEFAULT; Schema: public; Owner: crimsonknight
--

ALTER TABLE ONLY public.personas ALTER COLUMN id SET DEFAULT nextval('public.personas_id_seq'::regclass);


--
-- Name: personas personas_pkey; Type: CONSTRAINT; Schema: public; Owner: crimsonknight
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT personas_pkey PRIMARY KEY (id);


--
-- Name: personas_email_idx; Type: INDEX; Schema: public; Owner: crimsonknight
--

CREATE INDEX personas_email_idx ON public.personas USING btree (email);


--
-- PostgreSQL database dump complete
--

