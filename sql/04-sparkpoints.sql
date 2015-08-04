CREATE TABLE IF NOT EXISTS sparkpoints
(
  id serial NOT NULL,
  student_title text,
  teacher_title text,
  student_description text,
  teacher_description text,
  subject standards_subject,
  content_area_id integer,
  grade_level standards_grade[],
  metadata jsonb,

  PRIMARY KEY ("id")
);

CREATE INDEX sparkpoints_content_area_id_idx ON sparkpoints (content_area_id);
CREATE INDEX sparkpoints_subject_idx ON sparkpoints (subject);
CREATE INDEX sparkpoints_metadata_gin_idx  ON sparkpoints USING GIN (metadata);

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
