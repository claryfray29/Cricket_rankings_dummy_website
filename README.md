# ICC Cricket Rankings Web Application (Phase 4)

**Team Number:** 3  
**Mini World Domain:** ICC International Cricket Rankings & Match Centre  
**Reference Website:** [icc-cricket.com/rankings](https://www.icc-cricket.com/rankings)

---

## 1. Database Paradigm and Technology Stack

* **Database Paradigm:** Relational Database Management System (RDBMS)
* **DBMS:** MySQL Community Server 8.0.46 (InnoDB Storage Engine, Character Set: `utf8mb4`, Collation: `utf8mb4_0900_ai_ci`)
* **Python Backend:** Python 3.12.3 running **FastAPI** (`v0.162.5`), served by **Uvicorn** (`v0.54.0`)
* **Database Driver:** `PyMySQL` (`v1.2.4`) utilizing pure parameterized native SQL (`%s` placeholders, zero ORMs/query builders) with Python context-managed transaction demarcation (`cur.execute()`, explicit `commit()` / `rollback()`)
* **Environment Management:** `python-dotenv` (`v1.2.4`) loading connection credentials securely from `src/.env`
* **Frontend Stack:** Semantic HTML5, CSS3 (responsive grid and flexbox styled to mirror the official ICC portal), and modern Vanilla JavaScript (ES6+ Fetch API, dynamic DOM rendering, zero build steps/external npm dependencies)

---

## 2. Design Changes

* **Phase 2 Baseline Team:** Team 70
* **Phase 3 Evolution Team:** Team 61
* **Phase 4 Implementation Team:** Team 3

### Summary of Significant Schema Changes from Phase 3:
1. **Bowling Style 3NF Normalization (`Bowling_Style_Category` Table):** Extracted `Bowling_Style` and its transitive category `Bowling_Category` (`Pace`, `Spin`) into an independent lookup relation `Bowling_Style_Category` to eliminate functional transitive dependency ($Bowling\_Style \rightarrow Bowling\_Category$) and achieve strict Third Normal Form (3NF).
2. **Backtick Quoting of `Match` Relation:** Quoted the relation as `` `Match` `` across all schema definitions, DML queries, and triggers because `MATCH` is a reserved keyword in MySQL full-text search.
3. **Foreign Key Action Alignment (`RESTRICT` on Checked Columns):** Replaced `CASCADE` / `SET NULL` foreign key clauses on `Ranking_Snapshot(Team_ID)` and `Ranking_Snapshot(Player_ID)` with `ON DELETE RESTRICT` because MySQL 8.0 explicitly rejects `CASCADE`/`SET NULL` referential actions on attributes governed by `CHECK` constraints.
4. **Enforced Disjoint Specialization for Match Formats (Triggers `trg_test_match_bi`, `trg_odi_match_bi`, `trg_t20i_match_bi`):** Created `BEFORE INSERT` triggers on `Test_Match`, `ODI_Match`, and `T20I_Match` verifying that a `Match_ID` does not already belong to another format subtype table, ensuring strict disjoint specialization.
5. **Enforced Max Competing Teams & Category Match (Trigger `trg_competes_in_bi`):** Implemented a `BEFORE INSERT` trigger on `Competes_In` ensuring no match fixture exceeds 2 competing teams and enforcing that team age and gender categories strictly match the fixture's category.
6. **Delivery Role Partitioning Constraint (Trigger `trg_delivery_role_bi`):** Implemented a `BEFORE INSERT` trigger on `Delivery_Role` ensuring that Bowler, Striker, and Non-striker on any single delivery are mutually distinct players.
7. **Series Schedule Integrity Constraint (Triggers `trg_match_series_bi` & `trg_match_series_bu`):** Implemented triggers on `` `Match` `` asserting that `Match_Date` strictly falls within `Series.Start_Date` and `Series.End_Date`.
8. **Total Participation Guard for Player Representation (Trigger `trg_represents_keep_last`):** Implemented a `BEFORE DELETE` trigger on `Represents` forbidding deletion when a player represents only one team, preserving mandatory total participation.

---

## 3. Setup and Run Instructions

### Step 1: Database Initialization
Ensure your local MySQL service is running, then load the relational schema followed by the data population script:

```bash
# Start MySQL service if not already active
sudo service mysql start   # or: sudo systemctl start mysql

# 1. Create database 'icc_rankings', 34 normalized tables, foreign keys, and 8 triggers
mysql -u root -p < src/schema.sql

# 2. Seed realistic international cricket data (teams, players, matches, deliveries, rankings)
mysql -u root -p < src/populate.sql
```

### Step 2: Environment Configuration
Create your local environment file from the provided template:

```bash
cp src/.env.example src/.env
```

Open `src/.env` in your text editor and update the MySQL connection parameters to match your local setup:
```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_local_password
DB_NAME=icc_rankings
```

### Step 3: Python Environment & Dependencies
Create a virtual environment and install the required dependencies:

```bash
# Create and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate

# Install required Python packages
pip install -r src/requirements.txt
```

### Step 4: Launch the Backend Server
Start the Uvicorn ASGI server from inside the `src/` directory (or with `python -m uvicorn`):

```bash
cd src
uvicorn app:app --reload --port 8000
```

### Step 5: Access the Web Application
Open your web browser and navigate to:
* **Web Application:** [http://localhost:8000](http://localhost:8000)
* **Interactive REST API Documentation (Swagger / OpenAPI):** [http://localhost:8000/docs](http://localhost:8000/docs)

---

## 4. Numbered Feature List (Demonstration Order)

The following numbered list details every application feature, its location in the UI, how to trigger it, and its behavior. This sequence exactly matches the demonstration flow in `3.mp4`:

1. **Tour of Main Interface & Portal Overview (Introductory Tour):**
   * **Location:** Header navigation and Hero Banner (`/` or `/#rankings`).
   * **Trigger:** Initial page load and clicking navigation tabs ("Rankings", "Matches", "Teams", "Players", "Analytics").
   * **Function:** Provides an authentic ICC portal presentation modelled on [icc-cricket.com/rankings](https://www.icc-cricket.com/rankings), with format selector chips, gender/age badges, and live breadcrumb routing.

2. **Filter & View Published ICC Standings (Q1 Read):**
   * **Location:** Rankings View (`/#rankings`).
   * **Trigger:** Click format pills (`Test`, `ODI`, `T20I`), category buttons (`Team`, `Batting`, `Bowling`, `All-rounder`), or gender/age dropdowns.
   * **Function:** Executes native SQL with `MAX(As_Of)` subqueries joining `Ranking_Snapshot` with `Team` or `Player`, dynamically updating the top-3 podium cards and full leaderboard table.

3. **Search Player Directory (Q2 Read):**
   * **Location:** Players Hub (`/#players`).
   * **Trigger:** Type into the "Search by name or country..." input box (instant search).
   * **Function:** Executes parameterized query using `GROUP_CONCAT` across `Player`, `Represents`, `Team`, and `Player_Playing_Role`, rendering player cards with national affiliations and primary playing roles.

4. **Inspect Player Career Profile & Achievements (Q2 Read):**
   * **Location:** Player Profile Detail View (`/#player/{id}`).
   * **Trigger:** Click the "View Profile" button on any player card in the Players Hub.
   * **Function:** Executes multi-table join fetching biographical data, normalized bowling category (`Bowling_Style_Category`), representation tenures (`Represents_Tenure`), and career milestones (`Achievement` JOIN `Record`).

5. **Atomic Player Registration & Onboarding (W1 Create / INSERT):**
   * **Location:** Players Hub (`/#players`) $\rightarrow$ "+ Register New Player" button.
   * **Trigger:** Fill the registration form (ICC registration number, name, DOB, country, batting hand, bowling style, debut date, team, tenure start, and multi-role tags) and click "Submit Registration".
   * **Function:** Wraps 4 queries in a single database transaction (`INSERT INTO Player`, `INSERT INTO Represents`, `INSERT INTO Represents_Tenure`, `INSERT INTO Player_Playing_Role`), enforcing atomicity and rolling back cleanly if any constraint fails.

6. **Edit Player Biographical & Skill Profile (W2 Option B Update / UPDATE):**
   * **Location:** Player Profile View (`/#player/{id}`) $\rightarrow$ "Edit Profile" button.
   * **Trigger:** Update biography text, batting hand, or bowling style in the dialog modal and click "Save Profile Changes".
   * **Function:** Executes a parameterized `UPDATE Player SET Biography = %s, Batting_Hand = %s, Bowling_Style = %s WHERE Player_ID = %s`, immediately updating the profile view.

7. **Browse Match Schedule & Fixture Results (Q4 Read):**
   * **Location:** Matches View (`/#matches`).
   * **Trigger:** Click "Matches" in the top navigation bar and select format filter chips (`All`, `Test`, `ODI`, `T20I`).
   * **Function:** Executes SQL dynamically resolving fixture formats across subtype tables (`Test_Match`, `ODI_Match`, `T20I_Match`) and competing teams (`Competes_In`), displaying fixture cards with scores and series titles.

8. **Examine Detailed Match Scorecard & Ball Telemetry (Q4 Read):**
   * **Location:** Match Detail View (`/#match/{id}`).
   * **Trigger:** Click "Match Centre" on any completed fixture card (e.g., Match 1: IND vs AUS).
   * **Function:** Renders complete innings tabs, over-by-over totals, calculated run rates, ball-by-ball delivery stream with extras breakdown (`Ball_Extra`), player match appearances (`Player_Match_Appearance`), and official revision history (`Match_Correction`).

9. **Submit Auditable Match Correction (W2 Option A Update / UPDATE):**
   * **Location:** Match Detail View (`/#match/{id}`) $\rightarrow$ "Propose Correction" button.
   * **Trigger:** Fill out the correction form (official actor role, target field to correct such as `toss_decision`, new value, and audit justification reason) and click "Commit Match Correction".
   * **Function:** Executes a transaction with row-level locking (`SELECT ... FOR UPDATE`), computes next `Revision_No`, inserts an audit entry into `Match_Correction`, and updates `` `Match` ``.

10. **Explore Team Captaincy Lineage & Timeline (Q5 Read):**
    * **Location:** Teams Hub (`/#teams`) $\rightarrow$ Team Card $\rightarrow$ Team Detail View (`/#team/{id}`).
    * **Trigger:** Click any team card (e.g., "India - Senior Men") and scroll to "Captaincy Succession & Transition History".
    * **Function:** Queries `Captaincy_Transition` joined with `Player` (predecessor and successor) to display chronological leadership handovers, tenure dates, and active captains.

11. **Delete Historical Captaincy Transition (W3 Delete / DELETE):**
    * **Location:** Team Detail View (`/#team/{id}`) $\rightarrow$ Captaincy Timeline.
    * **Trigger:** Click "Delete" next to a transition record and confirm in the modal dialog.
    * **Function:** Executes a transaction deleting the row from `Captaincy_Transition` and automatically pruning the corresponding `Captaincy_Succession` relation once all dated instances are removed.

12. **Analyze Venue Bowling Discipline & Pace vs. Spin Splits (Q3 Read):**
    * **Location:** Bowling Analytics View (`/#analytics`).
    * **Trigger:** Click "Analytics" in the top navigation bar.
    * **Function:** Runs aggregate queries directly in MySQL (`SUM(b.Runs_Off_Bat + COALESCE(x.charged, 0))`, `SUM(b.Is_Legal)`, `SUM(Wickets)`) to calculate venue economy rates and strike rates without averaging rates in application memory, displayed in comparison tables and Pace vs Spin visual split cards.
