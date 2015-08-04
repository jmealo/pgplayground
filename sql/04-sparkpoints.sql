CREATE TABLE IF NOT EXISTS sparkpoints
(
  id serial NOT NULL,
  student_title character varying,
  teacher_title character varying,
  student_description character varying,
  teacher_description character varying,
  content_area_id integer,
  grade_level standard_grade[],
  metadata jsonb
);

ALTER TABLE sparkpoint
OWNER TO spark;

