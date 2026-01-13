-- DEBUG FILE
-- this is not used by the program directly
-- used to check which class to class transitions
-- were causing schedules to fail the walking time rule
-- helped catch duplicate meeting rows in the data


WITH gen AS (
  -- latest schedules 
  SELECT *
  FROM generated_schedules
  WHERE request_id = (SELECT MAX(request_id) FROM schedule_requests)
),
sched_meetings AS (
  -- expand each schedule into all its meeting rows
  SELECT DISTINCT
    g.request_id,
    g.picked_sections,
    m.meeting_id,
    m.section_id,
    m.day_of_week,
    m.start_time,
    m.end_time,
    m.building_code
  FROM gen g
  JOIN meetings m
    ON m.section_id = ANY(g.picked_sections)
),
pairs AS (
  -- for each meeting, get the next meeting that starts AFTER it, in same day same schedule
  SELECT
    sm.*,
    nxt.building_code AS next_bldg,
    nxt.start_time     AS next_start_time
  FROM sched_meetings sm
  LEFT JOIN LATERAL (
    SELECT sm2.*
    FROM sched_meetings sm2
    WHERE sm2.request_id = sm.request_id
      AND sm2.picked_sections = sm.picked_sections
      AND sm2.day_of_week = sm.day_of_week
      AND sm2.start_time > sm.start_time  
    ORDER BY sm2.start_time, sm2.end_time, sm2.meeting_id
    LIMIT 1
  ) nxt ON TRUE
)
SELECT
  request_id,
  picked_sections,
  day_of_week,
  building_code AS from_bldg,
  next_bldg     AS to_bldg,
  end_time,
  next_start_time,
  EXTRACT(EPOCH FROM (next_start_time - end_time))/60.0 AS gap_mins,
  COALESCE(w.minutes, 0) AS walk_mins,
  COALESCE(w.minutes, 0) + 10 AS needed_with_buffer,
  (next_start_time IS NOT NULL)
    AND (EXTRACT(EPOCH FROM (next_start_time - end_time))/60.0 < COALESCE(w.minutes, 0) + 10) AS fails
FROM pairs p
LEFT JOIN walking_time w
  ON w.from_building = p.building_code
 AND w.to_building   = p.next_bldg
WHERE next_start_time IS NOT NULL
ORDER BY request_id, picked_sections, day_of_week, end_time;
