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

NAMES := main argparse output argread maze path genetic

CC = clang -fcolor-diagnostics
CXX = clang++ -fcolor-diagnostics
OUT = lab

# C++ Flags
CFLAGS :=
# C++ Flags
CXXFLAGS := -Wnon-virtual-dtor
# C/C++ Flags
CPPFLAGS := -Wall -Wextra -Wshadow -Wunused -pedantic
# Linking Flags
LDFLAGS :=
DEPFLAGS = -MT $@ -MD -MP -MF $(DEPDIR)/$(1)/$*.d

SRC := src
NAMES := $(addsuffix .cc,$(NAMES))

# ------- WRITER DEFINED VARIABLES -------

ARTDIR = target
DEPDIR = deps
MKR = .dirstamp

# Eventually make this partially user defined, i.e. by expanding a TARGET variable
# or something like that
.PHONY: debug release clean all check makefile_debug directories test
.SUFFIXES:
ifneq ($(VERBOSE), 1)
.SILENT:
else
define v
\n\033[1mVERBOSE\033[0m:\033[0;33m
endef
endif

# Eventually make this partially user defined, i.e. by expanding a TARGET variable
# or something like that
.PHONY: debug release clean all check makefile_debug directories test
.SUFFIXES:
ifeq ($(DEBUG), )
else
define dbg
$(info $(shell printf "\033[1mDEBUG\033[0m:") $(1))
endef

# Maybe make this use the value of DEBUG
define dbg_var
$(info $(shell printf "\033[1mDEBUG\033[0m:") Variable `$(1)` defined as "$($(1))")
endef
$(call dbg,Debug mode active for Makefile)

$(call dbg_var,CC)
$(call dbg_var,CXX)
$(call dbg_var,OUT)
$(call dbg_var,CFLAGS)
$(call dbg_var,CXXFLAGS)
$(call dbg_var,CPPFLAGS)
$(call dbg_var,LDFLAGS)
$(call dbg_var,DEPFLAGS)
$(call dbg_var,SRC)

# ------- WRITER DEFINED VARIABLES -------

ARTDIR = target
DEPDIR = deps
MKR = .dirstamp
endif

DONE = \033[1;32mDone\033[0m!
ERROR = \033[1;31mFailed\033[0m

NAMES := $(addprefix $(SRC),$(NAMES))
OBJS = $(patsubst %,$(ARTDIR)/$(1)/%.o,$(basename $(SRCS)))
DEPS = $(patsubst %,$(DEPDIR)/$(1)/%.o,$(basename $(SRCS)))

$(call dbg_var,NAMES)
$(call dbg_var,OBJS)
$(call dbg_var,DEPS)

# -------- TARGET DEFINITIONS --------

debug: $(ARTDIR)/debug/$(MKR) $(DEPDIR)/$(MKR) $(call OBJS,$@) $(call DEPS,$@)

release: $(ARTDIR)/release/$(MKR) $(DEPDIR)/$(MKR) $(call OBJS,$@) $(call DEPS,$@)

clean:
	@printf "Cleaning compilation artifacts...$v "
	rm -rf $(ARTDIR)
	rm -rf $(DEPDIR)
	@printf "$(DONE)\n"

directories: $(ARTDIR)/debug/$(MKR) $(ARTDIR)/release/$(MKR) $(DEPDIR)/debug/$(MKR) $(DEPDIR)/release/$(MKR)

check: $(addprefix $(ARTDIR)/check/,$(OBJ_NAMES))
	@printf "Check complete!\n"

makefile_debug:
	$(info $n------- Calling new_recipe,main,$$(TEMPLATE_HEADERS),$$(TEMPLATE_HEADERS) -------)
	$(info $(call new_recipe,main,$(TEMPLATE_HEADERS),$(TEMPLATE_HEADERS)))
	$(info $n------------ Calling path with various arguments ------------)
	$(info $(call path,ARTDIR,debug,))
	$(info $(call path,ARTDIR,release,MKR))
	$(info $(call path,SRC,release,MKR))
	$(info $n-------------- Creating Unique Local Variable ---------------)
	$(info $@_MODE_PATH := $(call path,ARTDIR,debug))

all: directories debug release

# ------- FUNCTION DEFINITIONS -------

# Lowercase
lc = $(subst A,a,$(subst B,b,$(subst C,c,$(subst D,d,$(subst E,e,$(subst F,f,$(subst G,g,$(subst H,h,$(subst I,i,$(subst J,j,$(subst K,k,$(subst L,l,$(subst M,m,$(subst N,n,$(subst O,o,$(subst P,p,$(subst Q,q,$(subst R,r,$(subst S,s,$(subst T,t,$(subst U,u,$(subst V,v,$(subst W,w,$(subst X,x,$(subst Y,y,$(subst Z,z,$1))))))))))))))))))))))))))

# Uppercase
uc = $(subst a,A,$(subst b,B,$(subst c,C,$(subst d,D,$(subst e,E,$(subst f,F,$(subst g,G,$(subst h,H,$(subst i,I,$(subst j,J,$(subst k,K,$(subst l,L,$(subst m,M,$(subst n,N,$(subst o,O,$(subst p,P,$(subst q,Q,$(subst r,R,$(subst s,S,$(subst t,T,$(subst u,U,$(subst v,V,$(subst w,W,$(subst x,X,$(subst y,Y,$(subst z,Z,$1))))))))))))))))))))))))))

# Takes arguments:
define path
$(or $($(1)),$(1))$(addprefix /,$(or $($(2)), $(2)))$(addprefix /,$(or $($(3)),$(3)))
endef

# Generates a newline character
define n


endef

# Takes arguments:
# 1. Compilation mode: either release or debug
make_bold = \033[1m$(1)\033[0m

# Takes arguments:
# 1. Prefix
# 2. Suffix
# 3. Root(s)
addaffix = $(addprefix $(1),$(addsuffix $(2),$(3)))

# Compiles a binary from the object files.
#
# Takes arguments:
# 1. Compilation mode: either release or debug
# 2. File name: name of file without file extension
# 3. Flags: additional flags to pass to the compiler
# define compile_bin
# $(eval $@ERROR_PATH := $(call path,ARTDIR,$(1))/.error)
# $(eval $@OBJ_FILES := $(addprefix $(ARTDIR)/$(1)/,$(OBJ_NAMES)))
# 
# @printf "Building binary in $(call make_bold,$(1)) mode...$v "
# ( \
# 	$(CXX) -o $(OUT) \
# 		$(FLAGS) -lpthread $(3) \
# 		$($@OBJ_FILES) \
# 		2>"$($@ERROR_PATH)" \
# 	&& printf "$(DONE)" \
# 	&& cat "$($@ERROR_PATH)" \
# ) || (printf "$(ERROR)" && cat "$($@ERROR_PATH)" && false)
# endef

# Compiles a single .o file from a single C or C++ file.
#
# Takes arguments:
# 1. Compilation mode: either release or debug
# 2. File name: name of single file without file extension
# 3. Flags: additional flags to pass to the compiler
# define compile_obj
# $(eval $@MODE_PATH := $(call path,ARTDIR,$(1)))
# $(eval $@OBJ_FILE := $(call path,ARTDIR,$(1),$(basename $(2)).o))
# $(eval $@ERROR_PATH := $(call path,ARTDIR,$(1))/.error)
# 
# @printf "Building compilation artifact \`$(basename $(2)).o' in $(call make_bold,$(1)) mode...$v "
# @touch "$($@OBJ_FILE)"
# ( \
# 	$(CXX) -o "$($@OBJ_FILE)" -c \
# 		$(FLAGS) -pthread $(3) \
# 		"$(SRC)/$(2)" 2>"$($@ERROR_PATH)" \
# 	&& printf "$(DONE)" \
# 	&& cat "$($@ERROR_PATH)" \
# ) \
# || ( \
# 	printf "$(ERROR)" \
# 	&& cat "$($@ERROR_PATH)" \
# 	&& rm "$($@OBJ_FILE)" 2>/dev/null \
# 	&& false \
# )
# endef

# Builds the directory structure for a specific compilation mode.
#
# Takes arguments:
# 1. Compilation folder: folder that holds compilation artifacts
define build_dir
	@if [ $(VERBOSE) ]; then \
		printf "$(call make_bold,VERBOSE): Making the directory associated with \`$(call make_bold,$(dir $(1)))' mode...$v "; fi
	mkdir -p $(1) && touch $(1)/$(MKR) && touch $(1)/.error
	@if [ $(VERBOSE) ]; then \
		printf "$(DONE)"; fi
endef

$(DEPDIR)/$(MKR):
	$(call build_dir,$(@D))

$(ARTDIR)/%/$(MKR):
	$(call build_dir,$(@D))


