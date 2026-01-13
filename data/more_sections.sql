-- add extra section choices for each course in 2025W1

INSERT INTO sections (course_id, term, section_code, status, capacity, enrolled)
VALUES
  (1,'2025W1','LEC 102','open',200,150),
  (2,'2025W1','LEC 202','open',180,160),
  (3,'2025W1','LEC 002','open',120,90);

-- add meetings for those new sections, (Monday + Wednesday patterns)

-- CPSC 210 LEC 102
INSERT INTO meetings (section_id, day_of_week, start_time, end_time, building_code, room)
VALUES
  ((SELECT section_id FROM sections WHERE course_id=1 AND term='2025W1' AND section_code='LEC 102'), 1, '14:00', '15:30', 'DMP', '201'),
  ((SELECT section_id FROM sections WHERE course_id=1 AND term='2025W1' AND section_code='LEC 102'), 3, '14:00', '15:30', 'DMP', '201');

-- MATH 200 LEC 202
INSERT INTO meetings (section_id, day_of_week, start_time, end_time, building_code, room)
VALUES
  ((SELECT section_id FROM sections WHERE course_id=2 AND term='2025W1' AND section_code='LEC 202'), 1, '09:00', '10:00', 'ANGU', '098'),
  ((SELECT section_id FROM sections WHERE course_id=2 AND term='2025W1' AND section_code='LEC 202'), 3, '09:00', '10:00', 'ANGU', '098');

-- WRDS 150 LEC 002
INSERT INTO meetings (section_id, day_of_week, start_time, end_time, building_code, room)
VALUES
  ((SELECT section_id FROM sections WHERE course_id=3 AND term='2025W1' AND section_code='LEC 002'), 1, '10:30', '11:30', 'BUCH', 'A101'),
  ((SELECT section_id FROM sections WHERE course_id=3 AND term='2025W1' AND section_code='LEC 002'), 3, '10:30', '11:30', 'BUCH', 'A101');
