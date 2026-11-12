"""ICC Cricket Rankings: FastAPI backend (MySQL, raw parameterised SQL only).

Run:  cd src && uvicorn app:app --reload      ->  http://localhost:8000
Docs: http://localhost:8000/docs
"""
from datetime import date, datetime
from pathlib import Path
from typing import List, Literal, Optional

import pymysql
from fastapi import FastAPI, HTTPException, Query
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field

import db

app = FastAPI(title="ICC Cricket Rankings API")

# ----------------------------------------------------------------------
# Error handling: DB errors become clear JSON messages the UI shows
# ----------------------------------------------------------------------
MYSQL_MESSAGES = {
    1062: (409, "Duplicate value: that record already exists."),
    1452: (400, "A referenced record (team, player, ...) does not exist."),
    1451: (409, "Cannot delete: other records still reference this one."),
    1048: (400, "A required field is missing."),
    1264: (400, "A number is out of the allowed range."),
    1292: (400, "A value has an invalid format (e.g. a bad date)."),
    1366: (400, "A value has an invalid format."),
    1265: (400, "A value is not one of the allowed options."),
}


@app.exception_handler(pymysql.MySQLError)
async def mysql_error_handler(request, exc):
    code = exc.args[0] if exc.args else 0
    text = exc.args[1] if len(exc.args) > 1 else ""
    if code == 1644:                      # our triggers (SQLSTATE 45000)
        return JSONResponse({"detail": text}, status_code=400)
    if code in (3819, 4025):              # CHECK constraint violated
        return JSONResponse({"detail": f"Data rule violated: {text}"}, status_code=400)
    if code in MYSQL_MESSAGES:
        status, msg = MYSQL_MESSAGES[code]
        return JSONResponse({"detail": msg}, status_code=status)
    if code in (1045, 2002, 2003, 2006, 2013):
        return JSONResponse({"detail": "Database is unavailable."}, status_code=503)
    return JSONResponse({"detail": f"Unexpected database error: {text or code}"}, status_code=500)


@app.exception_handler(RequestValidationError)
async def validation_handler(request, exc):
    parts = []
    for e in exc.errors():
        field = ".".join(str(x) for x in e["loc"] if x not in ("body", "query", "path"))
        parts.append(f"{field}: {e['msg']}")
    return JSONResponse({"detail": "Invalid input: " + "; ".join(parts)}, status_code=422)


def like_pattern(q: str) -> str:
    """Escape LIKE wildcards in user text. The result is passed as a %s VALUE."""
    q = q.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    return f"%{q}%"


# ----------------------------------------------------------------------
# Lookups used by dropdowns
# ----------------------------------------------------------------------
@app.get("/api/teams")
def list_teams():
    return db.fetch_all(
        "SELECT Team_ID, Team_Name, ICC_Team_Code, Gender_Category, Age_Category "
        "FROM Team ORDER BY Team_Name, Gender_Category, Age_Category")


@app.get("/api/bowling-styles")
def list_bowling_styles():
    return db.fetch_all(
        "SELECT Bowling_Style, Bowling_Category FROM Bowling_Style_Category "
        "ORDER BY Bowling_Category, Bowling_Style")


# ----------------------------------------------------------------------
# Q1: latest published rankings for a cohort
# ----------------------------------------------------------------------
@app.get("/api/rankings")
def rankings(
    fmt: Literal["Test", "ODI", "T20I"] = Query("ODI", alias="format"),
    gender: Literal["Men", "Women"] = "Men",
    age: Literal["Senior", "U19"] = "Senior",
    category: Literal["Team", "Batting", "Bowling", "All-rounder"] = "Team",
):
    sql = (
        "SELECT rs.Published_Rank, "
        "       COALESCE(t.Team_Name, CONCAT_WS(' ', p.First_Name, p.Last_Name)) AS Name, "
        "       rs.Team_ID, rs.Player_ID, rs.Published_Rating, rs.Published_Points, "
        "       rs.Matches_Counted, rs.As_Of "
        "FROM Ranking_Snapshot rs "
        "LEFT JOIN Team t   ON t.Team_ID   = rs.Team_ID "
        "LEFT JOIN Player p ON p.Player_ID = rs.Player_ID "
        "WHERE rs.Ranking_Category = %s AND rs.Format = %s "
        "  AND rs.Gender_Category = %s AND rs.Age_Category = %s "
        "  AND rs.As_Of = (SELECT MAX(r2.As_Of) FROM Ranking_Snapshot r2 "
        "                  WHERE r2.Ranking_Category = %s AND r2.Format = %s "
        "                    AND r2.Gender_Category = %s AND r2.Age_Category = %s) "
        "ORDER BY rs.Published_Rank")
    return db.fetch_all(sql, (category, fmt, gender, age, category, fmt, gender, age))


