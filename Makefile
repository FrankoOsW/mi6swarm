up:
	pipenv run uvicorn src.main:app --reload

test:
	pipenv run pytest -k tests

black:
	pipenv run black src

atlantis: ## required by the Atlantis tool
	exit 0
