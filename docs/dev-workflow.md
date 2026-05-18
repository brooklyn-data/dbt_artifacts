# Development workflow: feature → release

This doc walks through every stage of getting a change from a feature
branch to a tagged release on GitHub, including which CI workflow fires at
each step and why. It is the operational counterpart to the high-level
design in [`specs/ci-rework/README.md`](../specs/ci-rework/README.md).

If you are new to the project, read [CONTRIBUTING.md](../CONTRIBUTING.md)
first.

## At a glance

```
  feature/* ─────PR─────► main ────push─────► release-candidate/X.Y.Z ──tag──► X.Y.Z
                  │                  │                       │                 │
                  ▼                  ▼                       ▼                 ▼
              Tier 1 CI         Tier 2 CI                Tier 3 CI         publish_docs
            (pr.yml)            (main.yml)             (release.yml)     (existing)
           no secrets        secrets, Snowflake +      secrets, full      release tag
           lint disabled¹    BigQuery, latest dbt      version matrix      triggers
                                                                          docs site
```

¹ Lint is currently in Tier 2 only because the package's models call
adapter methods at compile time and need a real Snowflake connection.
Tracked for fix in [specs §12.2](../specs/ci-rework/README.md).

---

## Stage 1 — Feature branch + PR

### As a fork contributor (external)

1. Fork the repo, clone your fork, create a branch.
2. Make your changes. Use `./scripts/ci/test.sh <warehouse>` to test
   locally against any warehouse you have access to. Postgres / Trino /
   SQL Server run in Docker containers — no warehouse credentials
   needed for these.
3. Open a PR against `brooklyn-data/dbt_artifacts:main`.

**What you'll see on your PR:**

- **Tier 1 CI runs** ([`pr.yml`](../.github/workflows/pr.yml)). One job
  per local-runnable warehouse (Postgres, Trino, SQL Server). Each
  spins up a container, runs the integration tests, tears down.
- **No lint, no Snowflake / BigQuery / Databricks signal on your PR.**
  This is deliberate — those require secrets, which forks cannot
  access by design. A maintainer will run the higher-tier checks for
  you after they merge (Stage 2).
- The matrix is configured with `fail-fast: false`, so a break in one
  warehouse does not hide results from the others.

If Tier 1 passes, a maintainer will review. If it fails, fix it locally
(`./scripts/ci/test.sh <warehouse>`) and push again — the same CI fires
on every push.

### As an internal contributor

Same flow as a fork. Internal contributors **also** PR against `main`
— there is no shortcut, no privileged branch. The PR-level CI is
identical to what a fork sees. The only difference is internal
contributors typically have their own warehouse credentials and can
run all warehouses locally before opening the PR.

---

## Stage 2 — Merge to `main`

After review and approval, the maintainer merges the PR. This is the
trust boundary — **only code merged through a reviewed PR ever sees
repository secrets.**

**What fires on push to `main`** ([`main.yml`](../.github/workflows/main.yml)):

| Job | What it does | Secrets used |
|---|---|---|
| `lint` | sqlfluff against `models/` | Snowflake (templater needs a real connection) |
| `integration-local` (matrix) | Re-runs Postgres / Trino / SQL Server against merged code | None |
| `integration-snowflake` | Latest `dbt-snowflake` against the test Snowflake account | Snowflake |
| `integration-bigquery` | Latest `dbt-bigquery` via Workload Identity Federation | GCP (WIF — keyless) |

If Tier 2 fails after a merge, the maintainer either:

- Reverts the merge commit on `main`, or
- Pushes a follow-up fix (which itself goes through a PR and Tier 1
  again, then Tier 2 reruns on push).

This is also where Snowflake / BigQuery regressions get caught for
changes contributed by forks who couldn't run those tests themselves.

---

## Stage 3 — Cut a `release-candidate` branch

When you have a set of merged changes ready to ship (~monthly cadence),
cut the release candidate. **Recommended path**: use the cutter, which
auto-bumps the version in `dbt_project.yml` and `README.md`, creates
the branch, commits, and pushes — one step:

**Via GitHub UI** (`workflow_dispatch`):

1. Actions tab → "Cut release-candidate" workflow → "Run workflow"
2. Pick `patch`, `minor`, or `major` (or paste an explicit `X.Y.Z`)
3. Click "Run"

**Or locally** (same script — single source of truth):

```bash
git checkout main && git pull
./scripts/release/cut-candidate.py --minor      # or --patch / --major / --version X.Y.Z
```

This automation is **bump, not merge**: the maintainer still reviews
Tier 3 results and drives the tag manually (Stage 4).

