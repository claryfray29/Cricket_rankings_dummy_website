-- =====================================================================
-- Run with:  mysql -u <user> -p < schema.sql
-- 34 relations: Phase 3's 33 + Bowling_Style_Category (3NF split)
-- Note: `Match` is a reserved word in MySQL, so it is always backticked.
-- Note: MySQL forbids CHECK on columns used in FK CASCADE/SET NULL actions,
--       so tables with such CHECKs use RESTRICT on those FK columns.
-- =====================================================================

DROP DATABASE IF EXISTS icc_rankings;
CREATE DATABASE icc_rankings CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE icc_rankings;

-- ---------------------------------------------------------------------
-- 1. Lookup / reference tables
-- ---------------------------------------------------------------------
CREATE TABLE Country (
  Country_Code CHAR(3)      NOT NULL,
  Country_Name VARCHAR(100) NOT NULL,
  PRIMARY KEY (Country_Code),
  UNIQUE (Country_Name)
);

-- Added in Phase 3 (3NF): Bowling_Style -> Bowling_Category
CREATE TABLE Bowling_Style_Category (
  Bowling_Style    VARCHAR(50)       NOT NULL,
  Bowling_Category ENUM('Pace','Spin') NOT NULL,
  PRIMARY KEY (Bowling_Style)
);

-- ---------------------------------------------------------------------
-- 2. Team and its multivalued attributes
-- ---------------------------------------------------------------------
CREATE TABLE Team (
  Team_ID         INT AUTO_INCREMENT NOT NULL,
  ICC_Team_Code   VARCHAR(10)  NOT NULL,
  Team_Name       VARCHAR(100) NOT NULL,
  Gender_Category ENUM('Men','Women')    NOT NULL,
  Age_Category    ENUM('Senior','U19')   NOT NULL,
  Start_Year      SMALLINT     NOT NULL,
  End_Year        SMALLINT     NULL,
  PRIMARY KEY (Team_ID),
  UNIQUE KEY uq_team_code (ICC_Team_Code, Gender_Category, Age_Category),
  UNIQUE KEY uq_team_name (Team_Name, Gender_Category, Age_Category),
  CONSTRAINT ck_team_start CHECK (Start_Year >= 1877),
  CONSTRAINT ck_team_end   CHECK (End_Year IS NULL OR End_Year >= Start_Year)
);

