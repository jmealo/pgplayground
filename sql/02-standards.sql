DROP TABLE IF EXISTS "standards";

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

CREATE UNIQUE INDEX standards_group_asn_id_idx ON "standards" (asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_code_idx ON "standards" (code) WITH (fillfactor = 100);
CREATE INDEX standards_jurisdiction_idx ON standards USING btree(jurisdiction) WITH (fillfactor = 100);
CREATE INDEX standards_grades_idx ON standards USING btree(grades) WITH (fillfactor = 100);
CREATE INDEX standards_standards_document_id ON standards (standard_document)  WITH (fillfactor = 100);
CREATE INDEX standards_subject_idx ON standards (subject)  WITH (fillfactor = 100);
CREATE INDEX standards_parent_asn_id_idx ON standards (parent_asn_id) WITH (fillfactor = 100);
CREATE INDEX standards_mb_long_idx ON standards (mb_long) WITH (fillfactor = 100);
CREATE INDEX standards_mb_short_idx ON standards (mb_short) WITH (fillfactor = 100);

VACUUM FULL ANALYZE standards;
