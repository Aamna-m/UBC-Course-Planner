-- walking time filter with 10 min buffer
-- take generated schedules + throw out ones where back-to-back classes are too far apart

WITH RECURSIVE
-- same schedule generator as in 02_generate_schedules 
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

  SELECT
    b.request_id,
    b.rn_done + 1,
    b.picked_sections || sfc.section_id
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
),
gen AS (
  SELECT b.request_id, b.picked_sections
  FROM build b
  JOIN max_rn m ON m.request_id = b.request_id
  WHERE b.rn_done = m.n
),

-- expand schedules into individual meetings so we can compare next class
sched_meetings AS (
  SELECT
    g.request_id,
    g.picked_sections,
    m.day_of_week,
    m.start_time,
    m.end_time,
    m.building_code,
    -- next class info on same day for this same schedule
    LEAD(m.start_time) OVER (
      PARTITION BY g.request_id, g.picked_sections, m.day_of_week
      ORDER BY m.start_time
    ) AS next_start_time,
    LEAD(m.building_code) OVER (
      PARTITION BY g.request_id, g.picked_sections, m.day_of_week
      ORDER BY m.start_time
    ) AS next_building
  FROM gen g
  JOIN meetings m ON m.section_id = ANY(g.picked_sections)
),

-- compute walking feasibility for each class -> next class pair
checks AS (
  SELECT
    request_id,
    picked_sections,
    day_of_week,
    building_code AS from_bldg,
    next_building AS to_bldg,
    end_time,
    next_start_time,

    -- minutes between classes
    EXTRACT(EPOCH FROM (next_start_time - end_time)) / 60.0 AS gap_mins,

    -- walking minutes, 0 if same building
    CASE
      WHEN next_start_time IS NULL THEN NULL
      WHEN building_code IS NULL OR next_building IS NULL THEN 0
      WHEN building_code = next_building THEN 0
      ELSE COALESCE(
        (SELECT wt.minutes
         FROM walking_time wt
         WHERE wt.from_building = building_code
           AND wt.to_building = next_building),
        0
      )
    END AS walk_mins
  FROM sched_meetings
  WHERE next_start_time IS NOT NULL
),

-- any schedule that has at least one too tight (more than 10 mins) transition is bad
bad_schedules AS (
  SELECT DISTINCT
    request_id,
    picked_sections
  FROM checks
  WHERE gap_mins < (walk_mins + 10)  -- 10 min walking buffer
)

-- keep schedules not in bad_schedules
SELECT
  g.request_id,
  g.picked_sections,
  array_agg(c.subject || ' ' || c.course_number || ' ' || s.section_code
            ORDER BY c.subject, c.course_number) AS schedule_labels
FROM gen g
JOIN LATERAL unnest(g.picked_sections) AS sid(section_id) ON true
JOIN sections s ON s.section_id = sid.section_id
JOIN courses  c ON c.course_id = s.course_id
LEFT JOIN bad_schedules b
  ON b.request_id = g.request_id
 AND b.picked_sections = g.picked_sections
WHERE b.request_id IS NULL
GROUP BY g.request_id, g.picked_sections
ORDER BY g.request_id, g.picked_sections;