CREATE TABLE Team_Alternate_Name (
  Team_ID        INT          NOT NULL,
  Alternate_Name VARCHAR(100) NOT NULL,
  PRIMARY KEY (Team_ID, Alternate_Name),
  FOREIGN KEY (Team_ID) REFERENCES Team(Team_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- R11 ORIGINATES_FROM (M:N)
CREATE TABLE Team_Country (
  Team_ID      INT     NOT NULL,
  Country_Code CHAR(3) NOT NULL,
  PRIMARY KEY (Team_ID, Country_Code),
  FOREIGN KEY (Team_ID) REFERENCES Team(Team_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (Country_Code) REFERENCES Country(Country_Code)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 3. Player and its multivalued attributes
-- ---------------------------------------------------------------------
CREATE TABLE Player (
  Player_ID           INT AUTO_INCREMENT NOT NULL,
  ICC_Registration_No VARCHAR(30)  NOT NULL,
  First_Name          VARCHAR(60)  NOT NULL,
  Middle_Name         VARCHAR(60)  NULL,
  Last_Name           VARCHAR(60)  NOT NULL,
  Date_Of_Birth       DATE         NULL,
  Country_Of_Birth    VARCHAR(100) NULL,
  Batting_Hand        ENUM('Right','Left') NULL,
  Bowling_Style       VARCHAR(50)  NULL,
  Biography           TEXT         NULL,
  Debut_Date          DATE         NULL,
  PRIMARY KEY (Player_ID),
  UNIQUE KEY uq_player_reg (ICC_Registration_No),
  KEY idx_player_name (Last_Name, First_Name),
  FOREIGN KEY (Bowling_Style) REFERENCES Bowling_Style_Category(Bowling_Style)
    ON DELETE SET NULL ON UPDATE CASCADE,
  -- A known debut date implies a minimum debut age of 13 (Phase 2)
  CONSTRAINT ck_player_debut CHECK (
    Debut_Date IS NULL OR Date_Of_Birth IS NULL
    OR Debut_Date >= DATE_ADD(Date_Of_Birth, INTERVAL 13 YEAR))
);

CREATE TABLE Player_Playing_Role (
  Player_ID    INT         NOT NULL,
  Playing_Role VARCHAR(40) NOT NULL,
  PRIMARY KEY (Player_ID, Playing_Role),
  FOREIGN KEY (Player_ID) REFERENCES Player(Player_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- R1 REPRESENTS (M:N). Player has total participation: enforced by app
-- transaction + trg_represents_keep_last (cannot delete a player's last team).
CREATE TABLE Represents (
  Player_ID INT NOT NULL,
  Team_ID   INT NOT NULL,
  PRIMARY KEY (Player_ID, Team_ID),
  FOREIGN KEY (Player_ID) REFERENCES Player(Player_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (Team_ID) REFERENCES Team(Team_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Represents_Tenure (
  Player_ID  INT  NOT NULL,
  Team_ID    INT  NOT NULL,
  Valid_From DATE NOT NULL,
  Valid_To   DATE NULL,
  PRIMARY KEY (Player_ID, Team_ID, Valid_From),
  FOREIGN KEY (Player_ID, Team_ID) REFERENCES Represents(Player_ID, Team_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT ck_tenure CHECK (Valid_To IS NULL OR Valid_To >= Valid_From)
);

-- R10 CAPTAINCY_SUCCESSION (ternary). RESTRICT so captaincy history is kept.
CREATE TABLE Captaincy_Succession (
  Predecessor_ID INT NOT NULL,
  Successor_ID   INT NOT NULL,
  Team_ID        INT NOT NULL,
  PRIMARY KEY (Predecessor_ID, Successor_ID, Team_ID),
  FOREIGN KEY (Predecessor_ID) REFERENCES Player(Player_ID)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  FOREIGN KEY (Successor_ID) REFERENCES Player(Player_ID)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  FOREIGN KEY (Team_ID) REFERENCES Team(Team_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT ck_captain_distinct CHECK (Predecessor_ID <> Successor_ID)
);

CREATE TABLE Captaincy_Transition (
  Predecessor_ID  INT  NOT NULL,
  Successor_ID    INT  NOT NULL,
  Team_ID         INT  NOT NULL,
  Transition_Date DATE NOT NULL,
  PRIMARY KEY (Predecessor_ID, Successor_ID, Team_ID, Transition_Date),
  FOREIGN KEY (Predecessor_ID, Successor_ID, Team_ID)
    REFERENCES Captaincy_Succession(Predecessor_ID, Successor_ID, Team_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 4. Series, venues
-- ---------------------------------------------------------------------
CREATE TABLE Series (
  Series_ID   INT AUTO_INCREMENT NOT NULL,
  Series_Name VARCHAR(150) NOT NULL,
  Series_Type ENUM('Bilateral','Tri-Series','ICC World Cup','ICC T20 World Cup',
                   'ICC Champions Trophy','League','Other') NOT NULL,
  Start_Date  DATE NOT NULL,
  End_Date    DATE NOT NULL,
  PRIMARY KEY (Series_ID),
  CONSTRAINT ck_series_dates CHECK (End_Date >= Start_Date)
);

-- R12 HOSTED_BY (M:N)
CREATE TABLE Series_Host (
  Series_ID    INT     NOT NULL,
  Country_Code CHAR(3) NOT NULL,
  PRIMARY KEY (Series_ID, Country_Code),
  FOREIGN KEY (Series_ID) REFERENCES Series(Series_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (Country_Code) REFERENCES Country(Country_Code)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

-- R14 LOCATED_IN (1:N, total on Venue)
CREATE TABLE Venue (
  Venue_ID     INT AUTO_INCREMENT NOT NULL,
  Stadium      VARCHAR(150) NOT NULL,
  City         VARCHAR(100) NOT NULL,
  Country_Code CHAR(3)      NOT NULL,
  PRIMARY KEY (Venue_ID),
  UNIQUE KEY uq_venue (Stadium, City),
  FOREIGN KEY (Country_Code) REFERENCES Country(Country_Code)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 5. Match and its specializations (Option 8A)
-- ---------------------------------------------------------------------
CREATE TABLE `Match` (
  Match_ID        INT AUTO_INCREMENT NOT NULL,
  Match_Date      DATE NOT NULL,
  Match_Time      TIME NULL,
  Toss_Decision   ENUM('Bat','Field') NULL,
  Match_Status    ENUM('Scheduled','Live','Completed','Abandoned','Voided')
                  NOT NULL DEFAULT 'Scheduled',
  Match_Result    ENUM('Win','Draw','Tie','No Result','Abandoned') NULL,
  Rating_Weight   DECIMAL(3,2) NOT NULL DEFAULT 1.00,
  DLS_Applied     BOOLEAN      NOT NULL DEFAULT FALSE,
  Age_Category    ENUM('Senior','U19')  NOT NULL,
  Gender_Category ENUM('Men','Women')   NOT NULL,
  Series_ID       INT NULL,   -- R3 PART_OF (optional)
  Venue_ID        INT NULL,   -- R13 HELD_AT (optional until venue confirmed)
  PRIMARY KEY (Match_ID),
  KEY idx_match_date (Match_Date),
  FOREIGN KEY (Series_ID) REFERENCES Series(Series_ID)
    ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (Venue_ID) REFERENCES Venue(Venue_ID)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT ck_match_weight CHECK (Rating_Weight BETWEEN 0.50 AND 2.00)
);

CREATE TABLE Test_Match (
  Match_ID           INT NOT NULL,
  Scheduled_Duration TINYINT UNSIGNED NOT NULL,
  Follow_On_Status   ENUM('Not Enforced','Enforced') NOT NULL DEFAULT 'Not Enforced',
  PRIMARY KEY (Match_ID),
  FOREIGN KEY (Match_ID) REFERENCES `Match`(Match_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT ck_test_days CHECK (Scheduled_Duration IN (4,5))
);

CREATE TABLE ODI_Match (
  Match_ID           INT NOT NULL,
  Max_Scheduled_Overs TINYINT UNSIGNED NOT NULL DEFAULT 50,
  DLS_Par_Score      INT NULL,
  PRIMARY KEY (Match_ID),
  FOREIGN KEY (Match_ID) REFERENCES `Match`(Match_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT ck_odi_overs CHECK (Max_Scheduled_Overs BETWEEN 1 AND 50)
);

CREATE TABLE T20I_Match (
  Match_ID            INT NOT NULL,
  Max_Scheduled_Overs TINYINT UNSIGNED NOT NULL DEFAULT 20,
  DLS_Par_Score       INT NULL,
  Super_Over_Indicator BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (Match_ID),
  FOREIGN KEY (Match_ID) REFERENCES `Match`(Match_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT ck_t20_overs CHECK (Max_Scheduled_Overs BETWEEN 1 AND 20)
);

-- Multivalued: Match.Official_Assignments
CREATE TABLE Match_Official (
  Match_ID      INT          NOT NULL,
  Official_Name VARCHAR(100) NOT NULL,
  Official_Role ENUM('On-field Umpire','TV Umpire','Reserve Umpire','Match Referee') NOT NULL,
  PRIMARY KEY (Match_ID, Official_Name, Official_Role),
  FOREIGN KEY (Match_ID) REFERENCES `Match`(Match_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- Multivalued: Match.Correction_Log (audit trail)
CREATE TABLE Match_Correction (
  Match_ID    INT          NOT NULL,
  Revision_No INT UNSIGNED NOT NULL,
  Changed_At  DATETIME     NOT NULL,
  Actor_Label VARCHAR(100) NOT NULL,
  Target_Path VARCHAR(255) NOT NULL,
  Old_Value   TEXT NULL,
  New_Value   TEXT NULL,
  Reason      VARCHAR(500) NULL,
  PRIMARY KEY (Match_ID, Revision_No),
  FOREIGN KEY (Match_ID) REFERENCES `Match`(Match_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- R2 COMPETES_IN (M:N with attributes). Exactly 2 teams per match is
-- enforced by trg_competes_in_bi (max 2) + application (min 2).
CREATE TABLE Competes_In (
  Match_ID              INT NOT NULL,
  Team_ID               INT NOT NULL,
  Toss_Winner           BOOLEAN NOT NULL DEFAULT FALSE,
  Winner_Status         ENUM('Won','Lost','Draw','Tie','No Result') NULL,
  Opponent_Rank_At_Match SMALLINT UNSIGNED NULL,
  PRIMARY KEY (Match_ID, Team_ID),
  FOREIGN KEY (Match_ID) REFERENCES `Match`(Match_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (Team_ID) REFERENCES Team(Team_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

-- R9 PLAYER_MATCH_APPEARANCE (ternary). (Player, Match) -> Team.
-- The composite FK forces the team to be one that competes in that match.
CREATE TABLE Player_Match_Appearance (
  Player_ID            INT NOT NULL,
  Match_ID             INT NOT NULL,
  Team_ID              INT NOT NULL,
  Runs_Scored          INT UNSIGNED NULL,
  Balls_Faced          INT UNSIGNED NULL,
  Wickets_Taken        TINYINT UNSIGNED NULL,
  Rating_Points_Earned DECIMAL(7,2) NULL,
  PRIMARY KEY (Player_ID, Match_ID),
  FOREIGN KEY (Player_ID) REFERENCES Player(Player_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (Match_ID, Team_ID) REFERENCES Competes_In(Match_ID, Team_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- R7 MATCH_RESPONSIBILITY (M:N) + multivalued Responsibilities
CREATE TABLE Match_Responsibility (
  Player_ID INT NOT NULL,
  Match_ID  INT NOT NULL,
  PRIMARY KEY (Player_ID, Match_ID),
  FOREIGN KEY (Player_ID) REFERENCES Player(Player_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (Match_ID) REFERENCES `Match`(Match_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Match_Responsibility_Role (
  Player_ID      INT NOT NULL,
  Match_ID       INT NOT NULL,
  Responsibility ENUM('Captain','Vice Captain','Wicketkeeper') NOT NULL,
  PRIMARY KEY (Player_ID, Match_ID, Responsibility),
  FOREIGN KEY (Player_ID, Match_ID) REFERENCES Match_Responsibility(Player_ID, Match_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- R19 AWARDED_TO (kept separate from leadership, Phase 2 C11)
CREATE TABLE Awarded_To (
  Player_ID  INT NOT NULL,
  Match_ID   INT NOT NULL,
  Award_Type ENUM('Player of the Match','Best Batter','Best Bowler') NOT NULL,
  PRIMARY KEY (Player_ID, Match_ID),
  FOREIGN KEY (Player_ID) REFERENCES Player(Player_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (Match_ID) REFERENCES `Match`(Match_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 6. Innings and ball-by-ball (weak entities)
-- ---------------------------------------------------------------------
-- R4 HAS_INNINGS (identifying). R15 BATTED_BY: the composite FK to
-- Competes_In forces the batting team to be one of the match's two teams.
CREATE TABLE Innings_Scorecard (
  Match_ID             INT NOT NULL,
  Innings_Number       TINYINT UNSIGNED NOT NULL,
  Innings_Type         ENUM('Regular','Follow-on','Super Over') NOT NULL DEFAULT 'Regular',
  Innings_Status       ENUM('Draft','Live','Completed') NOT NULL DEFAULT 'Draft',
  Target_Score         INT UNSIGNED NULL,
  Effective_Over_Limit TINYINT UNSIGNED NULL,
  DLS_Par_Score        INT UNSIGNED NULL,
  Batting_Team_ID      INT NOT NULL,
  PRIMARY KEY (Match_ID, Innings_Number),
  FOREIGN KEY (Match_ID) REFERENCES `Match`(Match_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (Match_ID, Batting_Team_ID) REFERENCES Competes_In(Match_ID, Team_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT ck_innings_no CHECK (Innings_Number BETWEEN 1 AND 6)
);

-- Multivalued: Innings.Score_Adjustments (non-delivery penalty runs)
CREATE TABLE Innings_Score_Adjustment (
  Match_ID       INT NOT NULL,
  Innings_Number TINYINT UNSIGNED NOT NULL,
  Adjustment_No  TINYINT UNSIGNED NOT NULL,
  Penalty_Runs   INT UNSIGNED NOT NULL,
  Reason         VARCHAR(255) NULL,
  PRIMARY KEY (Match_ID, Innings_Number, Adjustment_No),
  FOREIGN KEY (Match_ID, Innings_Number) REFERENCES Innings_Scorecard(Match_ID, Innings_Number)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- R5 DELIVERED_IN (identifying). One row per physical delivery attempt.
-- Over_Number is 0-based (first over = 0). Is_Legal = 0 for wides/no-balls.
CREATE TABLE Ball (
  Match_ID            INT NOT NULL,
  Innings_Number      TINYINT UNSIGNED NOT NULL,
  Over_Number         SMALLINT UNSIGNED NOT NULL,
  Delivery_Sequence   SMALLINT UNSIGNED NOT NULL,
  Runs_Off_Bat        TINYINT UNSIGNED NOT NULL DEFAULT 0,
  Legal_Ball_Sequence SMALLINT UNSIGNED NULL,
  Is_Legal            BOOLEAN NOT NULL DEFAULT TRUE,
  Wicket_Flag         BOOLEAN NOT NULL DEFAULT FALSE,
  Dismissal_Type      ENUM('Bowled','Caught','LBW','Run out','Stumped','Hit wicket',
                           'Obstructing the field','Handled the ball','Timed out',
                           'Hit the ball twice') NULL,
  Commentary          TEXT NULL,
  Dismissed_Player_ID INT NULL,      -- R16 DISMISSED_PLAYER
  PRIMARY KEY (Match_ID, Innings_Number, Over_Number, Delivery_Sequence),
  FOREIGN KEY (Match_ID, Innings_Number) REFERENCES Innings_Scorecard(Match_ID, Innings_Number)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (Dismissed_Player_ID) REFERENCES Player(Player_ID)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT ck_ball_runs  CHECK (Runs_Off_Bat <= 6),
  CONSTRAINT ck_ball_seq   CHECK (Delivery_Sequence >= 1),
  CONSTRAINT ck_ball_legal CHECK (
    (Is_Legal = 1 AND Legal_Ball_Sequence IS NOT NULL) OR
    (Is_Legal = 0 AND Legal_Ball_Sequence IS NULL)),
  CONSTRAINT ck_ball_wicket CHECK (
    (Wicket_Flag = 0 AND Dismissal_Type IS NULL AND Dismissed_Player_ID IS NULL) OR
    (Wicket_Flag = 1 AND Dismissal_Type IS NOT NULL AND Dismissed_Player_ID IS NOT NULL))
);

-- Multivalued: Ball.Extras (one ball can carry several extras, C08)
CREATE TABLE Ball_Extra (
  Match_ID          INT NOT NULL,
  Innings_Number    TINYINT UNSIGNED NOT NULL,
  Over_Number       SMALLINT UNSIGNED NOT NULL,
  Delivery_Sequence SMALLINT UNSIGNED NOT NULL,
  Extra_Type        ENUM('Wide','No-ball','Bye','Leg-bye') NOT NULL,
  Extra_Runs        TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (Match_ID, Innings_Number, Over_Number, Delivery_Sequence, Extra_Type),
  FOREIGN KEY (Match_ID, Innings_Number, Over_Number, Delivery_Sequence)
    REFERENCES Ball(Match_ID, Innings_Number, Over_Number, Delivery_Sequence)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- R8 DELIVERY_PARTICIPATION (M:N) + multivalued Delivery_Roles (A10)
CREATE TABLE Delivery_Participation (
  Match_ID          INT NOT NULL,
  Innings_Number    TINYINT UNSIGNED NOT NULL,
  Over_Number       SMALLINT UNSIGNED NOT NULL,
  Delivery_Sequence SMALLINT UNSIGNED NOT NULL,
  Player_ID         INT NOT NULL,
  PRIMARY KEY (Match_ID, Innings_Number, Over_Number, Delivery_Sequence, Player_ID),
  FOREIGN KEY (Match_ID, Innings_Number, Over_Number, Delivery_Sequence)
    REFERENCES Ball(Match_ID, Innings_Number, Over_Number, Delivery_Sequence)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (Player_ID) REFERENCES Player(Player_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Delivery_Role (
  Match_ID          INT NOT NULL,
  Innings_Number    TINYINT UNSIGNED NOT NULL,
  Over_Number       SMALLINT UNSIGNED NOT NULL,
  Delivery_Sequence SMALLINT UNSIGNED NOT NULL,
  Player_ID         INT NOT NULL,
  Delivery_Role     ENUM('Bowler','Striker','Non-striker','Catcher','Fielder',
                         'Run-out Fielder','Wicketkeeper') NOT NULL,
  PRIMARY KEY (Match_ID, Innings_Number, Over_Number, Delivery_Sequence, Player_ID, Delivery_Role),
  KEY idx_role_player (Delivery_Role, Player_ID),
  FOREIGN KEY (Match_ID, Innings_Number, Over_Number, Delivery_Sequence, Player_ID)
    REFERENCES Delivery_Participation(Match_ID, Innings_Number, Over_Number,
                                      Delivery_Sequence, Player_ID)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 7. Records, achievements, ranking snapshots
-- ---------------------------------------------------------------------
CREATE TABLE Record (
  Record_ID       INT AUTO_INCREMENT NOT NULL,
  Record_Title    VARCHAR(200) NOT NULL,
  Statistic_Value DECIMAL(12,2) NULL,
  Description     TEXT NULL,
  PRIMARY KEY (Record_ID),
  UNIQUE KEY uq_record_title (Record_Title)
);

-- R6a ACHIEVED, R6b OF_RECORD, R6c OCCURRED_IN
CREATE TABLE Achievement (
  Achievement_ID   INT AUTO_INCREMENT NOT NULL,
  Achievement_Date DATE NOT NULL,
  Achieved_Value   DECIMAL(12,2) NULL,
  Player_ID        INT NOT NULL,
  Record_ID        INT NOT NULL,
  Match_ID         INT NULL,
  PRIMARY KEY (Achievement_ID),
  FOREIGN KEY (Player_ID) REFERENCES Player(Player_ID)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (Record_ID) REFERENCES Record(Record_ID)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (Match_ID) REFERENCES `Match`(Match_ID)
    ON DELETE SET NULL ON UPDATE CASCADE
);

-- R17 TEAM_RANKING / R18 PLAYER_RANKING: exactly one subject (XOR).
-- Team_ID / Player_ID use RESTRICT because they appear in CHECK constraints.
CREATE TABLE Ranking_Snapshot (
  Snapshot_ID       INT AUTO_INCREMENT NOT NULL,
  As_Of             DATE NOT NULL,
  Format            ENUM('Test','ODI','T20I') NOT NULL,
  Ranking_Category  ENUM('Team','Batting','Bowling','All-rounder') NOT NULL,
  Gender_Category   ENUM('Men','Women')  NOT NULL,
  Age_Category      ENUM('Senior','U19') NOT NULL,
  Published_Rank    SMALLINT UNSIGNED NOT NULL,
  Published_Rating  DECIMAL(7,2) NULL,
  Published_Points  INT UNSIGNED NULL,
  Matches_Counted   INT UNSIGNED NULL,
  Team_ID           INT NULL,
  Player_ID         INT NULL,
  PRIMARY KEY (Snapshot_ID),
  KEY idx_rank_cohort (Format, Gender_Category, Age_Category, As_Of),
  FOREIGN KEY (Team_ID) REFERENCES Team(Team_ID)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  FOREIGN KEY (Player_ID) REFERENCES Player(Player_ID)
    ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT ck_rank_pos     CHECK (Published_Rank >= 1),
  CONSTRAINT ck_rank_subject CHECK ((Team_ID IS NULL) <> (Player_ID IS NULL)),
  CONSTRAINT ck_rank_cat     CHECK ((Ranking_Category = 'Team') = (Team_ID IS NOT NULL))
);

-- =====================================================================
-- TRIGGERS (rules Phase 3 left for Phase 4). DELIMITER is understood by
-- the mysql client, so `mysql < schema.sql` works unchanged.
-- =====================================================================
DELIMITER $$

-- T1: a match has at most 2 teams, and both must match the match's
--     gender/age category (Phase 2 C04). "At least 2" is checked by the app.
CREATE TRIGGER trg_competes_in_bi BEFORE INSERT ON Competes_In
FOR EACH ROW
BEGIN
  DECLARE m_gender VARCHAR(10);
  DECLARE m_age    VARCHAR(10);
  DECLARE t_gender VARCHAR(10);
  DECLARE t_age    VARCHAR(10);
  IF (SELECT COUNT(*) FROM Competes_In WHERE Match_ID = NEW.Match_ID) >= 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A match can have only two competing teams';
  END IF;
  SELECT Gender_Category, Age_Category INTO m_gender, m_age
    FROM `Match` WHERE Match_ID = NEW.Match_ID;
  SELECT Gender_Category, Age_Category INTO t_gender, t_age
    FROM Team WHERE Team_ID = NEW.Team_ID;
  IF m_gender <> t_gender OR m_age <> t_age THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Team gender/age category must match the match category';
  END IF;
END$$

-- T2: one bowler, one striker, one non-striker per ball, and one player
--     cannot hold two of these three roles on the same ball.
--     "Exactly one" (not just at most one) is guaranteed by the app transaction.
CREATE TRIGGER trg_delivery_role_bi BEFORE INSERT ON Delivery_Role
FOR EACH ROW
BEGIN
  IF NEW.Delivery_Role IN ('Bowler','Striker','Non-striker') THEN
    IF EXISTS (SELECT 1 FROM Delivery_Role
               WHERE Match_ID = NEW.Match_ID AND Innings_Number = NEW.Innings_Number
                 AND Over_Number = NEW.Over_Number
                 AND Delivery_Sequence = NEW.Delivery_Sequence
                 AND Delivery_Role = NEW.Delivery_Role) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This ball already has a player in that role';
    END IF;
    IF EXISTS (SELECT 1 FROM Delivery_Role
               WHERE Match_ID = NEW.Match_ID AND Innings_Number = NEW.Innings_Number
                 AND Over_Number = NEW.Over_Number
                 AND Delivery_Sequence = NEW.Delivery_Sequence
                 AND Player_ID = NEW.Player_ID
                 AND Delivery_Role IN ('Bowler','Striker','Non-striker')) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Bowler, striker and non-striker must be different players';
    END IF;
  END IF;
END$$

-- T3: a match belongs to exactly one subclass (disjoint specialization)
CREATE TRIGGER trg_test_match_bi BEFORE INSERT ON Test_Match
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM ODI_Match WHERE Match_ID = NEW.Match_ID)
     OR EXISTS (SELECT 1 FROM T20I_Match WHERE Match_ID = NEW.Match_ID) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Match already has another format';
  END IF;
END$$

CREATE TRIGGER trg_odi_match_bi BEFORE INSERT ON ODI_Match
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM Test_Match WHERE Match_ID = NEW.Match_ID)
     OR EXISTS (SELECT 1 FROM T20I_Match WHERE Match_ID = NEW.Match_ID) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Match already has another format';
  END IF;
END$$

CREATE TRIGGER trg_t20i_match_bi BEFORE INSERT ON T20I_Match
FOR EACH ROW
BEGIN
  IF EXISTS (SELECT 1 FROM Test_Match WHERE Match_ID = NEW.Match_ID)
     OR EXISTS (SELECT 1 FROM ODI_Match WHERE Match_ID = NEW.Match_ID) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Match already has another format';
  END IF;
END$$

-- T4: a series-linked match date must fall inside the series dates
CREATE TRIGGER trg_match_series_bi BEFORE INSERT ON `Match`
FOR EACH ROW
BEGIN
  DECLARE s_start DATE;
  DECLARE s_end   DATE;
  IF NEW.Series_ID IS NOT NULL THEN
    SELECT Start_Date, End_Date INTO s_start, s_end
      FROM Series WHERE Series_ID = NEW.Series_ID;
    IF NEW.Match_Date < s_start OR NEW.Match_Date > s_end THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Match date falls outside the series dates';
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_match_series_bu BEFORE UPDATE ON `Match`
FOR EACH ROW
BEGIN
  DECLARE s_start DATE;
  DECLARE s_end   DATE;
  IF NEW.Series_ID IS NOT NULL THEN
    SELECT Start_Date, End_Date INTO s_start, s_end
      FROM Series WHERE Series_ID = NEW.Series_ID;
    IF NEW.Match_Date < s_start OR NEW.Match_Date > s_end THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Match date falls outside the series dates';
    END IF;
  END IF;
END$$

-- T5: a player must keep at least one team (R1 total participation).
--     Fires on direct deletes only; deleting the Player row itself cascades.
CREATE TRIGGER trg_represents_keep_last BEFORE DELETE ON Represents
FOR EACH ROW
BEGIN
  IF (SELECT COUNT(*) FROM Represents WHERE Player_ID = OLD.Player_ID) <= 1 THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'A player must represent at least one team';
  END IF;
END$$

DELIMITER ;