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

CREATE OR REPLACE FUNCTION array_reverse(anyarray) RETURNS anyarray AS $$
  SELECT ARRAY(
      SELECT $1[i]
      FROM generate_subscripts($1,1) AS s(i)
      ORDER BY i DESC
  );
$$ LANGUAGE 'sql' STRICT IMMUTABLE;

INSERT INTO standards_documents (asn_id, jurisdiction, subject, grades, title, content_area_id) VALUES
  ('D10003FC', 'CCSS', 'English', '{"K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'English Language Arts & Literacy',  (SELECT id FROM content_areas WHERE code = 'ELA')),
  ('D10003FB', 'CCSS', 'Math', '{"K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'Mathematics',  (SELECT id FROM content_areas WHERE code = 'MATH')),
  ('D2594344', 'NJ', 'The Arts', '{"P","K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'Visual and Performing Arts',  (SELECT id FROM content_areas WHERE code = 'ART')),
  ('D2594343', 'NJ', 'Health', '{"P","K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'Health and Physical Education',  (SELECT id FROM content_areas WHERE code = 'PE')),
  ('D2594345', 'NJ', 'Social Studies', '{"P","K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'Social Studies',  (SELECT id FROM content_areas WHERE code = 'SS')),
  ('D2602363', 'NJ', 'Technology', '{"P","K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'Technology',  (SELECT id FROM content_areas WHERE code = 'TCH')),
  ('D2603532', 'NJ', 'Foreign Language', '{"3","4","5","6","7","8","9","10","11","12"}', 'World Languages',  (SELECT id FROM content_areas WHERE code = 'WL')),
  ('D2363748', 'MI', 'The Arts', '{"K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'Visual Arts, Music, Dance & Theater',  (SELECT id FROM content_areas WHERE code = 'ART')),
  ('D1000361', 'MI', 'Science', '{"9","10","11","12"}', 'Biology (HS)',  (SELECT id FROM content_areas WHERE code = 'SCI.BIO')),
  ('D1000362', 'MI', 'Science', '{"9","10","11","12"}', 'Chemistry (HS)',  (SELECT id FROM content_areas WHERE code = 'SCI.CHM')),
  ('D1000363', 'MI', 'Science', '{"9","10","11","12"}', 'Earth Science (HS)',  (SELECT id FROM content_areas WHERE code = 'SCI.EAR')),
  ('D1000394', 'MI', 'Health', '{"9","10","11","12"}', 'Credit Guidelines for Health Education',  (SELECT id FROM content_areas WHERE code = 'HLT')),
  ('D1000280', 'MI', 'Science', '{"9","10","11","12"}', '(HS) Science Essential',  (SELECT id FROM content_areas WHERE code = 'SCI.FDN')),
  ('D10003D5', 'MI', 'Physical Education', '{"K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'Physical Education',  (SELECT id FROM content_areas WHERE code = 'PE')),
  ('D1000332', 'MI', 'Science', '{"K","1","2","3","4","5","6","7"}', 'Science (K-7)',  (SELECT id FROM content_areas WHERE code = 'SCI.BIO')),
  ('D10002CE', 'MI', 'Social Studies', '{"K","1","2","3","4","5","6","7","8"}', 'Social Studies (K-8)',  (SELECT id FROM content_areas WHERE code = 'SS')),
  ('D2596842', 'MI', 'Social Studies', '{"9","10","11","12"}', 'Social Studies (HS)',  (SELECT id FROM content_areas WHERE code = 'SS')),
  ('D2587643', 'MI', 'Technology', '{"P","K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'Educational Technology for Students (METS-S)',  (SELECT id FROM content_areas WHERE code = 'TCH')),
  ('D1000395', 'MI', 'Foreign Language', '{"K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'World Language',  (SELECT id FROM content_areas WHERE code = 'WL')),
  ('D2454348', 'NGSS', 'Science', '{"K","1","2","3","4","5","6","7","8","9","10","11","12"}', 'Next Generation Science',  (SELECT id FROM content_areas WHERE code = 'SCI'));


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

  UPDATE standards_documents sd
  SET children      = (SELECT array_to_json(array_agg(row_to_json(d)))
                       FROM (
                              SELECT
                                tree.asn_id,
                                standards_nodes.parent_asn_id,
                                standards_nodes.title,
                                standards_nodes.code,
                                standards.alt_code,
                                (NOT EXISTS(SELECT asn_id
                                            FROM standards_groups sg
                                            WHERE sg.asn_id = tree.asn_id)) AS leaf
                              FROM tree
                                JOIN standards_nodes
                                  ON standards_nodes.asn_id = tree.asn_id
                                LEFT JOIN standards
                                  ON standards.asn_id = tree.asn_id
                              WHERE sd.asn_id = ANY (tree.ancestors)) d) :: JSONB,
    standards_count = (
      SELECT count(asn_id)
      FROM standards
      WHERE document_asn_id = sd.asn_id
    ),
    groups_count    = (
      SELECT count(asn_id)
      FROM standards_groups
      WHERE document_asn_id = sd.asn_id
    )
  WHERE asn_id IS NOT NULL;
END$$;

VACUUM FULL ANALYZE standards_documents;

/*
SELECT *
FROM (
       SELECT DISTINCT ON (title)
         title,
         array_length(children, 1) AS child_count,
         ((
           WITH RECURSIVE tree AS (
             SELECT
               asn_id,
               ARRAY [sg.asn_id :: TEXT] :: bpchar [] AS ancestors
             FROM standards_nodes
             WHERE parent_asn_id = sg.asn_id

             UNION ALL

             SELECT
               standards_nodes.asn_id,
               tree.ancestors || standards_nodes.parent_asn_id
             FROM standards_nodes, tree
             WHERE standards_nodes.parent_asn_id = tree.asn_id
           )

           SELECT count(asn_id)
           FROM tree
           WHERE sg.asn_id = ANY (tree.ancestors)
         )) AS descendant_count,
         jurisdiction,
         subject,
         grades,
         asn_id
       FROM standards_groups sg
       WHERE jurisdiction IN ('NGSS', 'CCSS')
       ORDER BY title
     ) AS distinct_titles
  JOIN standards_ancestors sa
    ON sa.asn_id = distinct_titles.asn_id
ORDER BY subject,
         descendant_count DESC;
/*