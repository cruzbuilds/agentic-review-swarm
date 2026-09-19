## security-reviewer

**Verdict:** BLOCK

### Blocking
- `src/session.py:22` `jwtVerify` is called without an `algorithms` allowlist. A token signed with `alg: none` or an RSA public key confusion could verify. Pin `algorithms: ["HS256"]`.

### Should fix
- (none)

### Noted
- Tools: gitleaks ran (0 leaks), semgrep ran (0 findings), pip-audit ran (0 advisories).

### Out of my lane
- (none)
