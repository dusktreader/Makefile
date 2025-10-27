VALID_SPECIES := jawa ewok hutt pyke
VALID_PLANETS := tatooine endor nal-hutta oba-diah
PLANET ?= tatooine

default: help


## ==== Basic targets ==================================================================================================

basic: ## Just a basic target with nothing fancy
	@echo Executing basic target

# Targets without a help string will not be shown in the help output
basic-no-help:
	@echo Executing basic target with no help

basic-preq: basic ## A basic target that has a single prerequisite
	@echo Executing basic target with a single prerequisite


## ==== Targets with patterns ==========================================================================================

pattern/%: ## A target with a pattern
	@echo Executing target with a pattern=$@

pattern-notdir/%: ## A target with a pattern where the command doesn't use the "dir" portion
	@echo Executing target with a "notdir" pattern=$(notdir $@)

pattern-preq/%: pattern-notdir/% ## A target with a pattern with a pattern prerequisite
	@echo Executing target with a pattern=$(notdir $@) and a pattern prerequisite


## ==== Targets with guards ============================================================================================

var-guarded: _guard_planet ## A target that includes a variable guard for planet
	@echo Executing target with a variable guard where PLANET=$(PLANET)

pattern-guarded/%: _guard_species/%  ## A target with a pattern that includes a pattern guard for species
	@echo Executing target with a pattern guard where species=$(notdir $@)


## ==== Targets with confirmation ======================================================================================

confirmed: _confirm ## A target that requires confirmation to continue
	@echo Executing target that required confirmation first


## ==== Helpers ========================================================================================================

help:  ## Show this help message
	@awk "$$PRINT_HELP_PREAMBLE" $(MAKEFILE_LIST)


## ---- Make configuration ---------------------------------------------------------------------------------------------

.ONESHELL:
SHELL := /bin/bash
.PHONY: default basic basic-no-help basic-preq \
	pattern/% pattern-notdir/% pattern-preq/% \
	var-guarded pattern-guarded/% \
	confirmed \
	clean help


## ---- Hidden auxiliary targets ---------------------------------------------------------------------------------------

_guard_species/%:  # Ensures a valid species is selected (Do not use directly)
	@if ! echo "$(VALID_SPECIES)" | grep -q "\b$(notdir $@)\b"; \
	then \
		echo -e "Invalid SPECIES:      $(RED)$(notdir $@)$(CLEAR)"; \
		echo -e "Valid SPECIES values: $(GREEN)$(VALID_SPECIES)$(CLEAR)"; \
		echo; \
		exit 1; \
	fi

_guard_planet:  # Ensures a valid planet is selected (Do not use directly)
	@if ! echo "$(VALID_PLANETS)" | grep -q "\b$(PLANET)\b"; \
	then \
		echo -e "Invalid PLANET:      $(RED)$(PLANET)$(CLEAR)"; \
		echo -e "Valid PLANET values: $(GREEN)$(VALID_PLANETS)$(CLEAR)"; \
		echo; \
		exit 1; \
	fi

_confirm:  # Requires confirmation before proceeding (Do not use directly)
	@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]


## ---- Help printer ---------------------------------------------------------------------------------------------------

RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
BLUE   := \033[34m
TEAL   := \033[36m
CLEAR  := \033[0m


define PRINT_HELP_PREAMBLE
BEGIN {
	print "Usage: $(YELLOW)make <target> [PLANET=<planet>]$(CLEAR)"
	print
	print "PLANET values: $(GREEN)$(VALID_PLANETS)$(CLEAR)"
	print "SPECIES values: $(GREEN)$(VALID_SPECIES)$(CLEAR)"
	print
	print "Targets:"
}
/^## =+ [^=]+ =+.*/ {
    s = $$0
    sub(/^## =+ /, "", s)
    sub(/ =+/, "", s)
	printf("\n  %s:\n", s)
}
/^[$$()% 0-9a-zA-Z_\/-]+(\\:[$$()% 0-9a-zA-Z_\/-]+)*:.*?##/ {
    t = $$0
    sub(/:.*/, "", t)
    h = $$0
    sub(/.?*##/, "", h)
    printf("    $(YELLOW)%-19s$(CLEAR) $(TEAL)%s$(CLEAR)\n", t, h)
}
endef
export PRINT_HELP_PREAMBLE
