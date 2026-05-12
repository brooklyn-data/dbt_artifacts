# CI Rework — Security-driven redesign of dbt_artifacts CI

**Status:** Approved plan, pre-implementation
**Author:** Michael Carlone
**Last updated:** 2026-05-11

---

## 1. Background

`brooklyn-data/dbt_artifacts` is an open-source dbt **package** consumed by many
downstream dbt projects. Historically, CI ran on every contributor PR — including
forks — via the GitHub Actions `pull_request_target` event so that secrets
(warehouse credentials, GCP Workload Identity, Databricks tokens) were available
when running integration tests against Snowflake, BigQuery, Databricks, Postgres,
SQL Server, and Trino.

A security issue was identified: `pull_request_target` runs in the **base repo's
context with secrets available**, but the prior workflows then `checkout` the PR
head SHA. That gives attacker-controlled code access to warehouse credentials.
A malicious PR could modify `tox.ini`, `pyproject.toml`, `dbt_project.yml`,
macros, pre/post hooks, or sqlfluff config to exfiltrate secrets the moment a
maintainer clicks "approve" on the Environments gate.

As of this writing, **all integration CI is disabled** (every workflow file
except `main_lint_package.yml` and `publish_docs_on_release.yml` is commented
out). The package is shipping without integration test signal, which has
disrupted the intended **monthly release cadence**.

This spec defines a new CI design that (a) removes the `pull_request_target`
vulnerability, (b) gives contributors meaningful PR signal, (c) preserves
maintainer ability to validate against cloud warehouses pre-release, and (d)
maintains a single source of truth between local development and CI execution.

---

## 2. Goals & non-goals

### Goals

- **No `pull_request_target` anywhere.** PRs from forks must never have access
  to repository secrets.
- **Contributors get real signal.** Fork PRs should run lint and every
  warehouse that can be containerized locally — without secrets.
- **Maintainers can verify against cloud warehouses** before merging /
  releasing.
- **Local ↔ CI parity.** Anything CI runs, a developer can run with the same
  command on their laptop. No GitHub-Actions-specific glue logic.
- **Path of least resistance for contributors.** Minimal external tooling
  beyond what is already in use (`uv`, `tox`, `docker compose`).
- **Restore monthly release cadence** by making release verification a
  reproducible, automatable step.

### Non-goals

- Changing where contributors PR. They continue to target `main`. We do **not**
  introduce a long-lived `release-candidate` branch.
- Adding Databricks local emulation (impossible). Databricks remains
  cloud-only and is stubbed in the matrix.
- Adding `make` as a tooling layer. Shell scripts only.
- Replacing branch protection configuration via code. Branch protection is
  already configured on `main`; status checks will be updated by the
  repository admin as new workflows land.

---

## 3. Threat model

The trust boundary for this package is **"code that has been reviewed and
merged into `main` by a maintainer."**

- Code on `main` is trusted with full warehouse credentials.
- Code on `release-candidate/*` branches is trusted (created by maintainers
  during release prep).
- Code on **any** PR branch (including internal feature branches) is **not
  trusted** until merged. Even maintainer-authored branches go through PR.

The key insight: by using `pull_request` (not `pull_request_target`), CI on PRs
runs in a context where secrets are **structurally unavailable** — not gated by
human approval, but absent from the runner environment entirely. This is a much
stronger guarantee than the old "Environments approval" approach.

### Important caveat about the pre-rework state

When this work began, we believed all integration CI had been disabled. The
`ci_test_*.yml` and `main_test_*.yml` files were commented out — except for
two that were **live**:

- `ci_test_latest_version_on_feature_branch.yml`
- `ci_test_supported_versions_on_feature_branch.yml`

Both used `pull_request_target` and were firing on every PR with full
warehouse secrets in the environment. The vulnerability was not "dormant
pending CI rework" — it was active. Those two files were removed in Step 5
of this rework. The rework's switch from `pull_request_target` to
`pull_request` for the new `pr.yml` is what makes that removal safe to do
without losing PR-level test signal.

### Files that previously expanded the attack surface

These remain sensitive — modifications to them must be reviewed carefully even
though the new design prevents direct exfiltration:

- `.github/workflows/**`
- `scripts/ci/**` (new in this spec)
- `compose.yml`, `init-scripts/**`
- `tox.ini`, `pyproject.toml`, `uv.lock`
- `dbt_project.yml`, `packages.yml`, `package-lock.yml`

A `CODEOWNERS` file (added as part of this work) will require maintainer review
on changes to these paths.

---

## 4. Branching model

Unchanged from current practice — contributors PR against `main`:

```
fork-PR ─┐
         ├─► main ─► release-candidate/X.Y.Z ─► tag X.Y.Z
internal-PR ┘                    │
                                 └─► hotfix branches off main, PRs into main
```

`release-candidate/X.Y.Z` branches are **ephemeral**, created by a maintainer
to bump the version and run the full release matrix before tagging. They are
deleted after the tag is cut.

---

## 5. CI tier design

Three tiers, gated by GitHub Actions event and ref. **Each tier is a superset
of the previous tier** — Tier 2 runs everything Tier 1 runs, plus its own
additions; Tier 3 runs everything Tier 2 runs, plus its own additions.

### Tier 1 — PR smoke test (untrusted, no secrets)

| | |
|---|---|
| **Trigger** | `pull_request` targeting `main` (any source, including forks) |
| **Permissions** | `contents: read` only. No `id-token`. |
| **Secrets** | None available — by virtue of the `pull_request` event. |
| **Jobs** | SQLFluff lint; integration tests against Postgres, Trino, SQL Server via `docker compose` |
| **dbt version** | Latest supported only |
| **Concurrency** | One run per PR; new pushes cancel prior runs |

