-- =====================================================================
-- populate.sql : ICC Cricket Rankings (Team 61)
-- Target: MySQL 8.0+ (icc_rankings database created by schema.sql)
-- Run with:  mysql -u <user> -p < populate.sql
-- Insertion Order: Strict parent-before-child order across all 34 tables.
-- Data Quality: Real ICC international cricket teams, players, series,
--   venues, matches, ball-by-ball deliveries, records, and rankings.
--   Includes unmatched rows (e.g. teams with no matches, players with no
--   achievements) and safe-to-update / safe-to-delete rows for the demo.
-- =====================================================================

USE icc_rankings;

-- ---------------------------------------------------------------------
-- 1. Lookup / reference tables: Country, Bowling_Style_Category
-- ---------------------------------------------------------------------
INSERT INTO Country (Country_Code, Country_Name) VALUES
  ('IND', 'India'),
  ('AUS', 'Australia'),
  ('ENG', 'England'),
  ('RSA', 'South Africa'),
  ('NZL', 'New Zealand'),
  ('PAK', 'Pakistan'),
  ('SLK', 'Sri Lanka'),
  ('WIN', 'West Indies'),
  ('AFG', 'Afghanistan'),
  ('IRE', 'Ireland');

INSERT INTO Bowling_Style_Category (Bowling_Style, Bowling_Category) VALUES
  ('Right-arm fast',         'Pace'),
  ('Right-arm fast-medium',  'Pace'),
  ('Left-arm fast',          'Pace'),
  ('Left-arm fast-medium',   'Pace'),
  ('Right-arm medium',       'Pace'),
  ('Right-arm offbreak',     'Spin'),
  ('Right-arm legbreak',     'Spin'),
  ('Left-arm orthodox',      'Spin'),
  ('Left-arm wrist-spin',    'Spin');

-- ---------------------------------------------------------------------
-- 2. Team, Team_Alternate_Name, Team_Country
--    Includes 12 teams across Men/Women and Senior/U19.
--    Team 11 (Ireland Men) and Team 12 (India U19 Women) have NO matches
--    so outer-join / non-matching cases are testable.
-- ---------------------------------------------------------------------
INSERT INTO Team (Team_ID, ICC_Team_Code, Team_Name, Gender_Category, Age_Category, Start_Year, End_Year) VALUES
  (1,  'IND', 'India',        'Men',   'Senior', 1932, NULL),
  (2,  'AUS', 'Australia',    'Men',   'Senior', 1877, NULL),
  (3,  'ENG', 'England',      'Men',   'Senior', 1877, NULL),
  (4,  'RSA', 'South Africa', 'Men',   'Senior', 1889, NULL),
  (5,  'NZL', 'New Zealand',  'Men',   'Senior', 1930, NULL),
  (6,  'PAK', 'Pakistan',     'Men',   'Senior', 1952, NULL),
  (7,  'AFG', 'Afghanistan',  'Men',   'Senior', 2009, NULL),
  (8,  'IND', 'India Women',  'Women', 'Senior', 1976, NULL),
  (9,  'AUS', 'Australia Women', 'Women', 'Senior', 1934, NULL),
  (10, 'IND', 'India U19',    'Men',   'U19',    1979, NULL),
  (11, 'IRE', 'Ireland',      'Men',   'Senior', 2007, NULL),
  (12, 'IND', 'India U19 Women', 'Women', 'U19', 2022, NULL);

INSERT INTO Team_Alternate_Name (Team_ID, Alternate_Name) VALUES
  (1, 'Men in Blue'),
  (1, 'Team India'),
  (2, 'Baggy Greens'),
  (3, 'Three Lions'),
  (4, 'Proteas'),
  (5, 'Black Caps'),
  (6, 'Shaheens'),
  (8, 'Women in Blue'),
  (9, 'Southern Stars');

INSERT INTO Team_Country (Team_ID, Country_Code) VALUES
  (1,  'IND'),
  (2,  'AUS'),
  (3,  'ENG'),
  (4,  'RSA'),
  (5,  'NZL'),
  (6,  'PAK'),
  (7,  'AFG'),
  (8,  'IND'),
  (9,  'AUS'),
  (10, 'IND'),
  (11, 'IRE'),
  (12, 'IND');

