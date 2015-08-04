DROP MATERIALIZED VIEW IF EXISTS public.standards_ancestors;

CREATE MATERIALIZED VIEW public.standards_ancestors AS

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

  SELECT *
  FROM tree;

DROP INDEX IF EXISTS standards_ancestors_asn_id;
CREATE UNIQUE INDEX standards_ancestors_asn_id ON public.standards_ancestors (asn_id);

DO $$
BEGIN

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

UPDATE standards_documents sd SET children = (SELECT array_to_json(array_agg(row_to_json(d))) FROM (
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
  WHERE sd.asn_id = ANY(tree.ancestors)) d)::JSONB
  WHERE asn_id IS NOT NULL;
END$$;

VACUUM FULL ANALYZE standards_documents;