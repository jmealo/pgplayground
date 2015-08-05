CREATE TABLE IF NOT EXISTS sparkpoints
(
  id serial NOT NULL,
  abbreviation text,
  code text,
  student_title text,
  teacher_title text,
  student_description text,
  teacher_description text,
  subject standards_subject,
  content_area_id integer,
  grade_level standards_grade[],
  parent_id integer,
  automatic bool DEFAULT false, -- temporary until revision/audit logs in place
  path ltree,
  metadata jsonb,

  CONSTRAINT sparkpoints_content_area_abbreviation_parent_id_constraint UNIQUE (content_area_id, parent_id, abbreviation),
  PRIMARY KEY ("id")
);

CREATE INDEX sparkpoints_content_area_id_idx ON sparkpoints (content_area_id);
CREATE INDEX sparkpoints_subject_idx ON sparkpoints (subject);
CREATE INDEX sparkpoints_metadata_gin_idx  ON sparkpoints USING GIN (metadata);
CREATE INDEX sparkpoints_parent_id_idx ON sparkpoints (parent_id);
CREATE INDEX sparkpoints_grade_level_gin_idx ON sparkpoints USING GIST (grade_level);
CREATE INDEX sparkpoints_code_idx ON sparkpoints (code);
CREATE INDEX sparkpoints_abbreviation_idx ON sparkpoints (abbreviation);
CREATE INDEX sparkpoints_path_gist_idx ON sparkpoints USING gist(path);
CREATE INDEX sparkpoints_path_idx ON sparkpoints USING btree(path);

CREATE TABLE IF NOT EXISTS sparkpoints_edges
(
  id serial NOT NULL,
  target_asn_id char(8),
  source_asn_id char(8),
  rel_type text,
  metadata jsonb,

  PRIMARY KEY ("id"),
  CONSTRAINT sparkpoints_edges_cycle_constraint UNIQUE (target_asn_id, source_asn_id, rel_type)
);

CREATE INDEX sparkpoints_edges_metadata_gin_idx  ON sparkpoints_edges USING GIN (metadata);
CREATE INDEX sparkpoints_edges_target_asn_id_idx ON "sparkpoints_edges" (target_asn_id);
CREATE INDEX sparkpoints_edges_source_asn_id_idx ON "sparkpoints_edges" (source_asn_id);
CREATE INDEX sparkpoints_edges_rel_type_idx      ON "sparkpoints_edges" (rel_type);

-- TODO: Temporary fix for null subjects
UPDATE standards_groups SET subject = (
  SELECT subject
    FROM standards_nodes
   WHERE standards_nodes.asn_id = standards_groups.parent_asn_id)
 WHERE subject IS NULL;

DELETE FROM sparkpoints WHERE automatic = true;

DO $$

-- Define variables to hold the id sequence for each top-level content area
DECLARE writing_id int;
DECLARE reading_id int;
DECLARE speaking_id int;
DECLARE vocab_id int;
DECLARE content_area_id int;

BEGIN
  SELECT id FROM content_areas where abbreviation = 'ELA' INTO content_area_id;

  -- Insert top SparkPoints for English
  INSERT INTO "sparkpoints" (student_title, abbreviation, subject, content_area_id, automatic) VALUES (
    'Reading', 'RDG', 'English', content_area_id, true
  ) RETURNING id INTO reading_id;

  INSERT INTO "sparkpoints" (student_title, abbreviation, subject, content_area_id, automatic) VALUES (
    'Writing', 'WRT', 'English', content_area_id, true
  ) RETURNING id INTO writing_id;

  INSERT INTO "sparkpoints" (student_title, abbreviation, subject, content_area_id, automatic) VALUES (
    'Speaking and Listening', 'SPK', 'English', content_area_id, true
  ) RETURNING id INTO speaking_id;

  INSERT INTO "sparkpoints" (student_title, abbreviation, subject, content_area_id, automatic) VALUES (
    'Vocabulary', 'VOC', 'English', content_area_id, true
  ) RETURNING id INTO vocab_id;

  INSERT INTO "sparkpoints" (student_title, abbreviation, parent_id, subject, content_area_id, automatic) VALUES

    -- Reading (RDG)
    ('Foundation', 'FDN', reading_id, 'English', content_area_id, true),
    ('Informational', 'INF', reading_id, 'English', content_area_id, true),
    ('Literature', 'LIT', reading_id, 'English', content_area_id, true),

  -- Writing (WTG)
    ('Text Types', 'FDN', writing_id, 'English', content_area_id, true),
    ('Production and Process', 'INF', writing_id, 'English', content_area_id, true),
    ('Research', 'LIT', writing_id, 'English', content_area_id, true),

  -- Speaking and Listening (SPK)
    ('Collaboration', 'COL', speaking_id, 'English', content_area_id, true),
    ('Presentation', 'PRS', speaking_id, 'English', content_area_id, true),

  -- Vocabulary
    ('Context', 'CON', vocab_id, 'English', content_area_id, true),
    ('Acquisition', 'ACQ', vocab_id, 'English', content_area_id, true),
    ('Usage', 'USG', vocab_id, 'English', content_area_id, true);

END $$;

WITH RECURSIVE tree AS (
  SELECT
    id, abbreviation, parent_id, content_area_id,
    ARRAY [abbreviation] :: TEXT [] as path
  FROM sparkpoints WHERE parent_id IS NULL

  UNION

  SELECT
    sparkpoints.id, sparkpoints.abbreviation, sparkpoints.parent_id, sparkpoints.content_area_id,
    tree.path || sparkpoints.abbreviation
  FROM sparkpoints, tree
  WHERE sparkpoints.parent_id = tree.id
)

UPDATE sparkpoints
SET path = text2ltree(subquery.path),
    code = subquery.code
FROM (
       SELECT id,
         replace(
             replace(
                     array_to_string(tree.path, '.'),
                 ' ', '_'),
             '&', 'and') AS path,
         (SELECT abbreviation FROM content_areas ca WHERE ca.id = tree.content_area_id) || '.' || array_to_string(tree.path, '.') AS code
       FROM tree
     ) AS subquery
WHERE sparkpoints.id = subquery.id;