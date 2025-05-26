ci: check_code

check_code:
	MIX_ENV=test mix compile
	mix check_code
	MIX_ENV=test mix ecto.rollback --all --quiet

playwright:
	@lsof -ti tcp:8931 | xargs kill -9
	mix cmd --cd assets npx @playwright/mcp@latest --port 8931
