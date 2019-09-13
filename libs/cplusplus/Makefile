# Dear reader,
#
# I had a lot of fun writing this Makefile (i.e. everything after "writer defined
# variables"). Please feel free to copy it, but if possible preserve this comment
# block when you do (lines 1 - 11).
#
# Best,
#
# Albert Liu
#
# P.S. I'm pretty sure if you include whitespace in your filenames, this will break.

# ---------- FILE DECLARATIONS -----------

SRC := src
NAMES := main
OUT = lab

# -------- USER DEFINED VARIABLES --------

# C Compiler
CC = clang -fcolor-diagnostics
# C++ Compiler
CXX = clang++ -fcolor-diagnostics

# C Flags
CFLAGS :=
# C++ Flags
CXXFLAGS := -std=c++11 -Wnon-virtual-dtor
# C/C++ Flags
CPPFLAGS := -Wall -Wextra -Wshadow -Wunused -pedantic
# Linking Flags
LDFLAGS := -lpthread

# Compilation targets
CHECK_CPPFLAGS := -fsyntax-only



# ------- WRITER DEFINED VARIABLES -------

define def
ifndef $(strip $(1))
	$(strip $(1)) := $(strip $(2))
endif

endef

define fun
ifndef $(strip $(1))
	$(strip $(1)) = $(strip $(2))
endif

endef


# User-defined values
$(eval $(call def,    SRC,                src))
$(eval $(call def,    NAMES,              ))
$(eval $(call def,    OUT,                out))

# Flags
$(eval $(call def,    CC,                 clang -fcolor-diagnostics))
$(eval $(call def,    CXX,                clang++ -fcolor-diagnostics))
$(eval $(call def,    CFLAGS,             -std=c99))
$(eval $(call def,    CXXFLAGS,           -std=c++11 -Wnon-virtual-dtor))
$(eval $(call def,    CPPFLAGS,           -Wall -Wextra -Wshadow -Wunused -pedantic))
$(eval $(call def,    LDFLAGS,            -lpthread))
$(eval $(call def,    DEBUG_CPPFLAGS,     -O0 -g))
$(eval $(call def,    DEBUG_LDFLAGS,      -O0 -g))
$(eval $(call def,    RELEASE_CPPFLAGS,   -O3))
$(eval $(call def,    RELEASE_LDFLAGS,    -O3))
$(eval $(call def,    CHECK_CPPFLAGS,     -fsyntax-only))
$(eval $(call def,    CHECK_PHONY,        1))

