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