-- ---------------------------------------------------------------------
-- 3. Player, Player_Playing_Role, Represents, Represents_Tenure,
--    Captaincy_Succession, Captaincy_Transition
-- ---------------------------------------------------------------------
INSERT INTO Player (Player_ID, ICC_Registration_No, First_Name, Middle_Name, Last_Name, Date_Of_Birth, Country_Of_Birth, Batting_Hand, Bowling_Style, Biography, Debut_Date) VALUES
  (1,  'ICC-IND-001', 'Rohit',     'Gurunath', 'Sharma',     '1987-04-30', 'India',        'Right', 'Right-arm offbreak',    'Indian opener and two-time ICC trophy winning captain.', '2007-06-23'),
  (2,  'ICC-IND-002', 'Virat',     NULL,       'Kohli',      '1988-11-05', 'India',        'Right', 'Right-arm medium',      'Former India captain and all-time ODI centuries record holder.', '2008-08-18'),
  (3,  'ICC-IND-003', 'Jasprit',   'Jasbirsingh', 'Bumrah',  '1993-12-06', 'India',        'Right', 'Right-arm fast',        'Spearhead of the Indian pace attack across all three formats.', '2016-01-23'),
  (4,  'ICC-IND-004', 'Ravindra',  'Anirudhsinh', 'Jadeja',  '1988-12-06', 'India',        'Left',  'Left-arm orthodox',     'Premier spin bowling all-rounder and elite fielder.', '2009-02-08'),
  (5,  'ICC-IND-005', 'Kuldeep',   NULL,       'Yadav',      '1994-12-14', 'India',        'Left',  'Left-arm wrist-spin',   'Left-arm wrist spinner known for middle-overs wickets.', '2017-03-25'),
  (6,  'ICC-IND-006', 'Suryakumar','Ashok',    'Yadav',      '1990-09-14', 'India',        'Right', 'Right-arm offbreak',    'India T20I captain and 360-degree middle-order batter.', '2021-03-14'),
  (7,  'ICC-IND-007', 'Hardik',    'Himanshu', 'Pandya',     '1993-10-11', 'India',        'Right', 'Right-arm fast-medium', 'Seam-bowling all-rounder and finisher.', '2016-01-26'),
  (8,  'ICC-IND-008', 'Rishabh',   'Rajendra', 'Pant',       '1997-10-04', 'India',        'Left',  NULL,                    'Dynamic wicketkeeper-batter in Test and white-ball cricket.', '2017-02-01'),
  (9,  'ICC-IND-009', 'Mahendra',  'Singh',    'Dhoni',      '1981-07-07', 'India',        'Right', 'Right-arm medium',      'Former Indian captain who won the 2007 T20 WC, 2011 CWC and 2013 CT.', '2004-12-23'),
  (10, 'ICC-AUS-001', 'Pat',       'James',    'Cummins',    '1993-05-08', 'Australia',    'Right', 'Right-arm fast',        'Australian Test and ODI captain; 2023 WTC and CWC winner.', '2011-10-13'),
  (11, 'ICC-AUS-002', 'Travis',    'Michael',  'Head',       '1993-12-29', 'Australia',    'Left',  'Right-arm offbreak',    'Aggressive top-order batter; Player of the Match in 2023 CWC Final.', '2016-01-26'),
  (12, 'ICC-AUS-003', 'Mitchell',  'Aaron',    'Starc',      '1990-01-30', 'Australia',    'Left',  'Left-arm fast',         'Left-arm express pace bowler famous for swinging yorkers.', '2010-10-20'),
  (13, 'ICC-AUS-004', 'Adam',      'Video',    'Zampa',      '1992-03-31', 'Australia',    'Right', 'Right-arm legbreak',    'Australia white-ball leg-spinner.', '2016-02-06'),
  (14, 'ICC-AUS-005', 'Steven',    'Peter',    'Smith',      '1989-06-02', 'Australia',    'Right', 'Right-arm legbreak',    'Former Australian captain and modern Test batting great.', '2010-02-05'),
  (15, 'ICC-ENG-001', 'Ben',       'Andrew',   'Stokes',     '1991-06-04', 'New Zealand',  'Left',  'Right-arm fast-medium', 'England Test captain and iconic match-winning all-rounder.', '2011-08-25'),
  (16, 'ICC-ENG-002', 'Joe',       'Edward',   'Root',       '1990-12-30', 'England',      'Right', 'Right-arm offbreak',    'England all-time leading Test run-scorer and former captain.', '2012-12-13'),
  (17, 'ICC-ENG-003', 'Jos',       'Charles',  'Buttler',    '1990-09-08', 'England',      'Right', NULL,                    'England white-ball wicketkeeper-batter and 2022 T20 WC winning captain.', '2011-08-31'),
  (18, 'ICC-RSA-001', 'Aiden',     'Kyle',     'Markram',    '1994-10-04', 'South Africa', 'Right', 'Right-arm offbreak',    'South Africa T20I captain who led Proteas to the 2024 T20 WC Final.', '2017-09-28'),
  (19, 'ICC-RSA-002', 'Kagiso',    NULL,       'Rabada',     '1995-05-25', 'South Africa', 'Left',  'Right-arm fast',        'South Africa premier fast bowler across all three formats.', '2014-11-05'),
  (20, 'ICC-RSA-003', 'Heinrich',  NULL,       'Klaasen',    '1991-07-30', 'South Africa', 'Right', NULL,                    'Explosive middle-order wicketkeeper-batter.', '2018-02-07'),
  (21, 'ICC-NZL-001', 'Kane',      'Stuart',   'Williamson', '1990-08-08', 'New Zealand',  'Right', 'Right-arm offbreak',    'Former New Zealand captain and leading Test run-scorer.', '2010-08-10'),
  (22, 'ICC-PAK-001', 'Babar',     'Mohammad', 'Azam',       '1994-10-15', 'Pakistan',     'Right', 'Right-arm offbreak',    'Top-order Pakistani batter and former all-format captain.', '2015-05-31'),
  (23, 'ICC-AFG-001', 'Rashid',    NULL,       'Khan',       '1998-09-20', 'Afghanistan',  'Right', 'Right-arm legbreak',    'Afghanistan T20I captain and world-leading leg-spinner.', '2015-10-18'),
  (24, 'ICC-INDW-01', 'Harmanpreet', NULL,     'Kaur',       '1989-03-08', 'India',        'Right', 'Right-arm offbreak',    'Captain of the Indian Women national cricket team.', '2009-03-07'),
  (25, 'ICC-INDW-02', 'Smriti',    'Shrinivas','Mandhana',   '1996-07-18', 'India',        'Left',  NULL,                    'Indian Women vice-captain and prolific left-handed opener.', '2013-04-05'),
  (26, 'ICC-AUSW-01', 'Alyssa',    'Jean',     'Healy',      '1990-03-24', 'Australia',    'Right', NULL,                    'Australian Women captain and wicketkeeper-batter.', '2010-02-10'),
  (27, 'ICC-AUSW-02', 'Ellyse',    'Alexandra','Perry',      '1990-11-03', 'Australia',    'Right', 'Right-arm fast-medium', 'Legendary Australian all-rounder.', '2007-07-22'),
  (28, 'ICC-INDU-01', 'Uday',      'Pratap',   'Saharan',    '2004-09-08', 'India',        'Right', 'Right-arm offbreak',    'Captain of India U19 at the 2024 Under-19 Cricket World Cup.', '2023-12-01');

INSERT INTO Player_Playing_Role (Player_ID, Playing_Role) VALUES
  (1,  'Opening Batter'),
  (2,  'Top-order Batter'),
  (3,  'Bowler'),
  (4,  'Bowling All-rounder'),
  (5,  'Bowler'),
  (6,  'Middle-order Batter'),
  (7,  'Batting All-rounder'),
  (8,  'Wicketkeeper-Batter'),
  (9,  'Wicketkeeper-Batter'),
  (10, 'Bowler'),
  (11, 'Opening Batter'),
  (12, 'Bowler'),
  (13, 'Bowler'),
  (14, 'Top-order Batter'),
  (15, 'Batting All-rounder'),
  (16, 'Top-order Batter'),
  (17, 'Wicketkeeper-Batter'),
  (18, 'Top-order Batter'),
  (19, 'Bowler'),
  (20, 'Wicketkeeper-Batter'),
  (21, 'Top-order Batter'),
  (22, 'Top-order Batter'),
  (23, 'Bowling All-rounder'),
  (24, 'Batting All-rounder'),
  (25, 'Opening Batter'),
  (26, 'Wicketkeeper-Batter'),
  (27, 'Batting All-rounder'),
  (28, 'Middle-order Batter');

INSERT INTO Represents (Player_ID, Team_ID) VALUES
  (1,  1), (2,  1), (3,  1), (4,  1), (5,  1),
  (6,  1), (7,  1), (8,  1), (9,  1),
  (2, 10), -- Virat Kohli also represented India U19
  (10, 2), (11, 2), (12, 2), (13, 2), (14, 2),
  (15, 3), (16, 3), (17, 3),
  (18, 4), (19, 4), (20, 4),
  (21, 5), (22, 6), (23, 7),
  (24, 8), (25, 8), (26, 9), (27, 9), (28, 10);

INSERT INTO Represents_Tenure (Player_ID, Team_ID, Valid_From, Valid_To) VALUES
  (1,  1,  '2007-06-23', NULL),
  (2,  10, '2006-07-01', '2008-03-05'),
  (2,  1,  '2008-08-18', NULL),
  (3,  1,  '2016-01-23', NULL),
  (4,  1,  '2009-02-08', NULL),
  (5,  1,  '2017-03-25', NULL),
  (6,  1,  '2021-03-14', NULL),
  (7,  1,  '2016-01-26', NULL),
  (8,  1,  '2017-02-01', NULL),
  (9,  1,  '2004-12-23', '2019-07-10'),
  (10, 2,  '2011-10-13', NULL),
  (11, 2,  '2016-01-26', NULL),
  (12, 2,  '2010-10-20', NULL),
  (13, 2,  '2016-02-06', NULL),
  (14, 2,  '2010-02-05', NULL),
  (15, 3,  '2011-08-25', NULL),
  (16, 3,  '2012-12-13', NULL),
  (17, 3,  '2011-08-31', NULL),
  (18, 4,  '2017-09-28', NULL),
  (19, 4,  '2014-11-05', NULL),
  (20, 4,  '2018-02-07', NULL),
  (21, 5,  '2010-08-10', NULL),
  (22, 6,  '2015-05-31', NULL),
  (23, 7,  '2015-10-18', NULL),
  (24, 8,  '2009-03-07', NULL),
  (25, 8,  '2013-04-05', NULL),
  (26, 9,  '2010-02-10', NULL),
  (27, 9,  '2007-07-22', NULL),
  (28, 10, '2023-12-01', '2024-02-15');

