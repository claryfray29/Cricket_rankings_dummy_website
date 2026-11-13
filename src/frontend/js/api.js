/**
 * ICC Cricket Rankings & Match Centre API Client
 * Wraps all FastAPI endpoints in src/app.py
 */

const API_BASE = '/api';

class ApiClient {
  /**
   * Internal fetch wrapper with unified JSON error handling
   */
  static async request(endpoint, options = {}) {
    const url = `${API_BASE}${endpoint}`;
    const headers = {
      'Accept': 'application/json',
      ...options.headers,
    };

    if (options.body && typeof options.body === 'object' && !(options.body instanceof FormData)) {
      headers['Content-Type'] = 'application/json';
      options.body = JSON.stringify(options.body);
    }

    try {
      const response = await fetch(url, { ...options, headers });
      const contentType = response.headers.get('content-type');
      let data = null;

      if (contentType && contentType.includes('application/json')) {
        data = await response.json();
      }

      if (!response.ok) {
        const errorMsg = data?.detail || data?.message || `HTTP ${response.status}: ${response.statusText}`;
        const error = new Error(errorMsg);
        error.status = response.status;
        error.data = data;
        throw error;
      }

      return data;
    } catch (err) {
      if (err.name === 'TypeError' && err.message.includes('fetch')) {
        const networkErr = new Error('Cannot connect to the ICC backend server. Please verify FastAPI is running at http://localhost:8000.');
        networkErr.status = 503;
        throw networkErr;
      }
      throw err;
    }
  }

  // Lookups
  static async getTeams() {
    return this.request('/teams');
  }

  static async getBowlingStyles() {
    return this.request('/bowling-styles');
  }

  // Q1: Latest published rankings snapshot
  static async getRankings({ format = 'ODI', gender = 'Men', age = 'Senior', category = 'Team' } = {}) {
    const params = new URLSearchParams({
      format,
      gender,
      age,
      category,
    });
    return this.request(`/rankings?${params.toString()}`);
  }

  // Q2: Player search & detail
  static async searchPlayers(query = '') {
    const params = new URLSearchParams({ q: query });
    return this.request(`/players?${params.toString()}`);
  }

  static async getPlayerProfile(playerId) {
    return this.request(`/players/${encodeURIComponent(playerId)}`);
  }

  // W1: Create new player (with team, tenure, roles)
  static async createPlayer(playerData) {
    return this.request('/players', {
      method: 'POST',
      body: playerData,
    });
  }

  // W2 (Option B): Update player profile
  static async updatePlayer(playerId, updateData) {
    return this.request(`/players/${encodeURIComponent(playerId)}`, {
      method: 'PUT',
      body: updateData,
    });
  }

  // Q4: Matches list & scorecard
  static async getMatches(format = null) {
    const params = new URLSearchParams();
    if (format) {
      params.append('format', format);
    }
    const query = params.toString() ? `?${params.toString()}` : '';
    return this.request(`/matches${query}`);
  }

  static async getMatchScorecard(matchId) {
    return this.request(`/matches/${encodeURIComponent(matchId)}`);
  }

  // W2 (Option A): Add auditable match correction
  static async addMatchCorrection(matchId, correctionData) {
    return this.request(`/matches/${encodeURIComponent(matchId)}/corrections`, {
      method: 'POST',
      body: correctionData,
    });
  }

  // Q5: Captaincy chain for a team
  static async getTeamCaptains(teamId) {
    return this.request(`/teams/${encodeURIComponent(teamId)}/captains`);
  }

  // W3: Delete captaincy transition
  static async deleteCaptainTransition(teamId, predecessorId, successorId, transitionDate) {
    const params = new URLSearchParams({
      predecessor_id: predecessorId,
      successor_id: successorId,
      transition_date: transitionDate,
    });
    return this.request(`/teams/${encodeURIComponent(teamId)}/captains?${params.toString()}`, {
      method: 'DELETE',
    });
  }

  // Q3: Bowling discipline by venue and pace/spin (Team 70, Report C)
  static async getBowlingAnalytics(category = null) {
    const params = new URLSearchParams();
    if (category) {
      params.append('category', category);
    }
    const query = params.toString() ? `?${params.toString()}` : '';
    return this.request(`/analytics/bowling${query}`);
  }
}

window.ApiClient = ApiClient;
