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
  "document_asn_id" char(8)  NOT NULL,
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

/*SELECT *
FROM standards_group_summary
WHERE subject = 'English' AND
    asn_id IN ('S11436A8', 'S11436A6', 'S11436A9', 'S11438D0', 'S1143938', 'S114372C', 'S11437EB', 'S114372B', 'S11436A5', 'S11437E9')
AND ARRAY ['S11436A8', 'S11436A6', 'S11436A9', 'S11438D0', 'S1143938', 'S114372C', 'S11437EB', 'S114372B', 'S11436A5', 'S11437E9']::char[]
      @> ancestors;*/

CREATE OR REPLACE FUNCTION get_descendant_standards_nodes(standard_asn_id CHAR(8))
  RETURNS SETOF standards_nodes AS $$
  WITH RECURSIVE tree AS (
    SELECT
      asn_id,
      ARRAY [$1] :: bpchar [] AS ancestors
    FROM standards_nodes
    WHERE parent_asn_id = $1

    UNION ALL

    SELECT
      standards_nodes.asn_id,
      tree.ancestors || standards_nodes.parent_asn_id
    FROM standards_nodes, tree
    WHERE standards_nodes.parent_asn_id = tree.asn_id)

  SELECT standards_nodes.*
  FROM tree
    JOIN standards_nodes ON tree.asn_id = standards_nodes.asn_id;
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_descendant_asn_ids(standard_asn_id CHAR(8))
  RETURNS bpchar[] AS $$

  WITH RECURSIVE tree AS (
    SELECT
      asn_id,
      ARRAY [$1] :: bpchar [] AS ancestors
    FROM standards_nodes
    WHERE parent_asn_id = $1

    UNION ALL

    SELECT
      standards_nodes.asn_id,
      tree.ancestors || standards_nodes.parent_asn_id
    FROM standards_nodes, tree
    WHERE standards_nodes.parent_asn_id = tree.asn_id)

  SELECT ARRAY(SELECT asn_id from tree);
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_ancestor_standards_nodes(standard_asn_id CHAR(8))
  RETURNS SETOF standards_nodes AS $$

    WITH RECURSIVE tree AS (
    SELECT
      asn_id,
      ARRAY [] :: bpchar [] AS ancestors
    FROM standards_documents

    UNION ALL

    SELECT
      standards_nodes.asn_id,
      tree.ancestors || standards_nodes.parent_asn_id
    FROM standards_nodes, tree
    WHERE standards_nodes.parent_asn_id = tree.asn_id
  )

  SELECT standards_nodes.*
    FROM tree
    JOIN standards_nodes
      ON tree.asn_id = standards_nodes.asn_id
   WHERE tree.asn_id = standard_asn_id;
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_ancestor_asn_ids(standard_asn_id CHAR(8))
  RETURNS bpchar[] AS $$

   WITH RECURSIVE tree AS (
    SELECT
      asn_id,
      ARRAY [] :: bpchar [] AS ancestors
    FROM standards_documents

    UNION ALL

    SELECT standards_nodes.asn_id,
      tree.ancestors || standards_nodes.parent_asn_id
    FROM standards_nodes, tree
    WHERE standards_nodes.parent_asn_id = tree.asn_id
  )

  SELECT ARRAY(
      SELECT asn_id
        FROM tree
       WHERE tree.asn_id = standard_asn_id
  );
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_root_asn_ids(standard_asn_id CHAR(8))
  RETURNS bpchar[] AS $$

  SELECT ARRAY(
      SELECT asn_id
        FROM standards_nodes
       WHERE parent_asn_id LIKE 'D%'
  );
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_root_standards_nodes(standard_asn_id CHAR(8))
  RETURNS SETOF standards_nodes AS $$

  SELECT * FROM standards_nodes WHERE parent_asn_id LIKE 'D%';
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_leaf_asn_ids(standard_asn_id CHAR(8))
  RETURNS bpchar[] AS $$

  SELECT ARRAY(
      SELECT asn_id
        FROM standards_nodes
       WHERE asn_id NOT IN (
         SELECT asn_id
           FROM standards_nodes
          WHERE parent_asn_id LIKE 'D%'
       )
  );
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_leaf_standards_nodes(standard_asn_id CHAR(8))
  RETURNS SETOF standards_nodes AS $$

  SELECT *
    FROM standards_nodes
   WHERE asn_id NOT IN (
      SELECT asn_id
        FROM standards_nodes
       WHERE parent_asn_id LIKE 'D%'
   );
