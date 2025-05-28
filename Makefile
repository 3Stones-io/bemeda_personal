ci: check_code

check_code:
	MIX_ENV=test mix compile
	mix check_code
	MIX_ENV=test mix ecto.rollback --all --quiet

show_missing_translations:
	@echo "Missing translations:"
	@for file in $$(find priv/gettext -name "*.po" -not -path "*/en/*"); do count=$$(grep -c "^msgstr \"\"$$" "$$file" | grep -v ":9:" || echo 0); if [ "$$count" -gt 1 ]; then echo "$$count $$file"; fi; done | sort -nr
