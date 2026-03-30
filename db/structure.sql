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

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: call_participants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.call_participants (
    id bigint NOT NULL,
    call_session_id bigint NOT NULL,
    user_id bigint NOT NULL,
    joined_at timestamp(6) without time zone NOT NULL,
    left_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: call_participants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.call_participants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: call_participants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.call_participants_id_seq OWNED BY public.call_participants.id;


--
-- Name: call_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.call_sessions (
    id bigint NOT NULL,
    conversation_id bigint NOT NULL,
    initiator_id bigint NOT NULL,
    call_type integer DEFAULT 0 NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    started_at timestamp(6) without time zone,
    ended_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: call_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.call_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: call_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.call_sessions_id_seq OWNED BY public.call_sessions.id;


--
-- Name: conversation_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_members (
    id bigint NOT NULL,
    conversation_id bigint NOT NULL,
    user_id bigint NOT NULL,
    role integer DEFAULT 0 NOT NULL,
    joined_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: conversation_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_members_id_seq OWNED BY public.conversation_members.id;


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id bigint NOT NULL,
    conversation_type integer DEFAULT 0 NOT NULL,
    name character varying,
    description text,
    created_by_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id bigint NOT NULL,
    content text NOT NULL,
    message_type integer DEFAULT 0 NOT NULL,
    edited_at timestamp with time zone,
    deleted_at timestamp with time zone,
    conversation_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    parent_message_id bigint,
    call_session_id bigint
)
PARTITION BY RANGE (created_at);


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.messages_id_seq OWNED BY public.messages.id;


--
-- Name: messages_2026_03; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages_2026_03 (
    id bigint DEFAULT nextval('public.messages_id_seq'::regclass) NOT NULL,
    content text NOT NULL,
    message_type integer DEFAULT 0 NOT NULL,
    edited_at timestamp with time zone,
    deleted_at timestamp with time zone,
    conversation_id bigint NOT NULL,
    user_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    parent_message_id bigint,
    call_session_id bigint
);


--
-- Name: reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reactions (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    message_created_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL,
    emoji character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reactions_id_seq OWNED BY public.reactions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp(6) without time zone,
    remember_created_at timestamp(6) without time zone,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp(6) without time zone,
    username character varying NOT NULL,
    display_name character varying,
    avatar_url character varying,
    last_seen_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: messages_2026_03; Type: TABLE ATTACH; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ATTACH PARTITION public.messages_2026_03 FOR VALUES FROM ('2026-03-01 02:00:00+02') TO ('2026-04-01 02:00:00+02');


--
-- Name: call_participants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_participants ALTER COLUMN id SET DEFAULT nextval('public.call_participants_id_seq'::regclass);


--
-- Name: call_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_sessions ALTER COLUMN id SET DEFAULT nextval('public.call_sessions_id_seq'::regclass);


--
-- Name: conversation_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_members ALTER COLUMN id SET DEFAULT nextval('public.conversation_members_id_seq'::regclass);


--
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages ALTER COLUMN id SET DEFAULT nextval('public.messages_id_seq'::regclass);


--
-- Name: reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions ALTER COLUMN id SET DEFAULT nextval('public.reactions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: call_participants call_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_participants
    ADD CONSTRAINT call_participants_pkey PRIMARY KEY (id);


--
-- Name: call_sessions call_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_sessions
    ADD CONSTRAINT call_sessions_pkey PRIMARY KEY (id);


--
-- Name: conversation_members conversation_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_members
    ADD CONSTRAINT conversation_members_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, created_at);


--
-- Name: messages_2026_03 messages_2026_03_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages_2026_03
    ADD CONSTRAINT messages_2026_03_pkey PRIMARY KEY (id, created_at);


--
-- Name: reactions reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_call_participants_on_call_session_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_call_participants_on_call_session_id_and_user_id ON public.call_participants USING btree (call_session_id, user_id);


--
-- Name: index_call_participants_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_participants_on_user_id ON public.call_participants USING btree (user_id);


--
-- Name: index_call_sessions_on_conversation_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_sessions_on_conversation_id_and_status ON public.call_sessions USING btree (conversation_id, status);


--
-- Name: index_call_sessions_on_initiator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_call_sessions_on_initiator_id ON public.call_sessions USING btree (initiator_id);


--
-- Name: index_conversation_members_on_conversation_id_and_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversation_members_on_conversation_id_and_user_id ON public.conversation_members USING btree (conversation_id, user_id);


--
-- Name: index_conversation_members_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversation_members_on_user_id ON public.conversation_members USING btree (user_id);


--
-- Name: index_conversations_on_conversation_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_conversation_type ON public.conversations USING btree (conversation_type);


--
-- Name: index_conversations_on_created_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_created_by_id ON public.conversations USING btree (created_by_id);


--
-- Name: index_conversations_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_conversations_on_name ON public.conversations USING btree (name);


--
-- Name: index_messages_on_call_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_call_session_id ON ONLY public.messages USING btree (call_session_id);


--
-- Name: index_messages_on_conversation_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_conversation_id_and_created_at ON ONLY public.messages USING btree (conversation_id, created_at);


--
-- Name: index_messages_on_deleted_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_deleted_at ON ONLY public.messages USING btree (deleted_at) WHERE (deleted_at IS NOT NULL);


--
-- Name: index_messages_on_parent_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_messages_on_parent_message_id ON ONLY public.messages USING btree (parent_message_id);


--
-- Name: index_reactions_on_message_id_and_user_id_and_emoji; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_reactions_on_message_id_and_user_id_and_emoji ON public.reactions USING btree (message_id, user_id, emoji);


--
-- Name: index_reactions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reactions_on_user_id ON public.reactions USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_last_seen_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_last_seen_at ON public.users USING btree (last_seen_at);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON public.users USING btree (unlock_token);


--
-- Name: index_users_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_username ON public.users USING btree (username);


--
-- Name: messages_2026_03_call_session_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2026_03_call_session_id_idx ON public.messages_2026_03 USING btree (call_session_id);


--
-- Name: messages_2026_03_conversation_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2026_03_conversation_id_created_at_idx ON public.messages_2026_03 USING btree (conversation_id, created_at);


--
-- Name: messages_2026_03_deleted_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2026_03_deleted_at_idx ON public.messages_2026_03 USING btree (deleted_at) WHERE (deleted_at IS NOT NULL);


--
-- Name: messages_2026_03_parent_message_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX messages_2026_03_parent_message_id_idx ON public.messages_2026_03 USING btree (parent_message_id);


--
-- Name: messages_2026_03_call_session_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_messages_on_call_session_id ATTACH PARTITION public.messages_2026_03_call_session_id_idx;


--
-- Name: messages_2026_03_conversation_id_created_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_messages_on_conversation_id_and_created_at ATTACH PARTITION public.messages_2026_03_conversation_id_created_at_idx;


--
-- Name: messages_2026_03_deleted_at_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_messages_on_deleted_at ATTACH PARTITION public.messages_2026_03_deleted_at_idx;


--
-- Name: messages_2026_03_parent_message_id_idx; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.index_messages_on_parent_message_id ATTACH PARTITION public.messages_2026_03_parent_message_id_idx;


--
-- Name: messages_2026_03_pkey; Type: INDEX ATTACH; Schema: public; Owner: -
--

ALTER INDEX public.messages_pkey ATTACH PARTITION public.messages_2026_03_pkey;


--
-- Name: call_sessions fk_rails_1b140a0a61; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_sessions
    ADD CONSTRAINT fk_rails_1b140a0a61 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: messages fk_rails_273a25a7a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.messages
    ADD CONSTRAINT fk_rails_273a25a7a6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: conversation_members fk_rails_35c44c194b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_members
    ADD CONSTRAINT fk_rails_35c44c194b FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: conversation_members fk_rails_4f7f4bd91a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_members
    ADD CONSTRAINT fk_rails_4f7f4bd91a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: messages fk_rails_7f927086d2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.messages
    ADD CONSTRAINT fk_rails_7f927086d2 FOREIGN KEY (conversation_id) REFERENCES public.conversations(id);


--
-- Name: call_participants fk_rails_9a674e9853; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_participants
    ADD CONSTRAINT fk_rails_9a674e9853 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: reactions fk_rails_9f02fc96a0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reactions
    ADD CONSTRAINT fk_rails_9f02fc96a0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: call_sessions fk_rails_a0514651dc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_sessions
    ADD CONSTRAINT fk_rails_a0514651dc FOREIGN KEY (initiator_id) REFERENCES public.users(id);


--
-- Name: call_participants fk_rails_cd4c33a766; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.call_participants
    ADD CONSTRAINT fk_rails_cd4c33a766 FOREIGN KEY (call_session_id) REFERENCES public.call_sessions(id);


--
-- Name: conversations fk_rails_f0647e99ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT fk_rails_f0647e99ab FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260329000001'),
('20260313201034'),
('20260313200309'),
('20260307181355'),
('20260307181354'),
('20260307181353'),
('20260307181352'),
('20260307181351'),
('20260307181350'),
('20260307181158');

