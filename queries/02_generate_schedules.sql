-- Add any number of courses) and build schedules one course at a time using recursion
-- store chosen section_ids in an array
-- when adding a new section, reject if it conflicts with any chosen section
-- feature B: generate schedules for ANY number of courses
-- student gives a list of desired courses (for a request_id)
-- output: arrays of section_ids that don't conflict

WITH RECURSIVE
desired AS (
  -- map desired course codes to course_id
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
  -- how many courses are in this request?
  SELECT request_id, MAX(rn) AS n
  FROM desired
  GROUP BY request_id
),
sections_for_course AS (
  -- all section choices for each desired course in the term
  SELECT
    d.request_id,
    d.rn,
    s.section_id
  FROM desired d
  JOIN sections s
    ON s.course_id = d.course_id
   AND s.term = d.term
),
build AS (
  -- base: start with empty schedule
  SELECT
    m.request_id,
    0 AS rn_done,
    ARRAY[]::INT[] AS picked_sections
  FROM max_rn m

  UNION ALL

  -- add a section for the next course
  SELECT
    b.request_id,
    b.rn_done + 1 AS rn_done,
    b.picked_sections || sfc.section_id AS picked_sections
  FROM build b
  JOIN sections_for_course sfc
    ON sfc.request_id = b.request_id
   AND sfc.rn = b.rn_done + 1

  -- reject this new section if it conflicts with anything already picked
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
SELECT
  b.request_id,
  b.picked_sections
FROM build b
JOIN max_rn m ON m.request_id = b.request_id
WHERE b.rn_done = m.n; 
