DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standard_edge_type') THEN
    CREATE TYPE public.standard_edge_type AS ENUM (
      'dependency',
      'relates_to'
    );
END IF;
END$$;

DROP TABLE IF EXISTS "standards_edges";

CREATE TABLE IF NOT EXISTS "standards_edges" (
  "id" serial,
  "target_asn_id" char(8),
  "source_asn_id" char(8),
  "rel_type" standard_edge_type,
  "weight" integer,

  PRIMARY KEY ("id"),
  CONSTRAINT standard_edges_cycle_constraint UNIQUE (target_asn_id, source_asn_id, rel_type)
);

DROP INDEX IF EXISTS standards_edges_target_asn_id_idx;
DROP INDEX IF EXISTS standards_edges_source_asn_id_idx;
DROP INDEX IF EXISTS standards_edges_rel_type_idx;

TRUNCATE table standards_edges;

COPY standards_edges (
  target_asn_id,
  source_asn_id,
  rel_type,
  weight
) FROM '/tmp/math_edges.tsv' NULL '';

CREATE INDEX standards_edges_target_asn_id_idx ON "standards_edges" (target_asn_id);
CREATE INDEX standards_edges_source_asn_id_idx ON "standards_edges" (source_asn_id);
CREATE INDEX standards_edges_rel_type_idx ON "standards_edges" (rel_type);

VACUUM FULL ANALYZE standards_edges;

DROP MATERIALIZED VIEW IF EXISTS public.standards_nodes;

CREATE MATERIALIZED VIEW public.standards_nodes AS
     SELECT asn_id, code, name, subject, jurisdiction, standard_document, grades, parent_asn_id
       FROM standards
  UNION ALL
     SELECT asn_id, code, name, subject, jurisdiction, standard_document, grades, parent_asn_id
       FROM standards_groups;