# ----------------------------------------------------------------------
# Q2: player search (with teams and roles)
# ----------------------------------------------------------------------
@app.get("/api/players")
def search_players(q: str = Query("", max_length=100)):
    sql = (
        "SELECT p.Player_ID, p.First_Name, p.Middle_Name, p.Last_Name, "
        "       p.Batting_Hand, p.Bowling_Style, bsc.Bowling_Category, "
        "       (SELECT GROUP_CONCAT(DISTINCT t.Team_Name ORDER BY t.Team_Name SEPARATOR ', ') "
        "          FROM Represents r JOIN Team t ON t.Team_ID = r.Team_ID "
        "         WHERE r.Player_ID = p.Player_ID) AS Teams, "
        "       (SELECT GROUP_CONCAT(pr.Playing_Role ORDER BY pr.Playing_Role SEPARATOR ', ') "
        "          FROM Player_Playing_Role pr WHERE pr.Player_ID = p.Player_ID) AS Roles "
        "FROM Player p "
        "LEFT JOIN Bowling_Style_Category bsc ON bsc.Bowling_Style = p.Bowling_Style "
        "WHERE CONCAT_WS(' ', p.First_Name, p.Middle_Name, p.Last_Name) LIKE %s "
        "ORDER BY p.Last_Name, p.First_Name LIMIT 50")
    return db.fetch_all(sql, (like_pattern(q.strip()),))


@app.get("/api/players/{player_id}")
def player_profile(player_id: int):
    player = db.fetch_one(
        "SELECT p.Player_ID, p.ICC_Registration_No, p.First_Name, p.Middle_Name, "
        "       p.Last_Name, p.Date_Of_Birth, p.Country_Of_Birth, p.Batting_Hand, "
        "       p.Bowling_Style, bsc.Bowling_Category, p.Biography, p.Debut_Date "
        "FROM Player p "
        "LEFT JOIN Bowling_Style_Category bsc ON bsc.Bowling_Style = p.Bowling_Style "
        "WHERE p.Player_ID = %s", (player_id,))
    if not player:
        raise HTTPException(404, "Player not found")
    player["roles"] = [r["Playing_Role"] for r in db.fetch_all(
        "SELECT Playing_Role FROM Player_Playing_Role WHERE Player_ID = %s "
        "ORDER BY Playing_Role", (player_id,))]
    player["tenures"] = db.fetch_all(
        "SELECT t.Team_ID, t.Team_Name, rt.Valid_From, rt.Valid_To "
        "FROM Represents_Tenure rt JOIN Team t ON t.Team_ID = rt.Team_ID "
        "WHERE rt.Player_ID = %s ORDER BY rt.Valid_From", (player_id,))
    player["achievements"] = db.fetch_all(
        "SELECT a.Achievement_ID, a.Achievement_Date, a.Achieved_Value, "
        "       r.Record_Title, m.Match_ID "
        "FROM Achievement a JOIN Record r ON r.Record_ID = a.Record_ID "
        "LEFT JOIN `Match` m ON m.Match_ID = a.Match_ID "
        "WHERE a.Player_ID = %s ORDER BY a.Achievement_Date DESC", (player_id,))
    return player


