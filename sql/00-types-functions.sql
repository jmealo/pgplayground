DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standard_grade') THEN
    CREATE TYPE public.standard_grade AS ENUM (
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

DROP MATERIALIZED VIEW IF EXISTS public.standard_grades;

CREATE MATERIALIZED VIEW public.standard_grades AS
    SELECT e.enumlabel AS "standard_grade",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standard_grade';
END$$;


DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standard_subject') THEN
    CREATE TYPE public.standard_subject AS ENUM (
            'English',
            'Math',
            'The Arts',
            'Health',
            'Social Studies',
            'Technology',
            'Foreign Language',
            'Science',
            'Physical Education'
        );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standard_subjects;

CREATE MATERIALIZED VIEW public.standard_subjects AS
    SELECT e.enumlabel AS "standard_subject",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standard_subject';
END$$;


DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standard_jurisdiction') THEN
    CREATE TYPE public.standard_jurisdiction AS ENUM (
            'CCSS',
            'NGSS',
            'NJ',
            'MI'
        );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standard_jurisdictions;

CREATE MATERIALIZED VIEW public.standard_jurisdictions AS
    SELECT e.enumlabel AS "standard_jurisdiction",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standard_jurisdiction';
END$$;


DO $$
BEGIN

IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'standard_document') THEN
    CREATE TYPE public.standard_document AS ENUM (
            'English Language Arts & Literacy',
            'Next Generation Science',
            'Mathematics',

            'Credit Guidelines for Health Education',
            'Health and Physical Education',
            'Physical Education',

            'Science (K-7)',
            '(HS) Science Essential',
            'Biology (HS)',
            'Chemistry (HS)',
            'Earth Science (HS)',

            'Social Studies',
            'Social Studies (K-8)',
            'Social Studies (HS)',

            'Technology',
            'Educational Technology for Students (METS-S)',

            'Visual and Performing Arts',
            'Visual Arts, Music, Dance & Theater',

            'World Language',
            'World Languages'
        );
END IF;

DROP MATERIALIZED VIEW IF EXISTS public.standard_documents;

CREATE MATERIALIZED VIEW public.standard_documents AS
    SELECT e.enumlabel AS "standard_document",
           e.enumsortorder AS "id"
     FROM pg_enum e
     JOIN pg_type t ON e.enumtypid = t.oid
    WHERE t.typname = 'standard_document';
END$$;