Tier 1 is the only signal a fork contributor sees on their PR. It is safe
because even arbitrary code execution on the runner gains nothing — there are
no secrets to steal.

### Tier 2 — Post-merge integration (trusted, cloud DWH)

| | |
|---|---|
| **Trigger** | `push` to `main` or `release-candidate/**` |
| **Permissions** | `contents: read`, `id-token: write` (for GCP WIF) |
| **Secrets** | Snowflake, BigQuery (via Workload Identity Federation), and any others required |
| **Jobs** | Everything in Tier 1 **plus** Snowflake and BigQuery on latest dbt |
| **dbt version** | Latest supported only |
| **Rationale** | Minimal cloud testing per maintainer convention: maintainers test their own DWH locally before merging; Tier 2 catches regressions on warehouses they don't personally use. |

Tier 2 is gated by branch protection on `main` requiring PR + maintainer
approval. Code only reaches a secrets-bearing context after human review of
the diff.

### Tier 3 — Release matrix (trusted, full validation)

| | |
|---|---|
| **Trigger** | `push` to `release-candidate/**`; `workflow_dispatch` |
| **Permissions** | Same as Tier 2 |
| **Secrets** | Same as Tier 2 |
| **Jobs** | Everything in Tier 2 **plus** full matrix: every warehouse × every supported dbt version |
| **dbt version** | All currently supported (matrix lives in `tox.ini`) |
| **Databricks** | Present in matrix as a stubbed job that exits with a documented "skipped — see issue #NNN" message |

Tier 3 is the gate on cutting a release tag. If Tier 3 is green on a
`release-candidate/X.Y.Z` branch, the maintainer tags `X.Y.Z` from that
branch's HEAD.

### Tier 4 — Docs publishing (unchanged)

Existing `publish_docs_on_release.yml`. Triggered on release tag.

### Summary table

| Event | Tier(s) that run | Secrets | Notes |
|---|---|---|---|
| `pull_request` → `main` | 1 | No | Fork-safe |
| `push` → `main` | 1 + 2 | Yes | Post-merge verification |
| `push` → `release-candidate/**` | 1 + 2 + 3 | Yes | Pre-release validation |
| `workflow_dispatch` (manual) | 3 (selectable) | Yes | Maintainer escape hatch |
| Release tag | 4 | N/A | Docs only |

---

## 6. Single-source-of-truth script layer

All test execution lives in `scripts/ci/`. GitHub Actions workflows are thin
shells that `checkout → setup → invoke a script`. The same scripts run locally.

### Proposed layout

```
scripts/ci/
  setup.sh              # uv sync; validate required env vars; dbt deps
  compose-up.sh         # docker compose up -d for local DWHs + wait-for-ready healthchecks
  compose-down.sh       # docker compose down -v
  lint.sh               # uv run tox -e lint (sqlfluff)
  test.sh               # USAGE: test.sh <warehouse> [<dbt_version>]
                        # Dispatches to: uv run tox -e integration_<warehouse>[_<version>]
                        # Handles compose-up / compose-down for local DWHs automatically.
  test-all-local.sh     # convenience: test.sh postgres + trino + sqlserver
```

### Design rules for scripts

- **No GitHub-Actions-isms.** No `${GITHUB_*}` env vars, no `::set-output`, no
  conditional logic on CI environment. Scripts behave identically on a laptop.
- **Fail fast** (`set -euo pipefail`).
- **Explicit env contract.** Each script documents the env vars it requires at
  the top and validates them before doing work (clear error → easier debugging
  for contributors).
- **Self-contained cleanup.** `test.sh postgres` is responsible for tearing
  down what it brought up, even on failure (`trap`-based cleanup).
- **No assumptions about cwd.** Scripts `cd` to the repo root themselves.

### What lives in GitHub Actions vs. in scripts

| GitHub Actions only | Shell scripts (shared) |
|---|---|
| `actions/checkout` | `uv sync` |
| `actions/setup-python` (if needed) | `docker compose up/down` |
| `google-github-actions/auth` (WIF) | `tox -e integration_*` invocation |
| Matrix definition | Healthcheck wait loops |
| Secret → env var mapping | Per-warehouse setup quirks |
| Concurrency config | dbt deps / debug |

### `act` compatibility

The shell-script design naturally supports `nektos/act` for local workflow
testing. Contributors who want to validate workflow changes can run `act
pull_request` and it will exercise the same scripts. We will **not** make `act`
a hard dependency, but documenting it as an optional tool is encouraged.

---

## 7. `compose.yml` (delivered in Step 1)

[`compose.yml`](../compose.yml) covers Postgres, Trino, SQL Server. Changes
made during Step 1:

1. **Fixed broken Trino config path.** The old file referenced `./.trino-config`
   (nonexistent at repo root); the actual config lives at
   `integration_test_project/.trino-config/`. Volume mount updated accordingly.
2. **Removed `sqlserver.post_start` apt-install.** It was installing ODBC tools
   *inside the SQL Server container*, which is useless — the dbt-sqlserver
   adapter runs on the host and connects in. The host-side ODBC driver
   requirement is now documented in `compose.yml`'s header and
   `scripts/ci/README.md`. No Dockerfile derivation was needed since the
   bundled `/opt/mssql-tools18/` is already present in the base image for the
   healthcheck and configurator sidecar.
