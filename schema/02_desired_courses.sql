-- Be able to run multiple schedule requests, so students can add as many courses as they would like 
-- like request 1 = (CPSC 210, MATH 200), request 2 = etc
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