# ----------------------------------------------------------------------
# Q3: bowling discipline by venue and pace/spin (Team 70, Report C)
# Aggregate first, compute rates from the sums (never average rates).
# ----------------------------------------------------------------------
@app.get("/api/analytics/bowling")
def bowling_by_venue(category: Optional[Literal["Pace", "Spin"]] = None):
    sql = (
        "SELECT v.Venue_ID, v.Stadium, v.City, c.Country_Name, bsc.Bowling_Category, "
        "       SUM(b.Runs_Off_Bat + COALESCE(x.charged, 0)) AS Runs_Charged, "
        "       SUM(b.Is_Legal) AS Legal_Balls, "
        "       SUM(b.Wicket_Flag = 1 AND b.Dismissal_Type IN "
        "           ('Bowled','Caught','LBW','Stumped','Hit wicket')) AS Wickets, "
        "       ROUND(6 * SUM(b.Runs_Off_Bat + COALESCE(x.charged, 0)) "
        "             / NULLIF(SUM(b.Is_Legal), 0), 2) AS Economy, "
        "       ROUND(SUM(b.Is_Legal) / NULLIF(SUM(b.Wicket_Flag = 1 AND b.Dismissal_Type IN "
        "             ('Bowled','Caught','LBW','Stumped','Hit wicket')), 0), 2) AS Strike_Rate "
        "FROM Delivery_Role dr "
        "JOIN Ball b ON b.Match_ID = dr.Match_ID AND b.Innings_Number = dr.Innings_Number "
        "           AND b.Over_Number = dr.Over_Number "
        "           AND b.Delivery_Sequence = dr.Delivery_Sequence "
        "JOIN `Match` m ON m.Match_ID = b.Match_ID "
        "JOIN Venue v ON v.Venue_ID = m.Venue_ID "
        "JOIN Country c ON c.Country_Code = v.Country_Code "
        "JOIN Player p ON p.Player_ID = dr.Player_ID "
        "JOIN Bowling_Style_Category bsc ON bsc.Bowling_Style = p.Bowling_Style "
        "LEFT JOIN (SELECT Match_ID, Innings_Number, Over_Number, Delivery_Sequence, "
        "                  SUM(Extra_Runs) AS charged "
        "           FROM Ball_Extra WHERE Extra_Type IN ('Wide','No-ball') "
        "           GROUP BY Match_ID, Innings_Number, Over_Number, Delivery_Sequence) x "
        "  ON x.Match_ID = b.Match_ID AND x.Innings_Number = b.Innings_Number "
        " AND x.Over_Number = b.Over_Number AND x.Delivery_Sequence = b.Delivery_Sequence "
        "WHERE dr.Delivery_Role = 'Bowler' "
        "  AND (%s IS NULL OR bsc.Bowling_Category = %s) "
        "GROUP BY v.Venue_ID, v.Stadium, v.City, c.Country_Name, bsc.Bowling_Category "
        "ORDER BY v.Stadium, bsc.Bowling_Category")
    return db.fetch_all(sql, (category, category))


# ----------------------------------------------------------------------
# Q4: match list + scorecard (totals computed inside SQL)
# ----------------------------------------------------------------------
@app.get("/api/matches")
def list_matches(fmt: Optional[Literal["Test", "ODI", "T20I"]] = Query(None, alias="format")):
    sql = (
        "SELECT * FROM ("
        " SELECT m.Match_ID, m.Match_Date, m.Match_Status, m.Match_Result, "
        "        CASE WHEN tm.Match_ID IS NOT NULL THEN 'Test' "
        "             WHEN om.Match_ID IS NOT NULL THEN 'ODI' "
        "             WHEN tt.Match_ID IS NOT NULL THEN 'T20I' END AS Format, "
        "        v.Stadium, v.City, s.Series_Name, "
        "        (SELECT GROUP_CONCAT(t.Team_Name ORDER BY t.Team_Name SEPARATOR ' vs ') "
        "           FROM Competes_In ci JOIN Team t ON t.Team_ID = ci.Team_ID "
        "          WHERE ci.Match_ID = m.Match_ID) AS Teams "
        " FROM `Match` m "
        " LEFT JOIN Test_Match tm ON tm.Match_ID = m.Match_ID "
        " LEFT JOIN ODI_Match om  ON om.Match_ID = m.Match_ID "
        " LEFT JOIN T20I_Match tt ON tt.Match_ID = m.Match_ID "
        " LEFT JOIN Venue v  ON v.Venue_ID  = m.Venue_ID "
        " LEFT JOIN Series s ON s.Series_ID = m.Series_ID) x "
        "WHERE (%s IS NULL OR x.Format = %s) "
        "ORDER BY x.Match_Date DESC, x.Match_ID DESC LIMIT 100")
    return db.fetch_all(sql, (fmt, fmt))