3. **Added healthchecks** to `postgres` (`pg_isready`) and `trino`
   (`/v1/info` curl). SQL Server already had one. `docker compose up --wait`
   now blocks deterministically until services are accepting connections,
   replacing the old `sleep 15` pattern in `integration_test_project/run_tests.sh`.
4. **Pinned image tags.** `postgres:15-alpine`, `trinodb/trino:476`. SQL
   Server stays on `mcr.microsoft.com/mssql/server:2025-latest` (MS doesn't
   publish more granular stable tags publicly).
5. **Shifted host-side ports to non-standard values** to eliminate clashes
   with developer-local services. See §8.5.
6. **Renamed `sqlserver.configurator` → `sqlserver-configurator`** (compose
   service names can't contain dots when used positionally with
   `docker compose up <service>`).

No Snowflake / BigQuery / Databricks entries — these are cloud-only and
remain out of `compose.yml`.

---

## 7.5. tox.ini modernization (delivered in Step 1)

Adjacent to the `compose.yml` cleanup, `tox.ini` was brought current with
real-world adapter releases (PyPI snapshot taken 2026-05-11):

| Adapter | Latest published | New version-pinned env(s) added |
|---|---|---|
| dbt-snowflake | 1.11.4 | `_1_10_0`, `_1_11_0` |
| dbt-bigquery | 1.11.1 | `_1_10_0`, `_1_11_0` |
| dbt-databricks | 1.11.8 | `_1_10_0`, `_1_11_0` |
| dbt-postgres | 1.10.0 | `_1_10_0` (no upstream 1.11 yet) |
| dbt-trino | 1.10.1 | `_1_10_0` (no upstream 1.11 yet) |
| dbt-sqlserver | 1.9.0 | `_1_9_0` (was missing); no 1.10/1.11 upstream |

Other changes:

- **Unversioned `integration_<warehouse>` envs** had their adapter upper
  bound tightened from `<3.0.0` to `<2.0.0`. Honest pin given there is no
  `dbt-*` 2.x line today; if/when one ships it will need deliberate review.
- **sqlfluff** moved from `~=3.0.0` (only 3.0.x) to `~=3.0` (all 3.x).
  Resolves to **3.5.0** today. A future bump to **4.x** is deferred —
  major version bumps surface new rule violations and deserve their own
  focused change.
- **`dbt-snowflake` companion of the sqlfluff env** moved to `~=1.11.0` to
  match what the active lint workflow installs.
- **dbt Fusion stub.** Fusion (the Rust reimplementation) is not on PyPI
  and cannot be installed by `pip` / `uv`. A commented placeholder section
  was added at the bottom of `tox.ini` showing the intended naming
  convention (`integration_fusion_<warehouse>`), so when Fusion becomes
  installable we wire it without re-debating the layout.

Old-version envs (`_1_3_0` through `_1_8_0`) were **not** removed. Whether
to drop EOL versions is a separate consumer-impact decision tracked in §13.

## 8. Host port decision (delivered in Step 1)

Local `compose.yml` binds to **non-standard host ports** so the test stack
never collides with whatever a developer is already running:

| Warehouse | Host port | Container port |
|---|---|---|
| postgres  | `55432` | `5432`  |
| trino     | `58080` | `8080`  |
| sqlserver | `51433` | `1433`  |

`integration_test_project/profiles.yml` hardcodes the shifted host ports for
the postgres/sqlserver/trino targets. CI runners get the same ports, since
they read the same compose file and same profiles.yml — no special-casing.

**Why not stock ports + env-var override?** Considered. Rejected because:

- Stock ports collide with `brew services` Postgres, locally-running web
  apps on `:8080`, etc. — friction every time a dev runs tests.
- Env-var indirection adds a thing to remember and a thing to forget. The
  failure mode (silent connection to the wrong DB) is worse than the
  failure mode of non-standard ports (everyone uses them, including CI).
- Connecting to `localhost:5432` with `psql` now hits the **developer's**
  Postgres, not the test container. That's actually safer.

If a future contributor's environment happens to already use `:55432` or
`:58080`, we'll revisit — but those are uncommon enough that it isn't worth
the indirection up front.

## 9. Workflow files

End state of `.github/workflows/`:

| File | Purpose | Tier | Status |
|---|---|---|---|
| `pr.yml` | `pull_request` → `main`. Local DWH matrix (no lint, see below). | 1 | ✅ delivered |
| `main.yml` | `push` → `main` + `workflow_dispatch`. Lint + local DWH matrix + Snowflake + BigQuery on latest dbt. | 1 + 2 | ✅ delivered |
| `release.yml` | `push` → `release-candidate/**` and `workflow_dispatch`. Full matrix. | 1 + 2 + 3 | ✅ delivered |
| `publish_docs_on_release.yml` | Existing. Triggered on release tag. | 4 | unchanged |

The six currently-commented-out workflow files are deleted as the final step.

### Tier 1 lint deferral

`pr.yml` deliberately does **not** run lint. The package's models call
adapter methods (`run_query`-style) at dbt compile time, so the sqlfluff
dbt-templater needs a real Snowflake connection to render templates. Since
Tier 1 has no secrets by design, lint cannot run there until the
introspection-at-compile-time issue is fixed (tracked in §13). Until then
lint lives in Tier 2 (which has secrets via merge gating). This is an
acknowledged trade-off documented in `scripts/ci/README.md` and
`.github/workflows/pr.yml`.

### Shared hardening applied to every workflow

- `permissions:` block defaulting to `read-all`, with explicit opt-in for jobs
  that need `id-token: write` (BigQuery WIF).
