-- Sample courses
INSERT INTO courses (subject, course_number, title, credits)
VALUES
  ('CPSC','210','Software Construction',4.0),
  ('MATH','200','Calculus III',3.0),
  ('WRDS','150','Writing and Research',3.0);

-- Sections
INSERT INTO sections (course_id, term, section_code, status, capacity, enrolled)
VALUES
  (1,'2025W1','LEC 101','open',200,198),
  (2,'2025W1','LEC 201','open',180,175),
  (3,'2025W1','LEC 001','open',120,110);

-- Meetings (conflict on Monday)
INSERT INTO meetings (section_id, day_of_week, start_time, end_time, building_code, room)
VALUES
  (1,1,'11:00','12:30','DMP','201'),
  (2,1,'12:00','13:00','ANGU','098'),
  (3,3,'10:00','11:00','BUCH','A101');

