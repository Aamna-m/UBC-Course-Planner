-- sample walking times in minutes to test the filter

INSERT INTO walking_time (from_building, to_building, minutes) VALUES
  ('DMP','ANGU',10),
  ('ANGU','DMP',10),

  ('DMP','BUCH',12),
  ('BUCH','DMP',12),

  ('ANGU','BUCH',8),
  ('BUCH','ANGU',8)
ON CONFLICT (from_building, to_building) DO NOTHING;