- Third-party actions pinned to commit SHAs, not tags. **Status:** SHA-pinned
  across `pr.yml` and `main.yml` as of Step 3. `release.yml` will follow the
  same pattern when delivered.
- `concurrency:` group keyed by workflow + PR number / ref so re-pushes
  cancel prior runs.
- `timeout-minutes` set per job to bound runaway costs.
- `fail-fast: false` on the matrix so one warehouse failure doesn't mask
  others.

---

## 10. CODEOWNERS

A new `.github/CODEOWNERS` file requires maintainer review on changes to:

- `.github/**`
- `scripts/ci/**`
- `compose.yml`, `init-scripts/**`
- `tox.ini`, `pyproject.toml`, `uv.lock`
- `dbt_project.yml`, `packages.yml`, `package-lock.yml`

This is defense-in-depth: the `pull_request` event removes the **direct**
exfiltration path, and CODEOWNERS ensures changes to sensitive plumbing get a
maintainer's eyes before merging exposes them to Tier 2/3 secrets.

---

## 11. Implementation order

Each step is independently mergeable and verifiable. Steps 1–2 do not touch
secrets and can be merged conservatively. Steps 3+ are where the new
trust-bearing CI lights up.

1. ✅ **`scripts/ci/` + `compose.yml` cleanup.** Delivered and live-verified.
   Files: `scripts/ci/{_lib,setup,compose-up,compose-down,lint,test,test-all-local}.sh`,
   `scripts/ci/README.md`, refactored `compose.yml`, updated
   `integration_test_project/profiles.yml` (shifted ports), bumped
   `tox.ini` lint deps to match the active workflow's known-working pair
   (`sqlfluff-templater-dbt~=3.0.0` + `dbt-snowflake~=1.9.0`). See §7 and §8
   for what changed.

   **Live verification results:**
   - `./scripts/ci/setup.sh` — OK
   - `./scripts/ci/test.sh postgres` — PASS=49 ERROR=0, compose teardown clean
   - `./scripts/ci/test.sh sqlserver` — PASS=49 ERROR=0, sidecar bootstrap clean
   - `./scripts/ci/test.sh trino` — initially FAILed on the `microbatch`
     model (`TrinoUserError: This connector does not support modifying
     table rows`); fixed by gating that model with
     `enabled = target.type != 'trino'` in
     `integration_test_project/models/microbatch.sql`. After the fix:
     PASS=48 ERROR=0. The Trino `memory` connector doesn't support MERGE,
     which the microbatch incremental strategy requires.
   - `./scripts/ci/lint.sh` — FAIL without real Snowflake credentials;
     PASSes when they are set. The active `main_lint_package.yml` workflow
     has the same requirement. Documented in `scripts/ci/README.md`.
2. ✅ **Tier 1 workflow** (`.github/workflows/pr.yml`). Delivered.
   `pull_request` → `main`, matrix over `postgres`/`trino`/`sqlserver`,
   each slot delegates to `scripts/ci/test.sh <warehouse>`. No secrets,
   `permissions: read-all`, `concurrency` cancels superseded runs.
   Validated via `act --list` and `act -n` (auth error on action-fetch is
   an `act`-only quirk; workflow structure parses cleanly). Real signal
   comes when this lands on `main` and a PR fires it.
3. ✅ **Tier 2 workflow** (`.github/workflows/main.yml`). Delivered.
   `push` → `main` and `workflow_dispatch`. Four jobs:
   `lint`, `integration-local` (postgres/trino/sqlserver matrix),
   `integration-snowflake`, `integration-bigquery`. Secret minimization
   verified — `integration-local` declares no secret env vars; Snowflake
   creds scoped to the two jobs that need them; `id-token: write` lives
   only on the BigQuery job. All actions SHA-pinned (and `pr.yml`
   back-ported to SHA pins in the same change):
   - `actions/checkout` → `34e114876b0b11c390a56381ad16ebd13914f8d5` (v4)
   - `astral-sh/setup-uv` → `caf0cab7a618c569241d31dcd442f54681755d39` (v3)
   - `google-github-actions/auth` → `c200f3691d83b41bf9bbd8638997a462592937ed` (v2)
   GCP Workload Identity Federation preserved from the pre-rework
   workflow — no static service account keys. WIF still has to be
   verified live; that happens when this lands on `main` and the next
   push fires it.
4. ✅ **Tier 3 workflow** (`.github/workflows/release.yml`) + Databricks
   stub + `.github/CODEOWNERS` + `.github/dependabot.yml`. Delivered.
   - `release.yml`: fires on `push` → `release-candidate/**` and
     `workflow_dispatch`. Three jobs: `lint`, `version-matrix`
     (42 entries — 5 unversioned "latest" + 37 pinned versions across 5
     warehouses), and `integration-databricks-stub` (visible-but-skipped).
     `max-parallel: 8` throttles the matrix to ~30–40 minute total
     runtime. Same SHA-pins as `pr.yml` / `main.yml`. `id-token: write`
     scoped to the matrix job only (for conditional WIF on bigquery
     slots).
   - `CODEOWNERS`: requires maintainer review on `.github/**`,
     `scripts/ci/**`, `compose.yml`, `init-scripts/**`, `tox.ini`,
     `pyproject.toml`, `uv.lock`, `dbt_project.yml`, `packages.yml`,
     `package-lock.yml`, and `specs/`. **Action required**: replace the
     placeholder `@brooklyn-data/dbt-artifacts-maintainers` handle with
     the real team slug before this lands.
   - `dependabot.yml`: weekly grouped action-update PRs. Closes the
     maintainability gap that SHA-pinning otherwise creates. Python deps
     intentionally NOT auto-bumped — dbt / adapter versions are test
     surface area and need deliberate `tox.ini` changes.