-- Captaincy chain for Q5 and W3 (Delete demo on Team 1 or Team 2)
INSERT INTO Captaincy_Succession (Predecessor_ID, Successor_ID, Team_ID) VALUES
  (9,  2,  1), -- MS Dhoni -> Virat Kohli (India Men)
  (2,  1,  1), -- Virat Kohli -> Rohit Sharma (India Men)
  (1,  7,  1), -- Rohit Sharma -> Hardik Pandya (India Men stand-in T20I)
  (7,  6,  1), -- Hardik Pandya -> Suryakumar Yadav (India Men T20I, safe to delete in W3 demo)
  (14, 10, 2), -- Steven Smith -> Pat Cummins (Australia Men)
  (16, 15, 3); -- Joe Root -> Ben Stokes (England Men)

INSERT INTO Captaincy_Transition (Predecessor_ID, Successor_ID, Team_ID, Transition_Date) VALUES
  (9,  2,  1, '2017-01-04'),
  (2,  1,  1, '2021-12-08'),
  (1,  7,  1, '2022-11-18'),
  (7,  6,  1, '2024-07-27'),
  (14, 10, 2, '2021-11-26'),
  (16, 15, 3, '2022-04-28');

-- ---------------------------------------------------------------------
-- 4. Series, Series_Host, Venue
-- ---------------------------------------------------------------------
INSERT INTO Series (Series_ID, Series_Name, Series_Type, Start_Date, End_Date) VALUES
  (1, 'ICC Men''s Cricket World Cup 2023',      'ICC World Cup',     '2023-10-05', '2023-11-19'),
  (2, 'ICC Men''s T20 World Cup 2024',          'ICC T20 World Cup', '2024-06-01', '2024-06-29'),
  (3, 'Border-Gavaskar Trophy 2024-25',         'Bilateral',         '2024-11-22', '2025-01-07'),
  (4, 'England Tour of India Test Series 2024', 'Bilateral',         '2024-01-25', '2024-03-11'),
  (5, 'Australia Women Tour of India 2023-24',  'Bilateral',         '2023-12-21', '2024-01-09');

INSERT INTO Series_Host (Series_ID, Country_Code) VALUES
  (1, 'IND'),
  (2, 'WIN'),
  (3, 'AUS'),
  (4, 'IND'),
  (5, 'IND');

INSERT INTO Venue (Venue_ID, Stadium, City, Country_Code) VALUES
  (1, 'Narendra Modi Stadium',                     'Ahmedabad',  'IND'),
  (2, 'Wankhede Stadium',                          'Mumbai',     'IND'),
  (3, 'Kensington Oval',                           'Bridgetown', 'WIN'),
  (4, 'Perth Stadium',                             'Perth',      'AUS'),
  (5, 'Melbourne Cricket Ground',                  'Melbourne',  'AUS'),
  (6, 'Rajiv Gandhi International Cricket Stadium','Hyderabad',  'IND'),
  (7, 'Lord''s Cricket Ground',                    'London',     'ENG'),
  (8, 'Eden Gardens',                              'Kolkata',    'IND');

-- ---------------------------------------------------------------------
-- 5. Match, Format Subclasses, Officials, Corrections, Competes_In,
--    Player_Match_Appearance, Match_Responsibility, Awarded_To
-- ---------------------------------------------------------------------
INSERT INTO `Match` (Match_ID, Match_Date, Match_Time, Toss_Decision, Match_Status, Match_Result, Rating_Weight, DLS_Applied, Age_Category, Gender_Category, Series_ID, Venue_ID) VALUES
  (1, '2023-11-19', '14:00:00', 'Field', 'Completed', 'Win', 1.50, FALSE, 'Senior', 'Men',   1, 1), -- 2023 CWC Final: IND vs AUS
  (2, '2023-11-15', '14:00:00', 'Bat',   'Completed', 'Win', 1.25, FALSE, 'Senior', 'Men',   1, 2), -- 2023 CWC SF1: IND vs NZL
  (3, '2024-06-29', '10:30:00', 'Bat',   'Completed', 'Win', 1.50, FALSE, 'Senior', 'Men',   2, 3), -- 2024 T20 WC Final: IND vs RSA
  (4, '2024-06-24', '10:30:00', 'Field', 'Completed', 'Win', 1.25, FALSE, 'Senior', 'Men',   2, 3), -- 2024 T20 WC Super 8: IND vs AUS
  (5, '2024-11-22', '10:20:00', 'Bat',   'Completed', 'Win', 1.00, FALSE, 'Senior', 'Men',   3, 4), -- BGT 1st Test: AUS vs IND
  (6, '2024-01-25', '09:30:00', 'Bat',   'Completed', 'Win', 1.00, FALSE, 'Senior', 'Men',   4, 6), -- IND vs ENG 1st Test (Hyderabad)
  (7, '2023-12-21', '09:30:00', 'Bat',   'Completed', 'Win', 1.00, FALSE, 'Senior', 'Women', 5, 2), -- IND-W vs AUS-W Only Test
  (8, '2024-01-05', '19:00:00', 'Field', 'Completed', 'Win', 1.00, FALSE, 'Senior', 'Women', 5, 2); -- IND-W vs AUS-W 1st T20I

INSERT INTO Test_Match (Match_ID, Scheduled_Duration, Follow_On_Status) VALUES
  (5, 5, 'Not Enforced'),
  (6, 5, 'Not Enforced'),
  (7, 4, 'Not Enforced');

INSERT INTO ODI_Match (Match_ID, Max_Scheduled_Overs, DLS_Par_Score) VALUES
  (1, 50, NULL),
  (2, 50, NULL);

INSERT INTO T20I_Match (Match_ID, Max_Scheduled_Overs, DLS_Par_Score, Super_Over_Indicator) VALUES
  (3, 20, NULL, FALSE),
  (4, 20, NULL, FALSE),
  (8, 20, NULL, FALSE);

INSERT INTO Match_Official (Match_ID, Official_Name, Official_Role) VALUES
  (1, 'Richard Illingworth', 'On-field Umpire'),
  (1, 'Richard Kettleborough', 'On-field Umpire'),
  (1, 'Joel Wilson',         'TV Umpire'),
  (1, 'Andy Pycroft',        'Match Referee'),
  (3, 'Chris Gaffaney',      'On-field Umpire'),
  (3, 'Richard Illingworth', 'On-field Umpire'),
  (3, 'Richie Richardson',   'Match Referee'),
  (5, 'Chris Gaffaney',      'On-field Umpire'),
  (5, 'Richard Kettleborough', 'On-field Umpire');