# Directories
$(eval $(call def,  ARTDIR,               target))
$(eval $(call def,  DEPDIR,               deps))
$(eval $(call def,  MKR,                  .dirstamp))
$(eval $(call def,  DONE_MKR,             .done))
$(eval $(call def,  ERROR_MKR,            .error))
$(eval $(call def,  DONE,                 \033[1;32mDone\033[0m!))
$(eval $(call def,  ERROR,                \033[1;31mFailed\033[0m!))
$(eval $(call def,  NORMAL,               \033[0m))

# Variable override
-include "MakefileOverride"

.PHONY: directories clean all debug release check $(TARGETS)
.SUFFIXES:
.SECONDARY:
$(eval $(call def,  .DEFAULT_GOAL,        debug))
.DEFAULT_GOAL := debug

PATHS := $(addprefix $(SRC)/,$(NAMES))
DEPS := $(patsubst %,$(DEPDIR)/%.dep,$(basename $(NAMES)))
get_objs = $(patsubst %,$(ARTDIR)/$(1)/%.o,$(basename $(NAMES)))

# -------- TARGET DEFINITIONS --------

# Creates a set of recipes for the given target.
#
# Arguments
# 1. Target name
define target_recipes
$(eval ART := $(ARTDIR)/$(1))
$(eval OBJS := $(call get_objs,$(1)))
$(eval ERR := $(ARTDIR)/$(1)/$(ERROR_MKR))

ifneq ($($(call uc,$(1))_PHONY), 1)
$(1): $(ART)/bin
	$$(call vexe,cp $(ART)/bin $(OUT))
	@printf "Target \`$(1)\` finished.\n$(NORMAL)"
else
$(1): $(ART)/bin
	@printf "Target \`$(1)\` finished.\n$(NORMAL)"
endif

ifneq ($($(call uc,$(1))_PHONY), 1)
$(ART)/bin: $(ART)/$(MKR) $(DEPDIR)/$(MKR) $(OBJS)
	@printf "Compiling binary in \`$(1)\` mode...$(NORMAL) $$v"
	$$(call run_with_error, $(CXX) $$(call get_target_flags,$(1),ld) $(LDFLAGS) $(OBJS) -o $(ART)/bin,true,$(ERR))
	@printf "$(DONE)\n"
else
$(ART)/bin: $(ART)/$(MKR) $(DEPDIR)/$(MKR) $(OBJS)
endif

$(ART)/%.o : $(SRC)/%.cc
	$$(call compile,$(1),$$(call get_target_flags,$(1),cpp) $$(call get_target_flags,$(1),) $$(call get_target_flags,$(1),cxx),$$@,$(SRC)/$$*.cc,$(DEPDIR)/$$*.dep)

$(ART)/%.o : $(SRC)/%.c
	$$(call compile_c,$(1),$$(call get_target_flags,$(1),cpp) $$(call get_target_flags,$(1),) $$(call get_target_flags,$(1),cxx),$$@,$(SRC)/$$*.c,$(DEPDIR)/$$*.dep)

$(ART)/%.o : $(SRC)/%.cpp
	$$(call compile,$(1),$$(call get_target_flags,$(1),cpp) $$(call get_target_flags,$(1),) $$(call get_target_flags,$(1),cxx),$$@,$(SRC)/$$*.cpp,$(DEPDIR)/$$*.dep)

$(ART)/$(MKR):
	$$(call build_dir,$(ART))

endef


clean:
	@printf "Cleaning compilation artifacts... $v"
	$(call vexe,rm -rf $(ARTDIR))
	$(call vexe,rm -rf $(DEPDIR))
	@printf "$(DONE)\n"

all: directories $(TARGETS)

# ---- HELPER TARGET DEFINITIONS -----


$(DEPDIR)/$(MKR):
	$(call build_dir,$(@D))

# ------- FUNCTION DEFINITIONS -------

# Generates a newline character
define n


endef

get_target_flags = $($(call uc,$(1))_$(call uc,$(2))FLAGS)

define vexe
@$(1)
endef

# Compile an object file.
# Arguments:
# 1. Target name
# 2. Target flags
# 3. Artifact name
# 4. Source file
# 5. Dependency file
define compile
$(eval ERR := $(ARTDIR)/$(1)/$(ERROR_MKR))
@printf "Building compilation artifact \`$(3:$(ARTDIR)/$(1)/%=%)\` in $(call make_bold,$(1)) mode... $v"

@mkdir -p $(dir $(3))
@mkdir -p $(dir $(5))
@touch $(3)

$(call run_with_error, \
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $(2) \
		-MD -MP -MF $(5) \
		-o $(3) $(4) \
		&& printf "$(DONE)\n", \
	rm "$(3)", \
	$(ERR) \
)
endef

# Compile an object file.
# Arguments:
# 1. Target name
# 2. Target flags
# 3. Artifact name
# 4. Source file
# 5. Dependency file
define compile_c
$(eval ERR := $(ARTDIR)/$(1)/$(ERROR_MKR))
@printf "Building compilation artifact \`$(3:$(ARTDIR)/$(1)/%=%)\` in $(call make_bold,$(1)) mode... $v"

@mkdir -p $(dir $(3))
@mkdir -p $(dir $(5))
@touch $(3)

$(call run_with_error, \
	$(CC) -c $(CPPFLAGS) $(CXXFLAGS) $(2) \
		-MD -MP -MF $(5) \
		-o $(3) $(4) \
		&& printf "$(DONE)\n", \
	rm "$(3)", \
	$(ERR) \
)
endef

# Runs a shell command, with nice error printing.
#
# Arguments
# 1. Command to run
# 2. Command to run to handle errors
# 3. File to hold errors temporarily
define run_with_error
$(call __run_with_error,$(strip $(1)),$(strip $(2)),$(strip $(3)))
endef

# Runs a shell command, with nice error printing.
#
# Arguments
# 1. Command to run
# 2. Command to run to handle errors
# 3. File to hold errors temporarily
define __run_with_error
@( \
	( $(1) ) 2>"$(3)" && cat "$(3)" \
) || ( \
	printf "$(ERROR)\n" \
	&& cat "$(3)" \
	&& $(2) \
	&& false \
)
endef

# Eventually make this partially user defined, i.e. by expanding a TARGET variable
# or something like that
ifneq ($(VERBOSE), 1)
.SILENT:
else
v := \n
define vexe
@printf '\033[1mVERBOSE\033[0m:\033[0;33m\
	$(subst \',\\',$(subst \,\\,$(strip $(1))))\
	\n$(NORMAL)'
@$(1)
endef
define run_with_error
@printf '\033[1mVERBOSE\033[0m:\033[0;33m\
	$(subst \',\\',$(subst \,\\,$(strip $(1))))\n$(NORMAL)'
$(call __run_with_error,$(strip $(1)),$(strip $(2)),$(strip $(3)))
endef
endif

# Eventually make this partially user defined, i.e. by expanding a TARGET variable
# or something like that
ifeq ($(DEBUG), )
else
v := \n
define dbg
$(info $(shell printf "\033[1mDEBUG\033[0m:") $(1))
endef

# Maybe make this use the value of DEBUG
define dbg_var
$(info $(shell printf "\033[1mDEBUG\033[0m:") Variable `$(1)` defined as "$($(1))")
endef
endif

# Builds the directory structure for a specific compilation mode.
#
# Takes arguments:
# 1. Compilation folder: folder that holds compilation artifacts
define build_dir
	@if [ $(VERBOSE) ]; then \
		printf "$(call make_bold,VERBOSE): Making the directory associated with \`$(call make_bold,$(notdir $(1)))' mode... $v"; fi
	$(call vexe,mkdir -p $(1) && touch $(1)/$(MKR) && touch $(1)/.error)
	@if [ $(VERBOSE) ]; then \
		printf "$(NORMAL)$(call make_bold,VERBOSE): $(DONE)\n"; fi
endef

# --- HELPER FUNCTION DEFINITIONS ----

# Takes arguments:
# 1. Compilation mode: either release or debug
make_bold = \033[1m$(1)\033[0m

# Lowercase
lc = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))

# Uppercase
uc = $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$1))))))))))))))))))))))))))


# ------- INCLUDE DEFINITIONS --------

$(eval $(foreach targets,debug release check $(TARGETS),$(call target_recipes,$(targets))))

-include $(DEPS)