@app.get("/api/matches/{match_id}")
def scorecard(match_id: int):
    header = db.fetch_one(
        "SELECT m.Match_ID, m.Match_Date, TIME_FORMAT(m.Match_Time, '%%H:%%i') AS Match_Time, "
        "       m.Toss_Decision, m.Match_Status, m.Match_Result, m.Rating_Weight, "
        "       m.DLS_Applied, m.Age_Category, m.Gender_Category, "
        "       CASE WHEN tm.Match_ID IS NOT NULL THEN 'Test' "
        "            WHEN om.Match_ID IS NOT NULL THEN 'ODI' "
        "            WHEN tt.Match_ID IS NOT NULL THEN 'T20I' END AS Format, "
        "       v.Stadium, v.City, s.Series_Name "
        "FROM `Match` m "
        "LEFT JOIN Test_Match tm ON tm.Match_ID = m.Match_ID "
        "LEFT JOIN ODI_Match om  ON om.Match_ID = m.Match_ID "
        "LEFT JOIN T20I_Match tt ON tt.Match_ID = m.Match_ID "
        "LEFT JOIN Venue v  ON v.Venue_ID  = m.Venue_ID "
        "LEFT JOIN Series s ON s.Series_ID = m.Series_ID "
        "WHERE m.Match_ID = %s", (match_id,))
    if not header:
        raise HTTPException(404, "Match not found")

    header["teams"] = db.fetch_all(
        "SELECT t.Team_ID, t.Team_Name, ci.Toss_Winner, ci.Winner_Status, "
        "       ci.Opponent_Rank_At_Match "
        "FROM Competes_In ci JOIN Team t ON t.Team_ID = ci.Team_ID "
        "WHERE ci.Match_ID = %s ORDER BY t.Team_Name", (match_id,))

    header["innings"] = db.fetch_all(
        "SELECT q.*, q.bat_runs + q.extras + q.penalties AS Total_Runs, "
        "       CONCAT(FLOOR(q.legal_balls / 6), '.', MOD(q.legal_balls, 6)) AS Overs, "
        "       ROUND(6 * (q.bat_runs + q.extras + q.penalties) "
        "             / NULLIF(q.legal_balls, 0), 2) AS Run_Rate "
        "FROM (SELECT i.Innings_Number, i.Innings_Type, i.Innings_Status, "
        "             t.Team_Name AS Batting_Team, "
        "  (SELECT COALESCE(SUM(b.Runs_Off_Bat), 0) FROM Ball b "
        "    WHERE b.Match_ID = i.Match_ID AND b.Innings_Number = i.Innings_Number) AS bat_runs, "
        "  (SELECT COALESCE(SUM(x.Extra_Runs), 0) FROM Ball_Extra x "
        "    WHERE x.Match_ID = i.Match_ID AND x.Innings_Number = i.Innings_Number) AS extras, "
        "  (SELECT COALESCE(SUM(a.Penalty_Runs), 0) FROM Innings_Score_Adjustment a "
        "    WHERE a.Match_ID = i.Match_ID AND a.Innings_Number = i.Innings_Number) AS penalties, "
        "  (SELECT COALESCE(SUM(b.Wicket_Flag), 0) FROM Ball b "
        "    WHERE b.Match_ID = i.Match_ID AND b.Innings_Number = i.Innings_Number) AS Wickets, "
        "  (SELECT COALESCE(SUM(b.Is_Legal), 0) FROM Ball b "
        "    WHERE b.Match_ID = i.Match_ID AND b.Innings_Number = i.Innings_Number) AS legal_balls "
        "      FROM Innings_Scorecard i JOIN Team t ON t.Team_ID = i.Batting_Team_ID "
        "      WHERE i.Match_ID = %s) q "
        "ORDER BY q.Innings_Number", (match_id,))

    header["balls"] = db.fetch_all(
        "SELECT b.Innings_Number, b.Over_Number, b.Delivery_Sequence, b.Runs_Off_Bat, "
        "       b.Is_Legal, b.Wicket_Flag, b.Dismissal_Type, b.Commentary, "
        "       NULLIF(CONCAT_WS(' ', pb.First_Name, pb.Last_Name), '') AS Bowler, "
        "       NULLIF(CONCAT_WS(' ', ps.First_Name, ps.Last_Name), '') AS Striker, "
        "       (SELECT GROUP_CONCAT(CONCAT(x.Extra_Type, ' ', x.Extra_Runs) SEPARATOR ', ') "
        "          FROM Ball_Extra x WHERE x.Match_ID = b.Match_ID "
        "           AND x.Innings_Number = b.Innings_Number "
        "           AND x.Over_Number = b.Over_Number "
        "           AND x.Delivery_Sequence = b.Delivery_Sequence) AS Extras "
        "FROM Ball b "
        "LEFT JOIN Delivery_Role rb ON rb.Match_ID = b.Match_ID "
        "     AND rb.Innings_Number = b.Innings_Number AND rb.Over_Number = b.Over_Number "
        "     AND rb.Delivery_Sequence = b.Delivery_Sequence AND rb.Delivery_Role = 'Bowler' "
        "LEFT JOIN Player pb ON pb.Player_ID = rb.Player_ID "
        "LEFT JOIN Delivery_Role rs ON rs.Match_ID = b.Match_ID "
        "     AND rs.Innings_Number = b.Innings_Number AND rs.Over_Number = b.Over_Number "
        "     AND rs.Delivery_Sequence = b.Delivery_Sequence AND rs.Delivery_Role = 'Striker' "
        "LEFT JOIN Player ps ON ps.Player_ID = rs.Player_ID "
        "WHERE b.Match_ID = %s "
        "ORDER BY b.Innings_Number, b.Over_Number, b.Delivery_Sequence", (match_id,))

    header["appearances"] = db.fetch_all(
        "SELECT p.Player_ID, CONCAT_WS(' ', p.First_Name, p.Last_Name) AS Player, "
        "       t.Team_Name, a.Runs_Scored, a.Balls_Faced, a.Wickets_Taken, "
        "       a.Rating_Points_Earned "
        "FROM Player_Match_Appearance a "
        "JOIN Player p ON p.Player_ID = a.Player_ID "
        "JOIN Team t ON t.Team_ID = a.Team_ID "
        "WHERE a.Match_ID = %s ORDER BY t.Team_Name, p.Last_Name", (match_id,))
    
    header["corrections"] = db.fetch_all(
        "SELECT Revision_No, Changed_At, Actor_Label, Target_Path, Old_Value, New_Value, Reason "
        "FROM Match_Correction WHERE Match_ID = %s ORDER BY Revision_No DESC", (match_id,))
    return header