INSERT INTO Match_Correction (Match_ID, Revision_No, Changed_At, Actor_Label, Target_Path, Old_Value, New_Value, Reason) VALUES
  (1, 1, '2023-11-19 22:35:00', 'ICC Scorer', 'match_status', 'Live', 'Completed', 'Official post-match sign-off by match referee'),
  (3, 1, '2024-06-29 14:40:00', 'ICC Scorer', 'match_status', 'Live', 'Completed', 'Final ball confirmed after third umpire boundary check');

INSERT INTO Competes_In (Match_ID, Team_ID, Toss_Winner, Winner_Status, Opponent_Rank_At_Match) VALUES
  (1, 1, FALSE, 'Lost', 2), -- IND vs AUS (2023 CWC Final)
  (1, 2, TRUE,  'Won',  1),
  (2, 1, TRUE,  'Won',  4), -- IND vs NZL (2023 CWC SF)
  (2, 5, FALSE, 'Lost', 1),
  (3, 1, TRUE,  'Won',  5), -- IND vs RSA (2024 T20 WC Final)
  (3, 4, FALSE, 'Lost', 1),
  (4, 1, FALSE, 'Won',  2), -- IND vs AUS (2024 T20 WC Super 8)
  (4, 2, TRUE,  'Lost', 1),
  (5, 2, FALSE, 'Lost', 2), -- AUS vs IND (Perth Test)
  (5, 1, TRUE,  'Won',  1),
  (6, 1, FALSE, 'Lost', 3), -- IND vs ENG (Hyderabad Test)
  (6, 3, TRUE,  'Won',  1),
  (7, 8, FALSE, 'Won',  1), -- IND-W vs AUS-W Test
  (7, 9, TRUE,  'Lost', 4),
  (8, 8, TRUE,  'Won',  1), -- IND-W vs AUS-W T20I
  (8, 9, FALSE, 'Lost', 4);

INSERT INTO Player_Match_Appearance (Player_ID, Match_ID, Team_ID, Runs_Scored, Balls_Faced, Wickets_Taken, Rating_Points_Earned) VALUES
  -- Match 1: 2023 CWC Final (IND vs AUS)
  (1,  1, 1, 47,  31,  0, 18.50),
  (2,  1, 1, 54,  63,  0, 21.00),
  (3,  1, 1, 1,   3,   2, 24.00),
  (4,  1, 1, 9,   22,  0,  4.00),
  (5,  1, 1, 10,  18,  0,  3.50),
  (10, 1, 2, 0,   0,   2, 28.00),
  (11, 1, 2, 137, 120, 0, 55.00),
  (12, 1, 2, 0,   0,   3, 34.00),
  (13, 1, 2, 0,   0,   1, 14.00),
  (14, 1, 2, 4,   9,   0,  2.00),
  -- Match 2: 2023 CWC SF1 (IND vs NZL)
  (1,  2, 1, 47,  29,  0, 19.00),
  (2,  2, 1, 117, 113, 0, 48.00),
  (3,  2, 1, 0,   0,   1, 12.00),
  (21, 2, 5, 69,  73,  0, 26.00),
  -- Match 3: 2024 T20 WC Final (IND vs RSA)
  (1,  3, 1, 9,   5,   0,  4.00),
  (2,  3, 1, 76,  59,  0, 42.00),
  (3,  3, 1, 0,   0,   2, 38.00),
  (4,  3, 1, 2,   2,   0,  3.00),
  (5,  3, 1, 0,   0,   0,  2.00),
  (6,  3, 1, 3,   4,   0,  8.00),
  (7,  3, 1, 5,   2,   3, 40.00),
  (8,  3, 1, 0,   2,   0,  5.00),
  (18, 3, 4, 4,   5,   0,  3.00),
  (19, 3, 4, 4,   3,   1, 15.00),
  (20, 3, 4, 52,  27,  0, 35.00),
  -- Match 4: 2024 T20 WC Super 8 (IND vs AUS)
  (1,  4, 1, 92,  41,  0, 52.00),
  (3,  4, 1, 0,   0,   1, 18.00),
  (5,  4, 1, 0,   0,   2, 26.00),
  (11, 4, 2, 76,  43,  0, 36.00),
  -- Match 5: BGT 1st Test (AUS vs IND at Perth)
  (2,  5, 1, 100, 143, 0, 44.00),
  (3,  5, 1, 8,   16,  8, 65.00),
  (10, 5, 2, 5,   19,  3, 20.00),
  (11, 5, 2, 89,  101, 0, 32.00),
  -- Match 6: IND vs ENG 1st Test (Hyderabad)
  (4,  6, 1, 87,  180, 5, 45.00),
  (15, 6, 3, 70,  88,  0, 28.00),
  (16, 6, 3, 29,  60,  5, 38.00),
  -- Match 7: IND-W vs AUS-W Test
  (24, 7, 8, 49,  77,  2, 30.00),
  (25, 7, 8, 112, 161, 0, 42.00),
  (26, 7, 9, 38,  75,  0, 15.00),
  (27, 7, 9, 45,  91,  1, 22.00);

INSERT INTO Match_Responsibility (Player_ID, Match_ID) VALUES
  (1,  1), (10, 1),
  (1,  2), (21, 2),
  (1,  3), (8,  3), (18, 3), (20, 3),
  (1,  4), (8,  4),
  (3,  5), (10, 5),
  (1,  6), (15, 6),
  (24, 7), (26, 7);

INSERT INTO Match_Responsibility_Role (Player_ID, Match_ID, Responsibility) VALUES
  (1,  1, 'Captain'),
  (10, 1, 'Captain'),
  (1,  2, 'Captain'),
  (21, 2, 'Captain'),
  (1,  3, 'Captain'),
  (8,  3, 'Wicketkeeper'),
  (18, 3, 'Captain'),
  (20, 3, 'Wicketkeeper'),
  (1,  4, 'Captain'),
  (8,  4, 'Wicketkeeper'),
  (3,  5, 'Captain'),
  (10, 5, 'Captain'),
  (1,  6, 'Captain'),
  (15, 6, 'Captain'),
  (24, 7, 'Captain'),
  (26, 7, 'Captain'),
  (26, 7, 'Wicketkeeper');

INSERT INTO Awarded_To (Player_ID, Match_ID, Award_Type) VALUES
  (11, 1, 'Player of the Match'),
  (2,  2, 'Player of the Match'),
  (2,  3, 'Player of the Match'),
  (7,  3, 'Best Bowler'),
  (1,  4, 'Player of the Match'),
  (3,  5, 'Player of the Match'),
  (25, 7, 'Best Batter');

-- ---------------------------------------------------------------------
-- 6. Innings_Scorecard, Innings_Score_Adjustment, Ball, Ball_Extra,
--    Delivery_Participation, Delivery_Role
--    3 matches with rich ball-by-ball deliveries (Match 1, Match 3, Match 6)
--    across multiple venues and both Pace & Spin bowlers for Q3 and Q4.
-- ---------------------------------------------------------------------
INSERT INTO Innings_Scorecard (Match_ID, Innings_Number, Innings_Type, Innings_Status, Target_Score, Effective_Over_Limit, DLS_Par_Score, Batting_Team_ID) VALUES
  (1, 1, 'Regular', 'Completed', NULL, 50, NULL, 1),
  (1, 2, 'Regular', 'Completed', 241,  50, NULL, 2),
  (3, 1, 'Regular', 'Completed', NULL, 20, NULL, 1),
  (3, 2, 'Regular', 'Completed', 177,  20, NULL, 4),
  (5, 1, 'Regular', 'Completed', NULL, NULL, NULL, 1),
  (5, 2, 'Regular', 'Completed', NULL, NULL, NULL, 2),
  (6, 1, 'Regular', 'Completed', NULL, NULL, NULL, 3),
  (6, 2, 'Regular', 'Completed', NULL, NULL, NULL, 1);

