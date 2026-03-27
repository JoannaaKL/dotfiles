.PHONY: lint install

lint:
	@echo "Running shellcheck..."
	@shellcheck install.sh helpers.sh clean-codespaces.sh export_codespace_cfg
	@echo "All checks passed."

install:
	@./install.sh