# ----------------------------------------------------------------------
# Q5: captaincy chain for a team   |   W3: delete a transition
# ----------------------------------------------------------------------
@app.get("/api/teams/{team_id}/captains")
def captaincy_chain(team_id: int):
    team = db.fetch_one(
        "SELECT Team_ID, Team_Name, Gender_Category, Age_Category FROM Team "
        "WHERE Team_ID = %s", (team_id,))
    if not team:
        raise HTTPException(404, "Team not found")
    team["transitions"] = db.fetch_all(
        "SELECT ct.Transition_Date, ct.Predecessor_ID, ct.Successor_ID, "
        "       CONCAT_WS(' ', pp.First_Name, pp.Last_Name) AS Predecessor, "
        "       CONCAT_WS(' ', ps.First_Name, ps.Last_Name) AS Successor "
        "FROM Captaincy_Transition ct "
        "JOIN Player pp ON pp.Player_ID = ct.Predecessor_ID "
        "JOIN Player ps ON ps.Player_ID = ct.Successor_ID "
        "WHERE ct.Team_ID = %s ORDER BY ct.Transition_Date", (team_id,))
    return team


@app.delete("/api/teams/{team_id}/captains")
def delete_transition(
    team_id: int,
    predecessor_id: int = Query(...),
    successor_id: int = Query(...),
    transition_date: date = Query(...)
):
    with db.transaction() as cur:
        cur.execute(
            "DELETE FROM Captaincy_Transition WHERE Team_ID = %s AND Predecessor_ID = %s "
            "AND Successor_ID = %s AND Transition_Date = %s",
            (team_id, predecessor_id, successor_id, transition_date))
        if cur.rowcount == 0:
            raise HTTPException(404, "Transition not found")
        # Drop the succession row too once it has no dated transitions left.
        cur.execute(
            "DELETE FROM Captaincy_Succession WHERE Team_ID = %s AND Predecessor_ID = %s "
            "AND Successor_ID = %s AND NOT EXISTS ("
            "  SELECT 1 FROM Captaincy_Transition ct WHERE ct.Team_ID = %s "
            "  AND ct.Predecessor_ID = %s AND ct.Successor_ID = %s)",
            (team_id, predecessor_id, successor_id, team_id, predecessor_id, successor_id))
    return {"deleted": True}