INSERT INTO Innings_Score_Adjustment (Match_ID, Innings_Number, Adjustment_No, Penalty_Runs, Reason) VALUES
  (3, 1, 1, 0, 'No penalty runs awarded');

-- Balls for Match 1 (Ahmedabad: IND vs AUS), Match 3 (Bridgetown: IND vs RSA), Match 6 (Hyderabad: IND vs ENG)
INSERT INTO Ball (Match_ID, Innings_Number, Over_Number, Delivery_Sequence, Runs_Off_Bat, Legal_Ball_Sequence, Is_Legal, Wicket_Flag, Dismissal_Type, Commentary, Dismissed_Player_ID) VALUES
  -- Match 1, Innings 1 (IND batting at Narendra Modi Stadium, AUS Pace & Spin bowling)
  (1, 1, 0, 1, 0, 1, TRUE,  FALSE, NULL,     'Starc to Rohit, full and swinging back in, defended solidly.', NULL),
  (1, 1, 0, 2, 4, 2, TRUE,  FALSE, NULL,     'Starc to Rohit, pitched up outside off, driven crisply through cover for four!', NULL),
  (1, 1, 0, 3, 6, 3, TRUE,  FALSE, NULL,     'Starc to Rohit, picked up effortlessly over deep square leg for six!', NULL),
  (1, 1, 0, 4, 0, NULL, FALSE, FALSE, NULL,  'Starc bowls a wide down the leg side.', NULL),
  (1, 1, 0, 5, 1, 4, TRUE,  FALSE, NULL,     'Starc to Rohit, tucked to midwicket for a quick single.', NULL),
  (1, 1, 0, 6, 4, 5, TRUE,  FALSE, NULL,     'Starc to Kohli, textbook cover drive races away to the boundary.', NULL),
  (1, 1, 0, 7, 0, 6, TRUE,  TRUE,  'Bowled', 'Cummins to Kohli, inside edge crashes back onto the stumps!', 2),
  (1, 1, 1, 1, 2, 1, TRUE,  FALSE, NULL,     'Zampa to Rohit, flighted legbreak worked into the gap for two.', NULL),
  (1, 1, 1, 2, 6, 2, TRUE,  FALSE, NULL,     'Zampa to Rohit, lofted clean over long-on for a maximum!', NULL),
  (1, 1, 1, 3, 0, 3, TRUE,  TRUE,  'Caught', 'Zampa to Rohit, leading edge taken brilliantly by Travis Head running back!', 1),

  -- Match 1, Innings 2 (AUS batting at Narendra Modi Stadium, IND Pace & Spin bowling)
  (1, 2, 0, 1, 4, 1, TRUE,  FALSE, NULL,     'Bumrah to Head, edged past third slip for four.', NULL),
  (1, 2, 0, 2, 0, 2, TRUE,  TRUE,  'LBW',    'Bumrah to Smith, seaming back sharply to trap Smith plumb in front!', 14),
  (1, 2, 0, 3, 4, 3, TRUE,  FALSE, NULL,     'Bumrah to Head, cut fiercely past point for four.', NULL),
  (1, 2, 1, 1, 1, 1, TRUE,  FALSE, NULL,     'Kuldeep to Head, googly pushed to long-on for one.', NULL),
  (1, 2, 1, 2, 4, 2, TRUE,  FALSE, NULL,     'Kuldeep to Head, slog-swept over midwicket for four.', NULL),
  (1, 2, 1, 3, 2, 3, TRUE,  FALSE, NULL,     'Jadeja to Head, flat delivery worked behind square for two.', NULL),

  -- Match 3, Innings 1 (IND batting at Kensington Oval, RSA Pace bowling)
  (3, 1, 0, 1, 4, 1, TRUE,  FALSE, NULL,     'Rabada to Kohli, half-volley driven straight down the ground for four!', NULL),
  (3, 1, 0, 2, 4, 2, TRUE,  FALSE, NULL,     'Rabada to Kohli, flicked off the pads through midwicket for another boundary.', NULL),
  (3, 1, 0, 3, 0, NULL, FALSE, FALSE, NULL,  'Rabada oversteps, no-ball called by the umpire.', NULL),
  (3, 1, 0, 4, 6, 3, TRUE,  FALSE, NULL,     'Rabada to Kohli, free hit launched over long-on for six!', NULL),
  (3, 1, 0, 5, 0, 4, TRUE,  TRUE,  'Caught', 'Rabada to Rohit, swept straight to square leg!', 1),
  (3, 1, 0, 6, 2, 5, TRUE,  FALSE, NULL,     'Rabada to Suryakumar, clipped neatly off the hip for two.', NULL),
  (3, 1, 0, 7, 4, 6, TRUE,  FALSE, NULL,     'Rabada to Kohli, punched off the back foot past cover for four.', NULL),

  -- Match 3, Innings 2 (RSA batting at Kensington Oval, IND Pace & Spin bowling)
  (3, 2, 0, 1, 0, 1, TRUE,  TRUE,  'Bowled', 'Bumrah to Markram, unplayable outswinger clips the top of off stump!', 18),
  (3, 2, 0, 2, 6, 2, TRUE,  FALSE, NULL,     'Kuldeep to Klaasen, smoked over wide long-on for a huge six.', NULL),
  (3, 2, 0, 3, 6, 3, TRUE,  FALSE, NULL,     'Kuldeep to Klaasen, deposited into the stands at cow corner!', NULL),
  (3, 2, 0, 4, 0, 4, TRUE,  TRUE,  'Caught', 'Hardik to Klaasen, wide slower ball nicked behind to Rishabh Pant!', 20),
  (3, 2, 0, 5, 0, 5, TRUE,  TRUE,  'Caught', 'Hardik to Rabada, full toss lofted to long-off — Suryakumar takes a miracle catch on the rope!', 19),

  -- Match 6, Innings 1 (ENG batting at Hyderabad, IND Spin & Pace bowling)
  (6, 1, 0, 1, 4, 1, TRUE,  FALSE, NULL,     'Jadeja to Stokes, reverse-swept past backward point for four.', NULL),
  (6, 1, 0, 2, 6, 2, TRUE,  FALSE, NULL,     'Jadeja to Stokes, danced down the track and lofted straight for six.', NULL),
  (6, 1, 0, 3, 0, 3, TRUE,  TRUE,  'Bowled', 'Bumrah to Stokes, reverse-swinging yorker shatters the stumps!', 15),
  (6, 1, 0, 4, 1, 4, TRUE,  FALSE, NULL,     'Kuldeep to Root, worked off the back foot to deep square leg.', NULL),

  -- Match 6, Innings 2 (IND batting at Hyderabad, ENG Spin bowling)
  (6, 2, 0, 1, 4, 1, TRUE,  FALSE, NULL,     'Root to Jadeja, cut late past slip for four.', NULL),
  (6, 2, 0, 2, 0, 2, TRUE,  TRUE,  'LBW',    'Root to Jadeja, arm ball skids on and traps Jadeja LBW!', 4);

