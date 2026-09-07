.PHONY: lint shellcheck secrets install

lint: shellcheck secrets
	@echo "All checks passed."

shellcheck:
	@echo "Running shellcheck..."
	@git ls-files | while IFS= read -r file; do \
		if [ -f "$$file" ] && { case "$$file" in *.sh) true ;; *) head -1 "$$file" | grep -qE '^#!.*bash' ;; esac; }; then \
			printf '%s\n' "$$file"; \
		fi; \
	done | sort -u | xargs shellcheck --severity=style

secrets:
	@echo "Checking tracked files for GitHub tokens..."
	@files="$$(git grep -lE '(gh[pousr]|github_pat)_[[:alnum:]_]{20,}' -- . || true)"; \
	if [ -n "$$files" ]; then \
		echo "Potential GitHub token found in tracked files:" >&2; \
		printf '%s\n' "$$files" >&2; \
		exit 1; \
	fi

install:
	@./install.sh