5. ✅ **Delete superseded files.** Delivered. Ten files removed:
   - **Five commented-out workflows**: `ci_test_package.yml`,
     `main_test_package.yml`, `main_test_latest_version.yml`,
     `main_test_supported_versions.yml`, `main_lint_package.yml`.
   - **Two ACTIVE `pull_request_target` workflows** —
     `ci_test_latest_version_on_feature_branch.yml` and
     `ci_test_supported_versions_on_feature_branch.yml`. **These were
     live, not commented out.** They fired on every PR with full
     Snowflake / GCP / Databricks secrets in the environment. They are
     the precise vulnerability that motivated this rework, and we
     operated for several steps believing they had already been
     disabled. **Their removal in this step is the actual closing of
     the disclosed vulnerability**, not just a tidying pass.
   - **Three superseded support files**:
     `integration_test_project/docker-compose.yml.bak` (older copy of
     compose.yml), `integration_test_project/run_tests.sh` (replaced by
     `scripts/ci/test-all-local.sh`), `init-scripts/progress.sh` (the
     15-second sleep loop replaced by container healthchecks).

   Post-cleanup `.github/workflows/` contains exactly four files:
   `pr.yml`, `main.yml`, `release.yml`, `publish_docs_on_release.yml`.
   `compose config -q` still validates.
6. ✅ **Contributor docs refreshed.** Delivered:
   - **New** `docs/dev-workflow.md` — end-to-end walkthrough of feature
     branch → PR → merge → release-candidate → tag, with a workflow ↔
     tier table and a hotfix section.
   - **Rewrote** `CONTRIBUTING.md` — replaced `pipx`/`tox`-direct with
     `uv` + `scripts/ci/`; added "What CI will and won't do on your PR"
     section so fork contributors understand the Tier 1 scope; updated
     the "add a new adapter" checklist with the three workflow files.
   - **Updated** `README.md` — replaced the two badges pointing at
     deleted workflows (`main_test_package.yml`, `main_lint_package.yml`)
     with `main.yml` and `release.yml` badges; expanded Contributing
     section to point at `dev-workflow.md` and `MAINTAINERS.md`.
   - **Updated** `docs/MAINTAINERS.md` — removed the dead "Approve
     Integration Tests" deployment-environment section; rewrote
     "How to release" to use the `release-candidate/X.Y.Z` flow;
     replaced the standalone `docker run` Postgres/Dremio snippets
     with the `compose.yml`-based local-DWH path; cleaned up the
     `pyenv virtualenv` section now that `tox` handles per-version
     isolation automatically.
   - **Updated** `CLAUDE.md` — new "CI model" orientation section at
     the top so future Claude sessions know the tier model and the
     `pull_request_target` prohibition; rewrote test-running commands
     to point at `scripts/ci/`; fixed the dead `main_test_package.yml`
     reference in "When adding support for a new adapter"; refreshed
     the Releasing section to point at `docs/dev-workflow.md`.
7. ✅ **Release-candidate cutter** (`scripts/release/cut-candidate.py` +
   `.github/workflows/cut-release-candidate.yml`). Delivered. Auto-bumps
   version in `dbt_project.yml` and the `README.md` Quickstart example,
   creates `release-candidate/X.Y.Z`, commits, and pushes — which then
   fires Tier 3. **Auto-bump, not auto-merge**: the maintainer still
   drives the tag and any merge-back to `main` manually. Available
   both via `workflow_dispatch` and locally as `./scripts/release/cut-candidate.py
   --patch | --minor | --major | --version X.Y.Z`. Safety guards: must
   be on `main`, working tree must be clean, target branch must not
   already exist locally or on origin.
8. ✅ **Weekly regression on `main`** (added to `release.yml`).
   Delivered. `schedule: '0 6 * * 1'` (Mondays 06:00 UTC) runs the full
   Tier 3 matrix against `main`. Scheduled runs execute on the default
   branch, so this validates the current state of `main` regardless of
   any in-flight release branches. Catches drift from upstream dbt
   adapter releases between scheduled releases.

---

## 12. Tech debt — to close after the framework is complete

Items we have identified during Steps 1–2 that we will work through **once
Steps 3–6 are merged and the framework itself is operational**. Each item is
a discrete piece of follow-up work, not part of the core CI rework.

### 12.1. Documentation debt

