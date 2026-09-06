# Native account API — development contract

Status: implemented server API, shared validation, native-safe HTTP client,
protected-session state and three native Android account screens. This
is not production authentication certification, an identity-provider integration
or completion of the Android target goal.

## Application boundary

`src/app/accounts/profile.cr` contains the platform-neutral account value and
display-name validation. Names are optional, trimmed, at most 64 Unicode scalar
values / 256 UTF-8 bytes, and cannot contain C0/C1 controls. Empty input clears
the name. This is not a grapheme-cluster limit.

`src/platform/server/account_service.cr` applies that operation to the signed-in
Regular/Admin model. Both the authenticated web settings form and mobile API
call it. No request chooses another account ID or changes its email/role.
The existing HTML/Tailwind presentation remains; the settings form includes
the actual `_csrf` field and escapes rendered names.

`src/app/accounts/remote.cr` defines the Android-facing asynchronous client using
`Amber::Native::HTTPClient`, not Crystal HTTP/OpenSSL. Its HTTPS origin is explicit;
credentials, extra paths, queries, fragments, whitespace and percent-encoded
authorities are rejected. Tokens go in Authorization, never a URL. The client
has a 15-second timeout, a 4 KiB encoded request cap, and strict 8 KiB response
parsing with duplicate/unknown-key and invalid UTF-8 rejection. The platform
adapter supplies TLS, cancellation and application-thread completion.

`src/app/accounts/session_state.cr` owns the native session state machine. It
fences HTTP completions by generation, serializes protected reads/writes/deletes,
and publishes sign-in only after the credential write succeeds. Origin-bound
credentials contain only the token and absolute expiry, never profile/password
data. Corrupt/wrong-origin vault entries are preserved until explicit clearing;
failed deletion blocks another sign-in and remains retryable. Local deletion and
server revocation are separate results. A kill before deletion acknowledgment is
interrupted logout, not a promise of crash-atomic sign-out intent.

`src/platform/android/app.cr` supplies Android HTTP/Secrets and the native sign-in,
dashboard and settings screens. Background clears the password draft; retained
navigation and editor metadata survive Activity recreation. A fresh process
does not restore drafts or route history: it opens protected credentials and
fetches current account data. Authorization/expiry is checked by the server on
every call; the app also checks absolute expiry before opening or editing an
account. Passive display is not continuous server-session validation.

## Endpoints

All paths are under `/api/native/v1`. Input objects are exact and flat. Body
values must be strings; query parameters and method overrides are not supported.

| Method / path | Input | Successful response |
| --- | --- | --- |
| POST `/session` | `email`, `password` | 201: `token`, Unix-seconds `expires_at`, `account` |
| GET `/account` | No body; bearer token | 200: `account` |
| PATCH `/account` | `display_name`; bearer token | 200: updated `account` |
| DELETE `/session` | No body; bearer token | Empty 204 |

An account contains `id`, `email`, `account_type` (`regular` or `admin`) and
`display_name`. A valid native bearer session is required on each protected
endpoint. Browser cookies do not grant API access. Native routes do not install
the browser Session, permissive CORS, or request-logging middleware.

Fixed JSON errors include 400 invalid request, 401 unauthorized, 413 oversized
request, 415 JSON required, 422 invalid display name, 426 HTTPS required,
429 rate limited and 503 unavailable. Unknown native paths/methods return 404;
OPTIONS is not a CORS/preflight permission grant. Responses use `no-store` and
`nosniff`. API errors never echo request data or exception messages.

## Server sessions and deployment limits

- Existing Regular/Admin credentials authenticate the request. Both candidate
  password hashes are checked, using a dummy hash for absent candidates; this
  does not promise constant-time identity hiding across different stored costs.
- Each session uses 32 CSPRNG bytes encoded as an opaque 43-character token.
  PostgreSQL stores its SHA-256 digest, account type/ID, timestamps and a digest
  of the current password hash, not the bearer token.
- The absolute lifetime is eight hours; the idle limit is 30 minutes. Both are
  server-enforced on every use. Activity updates idle time without extending the
  absolute deadline. Logout revokes only that session. Password changes and
  deleted users invalidate their previous sessions on subsequent authorization.
- Authorization already performed for an in-flight request is not retroactively
  cancelled by logout. The native coordinator fences stale completions and waits
  for acknowledged protected deletion, including a pending write's completion.
- Login admission is ten requests per peer per fixed minute, with at most 4,096
  process-local peer buckets. Malformed login submissions count too. No forwarded
  IP header is trusted. Multi-worker/proxy deployments need a shared edge limit,
  connection/read-timeout and capacity policy; this is not distributed abuse
  protection. Expired rows are pruned on session issuance, not by a scheduler.
- The initial API requires a **direct TLS listener**. Set both
  `AMBER_SERVER_SSL_KEY_FILE` and `AMBER_SERVER_SSL_CERT_FILE` (legacy `SSL_*`
  aliases are also accepted) or configure both in server settings. Missing TLS
  returns 426; `X-Forwarded-Proto` does not bypass this. TLS-terminating proxy
  support needs an explicit trusted deployment design and is not silently enabled.
- No refresh token, MFA, recovery, device-session management, OAuth/OIDC, email
  verification, tenant model or new admin privilege API is added here. Existing
  account-security and pending permission checks are not newly certified.

The HTTPS, endpoint authorization and bounded-input choices follow the
[OWASP API guidance](https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html).
Opaque random identifiers, server expiry and revocation are informed by
[OWASP session guidance](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html).
Those references do not substitute for an application security review.

## Isolated verification

Use the existing guarded runner described in `android-reference-migration.md`.
It now truncates native sessions as well as the task's user tables between tests.
`scripts/native_reference_migrate.cr` verifies the exact task-owned database
before forward migrations and offers no rollback/drop mode. Never point ordinary
specs or migrations at an ambient development/production database.

`scripts/native_reference_seed.cr` creates a clearly synthetic reference account
only after the same task-database identity check. It does not send mail or
overwrite an existing fixture with different credentials. Its test password is
not included in the Android app or any production configuration.

After starting the actual server with direct localhost TLS and normal web CSRF
(`AMBER_ENV=development`, not the spec build), run:

```sh
crystal run scripts/native_reference_account_smoke.cr -- \
  https://localhost:38248 /absolute/path/to/task-only-ca.crt
```

The smoke script uses the seeded account, verifies certificate trust, browser
login/settings CSRF, mobile sign-in, bidirectional Unicode name edits, HTML
escaping, repeated Authorization rejection, early body rejection, chunked body
limits and logout. It accepts only an explicit localhost HTTPS origin and never
prints credentials/session/cookie values. No global trust store or production
configuration should be changed to run it.

Host client tests are `crystal spec spec/accounts`; the native object boundary
probe is `scripts/native_reference_client_boundary.cr`. Its four fake-transport
operations test compilation, not an Android TLS exchange. The x86_64 compiler
requires AssetPipeline's canonical Crystal libc overlay. A standalone boundary
object is not an application shared library: the real Android entrypoint must
include the canonical runtime initializer and host wiring.

See AssetPipeline's `docs/android-agentc-account-api-proof-2026-09-05.md` for the
API-boundary evidence and remaining gates. The Android host's README documents
the separate real-device/emulator account suite, compile-time origin and
debug-only task CA. No TLS bypass is included in the native client or release host.