$$
LANGUAGE SQL;

-- Depth variants of above functions

CREATE OR REPLACE FUNCTION get_descendant_standards_nodes(standard_asn_id CHAR(8), depth INTEGER)
  RETURNS SETOF standards_nodes AS $$

  WITH RECURSIVE tree AS (
    SELECT
      asn_id,
      ARRAY [$1] :: bpchar [] AS ancestors
    FROM standards_nodes
    WHERE parent_asn_id = $1

    UNION ALL

    SELECT
      standards_nodes.asn_id,
      tree.ancestors || standards_nodes.parent_asn_id
    FROM standards_nodes, tree
    WHERE standards_nodes.parent_asn_id = tree.asn_id)

  SELECT asn_id
    FROM tree
    JOIN standards_nodes ON tree.asn_id = standards_nodes.asn_id
   WHERE standard_asn_id = ANY(tree.ancestors)
     AND cardinality(tree.ancestors) <= depth;
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_descendant_asn_ids(standard_asn_id CHAR(8), depth INTEGER)
  RETURNS bpchar[] AS $$

  WITH RECURSIVE tree AS (
    SELECT
      asn_id,
      ARRAY [$1] :: bpchar [] AS ancestors
    FROM standards_nodes
    WHERE parent_asn_id = $1

    UNION ALL

    SELECT
      standards_nodes.asn_id,
      tree.ancestors || standards_nodes.parent_asn_id
    FROM standards_nodes, tree
    WHERE standards_nodes.parent_asn_id = tree.asn_id)

  SELECT ARRAY(
      SELECT asn_id
        FROM tree
       WHERE standard_asn_id = ANY(tree.ancestors)
         AND cardinality(tree.ancestors) <= depth
  );
$$
LANGUAGE SQL;

WITH RECURSIVE tree AS (
  SELECT node_id, ARRAY[]::integer[] AS ancestors
  FROM nodes WHERE parent_id IS NULL

  UNION ALL

  SELECT nodes.node_id, tree.ancestors || nodes.parent_id
  FROM nodes, tree
  WHERE nodes.parent_id = tree.node_id
) SELECT unnest(ancestors) FROM tree WHERE node_id = 15;

CREATE OR REPLACE FUNCTION get_ancestor_standards_nodes(standard_asn_id CHAR(8), depth INTEGER)
  RETURNS SETOF standards_nodes AS $$
    WITH RECURSIVE tree AS (
    SELECT
      asn_id,
      ARRAY [] :: bpchar [] AS ancestors
    FROM standards_documents

    UNION ALL

    SELECT
      standards_nodes.asn_id,
      tree.ancestors || standards_nodes.parent_asn_id
    FROM standards_nodes, tree
    WHERE standards_nodes.parent_asn_id = tree.asn_id
  )

  SELECT standards_nodes.*
    FROM tree
    JOIN standards_nodes
      ON tree.asn_id = standards_nodes.asn_id
   WHERE tree.asn_id = standard_asn_id
   LIMIT depth;
$$
LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_ancestor_asn_ids(standard_asn_id CHAR(8), depth INTEGER)
  RETURNS bpchar[] AS $$
   WITH RECURSIVE tree AS (
    SELECT
      asn_id,
      ARRAY [] :: bpchar [] AS ancestors
    FROM standards_documents

    UNION ALL

    SELECT standards_nodes.asn_id,
      tree.ancestors || standards_nodes.parent_asn_id
    FROM standards_nodes, tree
    WHERE standards_nodes.parent_asn_id = tree.asn_id
  )

  SELECT ARRAY(
      SELECT asn_id
        FROM tree
       WHERE tree.asn_id = standard_asn_id
       LIMIT depth
  );
$$
LANGUAGE SQL;