**What fires** ([`release.yml`](../.github/workflows/release.yml)):

| Job | What it does |
|---|---|
| `lint` | Same as Tier 2 |
| `version-matrix` | 42 entries: every supported (warehouse, dbt_version) pair, plus an unversioned "latest" per warehouse. `max-parallel: 8`. |
| `integration-databricks-stub` | Visible-but-skipped placeholder until Databricks is reactivated (see [specs §12.3](../specs/ci-rework/README.md)). |

This typically takes 30–40 minutes. Watch the Actions tab. If anything
goes red, you have two choices:

1. **Fix forward on the release-candidate branch.** Push commits
   directly to `release-candidate/X.Y.Z` — Tier 3 reruns. Use this
   when the fix is small and clearly part of the release scope.
2. **Fix via a PR to `main`, then re-cut.** Delete the
   release-candidate branch, fix on a new feature branch through the
   normal PR flow, then re-create the release-candidate branch from
   the updated `main`. Use this when the fix is substantive enough
   to deserve PR review.

---

## Stage 4 — Tag and release

Once `release.yml` is green on the candidate branch:

1. Open a PR from `release-candidate/X.Y.Z` to `main` (if there were
   commits made directly to the candidate branch). Otherwise skip —
   the candidate branch already matches `main` at the head it was
   created from.
2. Merge the PR (or confirm the branches are in sync).
3. Create a [GitHub Release](https://github.com/brooklyn-data/dbt_artifacts/releases/new):
   - **Tag**: `X.Y.Z`
   - **Target**: `main` (the merge commit if you opened a PR, or the
     candidate branch head if it matches)
   - Title and notes summarizing the changes
4. Publish.

**What fires**: [`publish_docs_on_release.yml`](../.github/workflows/publish_docs_on_release.yml)
rebuilds the docs site. dbt Hub picks up the new release within an hour
via [dbt-labs/hubcap](https://github.com/dbt-labs/hubcap).

5. **Delete the `release-candidate/X.Y.Z` branch.** It's served its
   purpose. Keep it around only if you anticipate a same-day hotfix
   targeting the same minor.

---

## Hotfix flow

For a critical bug on a released version:

```
       hotfix/critical-bug ───PR───► main ───push───► release-candidate/X.Y.Z+1
              │                      │                          │
              ▼                      ▼                          ▼
          Tier 1 CI              Tier 2 CI                  Tier 3 CI
                                                            then tag
```

Hotfixes are not a separate code path — they're feature branches with a
narrow scope. Same PR → main → release-candidate → tag flow as Stage 1–4.
The only difference is urgency: maintainers may compress the timeline
(e.g., merge same-day rather than holding for a batch).

If a hotfix targets an older minor (you cannot fix-forward to the
latest), branch from the tag of that minor instead of `main`, then PR
into a `release-candidate/X.Y.Z+1` branch directly. This is rare and
not currently automated — talk to maintainers before attempting.

---

## Workflow file → tier mapping

| File | Tier | When it runs | Secrets |
|---|---|---|---|
| [`pr.yml`](../.github/workflows/pr.yml) | 1 | `pull_request` → `main` | **None** |
| [`main.yml`](../.github/workflows/main.yml) | 2 | `push` → `main`, manual | Snowflake, GCP WIF |
| [`release.yml`](../.github/workflows/release.yml) | 3 | `push` → `release-candidate/**`, manual, **Mondays 06:00 UTC** (weekly regression on `main`) | Snowflake, GCP WIF |
| [`cut-release-candidate.yml`](../.github/workflows/cut-release-candidate.yml) | — | `workflow_dispatch` only — auto-bumps and pushes a `release-candidate/X.Y.Z` branch | `contents: write` (push only) |
| `publish_docs_on_release.yml` | 4 | Release tag created | (none — docs only) |

### Weekly regression detail

Every Monday at 06:00 UTC the full Tier 3 matrix runs against the
current head of `main`. This catches drift from upstream dbt adapter
releases that land between our scheduled releases — e.g., a new
`dbt-snowflake` minor that breaks our package. If the weekly run
fails, treat it like any other Tier 2/3 failure: investigate, fix
forward via a PR, or pin the offending adapter version.

---

## See also

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — how to set up your local
  environment and submit a first PR
- [`docs/MAINTAINERS.md`](MAINTAINERS.md) — maintainer-specific
  guidance (warehouse credentials, release procedure detail)
- [`scripts/ci/README.md`](../scripts/ci/README.md) — script-by-script
  reference for the local CI shims
- [`specs/ci-rework/README.md`](../specs/ci-rework/README.md) — design rationale,
  threat model, tech debt backlog
