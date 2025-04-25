ci: check_code

check_code:
	MIX_ENV=test mix compile
	mix check_code
	MIX_ENV=test mix ecto.rollback --all --quiet
