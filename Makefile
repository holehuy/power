# Dev toolchain via Docker Compose — identical on Mac/Windows/Linux (docker-compose.yml + docker/Dockerfile).
# Not for running production workers (those need a real Windows Server with IPAM/DHCP/DNS — see README).

.PHONY: build lint-ps test-ps test-py test shell az-login

build:
	docker compose build

# Device code flow (no browser in the container). Session persists in the az-cli-config named
# volume, so later `docker compose run`/`make shell` calls don't need to log in again.
az-login: build
	docker compose run --rm dev az login --use-device-code

lint-ps: build
	docker compose run --rm dev pwsh -NoLogo -NoProfile -Command " \
		\$$results = Invoke-ScriptAnalyzer -Path . -Recurse; \
		\$$results | Format-Table -AutoSize; \
		if (\$$results | Where-Object Severity -eq 'Error') { exit 1 } "

test-ps: build
	docker compose run --rm dev pwsh -NoLogo -NoProfile -Command \
		"Invoke-Pester ./tests/powershell -CI"

# Uses its own venv instead of --break-system-packages: the latter conflicts with the `wheel`
# package apt already manages on the base image.
test-py: build
	docker compose run --rm dev bash -c \
		"python3 -m venv /tmp/venv && /tmp/venv/bin/pip install -q -r src/arp-collector/requirements.txt pytest && /tmp/venv/bin/pytest tests/python -v"

test: test-ps test-py

shell: build
	docker compose run --rm dev bash
