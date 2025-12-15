VALID_SPECIES := jawa ewok hutt pyke
VALID_PLANETS := tatooine endor nal-hutta oba-diah
DEFAULT_PLANET := tatooine
PLANET ?= $(DEFAULT_PLANET)

VERBOSE_FLAG :=
ifdef VERBOSE
	ifneq ($(filter $(VERBOSE), 1 t true yes y),)
		VERBOSE_FLAG := --verbose
	endif
endif

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


tool-guarded: _guard_drivel ## A target that includes a script guard for the drivel tool
	@echo Executing target with a tool guard where species=$$(drivel $(VERBOSE_FLAG) give --theme=star-wars --shuffle --no-fancy 1 | xargs)


## ==== Targets with sub-sections ======================================================================================

## ---- Sub-section 1 --------------------------------------------------------------------------------------------------

target1-1: ## Target 1 in sub-section 1
	@echo Executing target 1 in sub-section 1

target1-2: ## Target 2 in sub-section 1
	@echo Executing target 2 in sub-section 1


## ---- Sub-section 2 --------------------------------------------------------------------------------------------------

target2-1: ## Target 1 in sub-section 2
	@echo Executing target 1 in sub-section 2

target2-2: ## Target 2 in sub-section 2
	@echo Executing target 2 in sub-section 2


## ==== Targets with confirmation ======================================================================================

confirmed: _confirm ## A target that requires confirmation to continue
	@echo Executing target that required confirmation first


## ==== Helpers ========================================================================================================

help:  ## Show this help message
	@awk "$$PRINT_HELP_PREAMBLE" $(MAKEFILE_LIST)


# ..... Make configuration .............................................................................................

.ONESHELL:
SHELL := /bin/bash
.PHONY: default basic basic-no-help basic-preq \
	pattern/% pattern-notdir/% pattern-preq/% \
	var-guarded pattern-guarded/% \
	target1-1 target1-2 target2-1 target2-2 \
	confirmed \
	clean help


# ..... Color table for pretty printing ................................................................................

RED    := \033[31m
GREEN  := \033[32m
YELLOW := \033[33m
BLUE   := \033[34m
TEAL   := \033[36m
GRAY   := \033[90m
CLEAR  := \033[0m
ITALIC := \033[3m


# ..... Hidden auxiliary targets .......................................................................................

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

_guard_drivel:  # Ensure that drivel is installed
	@bash -c "$$ENSURE_DRIVEL_SCRIPT"

_confirm:  # Requires confirmation before proceeding (Do not use directly)
	@if [[ -z "$(CONFIRM)" ]]; \
	then \
		@echo -n "Are you sure? [y/N] " && read ans && [ $${ans:-N} = y ]; \
	fi

# ..... Ensure drivel is installed .....................................................................................

define ENSURE_DRIVEL_SCRIPT
	echo -e "$(TEAL)Ensuring drivel is available...$(CLEAR)"

	echo -en "  $(YELLOW)→ Checking for drivel...$(CLEAR)"
	if [[ ! $$(command -v drivel) ]]
	then
		echo -e "$(YELLOW)drivel not found! will attempt to install with uv$(CLEAR)"
	else
		echo -e "$(GREEN)drivel found!$(CLEAR)"
		exit 0
	fi

	echo -en "  $(YELLOW)→ Checking for uv...$(CLEAR)"
	if [[ ! $$(command -v uv) ]]
	then
		echo -e "$(RED)uv not found! $(YELLOW)see https://docs.astral.sh/uv/getting-started/installation/$(CLEAR)"
		exit 1
	else
		echo -e "$(GREEN)uv found!$(CLEAR)"
	fi

	echo -en "  $(YELLOW)→ Installing drivel with uv...$(CLEAR)"
	uv tool install py-drivel
	SUCCESS=$$?
	if (( $SUCCESS != 0 ))
	then
		echo -e "$(RED)Failed to install drivel!$(CLEAR)"
		exit $$SUCCESS
	else
		echo -e "$(GREEN)drivel installed successfully!$(CLEAR)"
	fi
endef
export ENSURE_DRIVEL_SCRIPT


# ..... Help printer ...................................................................................................

define PRINT_HELP_PREAMBLE
BEGIN {
	print "Usage: $(YELLOW)make <target> [PLANET=<planet>] [VERBOSE=1] [ARG=<arg>...]$(CLEAR)"
	print
	print "PLANET values: $(GREEN)$(VALID_PLANETS)$(CLEAR) $(TEAL)(default=$(DEFAULT_PLANET))$(CLEAR)"
	print "SPECIES values: $(GREEN)$(VALID_SPECIES)$(CLEAR)"
	print
	print "Targets:"
}
/^## =+ .+( =+)?/ {
    s = $$0
    sub(/^## =+ /, "", s)
    sub(/ =+/, "", s)
	printf("\n  %s:\n", s)
}
/^## -+ .+( -+)?/ {
    s = $$0
    sub(/^## -+ /, "", s)
    sub(/ -+/, "", s)
	printf("\n    $(TEAL)> %s$(CLEAR)\n", s)
}
/^[$$()% 0-9a-zA-Z_\/-]+(\\:[$$()% 0-9a-zA-Z_\/-]+)*:.*?##/ {
    t = $$0
    sub(/:.*/, "", t)
    h = $$0
    sub(/.?*##/, "", h)
    printf("    $(YELLOW)%-19s$(CLEAR) $(GRAY)$(ITALIC)%s$(CLEAR)\n", t, h)
}
endef
export PRINT_HELP_PREAMBLE
