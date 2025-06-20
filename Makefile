ci: check_code

check_code:
	MIX_ENV=test mix compile
	mix check_code
	MIX_ENV=test mix ecto.rollback --all --quiet
	make check_gettext check_translations

check_gettext:
	@echo "Checking for uncommitted Gettext translation changes..."
	@MIX_ENV=test mix gettext.extract --merge > /dev/null 2>&1
	@if ! git diff --quiet priv/gettext; then \
		echo '❌ Found uncommitted Gettext translation changes!' && \
		echo '\nModified files:' && \
		git diff --name-only priv/gettext | sed 's/^/  - /' && \
		echo '\nTo fix this:' && \
		echo '1. Run "mix gettext.extract --merge" locally' && \
		echo '2. Review and commit the changes' && \
		echo '3. If new strings were added, use Claude to translate them' && \
		echo '4. Run "make show_missing_translations" to check for missing translations' && \
		echo '5. Push the updates to your branch\n' && \
		exit 1; \
	fi

check_translations:
	@echo "Checking for missing translations..."
	@missing=$$($(MAKE) -s _find_missing_translations); \
	if [ -n "$$missing" ]; then \
		echo "Missing translations found:"; \
		echo "$$missing"; \
		echo ""; \
		echo "To fix this:"; \
		echo "1. Run 'make show_missing_translations' to see detailed missing translations"; \
		echo "2. Use Claude to translate the missing strings"; \
		echo "3. Commit the updated translation files"; \
		exit 1; \
	else \
		echo "All translations are complete!"; \
	fi

show_missing_translations:
	@echo "Missing translations:"
	@$(MAKE) -s _find_missing_translations

_find_missing_translations:
	@for file in $$(find priv/gettext -name "*.po" -not -path "*/en/*"); do count=$$(grep -c "^msgstr \"\"$$" "$$file" | grep -v ":9:" || echo 0); if [ "$$count" -gt 1 ]; then echo "$$count $$file"; fi; done | sort -nr
