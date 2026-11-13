/**
 * ICC Cricket Rankings & Match Centre - Application Controller
 * Modelled on icc-cricket.com
 */

(function () {
  'use strict';

  // Global State
  const state = {
    currentRoute: 'rankings',
    routeParams: {},
    teamsCache: [],
    bowlingStylesCache: [],
    rankingsFilter: {
      format: 'ODI',
      category: 'Team',
      gender: 'Men',
      age: 'Senior',
    },
    matchesFilter: {
      format: '',
    },
    teamsFilter: 'all',
    analyticsFilter: {
      category: '',
    },
    playerSearchQuery: '',
    currentMatchId: null,
    currentPlayerId: null,
    currentTeamId: null,
  };

  // DOM Elements Cache
  const views = {
    rankings: document.getElementById('rankings-view'),
    matches: document.getElementById('matches-view'),
    matchDetail: document.getElementById('match-detail-view'),
    teams: document.getElementById('teams-view'),
    teamDetail: document.getElementById('team-detail-view'),
    players: document.getElementById('players-view'),
    playerDetail: document.getElementById('player-detail-view'),
    analytics: document.getElementById('analytics-view'),
  };

  const navLinks = document.querySelectorAll('.nav-link');
  const heroTag = document.getElementById('hero-tag');
  const heroTitle = document.getElementById('hero-title');
  const heroDesc = document.getElementById('hero-desc');
  const toastContainer = document.getElementById('toast-container');

  // Modals
  const newPlayerModal = document.getElementById('new-player-modal');
  const editPlayerModal = document.getElementById('edit-player-modal');
  const matchCorrectionModal = document.getElementById('match-correction-modal');
  const deleteTransitionModal = document.getElementById('delete-transition-modal');

  /* -------------------------------------------------------------------
     Toast Notification System
     ------------------------------------------------------------------- */
  function showToast(message, type = 'info', duration = 4500) {
    if (!toastContainer) return;
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    
    const icon = type === 'success' ? '✅' : type === 'error' ? '⚠️' : 'ℹ️';
    toast.innerHTML = `
      <div style="display:flex; align-items:center; gap:0.6rem;">
        <span>${icon}</span>
        <span>${escapeHtml(message)}</span>
      </div>
      <button type="button" style="color:#fff; opacity:0.8; font-weight:bold; font-size:1.1rem; line-height:1;" aria-label="Dismiss">&times;</button>
    `;

    toast.querySelector('button').addEventListener('click', () => {
      toast.remove();
    });

    toastContainer.appendChild(toast);

    setTimeout(() => {
      toast.style.transition = 'opacity 300ms ease, transform 300ms ease';
      toast.style.opacity = '0';
      toast.style.transform = 'translateX(100%)';
      setTimeout(() => toast.remove(), 320);
    }, duration);
  }

  function escapeHtml(str) {
    if (str === null || str === undefined) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  function formatDate(dStr) {
    if (!dStr) return '-';
    try {
      const dt = new Date(dStr);
      if (isNaN(dt.getTime())) return dStr;
      return dt.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
      });
    } catch {
      return dStr;
    }
  }

  /* -------------------------------------------------------------------
     Router & Navigation
     ------------------------------------------------------------------- */
  function parseHash() {
    const raw = window.location.hash.slice(1) || 'rankings';
    const [path, queryStr] = raw.split('?');
    const params = {};
    if (queryStr) {
      new URLSearchParams(queryStr).forEach((val, key) => {
        params[key] = val;
      });
    }
    return { path, params };
  }

  async function handleRoute() {
    const { path, params } = parseHash();
    state.currentRoute = path;
    state.routeParams = params;

    // Hide all view sections
    Object.values(views).forEach((el) => {
      if (el) el.classList.remove('active');
    });

    // Update active nav link
    const baseNav = path.startsWith('match') ? 'matches' :
                    path.startsWith('team') ? 'teams' :
                    path.startsWith('player') ? 'players' : path;

    navLinks.forEach((link) => {
      if (link.dataset.nav === baseNav) {
        link.classList.add('active');
      } else {
        link.classList.remove('active');
      }
    });

    // Route dispatch
    try {
      switch (path) {
        case 'rankings':
          views.rankings?.classList.add('active');
          heroTag.textContent = 'ICC International Standings';
          heroTitle.textContent = `${state.rankingsFilter.gender}'s ${state.rankingsFilter.format} ${state.rankingsFilter.category} Rankings`;
          heroDesc.textContent = 'Official ICC cricket rankings for international teams and individual players across all formats.';
          await loadRankings();
          break;

        case 'matches':
          views.matches?.classList.add('active');
          heroTag.textContent = 'ICC Match Centre';
          heroTitle.textContent = 'Fixtures & Match Results';
          heroDesc.textContent = 'Browse comprehensive scorecards, ball-by-ball commentary, and official match records.';
          await loadMatches();
          break;

        case 'match':
          views.matchDetail?.classList.add('active');
          state.currentMatchId = params.id;
          heroTag.textContent = 'ICC Official Scorecard';
          heroTitle.textContent = 'Match Scorecard & Centre';
          heroDesc.textContent = 'Comprehensive ball-by-ball deliveries, innings totals, player appearances, and auditable score revisions.';
          await loadMatchDetail(params.id);
          break;

        case 'teams':
          views.teams?.classList.add('active');
          heroTag.textContent = 'ICC Member Federations';
          heroTitle.textContent = 'International Cricket Teams';
          heroDesc.textContent = 'Explore participating national teams across Men, Women, Senior, and Under-19 categories.';
          await loadTeams();
          break;

        case 'team':
          views.teamDetail?.classList.add('active');
          state.currentTeamId = params.id;
          heroTag.textContent = 'Team Profile & History';
          heroTitle.textContent = 'Team Leadership & Captaincy';
          heroDesc.textContent = 'Official captaincy transitions, tenure tracking, and team metadata.';
          await loadTeamDetail(params.id);
          break;

        case 'players':
          views.players?.classList.add('active');
          heroTag.textContent = 'ICC Player Registry';
          heroTitle.textContent = 'International Players Directory';
          heroDesc.textContent = 'Search active and historical international players, review career stats, or register new player entries.';
          await loadPlayers();
          break;

        case 'player':
          views.playerDetail?.classList.add('active');
          state.currentPlayerId = params.id;
          heroTag.textContent = 'Player Career Profile';
          heroTitle.textContent = 'Player Profile & Achievements';
          heroDesc.textContent = 'International appearances, playing styles, representation tenures, and world records.';
          await loadPlayerDetail(params.id);
          break;

        case 'analytics':
          views.analytics?.classList.add('active');
          heroTag.textContent = 'ICC Performance Intelligence (Team 70 Report C)';
          heroTitle.textContent = 'Bowling Discipline Analytics by Venue';
          heroDesc.textContent = 'Evaluating Economy (Runs per Over) and Strike Rate (Balls per Wicket) for Pace and Spin bowlers across international grounds.';
          await loadAnalytics();
          break;

        default:
          window.location.hash = '#rankings';
      }
    } catch (err) {
      console.error('Route error:', err);
      showToast(err.message, 'error');
    }
  }

  /* -------------------------------------------------------------------
     Lookup Pre-loaders (Teams & Bowling Styles)
     ------------------------------------------------------------------- */
  async function ensureLookupsLoaded() {
    if (state.teamsCache.length === 0) {
      try {
        state.teamsCache = await ApiClient.getTeams();
      } catch (err) {
        console.warn('Could not load teams lookup:', err.message);
      }
    }

    if (state.bowlingStylesCache.length === 0) {
      try {
        state.bowlingStylesCache = await ApiClient.getBowlingStyles();
      } catch (err) {
        console.warn('Could not load bowling styles lookup:', err.message);
      }
    }

    populateLookupSelects();
  }

  function populateLookupSelects() {
    // Populate Team Select in New Player Modal
    const teamSelect = document.getElementById('np-team');
    if (teamSelect && teamSelect.options.length <= 1) {
      state.teamsCache.forEach((t) => {
        const opt = document.createElement('option');
        opt.value = t.Team_ID;
        opt.textContent = `${t.Team_Name} (${t.Gender_Category} ${t.Age_Category})`;
        teamSelect.appendChild(opt);
      });
    }

    // Populate Bowling Style Select in New Player and Edit Player Modals
    const bowlingSelects = [
      document.getElementById('np-bowling'),
      document.getElementById('ep-bowling'),
    ];

    bowlingSelects.forEach((sel) => {
      if (sel && sel.options.length <= 1) {
        state.bowlingStylesCache.forEach((b) => {
          const opt = document.createElement('option');
          opt.value = b.Bowling_Style;
          opt.textContent = `${b.Bowling_Style} (${b.Bowling_Category})`;
          sel.appendChild(opt);
        });
      }
    });
  }

  /* -------------------------------------------------------------------
     Q1: Rankings Controller
     ------------------------------------------------------------------- */
  async function loadRankings() {
    const spotlightEl = document.getElementById('rank-hero-spotlight');
    const tbody = document.getElementById('rankings-tbody');
    const titleEl = document.getElementById('rankings-table-title');
    const asOfBadge = document.getElementById('rankings-as-of-badge');

    tbody.innerHTML = `
      <tr>
        <td colspan="6">
          <div class="loading-spinner"><div class="spinner"></div><div>Loading latest ICC rankings...</div></div>
        </td>
      </tr>
    `;
    spotlightEl.innerHTML = '';

    const { format, category, gender, age } = state.rankingsFilter;
    titleEl.textContent = `${gender}'s ${age} ${format} ${category} Standings`;

    try {
      const data = await ApiClient.getRankings({ format, category, gender, age });

      if (!data || data.length === 0) {
        tbody.innerHTML = `
          <tr>
            <td colspan="6">
              <div class="empty-state">
                <div class="empty-state-icon">📊</div>
                <div class="empty-state-title">No Rankings Snapshot Found</div>
                <div>There are currently no published rankings for this specific cohort filter.</div>
              </div>
            </td>
          </tr>
        `;
        asOfBadge.textContent = 'No Data';
        return;
      }

      const topRank = data[0];
      asOfBadge.textContent = `As of ${formatDate(topRank.As_Of)}`;

      // Render Hero #1 Spotlight
      const linkHash = topRank.Player_ID
        ? `#player?id=${topRank.Player_ID}`
        : topRank.Team_ID
        ? `#team?id=${topRank.Team_ID}`
        : '#';

      spotlightEl.innerHTML = `
        <div class="rank-hero-card">
          <div class="rank-hero-info">
            <div class="rank-hero-crown">1</div>
            <div>
              <div class="rank-hero-meta">ICC WORLD NUMBER ONE • ${escapeHtml(gender.toUpperCase())} ${escapeHtml(format.toUpperCase())}</div>
              <a href="${linkHash}" class="rank-hero-name">${escapeHtml(topRank.Name)}</a>
              <div class="rank-hero-meta" style="margin-top: 0.25rem;">
                Snapshot Date: ${formatDate(topRank.As_Of)} • ${topRank.Matches_Counted ?? 0} matches counted
              </div>
            </div>
          </div>
          <div class="rank-hero-stats">
            <div>
              <div class="rank-hero-stat-val">${topRank.Published_Rating ?? '-'}</div>
              <div class="rank-hero-stat-lbl">Rating</div>
            </div>
            <div>
              <div class="rank-hero-stat-val">${topRank.Published_Points ?? '-'}</div>
              <div class="rank-hero-stat-lbl">Points</div>
            </div>
          </div>
        </div>
      `;

      // Render Table Rows
      tbody.innerHTML = data
        .map((row) => {
          const rank = row.Published_Rank;
          const rankClass = rank === 1 ? 'rank-1' : rank === 2 ? 'rank-2' : rank === 3 ? 'rank-3' : '';
          const rowLink = row.Player_ID
            ? `#player?id=${row.Player_ID}`
            : row.Team_ID
            ? `#team?id=${row.Team_ID}`
            : '#';

          return `
            <tr>
              <td><span class="rank-badge ${rankClass}">${rank}</span></td>
              <td>
                <a href="${rowLink}" style="font-weight: 700; color: var(--icc-navy); text-decoration: none;" onmouseover="this.style.color='var(--icc-crimson)'" onmouseout="this.style.color='var(--icc-navy)'">
                  ${escapeHtml(row.Name)}
                </a>
              </td>
              <td><strong>${row.Published_Points ?? '-'}</strong></td>
              <td><strong style="color: var(--icc-blue); font-size: 1rem;">${row.Published_Rating ?? '-'}</strong></td>
              <td>${row.Matches_Counted ?? '-'}</td>
              <td style="color: var(--text-muted); font-size: 0.85rem;">${formatDate(row.As_Of)}</td>
            </tr>
          `;
        })
        .join('');
    } catch (err) {
      tbody.innerHTML = `
        <tr>
          <td colspan="6">
            <div class="empty-state" style="color: #dc2626;">
              <div class="empty-state-icon">⚠️</div>
              <div class="empty-state-title">Error Loading Rankings</div>
              <div>${escapeHtml(err.message)}</div>
            </div>
          </td>
        </tr>
      `;
    }
  }

  /* -------------------------------------------------------------------
     Q4: Matches List Controller
     ------------------------------------------------------------------- */
  async function loadMatches() {
    const container = document.getElementById('matches-container');
    container.innerHTML = `
      <div style="grid-column: 1 / -1;">
        <div class="loading-spinner"><div class="spinner"></div><div>Loading international fixtures & results...</div></div>
      </div>
    `;

    try {
      const matches = await ApiClient.getMatches(state.matchesFilter.format || null);

      if (!matches || matches.length === 0) {
        container.innerHTML = `
          <div style="grid-column: 1 / -1;">
            <div class="empty-state">
              <div class="empty-state-icon">🏏</div>
              <div class="empty-state-title">No Matches Found</div>
              <div>No fixtures or results match the selected format filter.</div>
            </div>
          </div>
        `;
        return;
      }

      container.innerHTML = matches
        .map((m) => {
          const fmtClass = m.Format === 'Test' ? 'badge-test' : m.Format === 'ODI' ? 'badge-odi' : 'badge-t20i';
          const statusClass = m.Match_Status === 'Completed' ? 'completed' : '';

          return `
            <div class="match-card" onclick="window.location.hash='#match?id=${m.Match_ID}'">
              <div>
                <div class="match-card-header">
                  <span class="badge ${fmtClass}">${escapeHtml(m.Format || 'Match')}</span>
                  <span class="badge badge-status ${statusClass}">${escapeHtml(m.Match_Status || 'Scheduled')}</span>
                </div>
                <div class="match-series" title="${escapeHtml(m.Series_Name || '')}">
                  ${escapeHtml(m.Series_Name || 'International Series')}
                </div>
                <div class="match-teams">${escapeHtml(m.Teams || 'Teams TBD')}</div>
                <div class="match-venue">
                  <span>📍</span>
                  <span>${escapeHtml(m.Stadium || 'Stadium')}, ${escapeHtml(m.City || '')}</span>
                </div>
                <div style="font-size: 0.8rem; color: var(--text-muted); margin-bottom: 0.5rem;">
                  🗓️ ${formatDate(m.Match_Date)}
                </div>
              </div>
              <div>
                ${
                  m.Match_Result
                    ? `<div class="match-result-banner">${escapeHtml(m.Match_Result)}</div>`
                    : '<div style="font-size: 0.85rem; color: var(--text-muted);">Match scheduled</div>'
                }
                <div style="margin-top: 1rem; display: flex; justify-content: flex-end;">
                  <span style="font-size: 0.825rem; font-weight: 700; color: var(--icc-navy); display: flex; align-items: center; gap: 0.3rem;">
                    Full Scorecard & Centre →
                  </span>
                </div>
              </div>
            </div>
          `;
        })
        .join('');
    } catch (err) {
      container.innerHTML = `
        <div style="grid-column: 1 / -1;">
          <div class="empty-state" style="color: #dc2626;">
            <div class="empty-state-icon">⚠️</div>
            <div class="empty-state-title">Error Loading Matches</div>
            <div>${escapeHtml(err.message)}</div>
          </div>
        </div>
      `;
    }
  }

  /* -------------------------------------------------------------------
     Q4: Match Detail & Scorecard Controller
     ------------------------------------------------------------------- */
  async function loadMatchDetail(matchId) {
    if (!matchId) {
      window.location.hash = '#matches';
      return;
    }

    try {
      const match = await ApiClient.getMatchScorecard(matchId);

      // Header Meta
      const teamsText = (match.teams && match.teams.length > 0)
        ? match.teams.map((t) => t.Team_Name).join(' vs ')
        : 'International Match';

      document.getElementById('match-detail-teams').textContent = teamsText;
      document.getElementById('match-detail-series').textContent = match.Series_Name || 'Bilateral Series';
      document.getElementById('match-detail-date').textContent = `${formatDate(match.Match_Date)} ${match.Match_Time ? 'at ' + match.Match_Time : ''}`;
      document.getElementById('match-detail-venue').textContent = `${match.Stadium || 'Ground'}, ${match.City || ''}`;
      document.getElementById('match-detail-toss').textContent = match.Toss_Decision ? `Toss: ${match.Toss_Decision}` : 'Toss not recorded';
      document.getElementById('match-detail-result').textContent = match.Match_Result || 'Match in progress / Result pending';

      const fmtBadge = document.getElementById('match-detail-format-badge');
      fmtBadge.className = `badge ${match.Format === 'Test' ? 'badge-test' : match.Format === 'ODI' ? 'badge-odi' : 'badge-t20i'}`;
      fmtBadge.textContent = match.Format || 'MATCH';

      const statusBadge = document.getElementById('match-detail-status-badge');
      statusBadge.className = `badge badge-status ${match.Match_Status === 'Completed' ? 'completed' : ''}`;
      statusBadge.textContent = match.Match_Status || 'Scheduled';

      // 1. Innings Cards
      const inningsGrid = document.getElementById('match-innings-cards');
      if (!match.innings || match.innings.length === 0) {
        inningsGrid.innerHTML = `
          <div style="grid-column: 1 / -1;" class="empty-state">
            <div>No innings scorecards logged for this match yet.</div>
          </div>
        `;
      } else {
        inningsGrid.innerHTML = match.innings
          .map((inn) => `
            <div class="innings-card">
              <div class="innings-team">${escapeHtml(inn.Batting_Team)} • ${escapeHtml(inn.Innings_Type || 'Innings ' + inn.Innings_Number)}</div>
              <div class="innings-score">
                ${inn.Total_Runs ?? 0} <span style="font-size: 1.5rem; color: var(--text-muted);">/ ${inn.Wickets ?? 0}</span>
              </div>
              <div class="innings-overs">Overs: ${inn.Overs ?? '0.0'} (RR: ${inn.Run_Rate ?? '0.00'})</div>
              <div class="innings-details">
                <span>Off Bat: <strong>${inn.bat_runs ?? 0}</strong></span>
                <span>Extras: <strong>${inn.extras ?? 0}</strong></span>
                <span>Penalties: <strong>${inn.penalties ?? 0}</strong></span>
                <span class="badge badge-navy">${escapeHtml(inn.Innings_Status || 'Completed')}</span>
              </div>
            </div>
          `)
          .join('');
      }

      // 2. Appearances Table
      const appTbody = document.getElementById('match-appearances-tbody');
      if (!match.appearances || match.appearances.length === 0) {
        appTbody.innerHTML = '<tr><td colspan="6" class="empty-state">No player appearances recorded for this fixture.</td></tr>';
      } else {
        appTbody.innerHTML = match.appearances
          .map((a) => `
            <tr>
              <td>
                <a href="#player?id=${a.Player_ID}" style="font-weight: 700; color: var(--icc-navy); text-decoration: none;" onmouseover="this.style.color='var(--icc-crimson)'" onmouseout="this.style.color='var(--icc-navy)'">
                  ${escapeHtml(a.Player)}
                </a>
              </td>
              <td>${escapeHtml(a.Team_Name)}</td>
              <td><strong>${a.Runs_Scored ?? 0}</strong></td>
              <td>${a.Balls_Faced ?? 0}</td>
              <td><strong style="color: var(--icc-crimson);">${a.Wickets_Taken ?? 0}</strong></td>
              <td><span class="badge badge-navy">+${a.Rating_Points_Earned ?? 0} pts</span></td>
            </tr>
          `)
          .join('');
      }

      // 3. Ball-by-ball Timeline
      const ballsEl = document.getElementById('match-balls-timeline');
      if (!match.balls || match.balls.length === 0) {
        ballsEl.innerHTML = '<div class="empty-state">No ball-by-ball deliveries recorded.</div>';
      } else {
        ballsEl.innerHTML = match.balls
          .map((b) => {
            const isWicket = b.Wicket_Flag === 1;
            const runs = b.Runs_Off_Bat;
            let runBadgeClass = '';
            if (isWicket) runBadgeClass = 'wicket';
            else if (runs === 4) runBadgeClass = 'four';
            else if (runs === 6) runBadgeClass = 'six';

            return `
              <div class="timeline-ball">
                <span class="timeline-over-badge">Over ${b.Over_Number}.${b.Delivery_Sequence}</span>
                <span class="timeline-runs-badge ${runBadgeClass}">${isWicket ? 'W' : runs}</span>
                <div class="timeline-desc">
                  <div class="timeline-players">
                    ${escapeHtml(b.Bowler || 'Bowler')} to ${escapeHtml(b.Striker || 'Striker')}
                    ${b.Extras ? `<span class="badge badge-test" style="margin-left: 0.5rem;">${escapeHtml(b.Extras)}</span>` : ''}
                    ${isWicket ? `<span class="badge badge-test" style="margin-left: 0.5rem; background:#dc2626; color:#fff;">OUT! ${escapeHtml(b.Dismissal_Type || 'Dismissal')}</span>` : ''}
                  </div>
                  <div class="timeline-text">${escapeHtml(b.Commentary || 'Standard delivery.')}</div>
                </div>
              </div>
            `;
          })
          .join('');
      }

      // 4. Corrections Audit Log
      const corrTbody = document.getElementById('match-corrections-tbody');
      if (!match.corrections || match.corrections.length === 0) {
        corrTbody.innerHTML = '<tr><td colspan="7" class="empty-state">No official revisions logged for this match yet.</td></tr>';
      } else {
        corrTbody.innerHTML = match.corrections
          .map((c) => `
            <tr>
              <td><span class="badge badge-navy">Rev #${c.Revision_No}</span></td>
              <td style="font-size: 0.825rem; color: var(--text-muted);">${formatDate(c.Changed_At)}</td>
              <td><strong>${escapeHtml(c.Actor_Label || 'Scorer')}</strong></td>
              <td><code>${escapeHtml(c.Target_Path)}</code></td>
              <td style="color: #dc2626; text-decoration: line-through;">${escapeHtml(c.Old_Value || '(empty)')}</td>
              <td style="color: #059669; font-weight: 700;">${escapeHtml(c.New_Value)}</td>
              <td style="font-size: 0.85rem;">${escapeHtml(c.Reason || '-')}</td>
            </tr>
          `)
          .join('');
      }

      // Pre-fill hidden match ID for correction dialog
      const mcMatchIdInput = document.getElementById('mc-match-id');
      if (mcMatchIdInput) mcMatchIdInput.value = matchId;
    } catch (err) {
      showToast(`Failed to load match scorecard: ${err.message}`, 'error');
    }
  }

  /* -------------------------------------------------------------------
     Teams Controller
     ------------------------------------------------------------------- */
  async function loadTeams() {
    await ensureLookupsLoaded();
    const container = document.getElementById('teams-container');
    const filter = state.teamsFilter;

    let filtered = state.teamsCache;
    if (filter !== 'all') {
      const [gender, age] = filter.split('-');
      filtered = filtered.filter((t) => t.Gender_Category === gender && t.Age_Category === age);
    }

    if (filtered.length === 0) {
      container.innerHTML = `
        <div style="grid-column: 1 / -1;" class="empty-state">
          <div class="empty-state-icon">👥</div>
          <div class="empty-state-title">No Teams Found</div>
          <div>No teams match the filter.</div>
        </div>
      `;
      return;
    }

    container.innerHTML = filtered
      .map((t) => `
        <div class="team-card" onclick="window.location.hash='#team?id=${t.Team_ID}'">
          <div>
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.5rem;">
              <span class="badge badge-navy">${escapeHtml(t.ICC_Team_Code)}</span>
              <span class="badge badge-status">${escapeHtml(t.Gender_Category)} ${escapeHtml(t.Age_Category)}</span>
            </div>
            <h3 style="font-size: 1.25rem; font-weight: 800; color: var(--icc-navy); margin-bottom: 0.35rem;">
              ${escapeHtml(t.Team_Name)}
            </h3>
            <p style="font-size: 0.825rem; color: var(--text-muted);">
              Official ICC International Federation
            </p>
          </div>
          <div style="margin-top: 1rem; border-top: 1px solid var(--border-color); padding-top: 0.75rem; display: flex; justify-content: space-between; align-items: center;">
            <span style="font-size: 0.8rem; font-weight: 700; color: var(--icc-crimson);">View Captaincy Chain & Records →</span>
          </div>
        </div>
      `)
      .join('');
  }

  /* -------------------------------------------------------------------
     Q5 & W3: Team Detail & Captaincy Controller
     ------------------------------------------------------------------- */
  async function loadTeamDetail(teamId) {
    if (!teamId) {
      window.location.hash = '#teams';
      return;
    }

    try {
      const team = await ApiClient.getTeamCaptains(teamId);

      document.getElementById('team-detail-name').textContent = team.Team_Name;
      document.getElementById('team-detail-code').textContent = `Code: ${team.Team_Name.slice(0, 3).toUpperCase()}`;
      document.getElementById('team-detail-category-badge').textContent = `${team.Gender_Category} ${team.Age_Category}`;

      const container = document.getElementById('team-captains-container');
      if (!team.transitions || team.transitions.length === 0) {
        container.innerHTML = `
          <div class="empty-state">
            <div class="empty-state-icon">🎖️</div>
            <div class="empty-state-title">No Captaincy Transitions Recorded</div>
            <div>This team has no registered historical leadership transitions.</div>
          </div>
        `;
        return;
      }

      container.innerHTML = team.transitions
        .map((tr) => `
          <div class="captain-item">
            <div class="captain-transition-flow">
              <div>
                <div style="font-size: 0.7rem; text-transform: uppercase; color: var(--text-muted); font-weight: 700;">Predecessor</div>
                <div class="captain-name">${escapeHtml(tr.Predecessor)}</div>
              </div>
              <div class="captain-arrow">➔</div>
              <div>
                <div style="font-size: 0.7rem; text-transform: uppercase; color: var(--text-muted); font-weight: 700;">Successor</div>
                <div class="captain-name">${escapeHtml(tr.Successor)}</div>
              </div>
            </div>
            <div style="display: flex; align-items: center; gap: 1rem;">
              <span class="captain-date">📅 ${formatDate(tr.Transition_Date)}</span>
              <button type="button" class="btn-danger btn-sm" onclick="window.confirmDeleteTransition(${team.Team_ID}, ${tr.Predecessor_ID}, ${tr.Successor_ID}, '${tr.Transition_Date}', '${escapeHtml(tr.Predecessor).replace(/'/g, "\\'")}', '${escapeHtml(tr.Successor).replace(/'/g, "\\'")}')">
                🗑️ Delete
              </button>
            </div>
          </div>
        `)
        .join('');
    } catch (err) {
      showToast(`Failed to load team details: ${err.message}`, 'error');
    }
  }

  // Global handler for W3 Delete Transition Confirmation
  window.confirmDeleteTransition = function (teamId, predId, succId, dateStr, predName, succName) {
    document.getElementById('del-team-id').value = teamId;
    document.getElementById('del-pred-id').value = predId;
    document.getElementById('del-succ-id').value = succId;
    document.getElementById('del-date').value = dateStr;

    document.getElementById('del-predecessor-name').textContent = predName;
    document.getElementById('del-successor-name').textContent = succName;
    document.getElementById('del-transition-date').textContent = formatDate(dateStr);

    if (deleteTransitionModal) {
      deleteTransitionModal.showModal();
    }
  };

  /* -------------------------------------------------------------------
     Q2: Players List Controller
     ------------------------------------------------------------------- */
  let searchDebounceTimeout = null;

  async function loadPlayers() {
    const container = document.getElementById('players-container');
    container.innerHTML = `
      <div style="grid-column: 1 / -1;">
        <div class="loading-spinner"><div class="spinner"></div><div>Searching player records...</div></div>
      </div>
    `;

    try {
      const players = await ApiClient.searchPlayers(state.playerSearchQuery);

      if (!players || players.length === 0) {
        container.innerHTML = `
          <div style="grid-column: 1 / -1;">
            <div class="empty-state">
              <div class="empty-state-icon">🏏</div>
              <div class="empty-state-title">No Players Found</div>
              <div>Try another name search or register a new player using the button above.</div>
            </div>
          </div>
        `;
        return;
      }

      container.innerHTML = players
        .map((p) => {
          const fullName = [p.First_Name, p.Middle_Name, p.Last_Name].filter(Boolean).join(' ');
          const bowlingBadgeClass = p.Bowling_Category === 'Pace' ? 'badge-pace' : 'badge-spin';

          return `
            <div class="player-card" onclick="window.location.hash='#player?id=${p.Player_ID}'">
              <div>
                <h3 class="player-card-name">${escapeHtml(fullName)}</h3>
                <div class="player-card-meta">
                  <span>${p.Batting_Hand ? escapeHtml(p.Batting_Hand) + ' Hand' : 'Batter'}</span>
                  ${p.Bowling_Style ? ` • <span class="badge ${bowlingBadgeClass}">${escapeHtml(p.Bowling_Style)}</span>` : ''}
                </div>
                <div style="font-size: 0.825rem; color: var(--text-muted); margin-bottom: 0.5rem;">
                  <strong>Teams:</strong> ${escapeHtml(p.Teams || 'Unassigned')}
                </div>
                <div>
                  ${
                    p.Roles
                      ? p.Roles.split(', ')
                          .map((r) => `<span class="badge badge-role">${escapeHtml(r)}</span>`)
                          .join('')
                      : ''
                  }
                </div>
              </div>
              <div style="margin-top: 1rem; border-top: 1px solid var(--border-color); padding-top: 0.75rem; text-align: right;">
                <span style="font-size: 0.8rem; font-weight: 700; color: var(--icc-navy);">View Career Profile →</span>
              </div>
            </div>
          `;
        })
        .join('');
    } catch (err) {
      container.innerHTML = `
        <div style="grid-column: 1 / -1;">
          <div class="empty-state" style="color: #dc2626;">
            <div class="empty-state-icon">⚠️</div>
            <div class="empty-state-title">Error Loading Players</div>
            <div>${escapeHtml(err.message)}</div>
          </div>
        </div>
      `;
    }
  }

  /* -------------------------------------------------------------------
     Q2: Player Career Profile Controller
     ------------------------------------------------------------------- */
  async function loadPlayerDetail(playerId) {
    if (!playerId) {
      window.location.hash = '#players';
      return;
    }

    await ensureLookupsLoaded();

    try {
      const p = await ApiClient.getPlayerProfile(playerId);

      const fullName = [p.First_Name, p.Middle_Name, p.Last_Name].filter(Boolean).join(' ');
      document.getElementById('player-detail-name').textContent = fullName;
      document.getElementById('player-detail-reg').textContent = `Reg: ${p.ICC_Registration_No || '-'}`;
      document.getElementById('player-detail-country').textContent = p.Country_Of_Birth || 'Country Unspecified';
      document.getElementById('player-detail-dob').textContent = `DOB: ${formatDate(p.Date_Of_Birth)}`;
      document.getElementById('player-detail-debut').textContent = `Debut: ${formatDate(p.Debut_Date)}`;

      // Roles badges
      const rolesContainer = document.getElementById('player-detail-roles-badges');
      if (p.roles && p.roles.length > 0) {
        rolesContainer.innerHTML = p.roles
          .map((r) => `<span class="badge badge-navy" style="font-size: 0.8rem;">${escapeHtml(r)}</span>`)
          .join('');
      } else {
        rolesContainer.innerHTML = '<span class="badge badge-status">No specific roles logged</span>';
      }

      // Playing style & bio
      document.getElementById('player-detail-batting').textContent = p.Batting_Hand ? `${p.Batting_Hand} Hand` : '-';
      document.getElementById('player-detail-bowling').textContent = p.Bowling_Style || 'None';
      document.getElementById('player-detail-bowling-cat').textContent = p.Bowling_Category || '-';
      document.getElementById('player-detail-bio').textContent = p.Biography || 'No international career biography currently logged.';

      // Tenures table
      const tenuresTbody = document.getElementById('player-tenures-tbody');
      if (!p.tenures || p.tenures.length === 0) {
        tenuresTbody.innerHTML = '<tr><td colspan="4" class="empty-state">No international tenures recorded.</td></tr>';
      } else {
        tenuresTbody.innerHTML = p.tenures
          .map((t) => `
            <tr>
              <td><strong>${escapeHtml(t.Team_Name)}</strong></td>
              <td>${formatDate(t.Valid_From)}</td>
              <td>${t.Valid_To ? formatDate(t.Valid_To) : 'Present'}</td>
              <td>
                <span class="badge ${t.Valid_To ? 'badge-status' : 'badge-status completed'}">
                  ${t.Valid_To ? 'Concluded' : 'Active Squad'}
                </span>
              </td>
            </tr>
          `)
          .join('');
      }

      // Achievements table
      const achTbody = document.getElementById('player-achievements-tbody');
      if (!p.achievements || p.achievements.length === 0) {
        achTbody.innerHTML = '<tr><td colspan="4" class="empty-state">No world records or achievements logged.</td></tr>';
      } else {
        achTbody.innerHTML = p.achievements
          .map((a) => `
            <tr>
              <td><strong>${escapeHtml(a.Record_Title)}</strong></td>
              <td><span class="badge badge-navy">${escapeHtml(a.Achieved_Value)}</span></td>
              <td>${formatDate(a.Achievement_Date)}</td>
              <td>
                ${
                  a.Match_ID
                    ? `<a href="#match?id=${a.Match_ID}" style="color: var(--icc-crimson); font-weight: 700;">Match #${a.Match_ID} →</a>`
                    : 'Bilateral Event'
                }
              </td>
            </tr>
          `)
          .join('');
      }

      // Pre-fill Edit Player Modal fields
      document.getElementById('ep-player-id').value = p.Player_ID;
      document.getElementById('ep-batting').value = p.Batting_Hand || '';
      document.getElementById('ep-bowling').value = p.Bowling_Style || '';
      document.getElementById('ep-bio').value = p.Biography || '';
    } catch (err) {
      showToast(`Failed to load player profile: ${err.message}`, 'error');
    }
  }

  /* -------------------------------------------------------------------
     Q3: Analytics Controller (Team 70 Report C)
     ------------------------------------------------------------------- */
  async function loadAnalytics() {
    const tbody = document.getElementById('analytics-tbody');
    tbody.innerHTML = `
      <tr>
        <td colspan="8">
          <div class="loading-spinner"><div class="spinner"></div><div>Computing venue bowling discipline rates...</div></div>
        </td>
      </tr>
    `;

    try {
      const data = await ApiClient.getBowlingAnalytics(state.analyticsFilter.category || null);

      if (!data || data.length === 0) {
        tbody.innerHTML = `
          <tr>
            <td colspan="8">
              <div class="empty-state">
                <div class="empty-state-icon">📊</div>
                <div class="empty-state-title">No Analytics Records</div>
                <div>No bowling delivery records found for this category filter.</div>
              </div>
            </td>
          </tr>
        `;
        return;
      }

      tbody.innerHTML = data
        .map((row) => {
          const catClass = row.Bowling_Category === 'Pace' ? 'badge-pace' : 'badge-spin';
          return `
            <tr>
              <td><strong>${escapeHtml(row.Stadium)}</strong></td>
              <td>${escapeHtml(row.City)}, ${escapeHtml(row.Country_Name)}</td>
              <td><span class="badge ${catClass}">${escapeHtml(row.Bowling_Category)}</span></td>
              <td>${row.Legal_Balls ?? 0} balls</td>
              <td>${row.Runs_Charged ?? 0}</td>
              <td><strong style="color: var(--icc-crimson); font-size: 1rem;">${row.Wickets ?? 0}</strong></td>
              <td><strong style="color: var(--icc-blue); font-size: 1.05rem;">${row.Economy ?? '-'}</strong></td>
              <td><strong>${row.Strike_Rate ?? '-'}</strong></td>
            </tr>
          `;
        })
        .join('');
    } catch (err) {
      tbody.innerHTML = `
        <tr>
          <td colspan="8">
            <div class="empty-state" style="color: #dc2626;">
              <div class="empty-state-icon">⚠️</div>
              <div class="empty-state-title">Error Loading Analytics</div>
              <div>${escapeHtml(err.message)}</div>
            </div>
          </td>
        </tr>
      `;
    }
  }

  /* -------------------------------------------------------------------
     Event Listeners & Form Submissions
     ------------------------------------------------------------------- */
  function setupEventListeners() {
    // Window Hashchange
    window.addEventListener('hashchange', handleRoute);

    // Dialog close buttons
    document.querySelectorAll('[data-close-dialog]').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        const dialog = e.target.closest('dialog');
        if (dialog) dialog.close();
      });
    });

    // Brand Link
    document.getElementById('brand-link')?.addEventListener('click', (e) => {
      e.preventDefault();
      window.location.hash = '#rankings';
    });

    // Open Register Player Modal
    const openRegisterBtns = [
      document.getElementById('btn-open-register'),
      document.getElementById('btn-player-list-register'),
    ];
    openRegisterBtns.forEach((btn) => {
      btn?.addEventListener('click', async () => {
        await ensureLookupsLoaded();
        if (newPlayerModal) newPlayerModal.showModal();
      });
    });

    // Open Edit Player Modal
    document.getElementById('btn-edit-player-open')?.addEventListener('click', async () => {
      await ensureLookupsLoaded();
      if (editPlayerModal) editPlayerModal.showModal();
    });

    // Open Match Correction Modal
    document.getElementById('btn-open-correction')?.addEventListener('click', () => {
      if (matchCorrectionModal) matchCorrectionModal.showModal();
    });

    // Rankings Filter Pills
    setupPillGroup('rankings-format-pills', (val) => {
      state.rankingsFilter.format = val;
      loadRankings();
    });

    setupPillGroup('rankings-category-pills', (val) => {
      state.rankingsFilter.category = val;
      loadRankings();
    });

    setupPillGroup('rankings-gender-pills', (val) => {
      state.rankingsFilter.gender = val;
      loadRankings();
    });

    setupPillGroup('rankings-age-pills', (val) => {
      state.rankingsFilter.age = val;
      loadRankings();
    });

    // Matches Format Filter Pills
    setupPillGroup('matches-format-pills', (val) => {
      state.matchesFilter.format = val;
      loadMatches();
    });

    // Teams Filter Pills
    setupPillGroup('teams-filter-pills', (val) => {
      state.teamsFilter = val;
      loadTeams();
    });

    // Analytics Category Filter Pills
    setupPillGroup('analytics-category-pills', (val) => {
      state.analyticsFilter.category = val;
      loadAnalytics();
    });

    // Player Search Input (Debounced)
    const playerSearchInput = document.getElementById('player-search-input');
    if (playerSearchInput) {
      playerSearchInput.addEventListener('input', (e) => {
        clearTimeout(searchDebounceTimeout);
        state.playerSearchQuery = e.target.value.trim();
        searchDebounceTimeout = setTimeout(() => {
          loadPlayers();
        }, 250);
      });
    }

    // W1: New Player Form Submission
    const newPlayerForm = document.getElementById('new-player-form');
    if (newPlayerForm) {
      newPlayerForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const submitBtn = document.getElementById('btn-save-player');
        submitBtn.disabled = true;
        submitBtn.textContent = 'Saving...';

        const checkedRoles = Array.from(
          newPlayerForm.querySelectorAll('input[name="playing_role"]:checked')
        ).map((cb) => cb.value);

        const payload = {
          icc_registration_no: document.getElementById('np-reg-no').value.trim(),
          team_id: parseInt(document.getElementById('np-team').value, 10),
          first_name: document.getElementById('np-first-name').value.trim(),
          middle_name: document.getElementById('np-middle-name').value.trim() || null,
          last_name: document.getElementById('np-last-name').value.trim(),
          date_of_birth: document.getElementById('np-dob').value || null,
          country_of_birth: document.getElementById('np-country').value.trim() || null,
          batting_hand: document.getElementById('np-batting').value || null,
          bowling_style: document.getElementById('np-bowling').value || null,
          valid_from: document.getElementById('np-valid-from').value || new Date().toISOString().split('T')[0],
          debut_date: document.getElementById('np-debut').value || null,
          playing_roles: checkedRoles,
          biography: document.getElementById('np-bio').value.trim() || null,
        };

        try {
          const res = await ApiClient.createPlayer(payload);
          showToast(`Player registered successfully! (ID: ${res.player_id})`, 'success');
          newPlayerModal.close();
          newPlayerForm.reset();
          window.location.hash = `#player?id=${res.player_id}`;
        } catch (err) {
          showToast(err.message, 'error', 6000);
        } finally {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Save & Register';
        }
      });
    }

    // W2 (Option B): Edit Player Form Submission
    const editPlayerForm = document.getElementById('edit-player-form');
    if (editPlayerForm) {
      editPlayerForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const submitBtn = document.getElementById('btn-update-player');
        submitBtn.disabled = true;
        submitBtn.textContent = 'Updating...';

        const playerId = document.getElementById('ep-player-id').value;
        const payload = {
          batting_hand: document.getElementById('ep-batting').value || null,
          bowling_style: document.getElementById('ep-bowling').value || null,
          biography: document.getElementById('ep-bio').value.trim() || null,
        };

        try {
          await ApiClient.updatePlayer(playerId, payload);
          showToast('Player profile updated successfully!', 'success');
          editPlayerModal.close();
          await loadPlayerDetail(playerId);
        } catch (err) {
          showToast(err.message, 'error', 6000);
        } finally {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Save Changes';
        }
      });
    }

    // W2 (Option A): Match Correction Form Submission
    const matchCorrForm = document.getElementById('match-correction-form');
    if (matchCorrForm) {
      matchCorrForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const submitBtn = document.getElementById('btn-submit-correction');
        submitBtn.disabled = true;
        submitBtn.textContent = 'Submitting...';

        const matchId = document.getElementById('mc-match-id').value;
        const payload = {
          actor_label: document.getElementById('mc-actor').value.trim() || 'Scorer Admin',
          target_path: document.getElementById('mc-target').value,
          new_value: document.getElementById('mc-new-value').value.trim(),
          reason: document.getElementById('mc-reason').value.trim(),
        };

        try {
          const res = await ApiClient.addMatchCorrection(matchId, payload);
          showToast(`Official revision #${res.revision_no} recorded successfully!`, 'success');
          matchCorrectionModal.close();
          matchCorrForm.reset();
          await loadMatchDetail(matchId);
        } catch (err) {
          showToast(err.message, 'error', 6000);
        } finally {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Commit Correction';
        }
      });
    }

    // W3: Confirm Delete Transition Action
    const confirmDeleteBtn = document.getElementById('btn-confirm-delete-transition');
    if (confirmDeleteBtn) {
      confirmDeleteBtn.addEventListener('click', async () => {
        confirmDeleteBtn.disabled = true;
        confirmDeleteBtn.textContent = 'Deleting...';

        const teamId = document.getElementById('del-team-id').value;
        const predId = document.getElementById('del-pred-id').value;
        const succId = document.getElementById('del-succ-id').value;
        const dateStr = document.getElementById('del-date').value;

        try {
          await ApiClient.deleteCaptainTransition(teamId, predId, succId, dateStr);
          showToast('Captaincy transition deleted successfully.', 'success');
          deleteTransitionModal.close();
          await loadTeamDetail(teamId);
        } catch (err) {
          showToast(err.message, 'error', 6000);
        } finally {
          confirmDeleteBtn.disabled = false;
          confirmDeleteBtn.textContent = 'Delete Transition';
        }
      });
    }
  }

  function setupPillGroup(groupId, onChange) {
    const group = document.getElementById(groupId);
    if (!group) return;

    group.addEventListener('click', (e) => {
      const btn = e.target.closest('.pill-btn');
      if (!btn) return;

      group.querySelectorAll('.pill-btn').forEach((b) => b.classList.remove('active'));
      btn.classList.add('active');

      const val = btn.dataset.format ?? btn.dataset.category ?? btn.dataset.gender ?? btn.dataset.age ?? btn.dataset.filter ?? '';
      onChange(val);
    });
  }

  // Initialization
  document.addEventListener('DOMContentLoaded', async () => {
    setupEventListeners();
    await ensureLookupsLoaded();
    handleRoute();
  });
})();