# ----------------------------------------------------------------------
# W1: create a player (+ team, tenure, roles) in ONE transaction
# ----------------------------------------------------------------------
class NewPlayer(BaseModel):
    icc_registration_no: str = Field(min_length=1, max_length=30)
    first_name: str = Field(min_length=1, max_length=60)
    middle_name: Optional[str] = Field(None, max_length=60)
    last_name: str = Field(min_length=1, max_length=60)
    date_of_birth: Optional[date] = None
    country_of_birth: Optional[str] = Field(None, max_length=100)
    batting_hand: Optional[Literal["Right", "Left"]] = None
    bowling_style: Optional[str] = Field(None, max_length=50)
    biography: Optional[str] = None
    debut_date: Optional[date] = None
    team_id: int
    valid_from: date = Field(default_factory=date.today)
    playing_roles: List[str] = Field(default_factory=list, max_length=6)


@app.post("/api/players", status_code=201)
def create_player(p: NewPlayer):
    with db.transaction() as cur:
        cur.execute(
            "INSERT INTO Player (ICC_Registration_No, First_Name, Middle_Name, Last_Name, "
            "Date_Of_Birth, Country_Of_Birth, Batting_Hand, Bowling_Style, Biography, "
            "Debut_Date) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
            (p.icc_registration_no.strip(), p.first_name.strip(), p.middle_name or None,
             p.last_name.strip(), p.date_of_birth, p.country_of_birth or None,
             p.batting_hand, p.bowling_style or None, p.biography or None, p.debut_date))
        player_id = cur.lastrowid
        cur.execute("INSERT INTO Represents (Player_ID, Team_ID) VALUES (%s, %s)",
                    (player_id, p.team_id))
        cur.execute("INSERT INTO Represents_Tenure (Player_ID, Team_ID, Valid_From) "
                    "VALUES (%s, %s, %s)", (player_id, p.team_id, p.valid_from))
        for role in sorted({r.strip() for r in p.playing_roles if r.strip()}):
            cur.execute("INSERT INTO Player_Playing_Role (Player_ID, Playing_Role) "
                        "VALUES (%s, %s)", (player_id, role))
    return {"player_id": player_id}


