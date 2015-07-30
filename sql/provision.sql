DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standard_grade') THEN
    CREATE TYPE public.standard_grade AS ENUM (
            'P',
            'K',
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '10',
            '11',
            '12',
            'AP'
        );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standard_grades;

CREATE MATERIALIZED VIEW public.standard_grades AS
    SELECT e.enumlabel AS "standard_grade",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standard_grade';
END$$;


DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standard_subject') THEN
    CREATE TYPE public.standard_subject AS ENUM (
            'English',
            'Math',
            'The Arts',
            'Health',
            'Social Studies',
            'Technology',
            'Foreign Language',
            'Science',
            'Physical Education'
        );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standard_subjects;

CREATE MATERIALIZED VIEW public.standard_subjects AS
    SELECT e.enumlabel AS "standard_subject",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standard_subject';
END$$;


DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standard_jurisdiction') THEN
    CREATE TYPE public.standard_jurisdiction AS ENUM (
            'CCSS',
            'NGSS',
            'NJ',
            'MI'
        );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standard_jurisdictions;

CREATE MATERIALIZED VIEW public.standard_jurisdictions AS
    SELECT e.enumlabel AS "standard_jurisdiction",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standard_jurisdiction';
END$$;


DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standard_document') THEN
    CREATE TYPE public.standard_document AS ENUM (
            'English Language Arts & Literacy',
            'Next Generation Science',
            'Mathematics',

            'Credit Guidelines for Health Education',
            'Health and Physical Education',
            'Physical Education',

            'Science (K-7)',
            '(HS) Science Essential',
            'Biology (HS)',
            'Chemistry (HS)',
            'Earth Science (HS)',

            'Social Studies',
            'Social Studies (K-8)',
            'Social Studies (HS)',

            'Technology',
            'Educational Technology for Students (METS-S)',

            'Visual and Performing Arts',
            'Visual Arts, Music, Dance & Theater',

            'World Language',
            'World Languages'
        );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standard_documents;

CREATE MATERIALIZED VIEW public.standard_documents AS
    SELECT e.enumlabel AS "standard_document",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standard_document';
END$$;
DROP TABLE IF EXISTS "standards_groups";

CREATE TABLE IF NOT EXISTS "standards_groups" (
    "id" serial,
    "asn_id" char(8),
    "mixed_group" bool DEFAULT 'false',
    "code" varchar(31),
    "name" text,
    "subject" standard_subject,
    "jurisdiction" standard_jurisdiction,
    "standard_document" standard_document,
    "grades" standard_grade[],
    "parent_asn_id" char(8),
    "children" char(8)[],
    PRIMARY KEY ("id"),
    UNIQUE ("asn_id")
);

DROP INDEX IF EXISTS standards_group_asn_id_idx;
DROP INDEX IF EXISTS standards_groups_code_idx;
DROP INDEX IF EXISTS standards_groups_jurisdiction_idx;
DROP INDEX IF EXISTS standards_groups_grades_idx;
DROP INDEX IF EXISTS standards_groups_standards_document_id;
DROP INDEX IF EXISTS standards_groups_subject_idx;
DROP INDEX IF EXISTS standards_groups_parent_asn_id_idx;

TRUNCATE table standards_groups;

COPY standards_groups (
    asn_id,
    mixed_group,
    code,
    name,
    subject,
    jurisdiction,
    standard_document,
    grades,
    parent_asn_id,
    children
) FROM '/tmp/standards-groups.tsv' NULL '';