INSERT INTO Ball_Extra (Match_ID, Innings_Number, Over_Number, Delivery_Sequence, Extra_Type, Extra_Runs) VALUES
  (1, 1, 0, 4, 'Wide',    1),
  (3, 1, 0, 3, 'No-ball', 1);

-- Delivery_Participation & Delivery_Role (Bowler, Striker, Non-striker, plus Catcher/Wicketkeeper)
INSERT INTO Delivery_Participation (Match_ID, Innings_Number, Over_Number, Delivery_Sequence, Player_ID) VALUES
  -- Match 1, Innings 1
  (1, 1, 0, 1, 12), (1, 1, 0, 1, 1),  (1, 1, 0, 1, 2),
  (1, 1, 0, 2, 12), (1, 1, 0, 2, 1),  (1, 1, 0, 2, 2),
  (1, 1, 0, 3, 12), (1, 1, 0, 3, 1),  (1, 1, 0, 3, 2),
  (1, 1, 0, 4, 12), (1, 1, 0, 4, 1),  (1, 1, 0, 4, 2),
  (1, 1, 0, 5, 12), (1, 1, 0, 5, 1),  (1, 1, 0, 5, 2),
  (1, 1, 0, 6, 12), (1, 1, 0, 6, 2),  (1, 1, 0, 6, 1),
  (1, 1, 0, 7, 10), (1, 1, 0, 7, 2),  (1, 1, 0, 7, 1),
  (1, 1, 1, 1, 13), (1, 1, 1, 1, 1),  (1, 1, 1, 1, 4),
  (1, 1, 1, 2, 13), (1, 1, 1, 2, 1),  (1, 1, 1, 2, 4),
  (1, 1, 1, 3, 13), (1, 1, 1, 3, 1),  (1, 1, 1, 3, 4),  (1, 1, 1, 3, 11),
  -- Match 1, Innings 2
  (1, 2, 0, 1, 3),  (1, 2, 0, 1, 11), (1, 2, 0, 1, 14),
  (1, 2, 0, 2, 3),  (1, 2, 0, 2, 14), (1, 2, 0, 2, 11),
  (1, 2, 0, 3, 3),  (1, 2, 0, 3, 11), (1, 2, 0, 3, 10),
  (1, 2, 1, 1, 5),  (1, 2, 1, 1, 11), (1, 2, 1, 1, 10),
  (1, 2, 1, 2, 5),  (1, 2, 1, 2, 11), (1, 2, 1, 2, 10),
  (1, 2, 1, 3, 4),  (1, 2, 1, 3, 11), (1, 2, 1, 3, 10),
  -- Match 3, Innings 1
  (3, 1, 0, 1, 19), (3, 1, 0, 1, 2),  (3, 1, 0, 1, 1),
  (3, 1, 0, 2, 19), (3, 1, 0, 2, 2),  (3, 1, 0, 2, 1),
  (3, 1, 0, 3, 19), (3, 1, 0, 3, 2),  (3, 1, 0, 3, 1),
  (3, 1, 0, 4, 19), (3, 1, 0, 4, 2),  (3, 1, 0, 4, 1),
  (3, 1, 0, 5, 19), (3, 1, 0, 5, 1),  (3, 1, 0, 5, 2),  (3, 1, 0, 5, 18),
  (3, 1, 0, 6, 19), (3, 1, 0, 6, 6),  (3, 1, 0, 6, 2),
  (3, 1, 0, 7, 19), (3, 1, 0, 7, 2),  (3, 1, 0, 7, 6),
  -- Match 3, Innings 2
  (3, 2, 0, 1, 3),  (3, 2, 0, 1, 18), (3, 2, 0, 1, 20),
  (3, 2, 0, 2, 5),  (3, 2, 0, 2, 20), (3, 2, 0, 2, 19),
  (3, 2, 0, 3, 5),  (3, 2, 0, 3, 20), (3, 2, 0, 3, 19),
  (3, 2, 0, 4, 7),  (3, 2, 0, 4, 20), (3, 2, 0, 4, 19), (3, 2, 0, 4, 8),
  (3, 2, 0, 5, 7),  (3, 2, 0, 5, 19), (3, 2, 0, 5, 18), (3, 2, 0, 5, 6),
  -- Match 6, Innings 1 & 2
  (6, 1, 0, 1, 4),  (6, 1, 0, 1, 15), (6, 1, 0, 1, 16),
  (6, 1, 0, 2, 4),  (6, 1, 0, 2, 15), (6, 1, 0, 2, 16),
  (6, 1, 0, 3, 3),  (6, 1, 0, 3, 15), (6, 1, 0, 3, 16),
  (6, 1, 0, 4, 5),  (6, 1, 0, 4, 16), (6, 1, 0, 4, 17),
  (6, 2, 0, 1, 16), (6, 2, 0, 1, 4),  (6, 2, 0, 1, 1),
  (6, 2, 0, 2, 16), (6, 2, 0, 2, 4),  (6, 2, 0, 2, 1);

