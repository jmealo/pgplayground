DO $$
BEGIN

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standards_grade') THEN
    CREATE TYPE public.standards_grade AS ENUM (
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

  DROP MATERIALIZED VIEW IF EXISTS public.standards_grades;

  CREATE MATERIALIZED VIEW public.standards_grades AS
    SELECT e.enumlabel AS "standards_grade",
           e.enumsortorder AS "id"
    FROM pg_enum e
      JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standards_grade';
END$$;


DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standards_subject') THEN
    CREATE TYPE public.standards_subject AS ENUM (
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

DROP MATERIALIZED VIEW IF EXISTS public.standards_subjects;

CREATE MATERIALIZED VIEW public.standards_subjects AS
    SELECT e.enumlabel AS "standards_subject",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standards_subject';
END$$;


DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standards_jurisdiction') THEN
    CREATE TYPE public.standards_jurisdiction AS ENUM (
      'CCSS',
      'NGSS',
      'AL',
      'AK',
      'AS',
      'AZ',
      'AR',
      'CA',
      'CO',
      'CT',
      'DE',
      'DC',
      'FM',
      'FL',
      'GA',
      'GU',
      'HI',
      'ID',
      'IL',
      'IN',
      'IA',
      'KS',
      'KY',
      'LA',
      'ME',
      'MH',
      'MD',
      'MA',
      'MI',
      'MN',
      'MS',
      'MO',
      'MT',
      'NE',
      'NV',
      'NH',
      'NJ',
      'NM',
      'NY',
      'NC',
      'ND',
      'MP',
      'OH',
      'OK',
      'OR',
      'PW',
      'PA',
      'PR',
      'RI',
      'SC',
      'SD',
      'TN',
      'TX',
      'UT',
      'VT',
      'VI',
      'VA',
      'WA',
      'WV',
      'WI',
      'WY'
    );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standards_jurisdictions;

CREATE MATERIALIZED VIEW public.standards_jurisdictions AS
    SELECT e.enumlabel AS "standards_jurisdiction",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standards_jurisdiction';
END$$;


DO $$
BEGIN

DROP MATERIALIZED VIEW IF EXISTS public.standards_documents;
DROP TYPE IF EXISTS public.standards_documents;

CREATE TABLE IF NOT EXISTS "public"."standards_documents" (
  "id" serial,
  "asn_id" char(8),
  "title" character varying,
  "full_title" character varying,
  "subject" standards_subject,
  "jurisdiction" standards_jurisdiction,
  "grades" standards_grade[],
  PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX standards_documents_asn_id_idx ON "standards_documents" (asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_documents_grades_idx ON standards_documents USING btree(grades) WITH (fillfactor = 100);
CREATE INDEX standards_documents_subject_idx ON standards_documents (subject)  WITH (fillfactor = 100);
CREATE INDEX standards_documents_jurisdiction_idx ON standards_documents (jurisdiction)  WITH (fillfactor = 100);

TRUNCATE table standards_documents;

COPY standards_documents (
  asn_id,
  jurisdiction,
  subject,
  grades,
  title
) FROM '/tmp/standards_documents.tsv' NULL '';


END$$;

DROP TABLE IF EXISTS "standards_groups";

CREATE TABLE IF NOT EXISTS "standards_groups" (
  "id" serial,
  "asn_id" char(8),
  "mixed_group" bool DEFAULT 'false',
  "code" varchar(31),
  "title" text,
  "subject" standards_subject,
  "jurisdiction" standards_jurisdiction,
  "grades" standards_grade[],
  "parent_asn_id" char(8),
  "document_asn_id" char(8),
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
DROP INDEX IF EXISTS standards_groups_document_asn_id_idx;

TRUNCATE table standards_groups;

COPY standards_groups (
  asn_id,
  mixed_group,
  code,
  title,
  subject,
  jurisdiction,
  grades,
  parent_asn_id,
  children,
  document_asn_id
) FROM '/tmp/standards_groups.tsv';

CREATE UNIQUE INDEX standards_group_asn_id_idx ON "standards_groups" (asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_group_code_idx ON "standards_groups" (code) WITH (fillfactor = 100);
CREATE INDEX standards_groups_jurisdiction_idx ON standards_groups USING btree(jurisdiction) WITH (fillfactor = 100);
CREATE INDEX standards_groups_grades_idx ON standards_groups USING btree(grades) WITH (fillfactor = 100);;
CREATE INDEX standards_groups_subject_idx ON standards_groups (subject)  WITH (fillfactor = 100);
CREATE INDEX standards_groups_parent_asn_id_idx ON standards_groups (parent_asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_groups_document_asn_id_idx ON standards_groups (document_asn_id) WITH (fillfactor=100);
CREATE INDEX standards_groups_children_idx ON standards_groups USING btree(children) WITH (fillfactor = 100);

VACUUM FULL ANALYZE standards_groups;

DROP TABLE IF EXISTS "standards" CASCADE;

CREATE TABLE IF NOT EXISTS "standards" (
  "id" serial,
  "asn_id" char(8),
  "code" varchar(31),
  "list_id" varchar(4),
  "alt_code" varchar(14),
  "mb_long" varchar(24),
  "mb_short" varchar(24),
  "anchor" bool,
  "title" text,
  "subject" standards_subject,
  "jurisdiction" standards_jurisdiction,
  "grades" standards_grade[],
  "parent_asn_id" char(8),
  "document_asn_id" char(8),
  PRIMARY KEY ("id"),
  UNIQUE ("asn_id")
);

DROP INDEX IF EXISTS standards_asn_id_idx;
DROP INDEX IF EXISTS standards_code_idx;
DROP INDEX IF EXISTS standards_jurisdiction_idx;
DROP INDEX IF EXISTS standards_grades_idx;
DROP INDEX IF EXISTS standards_subject_idx;
DROP INDEX IF EXISTS standards_parent_asn_id_idx;
DROP INDEX IF EXISTS standards_mb_short_idx;
DROP INDEX IF EXISTS standards_mb_long_idx;
DROP INDEX IF EXISTS standards_document_asn_id_idx;

TRUNCATE table standards;

COPY standards (
  asn_id,
  code,
  list_id,
  alt_code,
  mb_short,
  mb_long,
  anchor,
  title,
  subject,
  jurisdiction,
  grades,
  parent_asn_id,
  document_asn_id
) FROM '/tmp/standards.tsv' NULL '';

CREATE UNIQUE INDEX standards_asn_id_idx ON "standards" (asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_code_idx ON "standards" (code) WITH (fillfactor = 100);
CREATE INDEX standards_jurisdiction_idx ON standards USING btree(jurisdiction) WITH (fillfactor = 100);
CREATE INDEX standards_grades_idx ON standards USING btree(grades) WITH (fillfactor = 100);
CREATE INDEX standards_subject_idx ON standards (subject)  WITH (fillfactor = 100);
CREATE INDEX standards_parent_asn_id_idx ON standards (parent_asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_document_asn_id ON standards (document_asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_mb_long_idx ON standards (mb_long) WITH (fillfactor = 100);
CREATE INDEX standards_mb_short_idx ON standards (mb_short) WITH (fillfactor = 100);

VACUUM FULL ANALYZE standards;

DROP MATERIALIZED VIEW IF EXISTS public.standards_nodes;

CREATE MATERIALIZED VIEW public.standards_nodes AS
  SELECT
    standards.asn_id,
    standards.code,
    standards.title,
    standards.subject,
    standards.jurisdiction,
    standards.grades,
    standards.parent_asn_id,
    standards.document_asn_id
  FROM standards

  UNION ALL

  SELECT
    standards_groups.asn_id,
    standards_groups.code,
    standards_groups.title,
    standards_groups.subject,
    standards_groups.jurisdiction,
    standards_groups.grades,
    standards_groups.parent_asn_id,
    standards_groups.document_asn_id
  FROM standards_groups
WITH DATA;

CREATE UNIQUE INDEX standards_nodes_asn_id_idx ON "standards" (asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_nodes_code_idx ON "standards" (code) WITH (fillfactor = 100);
CREATE INDEX standards_nodes_jurisdiction_idx ON standards USING btree(jurisdiction) WITH (fillfactor = 100);
CREATE INDEX standards_nodes_grades_idx ON standards USING btree(grades) WITH (fillfactor = 100);
CREATE INDEX standards_nodes_subject_idx ON standards (subject)  WITH (fillfactor = 100);
CREATE INDEX standards_nodes_parent_asn_id_idx ON standards (parent_asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_nodes_document_asn_id ON standards (document_asn_id) WITH (fillfactor = 100);

VACUUM FULL ANALYZE standards_nodes;

DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standards_edge_type') THEN
    CREATE TYPE public.standards_edge_type AS ENUM (
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
  CONSTRAINT standards_edges_cycle_constraint UNIQUE (target_asn_id, source_asn_id, rel_type)
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

DROP MATERIALIZED VIEW IF EXISTS public.standards_ancestors;

CREATE MATERIALIZED VIEW public.standards_ancestors AS

  WITH RECURSIVE tree AS (
    SELECT
      asn_id,
      ARRAY [] :: bpchar [] AS ancestors
    FROM standards_nodes
    WHERE parent_asn_id IS NULL

    UNION ALL

    SELECT
      standards_nodes.asn_id,
      tree.ancestors || standards_nodes.parent_asn_id
    FROM standards_nodes, tree
    WHERE standards_nodes.parent_asn_id = tree.asn_id
  )

  SELECT *
  FROM tree;

DROP INDEX IF EXISTS standards_ancestors_asn_id;
CREATE UNIQUE INDEX standards_ancestors_asn_id ON public.standards_ancestors (asn_id);

DROP MATERIALIZED VIEW IF EXISTS public.standards_documents;

CREATE MATERIALIZED VIEW public.standards_documents AS

  WITH RECURSIVE tree AS (
    SELECT asn_id, ARRAY[]::bpchar[] AS ancestors
    FROM standards_nodes WHERE parent_asn_id IS NULL

    UNION ALL

    SELECT standards_nodes.asn_id, tree.ancestors || standards_nodes.parent_asn_id
    FROM standards_nodes, tree
    WHERE standards_nodes.parent_asn_id = tree.asn_id
  )

  SELECT outer_tree.asn_id, subject, jurisdiction, name, grades,
    (SELECT array_to_json(array_agg(row_to_json(d))) FROM (
      SELECT tree.asn_id,
        standards_nodes.parent_asn_id,
        standards_nodes.title,
        standards_nodes.code,
        standards.alt_code,
        (CASE
         WHEN (array_length(tree.ancestors, 1) >= 1 OR standards_nodes.parent_asn_id IS NULL)
           THEN false
         ELSE true
         END) AS leaf
      FROM tree
        JOIN standards_nodes
          ON standards_nodes.asn_id = tree.asn_id
        LEFT JOIN standards
          ON standards.asn_id = tree.asn_id
      WHERE outer_tree.asn_id = ANY(tree.ancestors)) d
    ) AS children
  FROM tree outer_tree
    JOIN standards_nodes ON outer_tree.asn_id = standards_nodes.asn_id
  WHERE outer_tree.asn_id LIKE 'D%';

DROP INDEX IF EXISTS standards_documents_asn_id;
CREATE UNIQUE INDEX standards_documents_asn_id ON public.standards_documents (asn_id);

