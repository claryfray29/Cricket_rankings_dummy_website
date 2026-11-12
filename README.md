# Cricket_rankings_dummy_website# ICC Cricket Rankings Web Application (Phase 4)

**Team Number:** 3  
**Mini World Domain:** ICC International Cricket Rankings & Match Centre  
**Reference Website:** [icc-cricket.com](https://www.icc-cricket.com/)

---

## 1. Database Paradigm and Technology Stack

* **Database Paradigm:** Relational Database Management System (RDBMS)
* **DBMS:** MySQL Community Server 8.0+ (InnoDB Storage Engine, `utf8mb4_0900_ai_ci`)
* **Python Backend:** Python 3.10+ using **FastAPI** (`fastapi>=0.110`, `uvicorn[standard]>=0.29`)
* **Database Driver:** `PyMySQL` (`pymysql>=1.1`, connecting with parameterized native SQL queries and manual transaction management)
* **Environment Configuration:** `python-dotenv` (`python-dotenv>=1.0`) loading variables from local `.env`
* **Frontend Stack:** Plain HTML5, CSS3, and modern Vanilla JavaScript (`fetch` API consuming JSON endpoints)

---

## 2. Design Changes

* **Phase 2 Baseline Team:** Team 70
* **Phase 3 Evolution Team:** Team 61

### Summary of Significant Schema Changes:
1. **Bowling Style 3NF Normalization (`Bowling_Style_Category` Table):** Extracted `Bowling_Style` and transitive `Bowling_Category` (`Pace`, `Spin`) into an independent lookup relation `Bowling_Style_Category` to eliminate functional transitive dependency and enforce 3NF.
2. **Backtick Quoting of `Match` Relation:** Quoted the relation as `` `Match` `` across all SQL statements and triggers because `MATCH` is a reserved full-text keyword in MySQL.
3. **Foreign Key Action Alignment (`RESTRICT` on Checked Columns):** Changed foreign key delete rules on `Ranking_Snapshot(Team_ID)` and `Ranking_Snapshot(Player_ID)` to `ON DELETE RESTRICT` because MySQL 8.0 forbids `CASCADE` / `SET NULL` actions on attributes constrained by `CHECK` clauses.
4. **Enforced Disjoint Specialization for Match Formats (Trigger `trg_test_match_bi`, `trg_odi_match_bi`, `trg_t20i_match_bi`):** Implemented `BEFORE INSERT` triggers on `Test_Match`, `ODI_Match`, and `T20I_Match` to guarantee that a `Match` instance belongs to exactly one subclass.
5. **Enforced Max Competing Teams Constraint (Trigger `trg_competes_in_bi`):** Implemented a `BEFORE INSERT` trigger on `Competes_In` ensuring no match has more than 2 competing teams and validating that team categories match the fixture’s age/gender category.
6. **Delivery Role Partitioning Constraint (Trigger `trg_delivery_role_bi`):** Implemented a `BEFORE INSERT` trigger on `Delivery_Role` ensuring that bowler, striker, and non-striker roles on any single ball are distinct individuals.
7. **Series Schedule Integrity Constraint (Trigger `trg_match_series_bi` / `trg_match_series_bu`):** Implemented triggers on `` `Match` `` checking that a scheduled match date strictly falls between `Series.Start_Date` and `Series.End_Date`.
8. **Total Participation Guard for Player Representation (Trigger `trg_represents_keep_last`):** Implemented a `BEFORE DELETE` trigger on `Represents` forbidding manual deletion of a player's last remaining team representation.

---

## 3. Setup and Run Instructions

### Step 1: Database Initialization
Open a terminal in the project root directory and execute the schema script followed by the data population script:

```bash
# Load the 34 tables, check constraints, and custom triggers
mysql -u root -p < src/schema.sql

# Populate with international cricket data
mysql -u root -p < src/populate.sql