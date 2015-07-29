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

VACUUM FULL ANALYZE standards_groups;