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
NAMES := 
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
LDFLAGS :=

# Compilation targets
TARGETS := debug release check
# Flags to use for target `check`
CHECK_FLAGS := -fsyntax-only

NAMES := $(addsuffix .cc,$(NAMES))


# ------- WRITER DEFINED VARIABLES -------

ARTDIR = target
DEPDIR = deps
MKR = .dirstamp
DONE_MKR = .done
ERROR_MKR = .error
DONE = \033[1;32mDone\033[0m!
ERROR = \033[1;31mFailed\033[0m!
NORMAL = \033[0m

.PHONY: clean all $(TARGETS)
.SUFFIXES:
.SECONDARY:

PATHS := $(addprefix $(SRC)/,$(NAMES))
DEPS := $(patsubst %,$(DEPDIR)/%.dep,$(basename $(NAMES)))
get_objs = $(patsubst %,$(ARTDIR)/$(1)/%.o,$(basename $(NAMES)))

# -------- TARGET DEFINITIONS --------

define target_recipes
$(eval ART := $(ARTDIR)/$(1))
$(eval OBJS := $(call get_objs,$(1)))

$(1): $(ART)/bin
	@cp $(ART)/bin $(OUT)
	@printf "Compiled in \`$(1)\` mode.\n$(NORMAL)"

$(ART)/bin: $(ART)/$(MKR) $(DEPDIR)/$(MKR) $(OBJS)
	@$(CXX) $(LDFLAGS) $(OBJS) -o $(ART)/bin

$(ART)/%.o : $(SRC)/%.cc $(DEPDIR)/%.dep
	$$(call compile_obj,debug,$$(call get_target_flags,$(1)),$$@,$(SRC)/$$*.cc,$(DEPDIR)/$$*.dep)

$(ART)/$(MKR):
	$$(call build_dir,$(ART))

endef

# $(info $(foreach targets,$(TARGETS),$(call target_recipes,$(targets))))
$(eval $(foreach targets,$(TARGETS),$(call target_recipes,$(targets))))

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

get_target_flags = $($(call uc,$(1))_FLAGS)

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
define compile_obj
$(eval ERR := $(ARTDIR)/$(1)/$(ERROR_MKR))
$(call vexe, \
	printf "Building compilation artifact \`$(3)\`\
	in $(call make_bold,$(1)) mode... $v" \
)

@mkdir -p $(dir $(3))
@mkdir -p $(dir $(5))
@touch $(3)

$(call vexe,$(call __compile_obj,$(2),$(3),$(4),$(5),$(ERR)))
endef

# Compile an object file.
# Arguments:
# 1. Target flags
# 2. Artifact name
# 3. Source file
# 4. Dependency file
# 5. Error file
define __compile_obj
	( \
	$(CXX) -c $(CPPFLAGS) $(CXXFLAGS) $(1) \
	-MD -MP -MF $(4) \
	-o $(2) $(3) 2>"$(5)" \
	&& printf "$(DONE)\n" && cat "$(5)" \
	) || ( \
		printf "$(ERROR)\n" \
		&& cat "$(5)" \
		&& rm "$(2)" 2>/dev/null \
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
		printf "$(call make_bold,VERBOSE): Making the directory associated with \`$(call make_bold,$(dir $(1)))' mode... $v"; fi
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

$(DEPDIR)/%.dep: ;
