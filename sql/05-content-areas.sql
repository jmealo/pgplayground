CREATE TABLE IF NOT EXISTS "content_areas" (
  "id" serial,
  "code" text,
  "title" text,
  "parent_id" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT content_areas_title_parent_id_constraint UNIQUE (parent_id, title)
);

BEGIN TRANSACTION;

DROP INDEX IF EXISTS content_areas_code_idx;
DROP INDEX IF EXISTS content_areas_parent_id_idx;

-- TODO: Find a better way to refresh system data; take into consider that we'll have foreign key constraints
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
  INSERT INTO "content_areas" (title) VALUES ('Math') RETURNING id INTO math_id;
  INSERT INTO "content_areas" (title) VALUES ('Science') RETURNING id INTO science_id;
  INSERT INTO "content_areas" (title) VALUES ('English') RETURNING id INTO english_id;
  INSERT INTO "content_areas" (title) VALUES ('World Language') RETURNING id INTO world_language_id;
  INSERT INTO "content_areas" (title) VALUES ('Social Studies') RETURNING id INTO social_studies_id;
  INSERT INTO "content_areas" (title) VALUES ('Physical Education') RETURNING id INTO phys_ed_id;
  INSERT INTO "content_areas" (title) VALUES ('Art') RETURNING id INTO art_id;
  INSERT INTO "content_areas" (title) VALUES ('Technology') RETURNING id INTO tech_id;
  INSERT INTO "content_areas" (title) VALUES ('Health') RETURNING id INTO health_id;

  INSERT INTO "content_areas" (title, parent_id) VALUES
    -- Math
    ('Arithmetic', math_id),
    ('Algebra', math_id),
    ('Geometry', math_id),
    ('Calculus', math_id),
    ('Trigonometry', math_id),
    ('Consumer Finance', math_id),

    -- Science
    ('Biology', science_id),
    ('Physics', science_id),
    ('Chemistry', science_id),
    ('Foundation', science_id),

    -- English
    ('Reading', english_id),
    ('Writing', english_id),
    ('Literature', english_id),

    -- World Language
    ('Spanish', world_language_id),
    ('French', world_language_id),
    ('German', world_language_id),
    ('Mandarin', world_language_id),

    -- Social Studies
    ('US Geography', social_studies_id),
    ('US History', social_studies_id),
    ('World Geography', social_studies_id),
    ('World History', social_studies_id),

    -- Art
    ('Photography', art_id),
    ('Pottery', art_id),
    ('Art History', art_id),
    ('Fine Art', art_id),
    ('Color and 2D', art_id),

    -- Technology
    ('Programming', tech_id),
    ('Robotics', tech_id),
    ('Web Design', tech_id),
    ('App Development', tech_id);
END $$;

CREATE INDEX content_areas_code_idx ON content_areas (code);
CREATE INDEX content_areas_parent_id_idx ON content_areas (parent_id);

COMMIT;