# dbt Fusion engine (dbt 2.x) in a throwaway container.
#
# Used by `scripts/fusion/dbtf.sh` to check this package against Fusion
# without installing the Fusion binary on the developer's machine.
#
# The version is pinned so local runs are reproducible. To bump it, change
# FUSION_VERSION (tags listed at https://public.cdn.getdbt.com/fs/versions.json)
# and rebuild with `scripts/fusion/dbtf.sh --rebuild`.

FROM debian:bookworm-slim

ARG FUSION_VERSION=2.0.6

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh \
      | sh -s -- --version "${FUSION_VERSION}" --to /usr/local/bin \
    && dbt --version

WORKDIR /work/integration_test_project
ENTRYPOINT ["dbt"]