INSERT INTO Delivery_Role (Match_ID, Innings_Number, Over_Number, Delivery_Sequence, Player_ID, Delivery_Role) VALUES
  -- Match 1, Innings 1
  (1, 1, 0, 1, 12, 'Bowler'),      (1, 1, 0, 1, 1,  'Striker'),     (1, 1, 0, 1, 2,  'Non-striker'),
  (1, 1, 0, 2, 12, 'Bowler'),      (1, 1, 0, 2, 1,  'Striker'),     (1, 1, 0, 2, 2,  'Non-striker'),
  (1, 1, 0, 3, 12, 'Bowler'),      (1, 1, 0, 3, 1,  'Striker'),     (1, 1, 0, 3, 2,  'Non-striker'),
  (1, 1, 0, 4, 12, 'Bowler'),      (1, 1, 0, 4, 1,  'Striker'),     (1, 1, 0, 4, 2,  'Non-striker'),
  (1, 1, 0, 5, 12, 'Bowler'),      (1, 1, 0, 5, 1,  'Striker'),     (1, 1, 0, 5, 2,  'Non-striker'),
  (1, 1, 0, 6, 12, 'Bowler'),      (1, 1, 0, 6, 2,  'Striker'),     (1, 1, 0, 6, 1,  'Non-striker'),
  (1, 1, 0, 7, 10, 'Bowler'),      (1, 1, 0, 7, 2,  'Striker'),     (1, 1, 0, 7, 1,  'Non-striker'),
  (1, 1, 1, 1, 13, 'Bowler'),      (1, 1, 1, 1, 1,  'Striker'),     (1, 1, 1, 1, 4,  'Non-striker'),
  (1, 1, 1, 2, 13, 'Bowler'),      (1, 1, 1, 2, 1,  'Striker'),     (1, 1, 1, 2, 4,  'Non-striker'),
  (1, 1, 1, 3, 13, 'Bowler'),      (1, 1, 1, 3, 1,  'Striker'),     (1, 1, 1, 3, 4,  'Non-striker'), (1, 1, 1, 3, 11, 'Catcher'),
  -- Match 1, Innings 2
  (1, 2, 0, 1, 3,  'Bowler'),      (1, 2, 0, 1, 11, 'Striker'),     (1, 2, 0, 1, 14, 'Non-striker'),
  (1, 2, 0, 2, 3,  'Bowler'),      (1, 2, 0, 2, 14, 'Striker'),     (1, 2, 0, 2, 11, 'Non-striker'),
  (1, 2, 0, 3, 3,  'Bowler'),      (1, 2, 0, 3, 11, 'Striker'),     (1, 2, 0, 3, 10, 'Non-striker'),
  (1, 2, 1, 1, 5,  'Bowler'),      (1, 2, 1, 1, 11, 'Striker'),     (1, 2, 1, 1, 10, 'Non-striker'),
  (1, 2, 1, 2, 5,  'Bowler'),      (1, 2, 1, 2, 11, 'Striker'),     (1, 2, 1, 2, 10, 'Non-striker'),
  (1, 2, 1, 3, 4,  'Bowler'),      (1, 2, 1, 3, 11, 'Striker'),     (1, 2, 1, 3, 10, 'Non-striker'),
  -- Match 3, Innings 1
  (3, 1, 0, 1, 19, 'Bowler'),      (3, 1, 0, 1, 2,  'Striker'),     (3, 1, 0, 1, 1,  'Non-striker'),
  (3, 1, 0, 2, 19, 'Bowler'),      (3, 1, 0, 2, 2,  'Striker'),     (3, 1, 0, 2, 1,  'Non-striker'),
  (3, 1, 0, 3, 19, 'Bowler'),      (3, 1, 0, 3, 2,  'Striker'),     (3, 1, 0, 3, 1,  'Non-striker'),
  (3, 1, 0, 4, 19, 'Bowler'),      (3, 1, 0, 4, 2,  'Striker'),     (3, 1, 0, 4, 1,  'Non-striker'),
  (3, 1, 0, 5, 19, 'Bowler'),      (3, 1, 0, 5, 1,  'Striker'),     (3, 1, 0, 5, 2,  'Non-striker'), (3, 1, 0, 5, 18, 'Catcher'),
  (3, 1, 0, 6, 19, 'Bowler'),      (3, 1, 0, 6, 6,  'Striker'),     (3, 1, 0, 6, 2,  'Non-striker'),
  (3, 1, 0, 7, 19, 'Bowler'),      (3, 1, 0, 7, 2,  'Striker'),     (3, 1, 0, 7, 6,  'Non-striker'),
  -- Match 3, Innings 2
  (3, 2, 0, 1, 3,  'Bowler'),      (3, 2, 0, 1, 18, 'Striker'),     (3, 2, 0, 1, 20, 'Non-striker'),
  (3, 2, 0, 2, 5,  'Bowler'),      (3, 2, 0, 2, 20, 'Striker'),     (3, 2, 0, 2, 19, 'Non-striker'),
  (3, 2, 0, 3, 5,  'Bowler'),      (3, 2, 0, 3, 20, 'Striker'),     (3, 2, 0, 3, 19, 'Non-striker'),
  (3, 2, 0, 4, 7,  'Bowler'),      (3, 2, 0, 4, 20, 'Striker'),     (3, 2, 0, 4, 19, 'Non-striker'), (3, 2, 0, 4, 8, 'Catcher'), (3, 2, 0, 4, 8, 'Wicketkeeper'),
  (3, 2, 0, 5, 7,  'Bowler'),      (3, 2, 0, 5, 19, 'Striker'),     (3, 2, 0, 5, 18, 'Non-striker'), (3, 2, 0, 5, 6, 'Catcher'),
  -- Match 6, Innings 1 & 2
  (6, 1, 0, 1, 4,  'Bowler'),      (6, 1, 0, 1, 15, 'Striker'),     (6, 1, 0, 1, 16, 'Non-striker'),
  (6, 1, 0, 2, 4,  'Bowler'),      (6, 1, 0, 2, 15, 'Striker'),     (6, 1, 0, 2, 16, 'Non-striker'),
  (6, 1, 0, 3, 3,  'Bowler'),      (6, 1, 0, 3, 15, 'Striker'),     (6, 1, 0, 3, 16, 'Non-striker'),
  (6, 1, 0, 4, 5,  'Bowler'),      (6, 1, 0, 4, 16, 'Striker'),     (6, 1, 0, 4, 17, 'Non-striker'),
  (6, 2, 0, 1, 16, 'Bowler'),      (6, 2, 0, 1, 4,  'Striker'),     (6, 2, 0, 1, 1,  'Non-striker'),
  (6, 2, 0, 2, 16, 'Bowler'),      (6, 2, 0, 2, 4,  'Striker'),     (6, 2, 0, 2, 1,  'Non-striker');

-- ---------------------------------------------------------------------
-- 7. Record, Achievement, Ranking_Snapshot
-- ---------------------------------------------------------------------
INSERT INTO Record (Record_ID, Record_Title, Statistic_Value, Description) VALUES
  (1, 'Most Career ODI Centuries',                 50.00,  'First batter in history to score 50 One-Day International centuries.'),
  (2, 'Most Runs in a Single Men''s CWC Edition',  765.00, 'Most runs scored by an individual batter in a single ICC Men''s Cricket World Cup.'),
  (3, 'Most Career International Sixes',           620.00, 'Highest number of sixes hit across Test, ODI and T20I cricket.'),
  (4, 'Highest Score in a Men''s CWC Final Chase', 137.00, 'Match-winning century in a World Cup final run chase.'),
  (5, 'Fastest to 200 Test Wickets by Balls',      8484.00,'Reached 200 Test wickets with the best strike rate among Indian bowlers.'),
  (6, 'Most Career Women''s T20I Appearances',     175.00, 'Most caps in Women''s T20 Internationals.');

INSERT INTO Achievement (Achievement_ID, Achievement_Date, Achieved_Value, Player_ID, Record_ID, Match_ID) VALUES
  (1, '2023-11-15', 50.00,  2,  1, 2),
  (2, '2023-11-19', 765.00, 2,  2, 1),
  (3, '2024-06-24', 620.00, 1,  3, 4),
  (4, '2023-11-19', 137.00, 11, 4, 1),
  (5, '2024-11-22', 200.00, 3,  5, 5),
  (6, '2024-01-05', 175.00, 24, 6, 8);

