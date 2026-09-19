## security-reviewer

**Verdict:** BLOCK

### Blocking
- `src/auth.py:40` Ownership check reads `user_id` from the request body and trusts it. Any logged-in user can PATCH another user's invoice by sending their id. Take the user id from the session, never from the body.

### Should fix
- (none)

### Noted
- Tools: gitleaks ran (0 leaks), semgrep ran (0 findings), pip-audit ran (0 advisories).

### Out of my lane
- (none)
