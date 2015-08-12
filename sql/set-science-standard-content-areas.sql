
UPDATE standards_nodes
   SET content_area_id = (SELECT id FROM content_areas WHERE code = 'SCI.EAR')
 WHERE subject = 'Science'
   AND parent_asn_id LIKE 'D%'
   AND asn_id NOT IN ('S2467516', 'S2467517', 'S2467518')
   AND (
         title ilike '%earth%' OR
         title ilike '%eco%' OR
         title ilike '%waves%transfer%'
       );

UPDATE standards_nodes
   SET content_area_id = (SELECT id FROM content_areas WHERE code = 'SCI.BIO')
 WHERE subject = 'Science'
   AND parent_asn_id LIKE 'D%'
   AND asn_id NOT IN ('S2467516', 'S2467517', 'S2467518')
   AND (
         title ilike '%bio%' OR
         title ilike '%organism%' OR
         title ilike '%heredity%' OR
         title ilike '%genetics%'
       )
    OR asn_id = 'S11367C1' -- MI: Organization and Development of Living Systems
    OR asn_id = 'S11367C2' -- MI: Interdependence of Living Systems and the Environment
    OR asn_id = 'S1130077' -- MI: Life Science
   AND content_area_id IS NULL;

UPDATE standards_nodes
   SET content_area_id = (SELECT id FROM content_areas WHERE code = 'SCI.PHY')
 WHERE subject = 'Science'
   AND parent_asn_id LIKE 'D%'
   AND asn_id NOT IN ('S2467516', 'S2467517', 'S2467518')
   AND (
         title ilike '%motion%' OR
         title ilike '%matter%' OR
         title ilike '%energy%' OR
         title ilike '%physi%'
       )
   AND content_area_id IS NULL;

UPDATE standards_nodes
   SET content_area_id = (SELECT id FROM content_areas WHERE code = 'SCI.CHM')
 WHERE subject = 'Science'
   AND parent_asn_id LIKE 'D%'
   AND asn_id NOT IN ('S2467516', 'S2467517', 'S2467518')
   AND title ilike '%chemistry%'
   AND content_area_id IS NULL;

UPDATE standards_nodes
SET content_area_id = (SELECT id FROM content_areas WHERE code = 'SCI.FDN')
WHERE subject = 'Science'
      AND parent_asn_id LIKE 'D%'
      AND asn_id NOT IN ('S2467516', 'S2467517', 'S2467518')
      AND (
        title ilike '%inquiry%reflection%implications%' OR
        title ilike '%engineering%design' OR
        title ilike '%science%processes%'
      )
      AND content_area_id IS NULL;

DO $$
  DECLARE
    row record;
  BEGIN
    FOR row IN
      SELECT get_descendant_asn_ids(asn_id) AS asn_ids,
             content_area_id
        FROM standards_nodes
       WHERE content_area_id IS NOT NULL
    LOOP
      UPDATE standards_nodes SET content_area_id = row.content_area_id WHERE asn_id = ANY(row.asn_ids);
    END LOOP;
END $$;