-- Ranking_Snapshot: includes multiple snapshot dates so Q1 MAX(As_Of) filter is tested,
-- and covers Team, Batting, Bowling, All-rounder across Test, ODI, T20I, Men/Women, Senior/U19.
INSERT INTO Ranking_Snapshot (As_Of, Format, Ranking_Category, Gender_Category, Age_Category, Published_Rank, Published_Rating, Published_Points, Matches_Counted, Team_ID, Player_ID) VALUES
  -- Historical Men's Senior ODI Team snapshot (2023-11-20)
  ('2023-11-20', 'ODI',  'Team', 'Men', 'Senior', 1, 121.00, 5445, 45, 1, NULL),
  ('2023-11-20', 'ODI',  'Team', 'Men', 'Senior', 2, 118.00, 4956, 42, 2, NULL),
  ('2023-11-20', 'ODI',  'Team', 'Men', 'Senior', 3, 110.00, 4070, 37, 4, NULL),

  -- Latest Men's Senior ODI Team snapshot (2025-01-10)
  ('2025-01-10', 'ODI',  'Team', 'Men', 'Senior', 1, 118.00, 5310, 45, 1, NULL),
  ('2025-01-10', 'ODI',  'Team', 'Men', 'Senior', 2, 113.00, 4746, 42, 2, NULL),
  ('2025-01-10', 'ODI',  'Team', 'Men', 'Senior', 3, 109.00, 3924, 36, 6, NULL),
  ('2025-01-10', 'ODI',  'Team', 'Men', 'Senior', 4, 106.00, 4028, 38, 4, NULL),
  ('2025-01-10', 'ODI',  'Team', 'Men', 'Senior', 5, 101.00, 3838, 38, 5, NULL),
  ('2025-01-10', 'ODI',  'Team', 'Men', 'Senior', 6,  95.00, 3420, 36, 3, NULL),
  ('2025-01-10', 'ODI',  'Team', 'Men', 'Senior', 7,  86.00, 2666, 31, 7, NULL),

  -- Latest Men's Senior Test Team snapshot (2025-01-10)
  ('2025-01-10', 'Test', 'Team', 'Men', 'Senior', 1, 124.00, 4588, 37, 2, NULL),
  ('2025-01-10', 'Test', 'Team', 'Men', 'Senior', 2, 118.00, 4012, 34, 1, NULL),
  ('2025-01-10', 'Test', 'Team', 'Men', 'Senior', 3, 112.00, 3136, 28, 4, NULL),
  ('2025-01-10', 'Test', 'Team', 'Men', 'Senior', 4, 108.00, 4860, 45, 3, NULL),
  ('2025-01-10', 'Test', 'Team', 'Men', 'Senior', 5,  98.00, 2744, 28, 5, NULL),

  -- Latest Men's Senior T20I Team snapshot (2025-01-10)
  ('2025-01-10', 'T20I', 'Team', 'Men', 'Senior', 1, 268.00, 18760, 70, 1, NULL),
  ('2025-01-10', 'T20I', 'Team', 'Men', 'Senior', 2, 259.00, 14763, 57, 2, NULL),
  ('2025-01-10', 'T20I', 'Team', 'Men', 'Senior', 3, 255.00, 12750, 50, 3, NULL),
  ('2025-01-10', 'T20I', 'Team', 'Men', 'Senior', 4, 249.00, 12450, 50, 4, NULL),
  ('2025-01-10', 'T20I', 'Team', 'Men', 'Senior', 5, 246.00, 11808, 48, 5, NULL),

  -- Latest Women's Senior ODI & T20I Team snapshots (2025-01-10)
  ('2025-01-10', 'ODI',  'Team', 'Women', 'Senior', 1, 164.00, 4920, 30, 9, NULL),
  ('2025-01-10', 'ODI',  'Team', 'Women', 'Senior', 2, 112.00, 3360, 30, 8, NULL),
  ('2025-01-10', 'T20I', 'Team', 'Women', 'Senior', 1, 296.00, 11840, 40, 9, NULL),
  ('2025-01-10', 'T20I', 'Team', 'Women', 'Senior', 2, 263.00, 11046, 42, 8, NULL),

  -- U19 Team snapshots (2025-01-10)
  ('2025-01-10', 'ODI',  'Team', 'Men',   'U19', 1, 120.00, 2400, 20, 10, NULL),
  ('2025-01-10', 'T20I', 'Team', 'Women', 'U19', 1, 118.00, 1770, 15, 12, NULL),

  -- Player Rankings (Test, ODI, T20I across Batting, Bowling, All-rounder)
  ('2025-01-10', 'Test', 'Batting',     'Men', 'Senior', 1, 895.00, 895, 52, NULL, 16), -- Joe Root
  ('2025-01-10', 'Test', 'Batting',     'Men', 'Senior', 2, 854.00, 854, 40, NULL, 21), -- Kane Williamson
  ('2025-01-10', 'Test', 'Batting',     'Men', 'Senior', 3, 788.00, 788, 38, NULL, 11), -- Travis Head
  ('2025-01-10', 'Test', 'Bowling',     'Men', 'Senior', 1, 907.00, 907, 44, NULL, 3),  -- Jasprit Bumrah
  ('2025-01-10', 'Test', 'Bowling',     'Men', 'Senior', 2, 845.00, 845, 42, NULL, 19), -- Kagiso Rabada
  ('2025-01-10', 'Test', 'Bowling',     'Men', 'Senior', 3, 841.00, 841, 48, NULL, 10), -- Pat Cummins
  ('2025-01-10', 'Test', 'All-rounder', 'Men', 'Senior', 1, 424.00, 424, 45, NULL, 4),  -- Ravindra Jadeja
  ('2025-01-10', 'Test', 'All-rounder', 'Men', 'Senior', 2, 315.00, 315, 42, NULL, 15), -- Ben Stokes

  ('2025-01-10', 'ODI',  'Batting',     'Men', 'Senior', 1, 825.00, 825, 36, NULL, 22), -- Babar Azam
  ('2025-01-10', 'ODI',  'Batting',     'Men', 'Senior', 2, 765.00, 765, 38, NULL, 1),  -- Rohit Sharma
  ('2025-01-10', 'ODI',  'Batting',     'Men', 'Senior', 3, 746.00, 746, 38, NULL, 2),  -- Virat Kohli
  ('2025-01-10', 'ODI',  'Bowling',     'Men', 'Senior', 1, 712.00, 712, 30, NULL, 23), -- Rashid Khan
  ('2025-01-10', 'ODI',  'Bowling',     'Men', 'Senior', 2, 689.00, 689, 32, NULL, 5),  -- Kuldeep Yadav
  ('2025-01-10', 'ODI',  'Bowling',     'Men', 'Senior', 3, 675.00, 675, 31, NULL, 3),  -- Jasprit Bumrah

  ('2025-01-10', 'T20I', 'Batting',     'Men', 'Senior', 1, 855.00, 855, 34, NULL, 11), -- Travis Head
  ('2025-01-10', 'T20I', 'Batting',     'Men', 'Senior', 2, 838.00, 838, 42, NULL, 6),  -- Suryakumar Yadav
  ('2025-01-10', 'T20I', 'Batting',     'Men', 'Senior', 3, 802.00, 802, 38, NULL, 17), -- Jos Buttler
  ('2025-01-10', 'T20I', 'Bowling',     'Men', 'Senior', 1, 708.00, 708, 35, NULL, 23), -- Rashid Khan
  ('2025-01-10', 'T20I', 'All-rounder', 'Men', 'Senior', 1, 244.00, 244, 38, NULL, 7),  -- Hardik Pandya

  ('2025-01-10', 'ODI',  'Batting',     'Women', 'Senior', 1, 748.00, 748, 28, NULL, 25), -- Smriti Mandhana
  ('2025-01-10', 'ODI',  'All-rounder', 'Women', 'Senior', 1, 374.00, 374, 30, NULL, 27); -- Ellyse Perry