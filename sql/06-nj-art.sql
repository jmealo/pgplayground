DO $$

  -- Define variables to hold the id sequence for each top-level content area
  DECLARE art_id int;
  DECLARE dance_id int;
  DECLARE visual_arts_id int;
  DECLARE music_id int;
  DECLARE theatre_id int;

  DECLARE dance_asn_ids char(8)[] := array_cat(get_descendant_asn_ids('S2594864'), get_descendant_asn_ids(' S2594989'));
  DECLARE music_asn_ids char(8)[] = array_cat(get_descendant_asn_ids('S2595103'), get_descendant_asn_ids('S2594949'));
  DECLARE visual_arts_asn_ids char(8)[] = array_cat(get_descendant_asn_ids('S2595103'), get_descendant_asn_ids('S2594949'));
  DECLARE theatre_asn_ids char(8)[] := array_cat(get_descendant_asn_ids('S2594918'), get_descendant_asn_ids('S2595077'));


  BEGIN
    -- Insert top level content areas
    art_id := (SELECT id FROM content_areas WHERE student_title = 'The Arts');
    dance_id := (SELECT id FROM content_areas WHERE student_title = 'Dance');
    visual_arts_id := (SELECT id FROM content_areas WHERE student_title = 'Visual Arts');
    theatre_id := (SELECT id FROM content_areas WHERE student_title = 'Theatre');
    music_id := (SELECT id FROM content_areas WHERE student_title = 'Music');

    INSERT INTO sparkpoints (code, abbreviation, student_title, teacher_title, subject, grade_level, automatic, content_area_id, metadata) VALUES
      ('', 'HI', 'History of the Arts and Culture', 'History of the Arts and Culture', 'The Arts', '{K,1,2,3,4,5,6,7,8,9,10,11,12}', true, art_id, '{"asn_id": "S2594967"}'),
      ('', 'AR', 'Aesthetic Responses', 'Aesthetic Responses', 'The Arts', '{P,K,1,2,3,4,5,6,7,8,9,10,11,12}', true, art_id, '{"asn_id": "S2595154"}'),
      ('', 'CM', 'Critique Methodologies', 'Critique Methodologies', 'The Arts', '{K,1,2,3,4,5,6,7,8,9,10,11,12}', true, art_id, '{"asn_id": "S2595197"}');

   INSERT INTO sparkpoints (
    code,
    abbreviation,
    student_title,
    teacher_title,
    subject,
    grade_level,
    automatic,
    content_area_id,
    metadata
  ) (
     SELECT
       mb_long as code,
       mb_short as abbreviation,
       title as student_title,
       title as teacher_title,
       'The Arts' as subject,
       grades as grade_level,
       true as automatic,
       art_id as content_area_id,
       json_build_object('asn_id', asn_id)::JSONB AS metadata
     FROM standards WHERE parent_asn_id = ANY(SELECT asn_id FROM standards_groups WHERE parent_asn_id IN('S2594967', 'S2595154', 'S2595197') ORDER BY parent_sort_order)
   );

    -- Music
    INSERT INTO sparkpoints (
      code,
      abbreviation,
      student_title,
      teacher_title,
      subject,
      grade_level,
      automatic,
      content_area_id,
      metadata
    ) (
      SELECT
        mb_long as code,
        mb_short as abbreviation,
        title as student_title,
        title as teacher_title,
        'The Arts' as subject,
        grades as grade_level,
        true as automatic,
        music_id as content_area_id,
        json_build_object('asn_id', asn_id)::JSONB AS metadata
      FROM standards
      WHERE asn_id = ANY(music_asn_ids)
      ORDER BY parent_sort_order
    );

    -- Visual Arts
    INSERT INTO sparkpoints (
      code,
      abbreviation,
      student_title,
      teacher_title,
      subject,
      grade_level,
      automatic,
      content_area_id,
      metadata
    ) (
      SELECT
        mb_long as code,
        mb_short as abbreviation,
        title as student_title,
        title as teacher_title,
        'The Arts' as subject,
        grades as grade_level,
        true as automatic,
        visual_arts_id as content_area_id,
        json_build_object('asn_id', asn_id)::JSONB AS metadata
      FROM standards
      WHERE asn_id = ANY(visual_arts_asn_ids)
      ORDER BY parent_sort_order
    );

    -- Theatre
    INSERT INTO sparkpoints (
      code,
      abbreviation,
      student_title,
      teacher_title,
      subject,
      grade_level,
      automatic,
      content_area_id,
      metadata
    ) (
      SELECT
        mb_long as code,
        mb_short as abbreviation,
        title as student_title,
        title as teacher_title,
        'The Arts' as subject,
        grades as grade_level,
        true as automatic,
        threatre_id as content_area_id,
        json_build_object('asn_id', asn_id)::JSONB AS metadata
      FROM standards
      WHERE asn_id = ANY(theatre_asn_ids)
      ORDER BY parent_sort_order
    );

    -- Dance
    INSERT INTO sparkpoints (
      code,
      abbreviation,
      student_title,
      teacher_title,
      subject,
      grade_level,
      automatic,
      content_area_id,
      metadata
    ) (
      SELECT
        mb_long as code,
        mb_short as abbreviation,
        title as student_title,
        title as teacher_title,
        'The Arts' as subject,
        grades as grade_level,
        true as automatic,
        dance_id as content_area_id,
        json_build_object('asn_id', asn_id)::JSONB AS metadata
      FROM standards
      WHERE asn_id = ANY(dance_asn_ids)
      ORDER BY parent_sort_order
    );

    UPDATE sparkpoints
    SET teacher_title = (SELECT title
                           FROM standards_groups sg
                          WHERE sg.asn_id = (SELECT parent_asn_id
                                               FROM standards s
                                              WHERE s.asn_id = sparkpoints.metadata ->> 'asn_id'))
    WHERE subject = 'The Arts';

    UPDATE sparkpoints
       SET student_title = student_description,
           teacher_title = student_description,
           student_description = null,
           teacher_description = null
     WHERE student_title IS NULL
       AND teacher_title IS NULL;


    INSERT into sparkpoint_standard_alignments (asn_id, sparkpoint_id) (
      SELECT
        metadata ->> 'asn_id' AS asn_id,
        id                    AS sparkpoint_id
      FROM sparkpoints
     WHERE subject = 'The Arts'
    );
END $$;
