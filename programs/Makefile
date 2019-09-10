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

# -------- USER DEFINED VARIABLES --------

NAMES := hi main

# C Compiler
CC = clang -fcolor-diagnostics
# C++ Compiler
CXX = clang++ -fcolor-diagnostics
OUT = lab

# C Flags
CFLAGS :=
# C++ Flags
CXXFLAGS := -Wnon-virtual-dtor
# C/C++ Flags
CPPFLAGS := -Wall -Wextra -Wshadow -Wunused -pedantic
# Linking Flags
LDFLAGS :=

SRC := src
NAMES := $(addsuffix .cc,$(NAMES))
VERBOSE := 1

TARGETS = debug release

# ------- WRITER DEFINED VARIABLES -------

ARTDIR = target
DEPDIR = deps
MKR = .dirstamp
DONE_MKR = .done
ERROR_MKR = .error
DONE = \033[1;32mDone\033[0m!
ERROR = \033[1;31mFailed\033[0m
NORMAL = \033[0m
# Dependency Generation Flags

.PHONY: clean all check
.SUFFIXES:

# Eventually make this partially user defined, i.e. by expanding a TARGET variable
# or something like that
ifneq ($(VERBOSE), 1)
.SILENT:
else
define v
\n\033[1mVERBOSE\033[0m:\033[0;33m
endef
endif

# Eventually make this partially user defined, i.e. by expanding a TARGET variable
# or something like that
ifeq ($(DEBUG), )
else
define dbg
$(info $(shell printf "\033[1mDEBUG\033[0m:") $(1))
endef

# Maybe make this use the value of DEBUG
define dbg_var
$(info $(shell printf "\033[1mDEBUG\033[0m:") Variable `$(1)` defined as "$($(1))")
endef
endif

PATHS := $(addprefix $(SRC)/,$(NAMES))
OBJS = $(patsubst %,$(ARTDIR)/$(1)/%.o,$(basename $(NAMES)))
DEPS := $(patsubst %,$(DEPDIR)/%.o,$(basename $(NAMES)))

# -------- TARGET DEFINITIONS --------

define target_recipes
$(eval ART := $(ARTDIR)/$(1))

$(1): $(ART)/$(DONE_MKR)
	

$(ART)/$(DONE_MKR): $(ART)/$(MKR) $(DEPDIR)/$(MKR) $(call OBJS,$(1))
	@touch $(DEPDIR)/$(DONE_MKR)
	@touch $(ART)/$(DONE_MKR)

$(ART)/%.o : $(SRC)/%.cc
	$(CXX) -MD -MP -MF $(DEPDIR)/$$*.dep -c -o $$@ $(SRC)/$$*.cc

$(ART)/$(MKR):
	$$(call build_dir,$(ART))

endef

$(eval $(foreach targets,$(TARGETS),$(call target_recipes,$(targets))))

clean:
	@printf "Cleaning compilation artifacts...$v "
	rm -rf $(ARTDIR)
	rm -rf $(DEPDIR)
	@printf "$(DONE)\n"

check: $(addprefix $(ARTDIR)/check/,$(OBJ_NAMES))
	@printf "Check complete!\n"

all: directories $(TARGETS)

# ---- HELPER TARGET DEFINITIONS -----

$(DEPDIR)/$(MKR):
	$(call build_dir,$(@D))

# ------- FUNCTION DEFINITIONS -------

# Generates a newline character
define n


endef

# Builds the directory structure for a specific compilation mode.
#
# Takes arguments:
# 1. Compilation folder: folder that holds compilation artifacts
define build_dir
	@if [ $(VERBOSE) ]; then \
		printf "$(call make_bold,VERBOSE): Making the directory associated with \`$(call make_bold,$(dir $(1)))' mode...$v "; fi
	mkdir -p $(1) && touch $(1)/$(MKR) && touch $(1)/.error
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

-include $(DEPS)