CREATE UNIQUE INDEX standards_group_asn_id_idx ON "standards_groups" (asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_group_code_idx ON "standards_groups" (code) WITH (fillfactor = 100);
CREATE INDEX standards_groups_jurisdiction_idx ON standards_groups USING btree(jurisdiction) WITH (fillfactor = 100);
CREATE INDEX standards_groups_grades_idx ON standards_groups USING btree(grades) WITH (fillfactor = 100);
CREATE INDEX standards_groups_standards_document_id ON standards_groups (standard_document)  WITH (fillfactor = 100);
CREATE INDEX standards_groups_subject_idx ON standards_groups (subject)  WITH (fillfactor = 100);
CREATE INDEX standards_groups_parent_asn_id_idx ON standards_groups (parent_asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_groups_children_idx ON standards_groups USING btree(children) WITH (fillfactor = 100);

VACUUM FULL ANALYZE standards_groups;DROP TABLE IF EXISTS "standards";

CREATE TABLE IF NOT EXISTS "standards" (
  "id" serial,
  "asn_id" char(8),
  "code" varchar(31),
  "list_id" varchar(4),
  "alt_code" varchar(14),
  "mb_long" varchar(24),
  "mb_short" varchar(24),
  "anchor" bool,
  "name" text,
  "subject" standard_subject,
  "jurisdiction" standard_jurisdiction,
  "standard_document" standard_document,
  "grades" standard_grade[],
  "parent_asn_id" char(8),
  PRIMARY KEY ("id"),
  UNIQUE ("asn_id")
);

DROP INDEX IF EXISTS standards_asn_id_idx;
DROP INDEX IF EXISTS standards_code_idx;
DROP INDEX IF EXISTS standards_jurisdiction_idx;
DROP INDEX IF EXISTS standards_grades_idx;
DROP INDEX IF EXISTS standards_standards_document_id;
DROP INDEX IF EXISTS standards_subject_idx;
DROP INDEX IF EXISTS standards_parent_asn_id_idx;
DROP INDEX IF EXISTS standards_mb_short_idx;
DROP INDEX IF EXISTS standards_mb_long_idx;

TRUNCATE table standards;

COPY standards (
  asn_id,
  code,
  list_id,
  alt_code,
  mb_short,
  mb_long,
  anchor,
  name,
  subject,
  jurisdiction,
  standard_document,
  grades,
  parent_asn_id
) FROM '/tmp/standards.tsv' NULL '';

CREATE UNIQUE INDEX standards_asn_id_idx ON "standards" (asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_code_idx ON "standards" (code) WITH (fillfactor = 100);
CREATE INDEX standards_jurisdiction_idx ON standards USING btree(jurisdiction) WITH (fillfactor = 100);
CREATE INDEX standards_grades_idx ON standards USING btree(grades) WITH (fillfactor = 100);
CREATE INDEX standards_standards_document_id ON standards (standard_document)  WITH (fillfactor = 100);
CREATE INDEX standards_subject_idx ON standards (subject)  WITH (fillfactor = 100);
CREATE INDEX standards_parent_asn_id_idx ON standards (parent_asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_mb_long_idx ON standards (mb_long) WITH (fillfactor = 100);
CREATE INDEX standards_mb_short_idx ON standards (mb_short) WITH (fillfactor = 100);

VACUUM FULL ANALYZE standards;
DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standard_edge_type') THEN
    CREATE TYPE public.standard_edge_type AS ENUM (
      'dependency',
      'relates_to'
    );
END IF;
END$$;

DROP TABLE IF EXISTS "standards_edges";

CREATE TABLE IF NOT EXISTS "standards_edges" (
  "id" serial,
  "target_asn_id" char(8),
  "source_asn_id" char(8),
  "rel_type" standard_edge_type,
  "weight" integer,

  PRIMARY KEY ("id"),
  CONSTRAINT standard_edges_cycle_constraint UNIQUE (target_asn_id, source_asn_id, rel_type)
);

DROP INDEX IF EXISTS standards_edges_target_asn_id_idx;
DROP INDEX IF EXISTS standards_edges_source_asn_id_idx;
DROP INDEX IF EXISTS standards_edges_rel_type_idx;

TRUNCATE table standards_edges;

COPY standards_edges (
  target_asn_id,
  source_asn_id,
  rel_type,
  weight
) FROM '/tmp/math_edges.tsv' NULL '';

CREATE INDEX standards_edges_target_asn_id_idx ON "standards_edges" (target_asn_id);
CREATE INDEX standards_edges_source_asn_id_idx ON "standards_edges" (source_asn_id);
CREATE INDEX standards_edges_rel_type_idx ON "standards_edges" (rel_type);

VACUUM FULL ANALYZE standards_edges;

DROP MATERIALIZED VIEW IF EXISTS public.standards_nodes;

CREATE MATERIALIZED VIEW public.standards_nodes AS
     SELECT asn_id, code, name, subject, jurisdiction, standard_document, grades, parent_asn_id
       FROM standards
  UNION ALL
     SELECT asn_id, code, name, subject, jurisdiction, standard_document, grades, parent_asn_id
       FROM standards_groups;