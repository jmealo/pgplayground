DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standards_grade') THEN
    CREATE TYPE public.standards_grade AS ENUM (
            'P',
            'K',
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
            '10',
            '11',
            '12',
            'AP'
        );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standards_grades;

CREATE MATERIALIZED VIEW public.standards_grades AS
    SELECT e.enumlabel AS "standards_grade",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standards_grade';
END$$;


DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standards_subject') THEN
    CREATE TYPE public.standards_subject AS ENUM (
            'English',
            'Math',
            'The Arts',
            'Health',
            'Social Studies',
            'Technology',
            'World Language',
            'Science',
            'Physical Education'
        );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standards_subjects;

CREATE MATERIALIZED VIEW public.standards_subjects AS
    SELECT e.enumlabel AS "standards_subject",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standards_subject';
END$$;


DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standards_jurisdiction') THEN
    CREATE TYPE public.standards_jurisdiction AS ENUM (
      'CCSS',
      'NGSS',
      'AL',
      'AK',
      'AS',
      'AZ',
      'AR',
      'CA',
      'CO',
      'CT',
      'DE',
      'DC',
      'FM',
      'FL',
      'GA',
      'GU',
      'HI',
      'ID',
      'IL',
      'IN',
      'IA',
      'KS',
      'KY',
      'LA',
      'ME',
      'MH',
      'MD',
      'MA',
      'MI',
      'MN',
      'MS',
      'MO',
      'MT',
      'NE',
      'NV',
      'NH',
      'NJ',
      'NM',
      'NY',
      'NC',
      'ND',
      'MP',
      'OH',
      'OK',
      'OR',
      'PW',
      'PA',
      'PR',
      'RI',
      'SC',
      'SD',
      'TN',
      'TX',
      'UT',
      'VT',
      'VI',
      'VA',
      'WA',
      'WV',
      'WI',
      'WY'
    );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standards_jurisdictions;

CREATE MATERIALIZED VIEW public.standards_jurisdictions AS
    SELECT e.enumlabel AS "standards_jurisdiction",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standards_jurisdiction';
END$$;


DO $$
BEGIN

CREATE TABLE IF NOT EXISTS "public"."standards_documents" (
  "id" serial,
  "asn_id" char(8),
  "title" text,
  "full_title" text,
  "subject" standards_subject,
  "jurisdiction" standards_jurisdiction,
  "grades" standards_grade[],
  "children" jsonb,
  "standards_count" integer,
  "groups_count" integer,
  "content_area_id" integer,
  PRIMARY KEY ("id")
);

TRUNCATE table standards_documents;

COPY standards_documents (
  asn_id,
  jurisdiction,
  subject,
  grades,
  title
) FROM '/tmp/standards_documents.tsv' NULL '';

DROP INDEX IF EXISTS standards_documents_asn_id_idx;
DROP INDEX IF EXISTS standards_documents_grades_idx;
DROP INDEX IF EXISTS standards_documents_subject_idx;
DROP INDEX IF EXISTS standards_documents_jurisdiction_idx;

CREATE UNIQUE INDEX standards_documents_asn_id_idx ON "standards_documents" (asn_id);
CREATE INDEX standards_documents_grades_idx ON standards_documents USING btree(grades);
CREATE INDEX standards_documents_subject_idx ON standards_documents (subject);
CREATE INDEX standards_documents_jurisdiction_idx ON standards_documents (jurisdiction);
CREATE INDEX standards_documents_content_area_id_idx ON standards_documents (content_area_id);

END$$;