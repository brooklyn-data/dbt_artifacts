# Contributing to the dbt Artifacts Package as a Maintainer

> [!IMPORTANT]
> This guide was written for Brooklyn Data engineers and contains details that are specific to the Brooklyn Data workplace (i.e., Slack channel names), but much of this
> will be useful for all contributors, internal or external to Brooklyn Data. 

## General Guidance
- You can create your own branches in the repo - no need to fork. Make sure to ask in the #_dbt_artifacts Slack channel
  if you need to be given permissions to contribute.
- If a contributor has a question about a PR, please try to answer it as soon as possible. If you are not sure, ask in 
  the #_dbt_artifacts Slack channel.
- If you review a PR from a contributor and request changes, please make sure to follow up with them to see if they have 
  any questions or need help. If you do not receive a response within a few weeks, and you can fix the code and merge it - 
  do it. If for whatever reasons permissions prevent you from doing so, add a short explanation that you’ve closed the PR
  for that reason, copied their work into your branch, and pasted a link so they can follow progress.

## Warehouse set-up for testing
You can use the following warehouses for testing. The credentials are picked up in the `integration_test_project/profiles.yml`
file via environment variables. So to be able to connect to the different sources, you should include the following in your
`integration_test_project/env.sh` file (these are exported by running the `. ./env.sh` command mentioned below).

### Snowflake
This uses our partner Snowflake account. Temporarily, you can make use of the shared CI login credentials. See #_dbt_artifacts
Slack channel for links.

````
# integration_test_project/env.sh
export DBT_ENV_SECRET_SNOWFLAKE_TEST_ACCOUNT=brooklyndatapartner
export DBT_ENV_SECRET_SNOWFLAKE_TEST_USER=dbt_artifacts_ci
export DBT_ENV_SECRET_SNOWFLAKE_TEST_PASSWORD=<see shared credentials>
export DBT_ENV_SECRET_SNOWFLAKE_TEST_ROLE=public
export DBT_ENV_SECRET_SNOWFLAKE_TEST_DATABASE=dev
export DBT_ENV_SECRET_SNOWFLAKE_TEST_WAREHOUSE=developer
````

