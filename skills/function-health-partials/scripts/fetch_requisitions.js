// function-health-partials :: fetch_requisitions.js
//
// Run via the gstack browse `eval` command on a logged-in Function Health page:
//     $B eval .../scripts/fetch_requisitions.js
// `eval` does NOT await the returned promise, so this script fires an async
// request and stashes the result on window.__FH_REQS. Read it back with:
//     $B js "window.__FH_REQS.slice(0, 80)"      // sanity check (status=200|...)
//     $B js "window.__FH_REQS.length"            // then slice it out in chunks
//
// Auth: the member API authenticates with the Firebase ID token stored in
// localStorage.userData.idToken (a Bearer token, ~1h TTL) — NOT the portal
// cookie. If you get status=401 the token expired: `$B reload` to let the
// Firebase SDK refresh it, then re-run this script.

window.__FH_REQS = 'pending';
(async () => {
  try {
    const ud = localStorage.getItem('userData');
    if (!ud) { window.__FH_REQS = 'ERR no userData in localStorage (not logged in?)'; return; }
    const token = JSON.parse(ud).idToken;
    if (!token) { window.__FH_REQS = 'ERR no idToken in userData'; return; }
    const r = await fetch(
      'https://member-app-mid.functionhealth.com/api/v1/requisitions?pending=false',
      { headers: { Authorization: 'Bearer ' + token } }
    );
    const body = await r.text();
    // prefix with status so the caller can detect 401/expiry before parsing
    window.__FH_REQS = 'status=' + r.status + '|' + body;
  } catch (e) {
    window.__FH_REQS = 'ERR ' + (e && e.message ? e.message : String(e));
  }
})();
'fired';
