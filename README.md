# mi6swarm

Internal AI agent swarm for Data Analysts. Provides natural language interface to query competitive data across GitLab ETL code, Confluence documentation, and vendor specs. Features supervisor agent with domain routing to Traffic and autoplac.pl specialists. Synthesizes knowledge that would otherwise require hours of manual searching.

This repo was built using the Service Shaper template [Python FastAPI App](https://git.naspersclassifieds.com/infrastructure/europe/eu-unified-service-platform/service-templates/fastapi-template) and configures a scaffolded [FastAPI](https://fastapi.tiangolo.com/) server with some opinionated defaults.

Template support available at #ct-devx-support

Features:

- can load `.env` file contents on start-up - these are excluded by the `.dockerignore` file
- shows json logs in when running via docker
- shows plain-text logs in the development environment
- application is wrapped by newrelic-admin to send APM data to [New Relic](onenr.io)
- application has sentry support too

## Pre-commit

If you have [pre-commit](https://pre-commit.com/) installed then enable it.

We use `pre-commit` to apply several pre-commit git hooks. For example, it uses black to improve the code formatting. See `.pre-commit-config.yaml` for other checks. To install pre-commit:

### installing pre-commit if you don't have it

#### sh install

```console
curl https://pre-commit.com/install-local.py | python -
```

#### asdf install

```console
asdf plugin add pre-commit
asdf install pre-commit latest
asdf global pre-commit lastest
```

### enabling pre-commit

Then from the root directory of this repo, run:

```console
pre-commit install
```

Then every time you run git commit you'll see which of the pre-commit checks passed. If black fails, it will fix the formatting, but won't commit the changes. So just add the changes that it created, and then git commit should work.

## Testing

Should be located in the project root `tests` folder. We use `pytest`.

```console
make test

# runs
# pipenv run pytest -k tests
```