# ----------------------------------------------------------------------
# W2 (Option A - Plan Spec): Append an auditable correction to a match
# ----------------------------------------------------------------------
class MatchCorrectionIn(BaseModel):
    actor_label: str = Field("Scorer Admin", max_length=100)
    target_path: Literal["match_result", "toss_decision", "match_status"]
    new_value: str = Field(min_length=1, max_length=100)
    reason: Optional[str] = Field(None, max_length=500)


# One fixed (SELECT, UPDATE) pair per correctable field. The SQL strings are
# constants, so no query is ever assembled from request data.
CORRECTABLE = {
    "match_result": (
        "SELECT Match_Result AS v FROM `Match` WHERE Match_ID = %s FOR UPDATE",
        "UPDATE `Match` SET Match_Result = %s WHERE Match_ID = %s"),
    "toss_decision": (
        "SELECT Toss_Decision AS v FROM `Match` WHERE Match_ID = %s FOR UPDATE",
        "UPDATE `Match` SET Toss_Decision = %s WHERE Match_ID = %s"),
    "match_status": (
        "SELECT Match_Status AS v FROM `Match` WHERE Match_ID = %s FOR UPDATE",
        "UPDATE `Match` SET Match_Status = %s WHERE Match_ID = %s"),
}


@app.post("/api/matches/{match_id}/corrections", status_code=201)
def add_match_correction(match_id: int, body: MatchCorrectionIn):
    select_sql, update_sql = CORRECTABLE[body.target_path]
    with db.transaction() as cur:
        # FOR UPDATE locks the match row so two corrections cannot pick the same Revision_No.
        cur.execute(select_sql, (match_id,))
        row = cur.fetchone()
        if not row:
            raise HTTPException(404, "Match not found")
        old_val = "" if row["v"] is None else str(row["v"])

        cur.execute(
            "SELECT COALESCE(MAX(Revision_No), 0) + 1 AS next_rev "
            "FROM Match_Correction WHERE Match_ID = %s", (match_id,))
        next_rev = cur.fetchone()["next_rev"]

        cur.execute(
            "INSERT INTO Match_Correction (Match_ID, Revision_No, Changed_At, Actor_Label, "
            "Target_Path, Old_Value, New_Value, Reason) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
            (match_id, next_rev, datetime.now(), body.actor_label, body.target_path,
             old_val, body.new_value, body.reason or None))
        # An invalid ENUM value fails here and the whole transaction rolls back.
        cur.execute(update_sql, (body.new_value, match_id))

    return {"revision_no": next_rev, "updated": True}


# ----------------------------------------------------------------------
# W2 (Option B): Update a player's profile
# ----------------------------------------------------------------------
class PlayerUpdate(BaseModel):
    biography: Optional[str] = None
    batting_hand: Optional[Literal["Right", "Left"]] = None
    bowling_style: Optional[str] = Field(None, max_length=50)


@app.put("/api/players/{player_id}")
def update_player(player_id: int, body: PlayerUpdate):
    with db.transaction() as cur:
        cur.execute("SELECT 1 FROM Player WHERE Player_ID = %s", (player_id,))
        if cur.fetchone() is None:
            raise HTTPException(404, "Player not found")
        cur.execute(
            "UPDATE Player SET Biography = %s, Batting_Hand = %s, Bowling_Style = %s "
            "WHERE Player_ID = %s",
            (body.biography or None, body.batting_hand, body.bowling_style or None,
             player_id))
    return {"updated": True}


# ----------------------------------------------------------------------
# Frontend (plain HTML/CSS/JS in web/), mounted LAST so /api wins
# ----------------------------------------------------------------------
FRONTEND_DIR = Path(__file__).resolve().parent / "web"
if not FRONTEND_DIR.is_dir():
    FRONTEND_DIR = Path(__file__).resolve().parent.parent / "web"
if FRONTEND_DIR.is_dir():
    app.mount("/", StaticFiles(directory=FRONTEND_DIR, html=True), name="frontend")