- **`CONTRIBUTORS.md`** (new file). The repo currently has no contributor
  guide. With the new CI model — and the fact that fork PRs now get a
  meaningfully different signal than internal PRs — we need to explain:
  - How to set up `uv`, Docker, ODBC driver
  - How to run `scripts/ci/test.sh <warehouse>` locally
  - What CI does and does not do on a fork PR (no lint, no cloud DWH —
    that's expected, not a bug)
  - What the maintainer flow looks like (review → merge → Tier 2 runs)
  - How to bump `tox.ini` when a new dbt version drops
  - Code style: SQLFluff rules in `tox.ini`, line-leading commas, etc.
- **Documented end-to-end dev workflow on GitHub.** A short doc
  (`docs/dev-workflow.md` or section of `CONTRIBUTORS.md`) that walks
  through `feature branch → PR → review → merge → release-candidate →
  tag` with screenshots of what passes/fails at each stage and which
  workflows fire. Should make the trust-boundary visible to a new
  maintainer joining the project.
- **`CLAUDE.md` + `README.md` updates** (Step 6) — describe the new CI
  flow in the existing places contributors already look.

### 12.2. Lint and model debt

- ~~**`{% if execute %}` guards on introspecting models.**~~ **Resolved
  as a no-op after survey.** The original hypothesis was that some
  package models call `run_query` / adapter methods at compile time,
  forcing the dbt templater to connect to Snowflake just to lint. A
  full grep across `models/` and `macros/` found that every DB-touching
  macro (`get_relation`, `insert_into_metadata_table` via
  `upload_results`, `safe_cast`) is **already guarded** by `{% if
  execute %}`. The actual cause of "lint needs Snowflake creds" is at
  the dbt-snowflake **adapter init** layer — the adapter establishes
  a session before any model compiles. Fixing this would require
  switching the lint target to Postgres (or another lightweight
  adapter), not changing any models. **Decision: keep lint in Tier 2.**
  Rationale: "loose at Tier 1, strict at Tier 2" is a defensible
  standalone position — fork contributors get fast structural signal;
  lint provides format control without wrangling external
  contributors. No further action needed.
#### 12.2.1. Bump sqlfluff to 4.x — **planned, not yet executed**

**Status:** Migration plan documented. Execution deferred — bundle with
the next major release (3.0.0, alongside the §12.3.1 EOL drop) so all
maintainer-facing breakage lands in one coordinated release. Update
this section when execution begins.

##### Current state

- `tox.ini` `[sqlfluff]` deps: `sqlfluff-templater-dbt~=3.0`
  (resolves to 3.5.0 today)
- `dbt-snowflake~=1.11.0` paired with it (matches what the active
  lint runs against)

##### What changes in 4.x (per sqlfluff 4.0.0 release notes)

1. **Rust-based parser/lexer as an opt-in extra** (`sqlfluff[rs]`).
   The Python parser remains the default. 5.0 will flip the default
   to Rust. We can adopt later — not part of the 4.x migration scope.
2. **Drops dbt 1.4 and older.** We're on dbt 1.10/1.11 — no impact.
3. **Adds dbt 1.10 templater support.** Aligns with our active dbt
   matrix.
4. **Bug fixes for CV12 (`structure.distinct`) and RF01
   (`references.from`).** This is the risk: previously-passing models
   may now flag.
5. **New "force implicit indents" capability.** Opt-in; safe to
   ignore.

##### Risks

- **New rule violations on existing models.** CV12 / RF01 fixes may
  surface lint failures we didn't see before. Estimated handful of
  models max; we'll know after running once.
- **Templater compatibility.** `sqlfluff-templater-dbt` 4.x requires
  dbt-core 1.5+. We're already past this floor.
- **CI lint failures during the bump.** Maintainer-only impact — Tier
  1 PRs are unaffected because lint lives in Tier 2 (see §9 "Tier 1
  lint deferral").

##### Migration steps (when ready)

1. **Cut a focused branch** off the `release-candidate/3.0.0` work
   (or its own `release-candidate/3.0.0` is fine — the bump is
   maintainer-visible only, not consumer-breaking).
2. **Bump the deps in `tox.ini`:**
   ```ini
   [sqlfluff]
   deps =
       sqlfluff-templater-dbt~=4.0
       dbt-snowflake~=1.11.0
   ```
3. **Run lint locally** with real Snowflake creds set (per §12.2's
   "lint requires Snowflake creds" constraint):
   ```bash
   . ./env.sh
   ./scripts/ci/lint.sh
   ```
4. **Triage any new violations:**
   - **Fix-able** (a real style issue): run `./scripts/ci/lint.sh
     --fix` to auto-resolve.
   - **False positive on this codebase**: add the specific rule code
     to the `rules` exclusion list at the top of `tox.ini` with a
     comment explaining why, OR add a `noqa` comment on the offending
     line in the model.
   - **Bug in 4.x itself**: open an upstream issue on sqlfluff;
     temporarily exclude the rule; revisit when fixed.
5. **Re-run lint until clean.**
6. **Verify integration tests still pass** — sqlfluff doesn't affect
   runtime SQL, but a sanity check on `./scripts/ci/test.sh postgres`
   confirms the upgrade hasn't broken `uv sync` resolution.
7. **Commit and push the release-candidate branch.** Tier 3 fires;
   confirm the lint job is green.
8. **Update this spec section** marking 12.2.1 ✅ delivered and note
   any rules that needed to be excluded (so future maintainers know
   why).

##### Files that change

- `tox.ini` — `[sqlfluff] deps` block, line ~7-9.
- Possibly individual model `.sql` files if violations need fixing.
- Possibly `tox.ini`'s `rules = ...` line (lines ~37) if rules need
  excluding.

##### Rollback

If 4.x proves too disruptive, revert the `tox.ini` deps change:

```ini
[sqlfluff]
deps =
    sqlfluff-templater-dbt~=3.0
    dbt-snowflake~=1.11.0
```

No data migration, no consumer impact — the rollback is trivial.

##### Why coordinate with 3.0.0?

sqlfluff is a CI-only tool; this bump doesn't affect consumers of the
package. But it **does** affect maintainer workflow if new violations
surface. Coordinating the bump with the 3.0.0 EOL release means all
the "this is the release where maintainer workflow changed" friction
lands once, not twice. If sqlfluff 4.x surfaces zero new violations
in practice, the coordination is harmless — bump it in 2.11.0
instead.

#### 12.2.2. Other lint / model debt

(Originally tracked the `{% if execute %}` guards item — resolved
as a no-op after survey. See 12.2 introduction.)

### 12.3. Test matrix debt

#### 12.3.1. Drop EOL dbt versions — **planned, not yet executed**

**Status:** Decision made (Option B below). Execution deferred to a
separate branch + PR after a broad announcement. The next major
release of `dbt_artifacts` (3.0.0) will land the removal. Update this
section when execution begins.

**Decision: drop dbt 1.3, 1.4, 1.5, 1.6 from the test matrix.** Keep
1.7, 1.8, 1.9, 1.10, 1.11 (where adapter releases exist).

##### The data

dbt-core release dates from PyPI, cross-referenced against dbt-labs'
published ~12-month active-support window. Pulled 2026-05-12.

| Minor | Released | Age (months) | Upstream status |
|---|---|---|---|
| 1.11 | 2025-12-19 | 4.7 | **supported** |
| 1.10 | 2025-06-16 | 10.8 | **supported** |
| 1.9 | 2024-12-09 | 17.0 | EOL |
| 1.8 | 2024-05-09 | 24.1 | EOL |
| 1.7 | 2023-11-02 | 30.3 | EOL |
| 1.6 | 2023-07-31 | 33.4 | EOL |
| 1.5 | 2023-04-27 | 36.5 | EOL |
| 1.4 | 2023-01-25 | 39.5 | EOL |
| 1.3 | 2022-10-12 | 43.0 | EOL |

> **Caveat on the data:** This is *upstream EOL* (what dbt-labs no
> longer supports). It is **not** direct consumer-usage data. That
> data lives in PyPI BigQuery dumps and dbt Hub usage figures we don't
> have easy access to. The recommendation is based on upstream policy
> + the prior maintainer judgment encoded in `tox.ini`'s existing
> "End of Life" comments on the 1.3-1.6 envs.

##### Options considered

| Option | Versions kept | Matrix size | Stance |
|---|---|---|---|
| A — strict | 1.10, 1.11 only | 42 → 12 (-71%) | Match dbt-labs' active-support window exactly |
| **B — chosen** | **1.7-1.11** | **42 → 22 (-48%)** | **Drop what `tox.ini` already labels EOL** |
| C — conservative | 1.6-1.11 | 42 → 27 (-36%) | Keep one extra year of legacy |

##### Per-warehouse impact

| Warehouse | Before | After | Removed |
|---|---|---|---|
| Snowflake | 1.3-1.11 (9) | 1.7, 1.8, 1.9, 1.10, 1.11 (5) | 4 envs |
| BigQuery | 1.3-1.11 (9) | 1.7, 1.8, 1.9, 1.10, 1.11 (5) | 4 envs |
| Postgres | 1.3-1.10 (8) | 1.7, 1.8, 1.9, 1.10 (4) | 4 envs |
| Trino | 1.3-1.7, 1.10 (6) | 1.7, 1.10 (2) | 4 envs |
| SQL Server | 1.3, 1.4, 1.7-1.9 (5) | 1.7, 1.8, 1.9 (3) | 2 envs |
| Databricks | stub | stub | 0 (stub stays) |
| **Total pinned** | **37** | **19** | **18 envs removed** |

Plus 5 unversioned "latest" entries remain in both states.

##### Rationale (for the announcement)

1. **Upstream is unsupported.** dbt-core 1.3-1.6 stopped receiving
   active maintenance from dbt-labs 33-43 months ago. Anyone still
   pinned to those versions is already running an unsupported dbt
   regardless of which packages they use.
2. **Prior maintainer intent.** `tox.ini` comments have flagged
   1.3-1.6 as "End of Life" envs slated for removal — we're acting on
   that long-standing plan.
3. **CI cost.** Tier 3 (full version matrix) currently runs ~42
   warehouse × dbt-version slots. Dropping 1.3-1.6 cuts it to ~24,
   shrinking Tier 3 (and the weekly regression that uses the same
   matrix) runtime by roughly half.
4. **Not a hard break.** The package code may still work on 1.3-1.6
   even after CI stops testing it. "Deprecated" here means *no longer
   tested*, not *intentionally broken*. Consumers on those versions
   can keep using older `dbt_artifacts` releases (pre-3.0.0).

##### Two-phase execution plan

| Phase | When | What happens | Where |
|---|---|---|---|
| 1. Announcement | In 2.11.0 (next minor) | Public deprecation notice — no code change, just docs. README, CHANGELOG, release notes. `tox.ini`'s existing "echo Warnings:" messages continue to fire. | `dbt-artifacts/dbt-artifacts` repo, dbt Hub, any community channels |
| 2. Removal | In 3.0.0 (next major) | Delete the EOL envs from `tox.ini`, drop the matrix entries from `release.yml`, bump `require-dbt-version` in `dbt_project.yml` to `>=1.7.0`. | Done in a focused branch like `release-candidate/3.0.0` |

Removing the envs is a **major-version bump** because consumers pinned
to dbt 1.3-1.6 will lose the ability to install new releases of
`dbt_artifacts`. Per semver, that's a breaking change.

##### Files that change in Phase 2 (the actual removal)

- `tox.ini` — delete `[testenv:integration_<warehouse>_1_3_0]` through
  `_1_6_0` blocks (~50 lines per warehouse, ~30 deletions total).
- `.github/workflows/release.yml` — delete the corresponding entries
  from the `version-matrix` job's `matrix.include` block (18 entries).
- `dbt_project.yml` — bump `require-dbt-version: [">=1.3.0", "<3.0.0"]`
  to `require-dbt-version: [">=1.7.0", "<3.0.0"]`.
- `README.md` — note the new minimum dbt version in the Quickstart
  section.
- `dbt_project.yml` — bump package version to `3.0.0`.

##### Draft announcement text

Adapt to taste; usable as-is for a GitHub Discussion, release notes,
or dbt Slack #package-ecosystem channel.

> **Heads up: `dbt_artifacts` 3.0.0 will drop support for dbt 1.3-1.6**
>
> The next major release of `dbt_artifacts` (3.0.0, target month: TBD)
> will remove CI coverage and support for dbt-core 1.3, 1.4, 1.5, and
> 1.6. The minimum supported dbt version becomes **1.7.0**.
>
> **Why now**
>
> dbt-labs ended active support for these versions between 33 and 43
> months ago. If you're still pinned to one of them, you're running
> upstream-unsupported dbt — `dbt_artifacts` testing against those
> versions doesn't change that. Removing them lets us focus CI cost
> on versions that are actively maintained.
>
> **What to do**
>
> - On dbt **1.7 or newer**: nothing. Continue using `dbt_artifacts`
>   normally; 3.0.0 will be a drop-in upgrade for you.
> - On dbt **1.3-1.6**: upgrade your dbt-core version first (see
>   https://docs.getdbt.com/docs/dbt-versions/upgrade-dbt-version-in-cloud).
>   If you cannot upgrade, pin `dbt_artifacts` to the last 2.x release
>   in your `packages.yml`:
>   ```yaml
>   packages:
>     - package: brooklyn-data/dbt_artifacts
>       version: ">=2.10.0,<3.0.0"
>   ```
>
> **Timeline**
>
> - 2.11.0 (this release): announcement only. No code change.
>   Existing deprecation warnings (already emitted at test time)
>   continue.
> - 3.0.0 (target: TBD): the CI envs and adapter matrix entries are
>   removed.
>
> Questions or concerns: open an issue or comment on this discussion.
> If a significant number of consumers are still on these versions,
> we'll revisit.

#### 12.3.2. Other test matrix items

- **Databricks reactivation.** Stubbed in `tox.ini` and Tier 3 as
  skipped-by-design. Needs its own design pass to wire up safely.
- **dbt Fusion.** Placeholder section in `tox.ini`. Wire up when
  Fusion becomes pip-installable (it isn't today).

### 12.4. Cleanup debt

- ✅ ~~**Remove `go-task-bin` from `pyproject.toml`**~~ Done.
  Survey surfaced a more significant scope: `Taskfile.yml` (~130
  lines, parallel orchestrator to `scripts/ci/`, already broken by
  Step 1 file deletions/renames) was using `go-task-bin`. Deleted
  the Taskfile and the dep. **Bonus finding during this work:**
  `pyproject.toml` and `uv.lock` were both in `.gitignore`, meaning
  the new CI system's `uv sync` step would have failed on any fresh
  checkout (including every CI runner). Removed the gitignore
  entries and made both files tracked so fresh clones reproduce the
  exact dep tree. **This unblocked a latent P0 issue** that would
  have surfaced the first time CI ran on a clean runner.
- ✅ ~~**Delete `integration_test_project/run_tests.sh` and
  `integration_test_project/docker-compose.yml.bak`**~~ Done in Step 5.
- ✅ ~~**Delete `init-scripts/progress.sh`**~~ Done in Step 5.
- **Fix the `pyarrow[pandas]<19.0.0` dep spec.** `uv sync` warns:
  `pyarrow==18.1.0 does not have an extra named pandas`. Pre-existing
  in `pyproject.toml`; surfaced once the file became tracked. Either
  drop the `[pandas]` extra (if just pyarrow is needed) or split into
  `pyarrow<19.0.0` and `pandas` as separate deps. ~5 min fix.

### 12.5. Hardening debt — operational

- **Pre-commit hooks for SQLFluff.** Catches lint issues before they
  reach CI. Optional, contributor convenience. Constraint inherited
  from §12.2: lint requires the dbt-snowflake adapter init, which
  requires Snowflake creds. So pre-commit hooks would be
  internal-contributor-only (or use `--templater=jinja` for a
  coarser, offline lint path). Decide at implementation time.
- **Cost of Tier 2 on every push to `main`.** Today: 2 cloud DWH jobs
  per merge. If this becomes expensive, options: throttle to one-per-day,
  batch via `workflow_dispatch`, or move Snowflake/BigQuery to Tier 3
  only. Revisit after we have 1–2 months of real billing data.
- ✅ ~~**Weekly Tier 3 against `main`.**~~ Delivered in Step 7
  (scheduled `release.yml` trigger). Mondays 06:00 UTC. Drop or
  throttle if cost becomes a concern.
- ✅ ~~**Auto-bump version + create `release-candidate/X.Y.Z` branch.**~~
  Delivered in Step 7 (`scripts/release/cut-candidate.py` +
  `.github/workflows/cut-release-candidate.yml`). Auto-bump, not
  auto-merge — the maintainer still drives the tag.

---

## 13. Maybe-someday — not actively planned

Things we've considered and consciously parked. Listed for posterity so
future maintainers can see the decision space.

- **BigQuery emulator** (`ghcr.io/goccy/bigquery-emulator`). Would let
  BigQuery move to Tier 1. Unreliable for this package's surface area
  today; revisit if it matures.
- **Replace tox with native `uv run` + pytest-style invocation.** Would
  simplify the script layer further; punted because tox already works
  and the script-first design hides this from contributors anyway.