### Databricks
This uses the dbt-artifacts project. Add a request in the #_sandbox_stewards Slack channel to be given permissions to use it.
Follow the instructions in [here](https://docs.databricks.com/aws/en/integrations/compute-details) to get the following details
(the Host and Http Path are placeholders to show what they might look like). You will need to get a [personal access token](https://docs.databricks.com/aws/en/dev-tools/auth#personal-access-tokens-for-users) too.

````
export DBT_ENV_SECRET_DATABRICKS_HOST=<<value>>.cloud.databricks.com
export DBT_ENV_SECRET_DATABRICKS_HTTP_PATH=/sql/1.0/warehouses/<<value>>
export DBT_ENV_SECRET_DATABRICKS_TOKEN=abcdefghijklmnop1234567890
````

### BigQuery
This is set up in the dbt-artifacts-ci [project](https://console.cloud.google.com/welcome?project=dbt-artifacts-ci). Add
a request in the #_sandbox_stewards Slack channel to be given permissions to use it. You will need to follow the instructions
[here](https://cloud.google.com/docs/authentication/provide-credentials-adc#how-to) to authorise BigQuery locally.

````
# integration_test_project/env.sh
export DBT_ENV_SECRET_GCP_PROJECT=dbt-artifacts-ci
````

### Postgres
Make sure to download [Docker](https://hub.docker.com/_/postgres), then use the following to spin up a local postgres instance (Make sure that your Dremio
container isn’t also running…).

````
docker pull postgres
docker run --name dbt-artifacts-postgres -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e DB_HOST=localhost -d postgres
````

### Dremio
Make sure to download [Docker](https://hub.docker.com/_/postgres), then use the following to spin up a local postgres instance (Make sure that your Postgres
container isn’t also running…).

````
docker pull dremio/dremio-oss 
docker run --name dbt-artifacts-dremio -p 9047:9047 -p 31010:31010 -p 45678:45678 dremio/dremio-oss
# Stop this running using Ctrl + C
docker start dbt-artifacts-dremio
````
Navigate to http://localhost:9047/signup and you should see a Dremio sign up screen. Sign up with your details (it’s just a local user).

## How the package works
- The dbt project in the `integration_test_project` is used to test the work that is done in the main folder. If you are running
  any dbt commands, it will be from in here, rather than the outer project.
- Most of the logic for getting the data is included in the `macros` folder. In here there are a number of 
  `upload_individual_datasets/upload_<<table>>.sql` files which have definitions for the individual data sets. You’ll notice
  that there is a default one at the top, and then any adapter specific ones below that. If you are wanting to make changes to tables
  it is likely to be in these files. If you are adding columns, these should be done in the same order as the columns appear in 
  the `macros/upload_results/get_column_name_lists.sql` file.
  ![img.png](/docs/images/img.png)
- Models in the `sources` folder creates empty tables with the correct field names and types. These get run as part of the
  `dbt run` to ensure that there are empty tables to upload results to. These are materialised as tables. You’ll notice that
  it makes use of `type_` macros to ensure types are accurate across each warehouse. The fields in here also need to be the
  same order as the fields in the `macros/upload_results/get_column_name_lists.sql` file, and any new fields must be added
  AT THE BOTTOM of the table.
  ![img_1.png](/docs/images/img_1.png)
- Models in the `staging` and outer folder create views which tidy these source tables up as in a standard dbt project. These
  are also run as part of `dbt run`.
- Once all tables have been built, they need to get updated by a hook - this is why in the instructions, people need to add
  this to their `dbt_project.yml` file. As an example, the hook is defined in `integration_test_project/dbt_project.yml`
  ````
  on-run-end:
  - "{{ dbt_artifacts.upload_results(results) }}"
  ````
- This then runs `macros/upload_results/upload_results` to populate the files by looking at the [run results](https://docs.getdbt.com/reference/artifacts/run-results-json) and using the
  `upload_*.sql` macros to individually create the results.

## Integration Tests
When you create a PR it will need to pass CI. To get the integration tests to run on your PR you need to approve them. Scroll to the bottom of the PR to find this section:

![img_2.png](/docs/images/img_2.png)

Click on “Show environments”:

![img_3.png](/docs/images/img_3.png)

Click on the blue link (i.e. integration-snowflake #352) and it will open up the action. Look for this section:

![img_4.png](/docs/images/img_4.png)

Click on “Review deployments":

![img_5.png](/docs/images/img_5.png)

Make sure to check “Approve Integration Tests” and then click “Approve and deploy”. If you head back to the PR you should see the tests are now running:

![img_6.png](/docs/images/img_6.png)

(If you notice the checks are still in status “Waiting” you may have to “Approve and deploy” again)

## How to test / verify issues locally
> [!NOTE]
> If you want to test an existing PR opened by another contributor you will have to add their repo as a new remote
> `````
> git remote add their-username https://github.com/their-username/repo-name
> git fetch their-username
> `````

- Following instructions in the [Contributing README](https://github.com/brooklyn-data/dbt_artifacts/blob/main/CONTRIBUTING.md#setting-up-your-development-environment) to
  get the `integration_test_project/env.sh` file ready, and update using the credentials above, as well as updating the `GITHUB_SHA=<initials>_test` to
  include your initials (e.g. `gd_test`), and setting the version number in `DBT_VERSION` to a version you want to use e.g. `1_5_0`.
- Test you can run it with the commands included in the README:
  ````
  cd integration_test_project
  . ./env.sh
  dbt deps
  tox -e integration_snowflake # For the Snowflake tests
  tox -e integration_databricks # For the Databricks tests (if used)
  tox -e integration_bigquery # For the BigQuery tests (if used)
  tox -e integration_postgres # For the Postgres tests (if used)
  ````
- You can check results within the warehouse using:
  ````
  use database dev; -- For Snowflake
  select * from dbt_artifacts_test_commit_<dbt_version>_<initials>_test.<table_name>;
  ````
- Before doing development it’s good to make sure the structure you are testing against is the same as main so drop the schema using:
  ````
  drop dbt_artifacts_test_commit_<dbt_version>_<initials>_test.<table_name> cascade;
  ````
  Then run against the latest version of main:
  ````
  git checkout main && git pull origin main
  tox -e integration_<<warehouse_name>> # Run on any warehouses you are testing on
  ````
  Once the models have been built from what is on main, then you can checkout the branch you want to test and run them from there.
- If you want to test specific tables, you might want to create different environment for the adapters. You could use dbtenv for
  this, or pyenv if you are more comfortable with that. This is how I set it up with [pyenv virtualenv](https://github.com/pyenv/pyenv-virtualenv):
  ````
  # Install latest 3.8 release (matches the CI test version)
  pyenv install 3.8.16
  
  # Snowflake environment
  pyenv virtualenv 3.8.16 dbt-artifacts-snowflake
  pyenv activate dbt-artifacts-snowflake
  pip install dbt-snowflake~=1.6.0
  pyenv local dbt-artifacts-snowflake # set as default - optional
  
  # Bigquery environment (if using)
  pyenv virtualenv 3.8.16 dbt-artifacts-bigquery
  pyenv activate dbt-artifacts-bigquery
  pip install dbt-bigquery~=1.6.0
  
  # Databricks environment (if using)
  pyenv virtualenv 3.8.16 dbt-artifacts-databricks
  pyenv activate dbt-artifacts-databricks
  pip install dbt-databricks~=1.6.0
  
  # Postgres environment (if using)
  pyenv virtualenv 3.8.16 dbt-artifacts-postgres
  pyenv activate dbt-artifacts-postgres
  pip install dbt-postgres~=1.6.0
  ````
  To test on a specific environment, you will need to activate the environment first, then get dbt to run using the appropriate target
  e.g. to test the `aliased` table with `bigquery`
  ````
  pyenv activate dbt-artifacts-bigquery
  dbt run --select aliased --target bigquery
  ````
> [!NOTE]
> If you don’t want to keep adding `--target bigquery` to your dbt commands, you can temporarily set it as the default in the `integration_test_project/profiles.yml` file by changing the target to `bigquery` at the top of the `dbt_artifacts` definition.

## How to release
- Use [semantic versioning](https://semver.org/) to work out whether it’s a patch, minor or major change. If it contains breaking changes (including new fields), then it should be at least a minor change. 
- Do a find and replace of the current version (e.g. `2.2.1`) with the new version (e.g. `2.2.2`)
- Merge a PR which applies that change 
- Make a new release: [Releases · brooklyn-data/dbt_artifacts](https://github.com/brooklyn-data/dbt_artifacts/releases)
  - This will automatically update the documentation through a GH action 
  - Per the [dbt guidance](https://docs.getdbt.com/guides/legacy/building-packages), the repo ([GitHub - dbt-labs/hubcap](https://github.com/dbt-labs/hubcap)) that adds releases to dbt Hub will run every hour and pick up any new versions. It will only pick up full versions, so use the guidance if you want to create a pre-release.
