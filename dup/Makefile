BUILD=dup-py
PYTHON=python3
TESTS=$(wildcard tests/*.txt)

## commands: show available commands (*)
.DEFAULT: commands
commands:
	@grep -h -E '^##' ${MAKEFILE_LIST} \
	| sed -e 's/## //g' \
	| column -t -s ':'

## launch: build and run in a single step
launch:
	dafny run --target=py --standard-libraries dup.dfy -- $(TESTS)

## build: compile to Python
build:
	rm -rf $(BUILD)
	dafny build --target=py --standard-libraries dup.dfy

## run: run the generated Python
run:
	PYTHONPATH=$(BUILD) $(PYTHON) -m dup-py $(TESTS)
