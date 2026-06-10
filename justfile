set shell := ["bash", "-cu"]

conda_env := "ansible-dev"
run := "conda run -n " + conda_env + " --live-stream"

# List available recipes
default:
    @just --list

# Lint everything (yamllint + ansible-lint)
lint:
    {{ run }} yamllint -c .yamllint.yml --strict .
    {{ run }} ansible-lint

# Full molecule test for one scenario (vagrant/libvirt)
test scenario="default":
    {{ run }} molecule test -s {{ scenario }}

# Lint + every local scenario, sequentially
test-all: lint (test "default") (test "multidisk") (test "upgrade") (test "cluster")

# Run the container-based CI scenario locally (needs docker)
ci-test distro="debian12":
    MOLECULE_DISTRO={{ distro }} {{ run }} molecule test -s ci

# Converge a scenario and keep the VM for inspection
converge scenario="default":
    {{ run }} molecule converge -s {{ scenario }}

verify scenario="default":
    {{ run }} molecule verify -s {{ scenario }}

destroy scenario="default":
    {{ run }} molecule destroy -s {{ scenario }}

# Shell into a scenario instance
login scenario="default" *args="":
    {{ run }} molecule login -s {{ scenario }} {{ args }}

# Fetch checksums for a Garage version (empty = latest stable)
update-checksums version="":
    ./scripts/update-checksums.sh {{ version }}

# Apply repo governance settings via gh (run after first CI run)
setup-repo repo="eyebrowkang/ansible-role-garage":
    ./scripts/setup-repo.sh {{ repo }}
