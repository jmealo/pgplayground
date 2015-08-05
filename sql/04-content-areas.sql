CREATE TABLE IF NOT EXISTS "content_areas" (
  "id" serial,
  "abbreviation" text,
  "code" text,
  "title" text,
  "parent_id" integer,
  "path" ltree,
  PRIMARY KEY ("id"),
  CONSTRAINT content_areas_title_parent_id_constraint UNIQUE (parent_id, title)
);

BEGIN TRANSACTION;

DROP INDEX IF EXISTS content_areas_code_idx;
DROP INDEX IF EXISTS content_areas_parent_id_idx;
DROP INDEX IF EXISTS content_areas_abbreviation_idx;
DROP INDEX IF EXISTS content_areas_abbreviation_idx;
DROP INDEX IF EXISTS content_areas_path_gist_idx;
DROP INDEX IF EXISTS content_areas_path_idx;

-- TODO: Find a better way to refresh system data; take into consideration that we'll have foreign key constraints
-- (maybe we can drop all indexes and fks until the end of provisioning then re-add them?)
DELETE FROM "content_areas" where id <= 37;

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
  INSERT INTO "content_areas" (title, abbreviation) VALUES ('Math', 'MAT') RETURNING id INTO math_id;
  INSERT INTO "content_areas" (title, abbreviation) VALUES ('Science', 'SCI') RETURNING id INTO science_id;
  INSERT INTO "content_areas" (title, abbreviation) VALUES ('English', 'ELA') RETURNING id INTO english_id;
  INSERT INTO "content_areas" (title, abbreviation) VALUES ('World Language', 'WL') RETURNING id INTO world_language_id;
  INSERT INTO "content_areas" (title, abbreviation) VALUES ('Social Studies', 'SS') RETURNING id INTO social_studies_id;
  INSERT INTO "content_areas" (title, abbreviation) VALUES ('Physical Education', 'PE') RETURNING id INTO phys_ed_id;
  INSERT INTO "content_areas" (title, abbreviation) VALUES ('Art', 'ART') RETURNING id INTO art_id;
  INSERT INTO "content_areas" (title, abbreviation) VALUES ('Technology', 'TCH') RETURNING id INTO tech_id;
  INSERT INTO "content_areas" (title, abbreviation) VALUES ('Health', 'HLT') RETURNING id INTO health_id;

  INSERT INTO "content_areas" (title, abbreviation, parent_id) VALUES
    -- Math
    ('Arithmetic', 'ARI', math_id),
    ('Algebra', 'ALG', math_id),
    ('Geometry', 'GEO', math_id),
    ('Calculus', 'CAL', math_id),
    ('Trigonometry', 'TRG', math_id),

    -- Science
    ('Biology', 'BIO', science_id),
    ('Physics', 'PHY', science_id),
    ('Chemistry', 'CHM', science_id),
    ('Foundation', 'FDN', science_id),

    -- English
    /* ('Language', english_id),
    ('Reading', english_id),
    ('Writing', english_id),
    ('Literature', english_id), */

    -- World Language
    ('Spanish', 'SPA', world_language_id),
    ('French', 'FRA', world_language_id),
    ('German', 'GER', world_language_id),
    ('Mandarin', 'MAN', world_language_id),

    -- Social Studies
    ('US Geography', 'USG', social_studies_id),
    ('US History', 'USH', social_studies_id),
    ('World Geography', 'GEO', social_studies_id),
    ('World History', 'HIS', social_studies_id),

    -- Art
    ('Photography', 'PHO', art_id),
    ('Pottery', 'POT', art_id),
    ('Art History', 'HIS', art_id),
    ('Fine Art', 'FNE', art_id),
    ('Color and 2D', 'C2D', art_id),

    -- Technology
    ('Programming', 'PRG', tech_id),
    ('Robotics', 'ROB', tech_id),
    ('Web Design', 'WEB', tech_id),
    ('App Development', 'APP', tech_id);
END $$;

WITH RECURSIVE tree AS (
  SELECT
    id, title, parent_id,
    ARRAY [title] :: TEXT [] AS path,
    ARRAY [abbreviation] :: TEXT [] as code
  FROM content_areas WHERE parent_id IS NULL

  UNION

  SELECT
    content_areas.id, content_areas.title, content_areas.parent_id,
    tree.path || content_areas.title,
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

COMMIT;