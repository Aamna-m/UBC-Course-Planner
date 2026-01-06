-- Finds overlapping meetings between different sections

SELECT
  s1.section_id AS section_id_1,
  c1.subject || ' ' || c1.course_number || ' ' || s1.section_code AS section_1,
  m1.day_of_week,
  m1.start_time AS start_1,
  m1.end_time   AS end_1,
  m1.building_code AS building_1,

  s2.section_id AS section_id_2,
  c2.subject || ' ' || c2.course_number || ' ' || s2.section_code AS section_2,
  m2.start_time AS start_2,
  m2.end_time   AS end_2,
  m2.building_code AS building_2
FROM meetings m1
JOIN sections s1 ON s1.section_id = m1.section_id
JOIN courses  c1 ON c1.course_id = s1.course_id

JOIN meetings m2
  ON m2.day_of_week = m1.day_of_week
 AND m2.section_id  > m1.section_id               -- prevents duplicates + self-match
 AND m1.start_time  < m2.end_time                 -- overlap rule part 1
 AND m2.start_time  < m1.end_time                 -- overlap rule part 2

JOIN sections s2 ON s2.section_id = m2.section_id
JOIN courses  c2 ON c2.course_id = s2.course_id
ORDER BY m1.day_of_week, m1.start_time;
