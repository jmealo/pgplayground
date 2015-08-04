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
