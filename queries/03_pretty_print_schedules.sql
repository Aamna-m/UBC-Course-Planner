-- pretty print schedules for the request_id

WITH gen AS (
  -- paste the FINAL SELECT from generator here, outputs request_id, picked_sections

  WITH RECURSIVE
  desired AS (
    SELECT
      sr.request_id,
      sr.term,
      c.course_id,
      ROW_NUMBER() OVER (ORDER BY c.subject, c.course_number) AS rn
    FROM schedule_requests sr
    JOIN desired_courses dc ON dc.request_id = sr.request_id
    JOIN courses c
      ON c.subject = dc.subject
     AND c.course_number = dc.course_number
    WHERE sr.request_id = (SELECT MAX(request_id) FROM schedule_requests)
  ),
  max_rn AS (
    SELECT request_id, MAX(rn) AS n
    FROM desired
    GROUP BY request_id
  ),
  sections_for_course AS (
    SELECT d.request_id, d.rn, s.section_id
    FROM desired d
    JOIN sections s
      ON s.course_id = d.course_id
     AND s.term = d.term
  ),
  build AS (
    SELECT m.request_id, 0 AS rn_done, ARRAY[]::INT[] AS picked_sections
    FROM max_rn m
    UNION ALL
    SELECT b.request_id, b.rn_done + 1, b.picked_sections || sfc.section_id
    FROM build b
    JOIN sections_for_course sfc
      ON sfc.request_id = b.request_id
     AND sfc.rn = b.rn_done + 1
    WHERE NOT EXISTS (
      SELECT 1
      FROM meetings new_m
      JOIN meetings old_m
        ON old_m.section_id = ANY(b.picked_sections)
       AND old_m.day_of_week = new_m.day_of_week
       AND new_m.start_time < old_m.end_time
       AND old_m.start_time < new_m.end_time
      WHERE new_m.section_id = sfc.section_id
    )
  )
  SELECT b.request_id, b.picked_sections
  FROM build b
  JOIN max_rn m ON m.request_id = b.request_id
  WHERE b.rn_done = m.n
)
SELECT
  gen.request_id,
  gen.picked_sections,
  -- turn each picked section_id into a readable label
  array_agg(c.subject || ' ' || c.course_number || ' ' || sec.section_code ORDER BY c.subject, c.course_number) AS schedule_labels
FROM gen
JOIN LATERAL unnest(gen.picked_sections) AS sid(section_id) ON true
JOIN sections sec ON sec.section_id = sid.section_id
JOIN courses  c   ON c.course_id = sec.course_id
GROUP BY gen.request_id, gen.picked_sections
ORDER BY gen.request_id, gen.picked_sections;
