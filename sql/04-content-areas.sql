CREATE TABLE IF NOT EXISTS "content_areas" (
  "id" serial,
  "abbreviation" text,
  "code" text,
  "student_title" text,
  "teacher_title" text,
  "parent_id" integer,
  "subject" standards_subject,
  "path" ltree,
  PRIMARY KEY ("id"),
  CONSTRAINT content_areas_title_parent_id_constraint UNIQUE (parent_id, student_title, teacher_title)
);

BEGIN TRANSACTION;

DROP INDEX IF EXISTS content_areas_code_idx;
DROP INDEX IF EXISTS content_areas_parent_id_idx;
DROP INDEX IF EXISTS content_areas_abbreviation_idx;
DROP INDEX IF EXISTS content_areas_abbreviation_idx;
DROP INDEX IF EXISTS content_areas_path_gist_idx;
DROP INDEX IF EXISTS content_areas_path_idx;
DROP INDEX IF EXISTS content_areas_subject_idx;

-- TODO: Find a better way to refresh system data; take into consideration that we'll have foreign key constraints
-- (maybe we can drop all indexes and fks until the end of provisioning then re-add them?)
-- DELETE FROM "content_areas" where id <= 37;

DO $$

-- Define variables to hold the id sequence for each top-level content area
DECLARE math_id int;
DECLARE science_id int;
DECLARE english_id int;
DECLARE world_language_id int;
DECLARE social_studies_id int;
DECLARE phys_ed_id int;
DECLARE art_id int;
DECLARE tech_id int;
DECLARE health_id int;

BEGIN
  -- Insert top level content areas
  INSERT INTO "content_areas" (student_title, abbreviation, subject) VALUES ('Math', 'MAT', 'Math') RETURNING id INTO math_id;
  INSERT INTO "content_areas" (student_title, abbreviation, subject) VALUES ('Science', 'SCI', 'Science') RETURNING id INTO science_id;
  INSERT INTO "content_areas" (student_title, abbreviation, subject) VALUES ('English', 'ELA', 'English') RETURNING id INTO english_id;
  INSERT INTO "content_areas" (student_title, abbreviation, subject) VALUES ('World Language', 'WL', 'Foreign Language') RETURNING id INTO world_language_id;
  INSERT INTO "content_areas" (student_title, abbreviation, subject) VALUES ('Social Studies', 'SS', 'Social Studies') RETURNING id INTO social_studies_id;
  INSERT INTO "content_areas" (student_title, abbreviation, subject) VALUES ('Physical Education', 'PE', 'Physical Education') RETURNING id INTO phys_ed_id;
  INSERT INTO "content_areas" (student_title, abbreviation, subject) VALUES ('The Arts', 'ART', 'The Arts') RETURNING id INTO art_id;
  INSERT INTO "content_areas" (student_title, abbreviation, subject) VALUES ('Technology', 'TCH', 'Technology') RETURNING id INTO tech_id;
  INSERT INTO "content_areas" (student_title, abbreviation, subject) VALUES ('Health', 'HLT', 'Health') RETURNING id INTO health_id;

  INSERT INTO "content_areas" (student_title, abbreviation, parent_id, subject) VALUES
    -- Math
    ('Arithmetic', 'ARI', math_id, 'Math'),
    ('Algebra', 'ALG', math_id, 'Math'),
    ('Geometry', 'GEO', math_id, 'Math'),
    ('Calculus', 'CAL', math_id, 'Math'),
    ('Trigonometry', 'TRG', math_id, 'Math'),

    -- Science
    ('Biology', 'BIO', science_id, 'Science'),
    ('Physics', 'PHY', science_id, 'Science'),
    ('Chemistry', 'CHM', science_id, 'Science'),
    ('Earth', 'EAR', science_id, 'Science'),
    ('Foundation', 'FDN', science_id, 'Science'),

    -- English
    /* ('Language', english_id),
    ('Reading', english_id),
    ('Writing', english_id),
    ('Literature', english_id), */

    -- TODO: when we deprecate enums, switch subject from Foreign Language to World Language
    -- World Language
    ('Spanish', 'SPA', world_language_id, 'Foreign Language'),
    ('French', 'FRA', world_language_id, 'Foreign Language'),
    ('German', 'GER', world_language_id, 'Foreign Language'),
    ('Mandarin', 'MAN', world_language_id, 'Foreign Language'),

    -- Social Studies
    ('US Geography', 'USG', social_studies_id, 'Social Studies'),
    ('US History', 'USH', social_studies_id, 'Social Studies'),
    ('World Geography', 'GEO', social_studies_id, 'Social Studies'),
    ('World History', 'HIS', social_studies_id, 'Social Studies'),

    -- Art
    ('Dance',      'DNC', art_id, 'The Arts'),
    ('Music',      'MUS', art_id, 'The Arts'),
    ('Theatre',    'THE', art_id, 'The Arts'),
    ('Visual Art', 'VIS', art_id, 'The Arts'),

    -- Technology
    ('Programming', 'PRG', tech_id, 'Technology'),
    ('Robotics', 'ROB', tech_id, 'Technology'),
    ('Web Design', 'WEB', tech_id, 'Technology'),
    ('App Development', 'APP', tech_id, 'Technology');
