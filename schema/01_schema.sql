-- Core tables for Schedule Planner

CREATE TABLE courses (
  course_id SERIAL PRIMARY KEY,
  subject TEXT NOT NULL,
  course_number TEXT NOT NULL,
  title TEXT NOT NULL,
  credits NUMERIC(3,1) NOT NULL,
  UNIQUE(subject, course_number)
);

CREATE TABLE sections (
  section_id SERIAL PRIMARY KEY,
  course_id INT NOT NULL REFERENCES courses(course_id),
  term TEXT NOT NULL,
  section_code TEXT NOT NULL, 
  status TEXT NOT NULL,     
  capacity INT,
  enrolled INT,
  UNIQUE(course_id, term, section_code)
);

CREATE TABLE meetings (
  meeting_id SERIAL PRIMARY KEY,
  section_id INT NOT NULL REFERENCES sections(section_id) ON DELETE CASCADE,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 1 AND 7),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  building_code TEXT,
  room TEXT,
  CHECK (start_time < end_time)
);

CREATE TABLE walking_time (
  from_building TEXT NOT NULL,
  to_building TEXT NOT NULL,
  minutes INT NOT NULL CHECK (minutes >= 0),
  PRIMARY KEY (from_building, to_building)
);

-- Be able to run multiple schedule requests, so students can add as many courses as they would like 

CREATE TABLE schedule_requests (
  request_id SERIAL PRIMARY KEY,
  term TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE desired_courses (
  request_id INT NOT NULL REFERENCES schedule_requests(request_id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  course_number TEXT NOT NULL,
  PRIMARY KEY (request_id, subject, course_number)
);


