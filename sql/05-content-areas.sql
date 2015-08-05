CREATE TABLE IF NOT EXISTS "content_areas" (
  "id" serial,
  "code" text,
  "title" text,
  "parent_id" integer,
  PRIMARY KEY ("id"),
  CONSTRAINT content_areas_title_parent_id_constraint UNIQUE (parent_id, title)
);

DROP INDEX IF EXISTS content_areas_code_idx;
DROP INDEX IF EXISTS content_areas_parent_id_idx;

INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (1, null, 'Math', null);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (24, null, 'Arithmetic', 1);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (15, null, 'Algebra', 1);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (16, null, 'Geometry', 1);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (17, null, 'Calculus', 1);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (18, null, 'Trigonometry', 1);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (19, null, 'Consumer Finance', 1);

INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (2, null, 'Science', null);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (20, null, 'Biology', 2);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (21, null, 'Physics', 2);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (22, null, 'Chemistry', 2);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (23, null, 'Foundation', 2);

INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (3, null, 'English', null);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (34, null, 'Reading', 3);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (35, null, 'Writing', 3);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (36, null, 'Literature', 3);

INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (4, null, 'World Language', null);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (11, null, 'Spanish', 4);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (12, null, 'French', 4);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (13, null, 'German', 4);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (14, null, 'Mandarin', 4);

INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (5, null, 'Social Studies', null);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (31, null, 'US Geography', 5);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (32, null, 'US History', 5);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (33, null, 'World Geography', 5);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (34, null, 'World History', 5);

INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (6, null, 'Physical Education', null);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (7, null, 'Health', null);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (8, null, 'Music', null);

INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (9, null, 'Art', null);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (10, null, 'Photography', 9);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (25, null, 'Pottery', 9);

INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (26, null, 'Technology', null);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (27, null, 'Programming', 26);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (28, null, 'Robotics', 26);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (29, null, 'Web Design', 26);
INSERT INTO "content_areas"(id, code, title, parent_id) VALUES (30, null, 'App Development', 26);

CREATE INDEX content_areas_code_idx ON content_areas (code);
CREATE INDEX content_areas_parent_id_idx ON content_areas (parent_id);
