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
    ('Photography', 'PHO', art_id, 'The Arts'),
    ('Pottery', 'POT', art_id, 'The Arts'),
    ('Art History', 'HIS', art_id, 'The Arts'),
    ('Fine Art', 'FNE', art_id, 'The Arts'),
    ('Color and 2D', 'C2D', art_id, 'The Arts'),

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

COMMIT;