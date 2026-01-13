# UBC-Course-Planner

# UBC Course Planner (Postgres + SQL)

This project is a SQL-first schedule generator for UBC course data.  
Given a term and a list of desired courses, it generates **non-conflicting schedules** (combinations of sections) and can optionally filter out schedules that require unrealistic walking time between consecutive classes.

This repo is **in progress** — the database + schedule-generation logic is complete and work on sample data. The next steps being worked on is connecting to real course data + building a basic interface.

-------------------------------------------

## What this project does (at a high level)

### 1. Stores course data in a relational model
Courses → Sections → Meetings:

- **courses** = the course code and metadata (ex: CPSC 210)
- **sections** = section offerings in a term (ex: CPSC 210 LEC 101)
- **meetings** = the actual meeting times + building codes (ex: Mon 11–12:30 at DMP)

### 2. Generates schedules by building combinations of sections
The generator uses a **recursive CTE** to build schedules one course at a time:

- Start with an empty schedule (`picked_sections = []`)
- For course #1, try each possible section
- For course #2, try each section **only if it doesn’t conflict**
- Repeat until all desired courses have a section picked

Each schedule is stored as an **array of section_ids** (so one row = one full schedule).

### 3. Walking-time filtering (optional)
After schedules are generated, schedules can be filtered out if:

`gap between classes < walking_time(from_building → to_building) + buffer`

This uses meeting-to-meeting “next class” checks on the same day.

-------------------------------------------

## Repo structure

### `schema/`
**Database schema (tables + constraints).**

- `schema/01_schema.sql`  
  Creates all core tables:
  - `courses`
  - `sections`
  - `meetings`
  - `walking_time`

  It also includes constraints like:
  - meeting times must satisfy `start_time < end_time`
  - `day_of_week` must be 1–7
  - unique course codes (`subject + course_number`)
  - unique sections per course/term/code

-------------------------------------------

### `data/`
**Sample data to make the project runnable without external APIs.**

- `data/sample_data.sql`  
  Inserts sample rows into `courses`, `sections`, `meetings`.

- `data/more_sections.sql`  
  Adds extra section options so schedule generation produces multiple combinations.

- `data/sample_request.sql`  
  Inserts a sample `schedule_requests` row and matching `desired_courses` rows (the “inputs” that tell the generator what to schedule).

- `data/walking_time_sample.sql`  
  Inserts sample walking times (minutes) between building codes (ex: DMP → ANGU).

-------------------------------------------

### `queries/`
**SQL scripts that run the “planner logic.”**

- `queries/01_conflict_detection.sql`  
  Shows overlapping meeting pairs using the standard overlap rule:
  - `start1 < end2 AND start2 < end1`
  
- `queries/02_generate_schedules.sql`  
  The main schedule generator, using the following key ideas: 
  - **Recursive CTE (`WITH RECURSIVE`)** to build schedules incrementally
  - **Row numbering (`ROW_NUMBER()`)** to treat “desired courses” as an ordered list
  - **Arrays** (`picked_sections INT[]`) to store chosen section IDs for each schedule
  - **Conflict rejection** using `NOT EXISTS` + a join against meetings already chosen:
    - reject a candidate section if any meeting overlaps a meeting from an already-picked section

  Output is:
  - `request_id`
  - `picked_sections` (array of section IDs)

- `queries/03_pretty_print_schedules.sql`  
  Converts a schedule’s `picked_sections` array into readable labels like:
  `CPSC 210 LEC 101`

  Key ideas used:
  - `unnest(picked_sections)` to explode the section array into rows
  - `array_agg(... ORDER BY ...)` to rebuild nicely ordered display labels

- `queries/04_walking_time_filter.sql`  
  Filters schedules using walking-time constraints using the following key ideas:
  - turning schedules → meetings (join meetings where section_id is in the schedule array)
  - generating “current → next class” pairs on the same day using window functions (ex: `LEAD`)
  - computing time gaps using:
    - `EXTRACT(EPOCH FROM (next_start_time - end_time)) / 60.0`
  - looking up walking minutes from `walking_time`
  - excluding schedules that fail any transition

- `queries/04_walking_time_debug.sql`  
  Debug helper to print every checked transition:
  - from_building → to_building
  - gap minutes vs walk minutes + buffer
  - whether it fails

  This exists so it’s easy to verify the filter is checking the correct pairs and that walking-time lookups behave as expected.

-------------------------------------------

## SQL concepts demonstrated (skills used)

This project intentionally focuses on SQL problem solving:

- **Relational modeling**
  - normalized tables for courses/sections/meetings
  - constraints + keys to enforce data integrity

- **Recursive CTEs**
  - building combinations step-by-step
  - avoiding brute-force in application code

- **Time overlap logic**
  - correct overlap condition for intervals

- **Arrays + unnest**
  - storing each schedule as an array of chosen section IDs
  - exploding arrays back into rows for printing + checking

- **Window functions**
  - `LEAD()` to find next meeting on the same day

- **Filtering with NOT EXISTS**
  - reject candidate sections that conflict with already-chosen ones
  - remove schedules that fail walking-time constraints

-------------------------------------------

## How to run (sample workflow)

From psql (connected to an empty database):

1) Load schema:
\i schema/01_schema.sql
2) Load sample data:
\i data/sample_data.sql
\i data/more_sections.sql
\i data/walking_time_sample.sql
\i data/sample_request.sql
3) Generates schedules:
\i queries/02_generate_schedules.sql
4) Pretty print schedules:
\i queries/03_pretty_print_schedules.sql
5) Apply walking-time filter (optional):
\i queries/04_walking_time_debug.sql