END $$;

WITH RECURSIVE tree AS (
  SELECT
    id, student_title, parent_id,
    ARRAY [student_title] :: TEXT [] AS path,
    ARRAY [abbreviation] :: TEXT [] as code
  FROM content_areas WHERE parent_id IS NULL

  UNION

  SELECT
    content_areas.id, content_areas.student_title, content_areas.parent_id,
    tree.path || content_areas.student_title,
    tree.code || content_areas.abbreviation
  FROM content_areas, tree
  WHERE content_areas.parent_id = tree.id
)

UPDATE content_areas
   SET path = text2ltree(subquery.path),
       code = subquery.code
  FROM (
     SELECT id,
            replace(
                replace(
                    lower(
                        array_to_string(tree.path, '.')
                    ),
                    ' ', '_'),
                '&', 'and') AS path,
            array_to_string(tree.code, '.') AS code
       FROM tree
  ) AS subquery
 WHERE content_areas.id = subquery.id;

CREATE INDEX content_areas_code_idx ON content_areas (code);
CREATE INDEX content_areas_parent_id_idx ON content_areas (parent_id);
CREATE INDEX content_areas_abbreviation_idx ON content_areas (abbreviation);
CREATE INDEX content_areas_path_gist_idx ON content_areas USING gist(path);
CREATE INDEX content_areas_path_idx ON content_areas USING btree(path);
CREATE INDEX content_areas_subject_idx ON content_areas (subject);

UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'ELA')     WHERE asn_id = 'D10003FC';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'MAT')     WHERE asn_id = 'D10003FB';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'ART')     WHERE asn_id = 'D2594344';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'PE')      WHERE asn_id = 'D2594343';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'SS')      WHERE asn_id = 'D2594345';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'TCH')     WHERE asn_id = 'D2602363';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'WL')      WHERE asn_id = 'D2603532';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'ART')     WHERE asn_id = 'D2363748';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'SCI.BIO') WHERE asn_id = 'D1000361';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'SCI.CHM') WHERE asn_id = 'D1000362';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'SCI.EAR') WHERE asn_id = 'D1000363';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'HLT')     WHERE asn_id = 'D1000394';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'SCI.FDN') WHERE asn_id = 'D1000280';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'PE')      WHERE asn_id = 'D10003D5';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'SCI.BIO') WHERE asn_id = 'D1000332';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'SS')      WHERE asn_id = 'D10002CE';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'SS')      WHERE asn_id = 'D2596842';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'TCH')     WHERE asn_id = 'D2587643';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'WL')      WHERE asn_id = 'D1000395';
UPDATE standards_documents SET content_area_id = (SELECT id from content_areas WHERE code = 'SCI')     WHERE asn_id = 'D2454348';

COMMIT;

WITH sub_ca_asn_ids AS
(
  SELECT ca.id,
         get_descendant_standards_nodes(sd.asn_id, 1) AS asn_ids
    FROM content_areas ca
    JOIN standards_documents sd
      ON sd.content_area_id = ca.id
),
(
    SELECT *
      FROM sub_ca_asn_ids
      JOIN standards_nodes sn
        ON sn
) AS sub_ca_standards

SELECT * from sub_content_areas;

/* SELECT ca.*,
       ARRAY(SELECT id FROM sparkpoints JOIN get_descendant_standards_nodes(sd.asn_id, 1) dsn ON metadata->asn_id = dsn.asn_id) AS subcontent_areas
FROM content_areas ca JOIN standards_documents sd ON sd.content_area_id = ca.id; */

/*
SELECT  *,
  (SELECT id
     FROM sparkpoints
    WHERE metadata->>asn_id IN get_descendant_asn_ids(sd.asn_id, 1)) AS subcontent_sparkpoint_is
  FROM content_areas ca
  JOIN standards_documents sd
    ON ca.id = sd.content_area_id;

INSERT into foo_bar (foo_id, bar_id) (
  SELECT foo.id, bar.id FROM foo CROSS JOIN bar
  WHERE type = 'name' AND name IN ('selena', 'funny', 'chip')
);
*/