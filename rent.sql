--
-- PostgreSQL database dump
--

-- Dumped from database version 14.5
-- Dumped by pg_dump version 14.5

-- Started on 2022-12-19 01:00:01

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE rent;
--
-- TOC entry 3430 (class 1262 OID 16642)
-- Name: rent; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE rent WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'Russian_Russia.1251';


ALTER DATABASE rent OWNER TO postgres;

\connect rent

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 228 (class 1255 OID 16881)
-- Name: clients_passport_update_checker(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.clients_passport_update_checker() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF (NEW.series = OLD.series AND NEW.number = OLD.number AND NEW.issued_by = OLD.issued_by AND
			NEW.issue_date = OLD.issue_date AND NEW.division_code = OLD.division_code AND NEW.registration_address = OLD.registration_address) THEN
            RAISE EXCEPTION 'Нет изменений для обновления';
        END IF;
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.clients_passport_update_checker() OWNER TO postgres;

--
-- TOC entry 227 (class 1255 OID 16879)
-- Name: clients_personal_update_checker(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.clients_personal_update_checker() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF (NEW.name = OLD.name AND NEW.surname = OLD.surname AND NEW.phone = OLD.phone AND
			NEW.telegram = OLD.telegram AND NEW.comment = OLD.comment AND NEW.discount = OLD.discount) THEN
            RAISE EXCEPTION 'Нет изменений для обновления';
        END IF;
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.clients_personal_update_checker() OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 16911)
-- Name: create_client(character varying, character varying, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_client(name character varying, surname character varying, phone character varying, telegram character varying, comment character varying, discount integer) RETURNS TABLE(new_id integer)
    LANGUAGE plpgsql
    AS $$
begin
    return query INSERT INTO clients VALUES(DEFAULT, name, surname, phone, telegram, comment, discount) RETURNING id;
end;
$$;


ALTER FUNCTION public.create_client(name character varying, surname character varying, phone character varying, telegram character varying, comment character varying, discount integer) OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 16975)
-- Name: create_equipment(integer, character varying, integer, character varying, character varying[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_equipment(parent_id integer, title character varying, category_id integer, description character varying, images character varying[]) RETURNS TABLE(new_id integer)
    LANGUAGE plpgsql
    AS $$
begin
    return query INSERT INTO equipments VALUES(DEFAULT, parent_id, title, category_id, description, images, DEFAULT) RETURNING id;
end;
$$;


ALTER FUNCTION public.create_equipment(parent_id integer, title character varying, category_id integer, description character varying, images character varying[]) OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 16940)
-- Name: create_estimate(integer, integer, character varying, timestamp without time zone, timestamp without time zone, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_estimate(creator_id integer, client_id integer, project character varying, start_date timestamp without time zone, close_date timestamp without time zone, comment character varying) RETURNS TABLE(new_id integer)
    LANGUAGE plpgsql
    AS $$
begin
    return query INSERT INTO estimates VALUES(DEFAULT, creator_id, client_id, project, start_date, close_date, comment) RETURNING id;
end;
$$;


ALTER FUNCTION public.create_estimate(creator_id integer, client_id integer, project character varying, start_date timestamp without time zone, close_date timestamp without time zone, comment character varying) OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 16951)
-- Name: create_estimate_details(integer, integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.create_estimate_details(IN estimate_id integer, IN equipment_id integer, IN price_id integer, IN count integer)
    LANGUAGE plpgsql
    AS $$
begin
    INSERT INTO estimates_details VALUES(DEFAULT, estimate_id, equipment_id, price_id, count);
end;
$$;


ALTER PROCEDURE public.create_estimate_details(IN estimate_id integer, IN equipment_id integer, IN price_id integer, IN count integer) OWNER TO postgres;

--
-- TOC entry 250 (class 1255 OID 17119)
-- Name: equipments_update_checker(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.equipments_update_checker() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF (NEW.title = OLD.title AND NEW.parent_id = OLD.parent_id AND NEW.category_id = OLD.category_id AND
			NEW.description = OLD.description AND NEW.count = OLD.count) THEN
            RAISE EXCEPTION 'Нет изменений для обновления';
        END IF;
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.equipments_update_checker() OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 17000)
-- Name: estimates_payed_updater(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.estimates_payed_updater() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF (NEW.is_payed = true AND OLD.is_payed = false) THEN
            NEW.payed_date = NOW()::timestamp(0);
        END IF;
        RETURN NEW;
    END;
$$;


ALTER FUNCTION public.estimates_payed_updater() OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 16932)
-- Name: get_all_clients_details(character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_all_clients_details(field_name character varying, query character varying, is_payed boolean) RETURNS TABLE(id integer, name character varying, surname character varying, phone character varying, telegram character varying, comment character varying, discount integer, active_estimates bigint, total_estimates bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    statement TEXT;
BEGIN
	statement := 'SELECT c.*, count(e.id) as active_estimates, coalesce(te.total_estimates, 0)
	as total_estimate FROM clients c LEFT JOIN estimates e ON e.client_id = c.id AND
	e.is_payed = false LEFT JOIN ( SELECT count(ee.id) as total_estimates, ee.client_id from
	estimates ee group by ee.client_id ) te ON te.client_id = c.id WHERE 1=1 AND';
	IF (field_name = 'all') THEN
		statement := format('%s c.name ILIKE ''%%%s%%'' OR c.surname ILIKE ''%%%s%%'' OR c.phone ILIKE ''%%%s%%'' OR c.telegram ILIKE ''%%%s%%'' OR c.comment ILIKE ''%%%s%%'' AND', statement, query, query, query, query, query);
	ELSIF (field_name = 'name' and LENGTH(query) != 0) THEN
		statement := format('%s c.name ILIKE ''%%%s%%'' OR c.surname ILIKE ''%%%s%%'' AND', statement, query, query);
	ELSIF (field_name = 'phone' and LENGTH(query) != 0) THEN
		statement := format('%s c.phone ILIKE ''%%%s%%'' AND', statement, query);
	ELSIF (field_name = 'telegram' and LENGTH(query) != 0) THEN
		statement := format('%s c.telegram ILIKE ''%%%s%%'' AND', statement, query);
	ELSIF (field_name = 'comment' and LENGTH(query) != 0) THEN
		statement := format('%s c.comment ILIKE ''%%%s%%'' AND', statement, query);
	END IF;
	
	IF (is_payed = TRUE) THEN
		statement := format('%s 1=1 GROUP BY c.id, te.total_estimates having count(e.*) > 0 ORDER BY c.id;', statement);
	ELSE
		statement := format('%s 1=1 GROUP BY c.id, te.total_estimates ORDER BY c.id;', statement);
	END IF;
	
	RETURN QUERY EXECUTE statement;
END;
$$;


ALTER FUNCTION public.get_all_clients_details(field_name character varying, query character varying, is_payed boolean) OWNER TO postgres;

--
-- TOC entry 232 (class 1255 OID 16891)
-- Name: get_all_clients_short(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_all_clients_short() RETURNS TABLE(id integer, name character varying, surname character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY EXECUTE 'SELECT id, name, surname FROM clients ORDER BY surname';
END;
$$;


ALTER FUNCTION public.get_all_clients_short() OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 17111)
-- Name: get_categories_tree(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_categories_tree() RETURNS TABLE(id integer, parent_id integer, title character varying, path character varying, depth integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY EXECUTE 'select * from get_categories';
END;
$$;


ALTER FUNCTION public.get_categories_tree() OWNER TO postgres;

--
-- TOC entry 226 (class 1255 OID 16878)
-- Name: get_client_by_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_client_by_id(client_id integer) RETURNS TABLE(id integer, name character varying, surname character varying, phone character varying, telegram character varying, comment character varying, discount integer, series character varying, number character varying, issued_by character varying, issue_date date, division_code character varying, registration_address character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN QUERY EXECUTE format('SELECT c.*, pd.series, pd.number, pd.issued_by, pd.issue_date, pd.division_code,
		pd.registration_address FROM clients c LEFT JOIN passports_data pd ON pd.client_id=c.id WHERE c.id = %L', client_id);
END;
$$;


ALTER FUNCTION public.get_client_by_id(client_id integer) OWNER TO postgres;

--
-- TOC entry 252 (class 1255 OID 16971)
-- Name: get_equipment_by_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_equipment_by_id(equipment_id integer) RETURNS TABLE(id integer, parent_id integer, title character varying, category_id integer, description character varying, images character varying[], count integer, category character varying, parent_title character varying, price_id integer, price real)
    LANGUAGE plpgsql
    AS $$
DECLARE
    statement TEXT;
BEGIN
	statement := format('SELECT e.*, c.title, ee.title, p.id price_id, p.price FROM equipments e LEFT JOIN categories c ON c.id = e.category_id
						LEFT JOIN equipments ee ON ee.id = e.parent_id LEFT JOIN ( SELECT id, equipment_id, price FROM prices where equipment_id=%L
						order by change_date DESC limit 1 ) p ON p.equipment_id = e.id WHERE e.id = %L;', equipment_id, equipment_id);
	RETURN QUERY EXECUTE statement;
END;
$$;


ALTER FUNCTION public.get_equipment_by_id(equipment_id integer) OWNER TO postgres;

--
-- TOC entry 253 (class 1255 OID 16979)
-- Name: get_equipments(integer, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_equipments(cat_id integer, query character varying) RETURNS TABLE(id integer, parent_id integer, title character varying, category_id integer, description character varying, images character varying[], count integer, category character varying, parent_title character varying, price real)
    LANGUAGE plpgsql
    AS $$
DECLARE
    statement TEXT;
BEGIN
	statement := 'SELECT e.*, c.title, ee.title, pp.price FROM equipments e LEFT JOIN categories c ON c.id = e.category_id LEFT JOIN equipments ee
	ON ee.id = e.parent_id LEFT JOIN (SELECT tmp.price, tmp.equipment_id FROM (SELECT price, equipment_id, row_number() OVER 
	(PARTITION BY equipment_id ORDER BY change_date DESC) AS rn FROM prices ) tmp WHERE tmp.rn = 1) pp ON pp.equipment_id = e.id WHERE 1=1 AND';
	IF (cat_id > -1) THEN
		statement := format('%s e.category_id = %L AND', statement, cat_id);
	END IF;
	
	statement := format('%s e.title ILIKE ''%%%s%%'' ORDER BY ee.title;', statement, query);
	
	RETURN QUERY EXECUTE statement;
END;
$$;


ALTER FUNCTION public.get_equipments(cat_id integer, query character varying) OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 16993)
-- Name: get_estimate_by_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_estimate_by_id(_estimate_id integer) RETURNS TABLE(id integer, creator_id integer, client_id integer, project character varying, start_date timestamp without time zone, close_date timestamp without time zone, comment character varying, payed_date timestamp without time zone, is_payed boolean, create_date timestamp without time zone, creator_login character varying, client_name character varying, client_surname character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    statement TEXT;
BEGIN
	statement := format('SELECT e.*, u.login, c.name, c.surname  FROM estimates e LEFT JOIN users u ON u.id = e.creator_id
						LEFT JOIN clients c ON c.id = e.client_id WHERE e.id = %L', _estimate_id);
	
	RETURN QUERY EXECUTE statement;
END;
$$;


ALTER FUNCTION public.get_estimate_by_id(_estimate_id integer) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 16995)
-- Name: get_estimates_details_by_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_estimates_details_by_id(_estimate_id integer) RETURNS TABLE(id integer, estimate_id integer, equipment_id integer, price_id integer, count integer, equipment_title character varying, price real)
    LANGUAGE plpgsql
    AS $$
DECLARE
    statement TEXT;
BEGIN
	statement := format('SELECT ed.*, e.title, p.price FROM estimates_details ed LEFT JOIN equipments e ON e.id = ed.equipment_id
		LEFT JOIN prices p ON p.id = ed.price_id WHERE ed.estimate_id = %L', _estimate_id);
	RETURN QUERY EXECUTE statement;
END;
$$;


ALTER FUNCTION public.get_estimates_details_by_id(_estimate_id integer) OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 16992)
-- Name: get_filtered_estimates(timestamp without time zone, timestamp without time zone, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_filtered_estimates(_start_date timestamp without time zone, _close_date timestamp without time zone, _client_id integer) RETURNS TABLE(id integer, creator_id integer, client_id integer, project character varying, start_date timestamp without time zone, close_date timestamp without time zone, comment character varying, payed_date timestamp without time zone, is_payed boolean, create_date timestamp without time zone, client_name character varying, client_surname character varying, creator_login character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    statement TEXT;
BEGIN
	statement := 'SELECT e.*, c.name client_name, c.surname client_surname, u.login FROM estimates e LEFT JOIN clients c ON c.id = e.client_id
	LEFT JOIN users u ON u.id = e.creator_id WHERE 1=1 AND';
	IF (_start_date IS NOT NULL) THEN
		statement := format('%s CAST(e.start_date as DATE) = CAST(%L as DATE) AND', statement, _start_date);
	END IF;
	IF (_close_date IS NOT NULL) THEN
		statement := format('%s CAST(e.close_date as DATE) = CAST(%L as DATE) AND', statement, _close_date);
	END IF;
	IF (_client_id IS NOT NULL) THEN
		statement := format('%s e.client_id = %L AND', statement, _client_id);
		
	END IF;
	statement := format('%s 1=1 ORDER BY e.start_date DESC;', statement);
	RETURN QUERY EXECUTE statement;
END;
$$;


ALTER FUNCTION public.get_filtered_estimates(_start_date timestamp without time zone, _close_date timestamp without time zone, _client_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 214 (class 1259 OID 16662)
-- Name: categories; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    parent_id integer,
    title character varying(32) NOT NULL
);


ALTER TABLE public.categories OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 16661)
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.categories ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 212 (class 1259 OID 16650)
-- Name: clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clients (
    id integer NOT NULL,
    name character varying(32) NOT NULL,
    surname character varying(32) DEFAULT ''::character varying,
    phone character varying(11) NOT NULL,
    telegram character varying(64) DEFAULT NULL::character varying,
    comment character varying(128) DEFAULT NULL::character varying,
    discount integer DEFAULT 0
);


ALTER TABLE public.clients OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 16649)
-- Name: clients_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.clients ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 216 (class 1259 OID 16681)
-- Name: equipments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipments (
    id integer NOT NULL,
    parent_id integer,
    title character varying(128) NOT NULL,
    category_id integer NOT NULL,
    description character varying(2048) DEFAULT NULL::character varying,
    images character varying(128)[] DEFAULT NULL::character varying[],
    count integer DEFAULT 1
);


ALTER TABLE public.equipments OWNER TO postgres;

--
-- TOC entry 215 (class 1259 OID 16680)
-- Name: equipments_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.equipments ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.equipments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 220 (class 1259 OID 16698)
-- Name: estimates; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estimates (
    id integer NOT NULL,
    creator_id integer NOT NULL,
    client_id integer NOT NULL,
    project character varying(32) DEFAULT NULL::character varying,
    start_date timestamp without time zone NOT NULL,
    close_date timestamp without time zone NOT NULL,
    comment character varying(128) DEFAULT NULL::character varying,
    payed_date timestamp without time zone,
    is_payed boolean DEFAULT false,
    create_date timestamp without time zone DEFAULT (now())::timestamp(0) without time zone
);


ALTER TABLE public.estimates OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16845)
-- Name: estimates_details; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estimates_details (
    id integer NOT NULL,
    estimate_id integer NOT NULL,
    equipment_id integer NOT NULL,
    price_id integer NOT NULL,
    count integer DEFAULT 1
);


ALTER TABLE public.estimates_details OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16844)
-- Name: estimates_details_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.estimates_details ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.estimates_details_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 219 (class 1259 OID 16697)
-- Name: estimates_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.estimates ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.estimates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 225 (class 1259 OID 17112)
-- Name: get_categories; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.get_categories AS
 WITH RECURSIVE top_down AS (
         SELECT categories.id,
            categories.parent_id,
            categories.title,
            (categories.title)::character varying AS path,
            1 AS depth
           FROM public.categories
          WHERE (categories.parent_id IS NULL)
        UNION ALL
         SELECT t.id,
            t.parent_id,
            t.title,
            concat(r.path, ' > ', t.title) AS concat,
            (r.depth + 1)
           FROM (public.categories t
             JOIN top_down r ON ((t.parent_id = r.id)))
        )
 SELECT top_down.id,
    top_down.parent_id,
    top_down.title,
    top_down.path,
    top_down.depth
   FROM top_down
  ORDER BY top_down.path, top_down.depth;


ALTER TABLE public.get_categories OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16866)
-- Name: passports_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.passports_data (
    id integer NOT NULL,
    client_id integer NOT NULL,
    series character varying(4) DEFAULT NULL::character varying,
    number character varying(6) DEFAULT NULL::character varying,
    issued_by character varying(64) DEFAULT NULL::character varying,
    issue_date date,
    division_code character varying(7) DEFAULT NULL::character varying,
    registration_address character varying(128) DEFAULT NULL::character varying
);


ALTER TABLE public.passports_data OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16865)
-- Name: passports_data_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.passports_data ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.passports_data_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 218 (class 1259 OID 16691)
-- Name: prices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prices (
    id integer NOT NULL,
    equipment_id integer NOT NULL,
    price real NOT NULL,
    change_date timestamp without time zone DEFAULT (now())::timestamp(0) without time zone
);


ALTER TABLE public.prices OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16690)
-- Name: prices_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.prices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.prices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 210 (class 1259 OID 16644)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id integer NOT NULL,
    login character varying(32) NOT NULL,
    password character varying(256) NOT NULL,
    role character varying(64) DEFAULT 'Storer'::character varying
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 209 (class 1259 OID 16643)
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.users ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 3414 (class 0 OID 16662)
-- Dependencies: 214
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (8, NULL, 'Штативы');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (14, NULL, 'Рамы');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (15, 14, '8x8');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (16, 14, '12x12');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (17, 14, '20x20');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (18, NULL, 'Коммутация');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (19, 18, '220 В');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (20, 18, '380 В');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (21, NULL, 'Светодиодные приборы');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (9, 8, 'Без роликов');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (10, 8, 'Роликовые');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (22, 21, 'Аккумуляторные');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (23, 21, 'Сетевые');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (24, NULL, 'Разное');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (25, NULL, 'Железо');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (26, NULL, 'Текстиль');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (27, 26, '8x8');
INSERT INTO public.categories (id, parent_id, title) OVERRIDING SYSTEM VALUE VALUES (28, 26, '12x12');


--
-- TOC entry 3412 (class 0 OID 16650)
-- Dependencies: 212
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.clients (id, name, surname, phone, telegram, comment, discount) OVERRIDING SYSTEM VALUE VALUES (29, 'Скворцов', 'Петр', '87772221287', 'skvoretc', NULL, 10);
INSERT INTO public.clients (id, name, surname, phone, telegram, comment, discount) OVERRIDING SYSTEM VALUE VALUES (31, 'Смирнова', 'Евгения', '89993334455', NULL, NULL, 0);
INSERT INTO public.clients (id, name, surname, phone, telegram, comment, discount) OVERRIDING SYSTEM VALUE VALUES (32, 'Григорий', ' ', '89997776633', 'ostapov', NULL, 0);
INSERT INTO public.clients (id, name, surname, phone, telegram, comment, discount) OVERRIDING SYSTEM VALUE VALUES (28, 'Данила', 'Малинкин', '89998887766', 'borobeyka', 'Постоянный клиент', 20);


--
-- TOC entry 3416 (class 0 OID 16681)
-- Dependencies: 216
-- Data for Name: equipments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (28, 24, 'Astera Titan Tube 4', 22, 'Titan Tube яркая беспроводная трубка на базе RGBW светодиодов с возможностью индивидуального управления пикселями, как с помощью кнопок на корпусе или ИК-пульта, так и через мобильное приложения AsteraApp совместно с беспроводным интерфейсом Astera ART7 AsteraBox. Также Titan Tube может подключаться к сети DMX через специальный гибридный кабель питания и данных.', '{https://i.ibb.co/n01LMSc/f160d370ac2b.jpg,https://i.ibb.co/mC8xRFg/c2f35b9a0667.jpg}', 5);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (29, 25, 'NanLux Evoke 1200 Led Spot Light 65280 Lux', 23, 'Компания NANLUX представляет совершенно новый прибор Evoke 1200. Evoke 1200 это точечный светодиодный светильник мощностью 1200W, сочетает беспрецедентный уровень четкого и яркого светодиодного освещения с множеством вариантов конфигурации.', '{https://i.ibb.co/Q6XCT7P/46267a1f31ac.jpg,https://i.ibb.co/TBP3Fqr/6c44fd5ddc8b.jpg}', 1);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (17, NULL, 'Рама 12x12', 25, 'Стальная сборная рама 12x12 футов из квадратного профиля', '{https://i.ibb.co/rxB6K98/3bc6603ae3f8.jpg}', 9);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (15, NULL, 'Рама 8x8', 25, 'Стальная сборная рама 8x8 футов из квадратного профиля', '{https://i.ibb.co/7V18nMs/4c8764be98b4.jpg}', 6);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (23, 22, 'Вынос Avenger Boom Arm A470', 25, 'Используется для установки световых приборов и другого съемочного оборудования.', '{https://i.ibb.co/HHDJ2XY/0f43c76b332a.jpg}', 3);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (25, 24, 'Вынос Avenger Mini Boom D600CB', 25, 'Телескопический журавль. Пригодиться тебе, если нужно вынести небольшой световой прибор или фрост-раму.', '{https://i.ibb.co/StStdH2/d7a233de74ea.jpg}', 7);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (21, 17, 'Фон Chromakey Blue / Green', 28, 'Текстиль Chromakey Blue / Green. Двусторонний', '{https://i.ibb.co/nff3LY4/8f08cba3faec.jpg}', 6);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (24, NULL, 'Avenger A2033LKIT C-Stand', 25, 'Стойка для оборудования Avenger A2033LKIT C-Stand, удлинительная штанга', '{https://i.ibb.co/YfZXCWx/a906b4bdbcd4.jpg}', 18);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (22, NULL, 'Avenger B150P', 10, 'Стойка Avenger B150P-1 Strato Safe Stand с 4 подъемниками', '{https://i.ibb.co/qCBrpvR/9534d8572446.jpg}', 1);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (26, 15, 'Текстиль Full Grid', 27, 'Текстиль 8x8 Soft Diffusion (Full Grid), для модульной рамы.', '{https://i.ibb.co/hcbr40h/0fc667f7ee57.jpg}', 2);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (27, 17, 'Текстиль Full Grid', 28, 'Текстиль 12x12 Soft Diffusion  (Full Grid), для модульной рамы.', '{https://i.ibb.co/hcbr40h/0fc667f7ee57.jpg}', 3);
INSERT INTO public.equipments (id, parent_id, title, category_id, description, images, count) OVERRIDING SYSTEM VALUE VALUES (16, 15, 'Фон Chromakey Blue / Green', 27, 'Текстиль Chromakey Blue / Green.
Двусторонний', '{https://i.ibb.co/nff3LY4/8f08cba3faec.jpg}', 5);


--
-- TOC entry 3420 (class 0 OID 16698)
-- Dependencies: 220
-- Data for Name: estimates; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.estimates (id, creator_id, client_id, project, start_date, close_date, comment, payed_date, is_payed, create_date) OVERRIDING SYSTEM VALUE VALUES (22, 1, 32, 'Beauty съемка', '2022-12-19 00:38:00', '2022-12-21 00:38:00', NULL, NULL, false, '2022-12-19 00:38:35');
INSERT INTO public.estimates (id, creator_id, client_id, project, start_date, close_date, comment, payed_date, is_payed, create_date) OVERRIDING SYSTEM VALUE VALUES (23, 1, 28, '-', '2022-12-19 00:39:00', '2022-12-19 05:39:00', NULL, '2022-12-19 00:42:27', true, '2022-12-19 00:39:27');
INSERT INTO public.estimates (id, creator_id, client_id, project, start_date, close_date, comment, payed_date, is_payed, create_date) OVERRIDING SYSTEM VALUE VALUES (24, 1, 31, 'Тряпки ', '2022-12-23 00:46:00', '2022-12-27 00:46:00', NULL, NULL, false, '2022-12-19 00:46:33');
INSERT INTO public.estimates (id, creator_id, client_id, project, start_date, close_date, comment, payed_date, is_payed, create_date) OVERRIDING SYSTEM VALUE VALUES (25, 2, 28, 'Без названия', '2022-12-31 00:47:00', '2023-01-01 00:47:00', NULL, NULL, false, '2022-12-19 00:47:32');


--
-- TOC entry 3422 (class 0 OID 16845)
-- Dependencies: 222
-- Data for Name: estimates_details; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.estimates_details (id, estimate_id, equipment_id, price_id, count) OVERRIDING SYSTEM VALUE VALUES (30, 22, 28, 49, 2);
INSERT INTO public.estimates_details (id, estimate_id, equipment_id, price_id, count) OVERRIDING SYSTEM VALUE VALUES (31, 22, 25, 52, 2);
INSERT INTO public.estimates_details (id, estimate_id, equipment_id, price_id, count) OVERRIDING SYSTEM VALUE VALUES (32, 22, 24, 54, 7);
INSERT INTO public.estimates_details (id, estimate_id, equipment_id, price_id, count) OVERRIDING SYSTEM VALUE VALUES (33, 23, 27, 47, 1);
INSERT INTO public.estimates_details (id, estimate_id, equipment_id, price_id, count) OVERRIDING SYSTEM VALUE VALUES (34, 23, 21, 34, 1);
INSERT INTO public.estimates_details (id, estimate_id, equipment_id, price_id, count) OVERRIDING SYSTEM VALUE VALUES (35, 23, 15, 31, 1);
INSERT INTO public.estimates_details (id, estimate_id, equipment_id, price_id, count) OVERRIDING SYSTEM VALUE VALUES (36, 23, 17, 30, 2);
INSERT INTO public.estimates_details (id, estimate_id, equipment_id, price_id, count) OVERRIDING SYSTEM VALUE VALUES (37, 24, 27, 47, 3);
INSERT INTO public.estimates_details (id, estimate_id, equipment_id, price_id, count) OVERRIDING SYSTEM VALUE VALUES (38, 25, 15, 31, 3);
INSERT INTO public.estimates_details (id, estimate_id, equipment_id, price_id, count) OVERRIDING SYSTEM VALUE VALUES (39, 25, 17, 30, 1);


--
-- TOC entry 3424 (class 0 OID 16866)
-- Dependencies: 224
-- Data for Name: passports_data; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.passports_data (id, client_id, series, number, issued_by, issue_date, division_code, registration_address) OVERRIDING SYSTEM VALUE VALUES (2, 31, '4444', '555666', 'МФЦ г. Москва', '2022-12-16', '234-123', 'г. Москва, ул. Прекрасная, д. 13');
INSERT INTO public.passports_data (id, client_id, series, number, issued_by, issue_date, division_code, registration_address) OVERRIDING SYSTEM VALUE VALUES (3, 29, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO public.passports_data (id, client_id, series, number, issued_by, issue_date, division_code, registration_address) OVERRIDING SYSTEM VALUE VALUES (4, 32, '1111', '222333', 'ГУ МВД России', '2008-12-01', '444-222', 'г. Москва, ул. Волшебная, д. 177');


--
-- TOC entry 3418 (class 0 OID 16691)
-- Dependencies: 218
-- Data for Name: prices; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (20, 15, 300, '2022-12-18 22:06:09');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (24, 16, 0, '2022-12-18 22:47:07');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (25, 16, 560, '2022-12-18 22:47:16');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (26, 16, 560, '2022-12-18 22:58:41');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (27, 17, 300, '2022-12-18 22:59:59');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (28, 21, 400, '2022-12-18 23:42:20');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (29, 21, 400, '2022-12-18 23:42:23');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (30, 17, 300, '2022-12-18 23:43:22');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (31, 15, 300, '2022-12-18 23:43:28');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (32, 21, 400, '2022-12-18 23:58:16');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (33, 21, 390, '2022-12-18 23:58:53');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (34, 21, 390, '2022-12-18 23:58:57');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (36, 22, 240, '2022-12-19 00:02:33');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (37, 22, 240, '2022-12-19 00:02:37');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (40, 25, 170, '2022-12-19 00:10:22');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (41, 25, 170, '2022-12-19 00:10:32');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (42, 23, 230, '2022-12-19 00:10:46');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (43, 26, 340, '2022-12-19 00:12:49');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (44, 26, 340, '2022-12-19 00:12:52');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (45, 27, 540, '2022-12-19 00:13:28');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (46, 26, 340, '2022-12-19 00:13:40');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (47, 27, 540, '2022-12-19 00:14:00');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (48, 28, 2400, '2022-12-19 00:16:26');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (49, 28, 2400, '2022-12-19 00:16:33');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (50, 29, 2310, '2022-12-19 00:18:16');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (51, 23, 230, '2022-12-19 00:18:27');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (52, 25, 170, '2022-12-19 00:18:43');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (53, 24, 140, '2022-12-19 00:35:23');
INSERT INTO public.prices (id, equipment_id, price, change_date) OVERRIDING SYSTEM VALUE VALUES (54, 24, 140, '2022-12-19 00:37:55');


--
-- TOC entry 3410 (class 0 OID 16644)
-- Dependencies: 210
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.users (id, login, password, role) OVERRIDING SYSTEM VALUE VALUES (1, 'borobeyka', 'pbkdf2:sha256:260000$NQ74K2BadnVL7UM3$cf4c9c2e5720ffde53c9f08775b45bae359c0ae4feed483fc266df07a0e1f06e', 'Owner');
INSERT INTO public.users (id, login, password, role) OVERRIDING SYSTEM VALUE VALUES (2, 'michael', 'pbkdf2:sha256:260000$uk2GwJnJoUlU1Lpc$5c68c02371c9fc121b27891ebb054ada55612ad09a74f838cfd4af79d1722c86', 'Storer');


--
-- TOC entry 3431 (class 0 OID 0)
-- Dependencies: 213
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categories_id_seq', 28, true);


--
-- TOC entry 3432 (class 0 OID 0)
-- Dependencies: 211
-- Name: clients_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clients_id_seq', 32, true);


--
-- TOC entry 3433 (class 0 OID 0)
-- Dependencies: 215
-- Name: equipments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipments_id_seq', 29, true);


--
-- TOC entry 3434 (class 0 OID 0)
-- Dependencies: 221
-- Name: estimates_details_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.estimates_details_id_seq', 39, true);


--
-- TOC entry 3435 (class 0 OID 0)
-- Dependencies: 219
-- Name: estimates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.estimates_id_seq', 25, true);


--
-- TOC entry 3436 (class 0 OID 0)
-- Dependencies: 223
-- Name: passports_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.passports_data_id_seq', 4, true);


--
-- TOC entry 3437 (class 0 OID 0)
-- Dependencies: 217
-- Name: prices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prices_id_seq', 54, true);


--
-- TOC entry 3438 (class 0 OID 0)
-- Dependencies: 209
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- TOC entry 3244 (class 2606 OID 16666)
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- TOC entry 3242 (class 2606 OID 16654)
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- TOC entry 3246 (class 2606 OID 16689)
-- Name: equipments equipments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT equipments_pkey PRIMARY KEY (id);


--
-- TOC entry 3252 (class 2606 OID 16849)
-- Name: estimates_details estimates_details_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estimates_details
    ADD CONSTRAINT estimates_details_pkey PRIMARY KEY (id);


--
-- TOC entry 3250 (class 2606 OID 16703)
-- Name: estimates estimates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estimates
    ADD CONSTRAINT estimates_pkey PRIMARY KEY (id);


--
-- TOC entry 3254 (class 2606 OID 16870)
-- Name: passports_data passports_data_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passports_data
    ADD CONSTRAINT passports_data_pkey PRIMARY KEY (id);


--
-- TOC entry 3248 (class 2606 OID 16696)
-- Name: prices prices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT prices_pkey PRIMARY KEY (id);


--
-- TOC entry 3240 (class 2606 OID 16648)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 3268 (class 2620 OID 16882)
-- Name: passports_data clients_passport_update_checker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER clients_passport_update_checker BEFORE INSERT OR UPDATE ON public.passports_data FOR EACH ROW EXECUTE FUNCTION public.clients_passport_update_checker();


--
-- TOC entry 3265 (class 2620 OID 16880)
-- Name: clients clients_personal_update_checker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER clients_personal_update_checker BEFORE INSERT OR UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION public.clients_personal_update_checker();


--
-- TOC entry 3266 (class 2620 OID 17120)
-- Name: equipments equipments_update_checker; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER equipments_update_checker BEFORE INSERT OR UPDATE ON public.equipments FOR EACH ROW EXECUTE FUNCTION public.equipments_update_checker();


--
-- TOC entry 3267 (class 2620 OID 17001)
-- Name: estimates estimates_payed_updater; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER estimates_payed_updater BEFORE INSERT OR UPDATE ON public.estimates FOR EACH ROW EXECUTE FUNCTION public.estimates_payed_updater();


--
-- TOC entry 3257 (class 2606 OID 16730)
-- Name: equipments fk_category_id__categories; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT fk_category_id__categories FOREIGN KEY (category_id) REFERENCES public.categories(id) NOT VALID;


--
-- TOC entry 3260 (class 2606 OID 16750)
-- Name: estimates fk_client_id__clients; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estimates
    ADD CONSTRAINT fk_client_id__clients FOREIGN KEY (client_id) REFERENCES public.clients(id) NOT VALID;


--
-- TOC entry 3264 (class 2606 OID 16871)
-- Name: passports_data fk_client_id__clients; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passports_data
    ADD CONSTRAINT fk_client_id__clients FOREIGN KEY (client_id) REFERENCES public.clients(id) NOT VALID;


--
-- TOC entry 3259 (class 2606 OID 16745)
-- Name: estimates fk_creator_id__users; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estimates
    ADD CONSTRAINT fk_creator_id__users FOREIGN KEY (creator_id) REFERENCES public.users(id) NOT VALID;


--
-- TOC entry 3258 (class 2606 OID 16740)
-- Name: prices fk_equipment_id__equipments; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prices
    ADD CONSTRAINT fk_equipment_id__equipments FOREIGN KEY (equipment_id) REFERENCES public.equipments(id) NOT VALID;


--
-- TOC entry 3263 (class 2606 OID 16959)
-- Name: estimates_details fk_equipment_id__equipments; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estimates_details
    ADD CONSTRAINT fk_equipment_id__equipments FOREIGN KEY (equipment_id) REFERENCES public.equipments(id) NOT VALID;


--
-- TOC entry 3261 (class 2606 OID 16850)
-- Name: estimates_details fk_estimate_id__estimates; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estimates_details
    ADD CONSTRAINT fk_estimate_id__estimates FOREIGN KEY (estimate_id) REFERENCES public.estimates(id) NOT VALID;


--
-- TOC entry 3255 (class 2606 OID 16720)
-- Name: categories fk_parent_id__categories; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT fk_parent_id__categories FOREIGN KEY (parent_id) REFERENCES public.categories(id) NOT VALID;


--
-- TOC entry 3256 (class 2606 OID 16725)
-- Name: equipments fk_parent_id__equipments; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipments
    ADD CONSTRAINT fk_parent_id__equipments FOREIGN KEY (parent_id) REFERENCES public.equipments(id) NOT VALID;


--
-- TOC entry 3262 (class 2606 OID 16860)
-- Name: estimates_details fk_price_id__prices; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estimates_details
    ADD CONSTRAINT fk_price_id__prices FOREIGN KEY (price_id) REFERENCES public.prices(id) NOT VALID;


-- Completed on 2022-12-19 01:00:02

--
-- PostgreSQL database dump complete
--

