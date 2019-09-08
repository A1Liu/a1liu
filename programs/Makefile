# Dear reader,
#
# I had a lot of fun writing this Makefile (i.e. everything after writer defined
# variables). Please feel free to copy it, but if possible preserve this comment
# block when you do (lines 1 - 11).
#
# Best,
#
# Albert Liu
#
# P.S. I'm pretty sure if you include whitespace in your filenames, this will break.

# -------- USER DEFINED VARIABLES --------
CXX = clang++
FLAGS = --std=c++11 -Wall -Wextra -Wshadow -Wnon-virtual-dtor -Wunused -pedantic -fcolor-diagnostics
OUT = lab

# -MF -MD to auto generate make files
# use include to copy those files into make

SRC = src
NAMES = main.cc argparse.cc output.cc argread.cc maze.cc path.cc genetic.cc
TEMPLATE_HEADERS = thread_pool threadsafe_stack bench
HEADERS = path output argparse argread maze genetic $(TEMPLATE_HEADERS)

# Uncomment this to make this file print out the commands it's calling. You can
# also call make using VERBOSE=1, i.e. `make VERBOSE=1 <target>` for the same
# effect for a specific run.
# VERBOSE = 1


# ------- WRITER DEFINED VARIABLES -------

ART = target
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

DONE = \033[1;32mDone\033[0m!\n
ERROR = \033[1;31mFailed\033[0m:\n\n

# Will have to do conversion from '/' character to '#' character eventually
# And then make a meta-target function and stuff like that
OBJ_NAMES = $(addsuffix .o, $(basename $(NAMES)))

# -------- TARGET DEFINITIONS --------

debug: $(addprefix $(ART)/debug/,$(OBJ_NAMES))
	$(call compile_bin,debug,-O0 -g)

release: $(addprefix $(ART)/release/,$(OBJ_NAMES))
	$(call compile_bin,release,-O3)

clean:
	@printf "Cleaning compilation artifacts...$v "
	rm -rf $(ART)
	@printf "$(DONE)"

directories: $(ART)/debug/$(MKR) $(ART)/release/$(MKR)

check: $(addprefix $(ART)/check/,$(OBJ_NAMES))
	@printf "Check complete!\n"

makefile_debug:
	$(info $n------- Calling new_recipe,main,$$(TEMPLATE_HEADERS),$$(TEMPLATE_HEADERS) -------)
	$(info $(call new_recipe,main,$(TEMPLATE_HEADERS),$(TEMPLATE_HEADERS)))
	$(info $n------------ Calling path with various arguments ------------)
	$(info $(call path,ART,debug,))
	$(info $(call path,ART,release,MKR))
	$(info $(call path,SRC,release,MKR))
	$(info $n-------------- Creating Unique Local Variable ---------------)
	$(info $@_MODE_PATH := $(call path,ART,debug))

all: directories debug release

# ------ META-RECIPE DEFINITIONS -----

# Takes arguments:
define path
$(or $($(1)),$(1))$(addprefix /,$(or $($(2)), $(2)))$(addprefix /,$(or $($(3)),$(3)))
endef

# Handles the creation of a new recipe in a specific compilation mode.
#
# Takes arguments:
# 1. Compilation mode: either release or debug
# 2. File name: name of file without file extension
# 3. Header files: header files of the form %.hpp, without the extension
# 4. Header files: header files of the form %.cc, without the extension
define _new_recipe
$(eval $@OBJ_FILE := $(call path,ART,$(1),$(basename $(2)).o))
$(eval $@DIR_MARKER := $(call path,ART,$(1),MKR))
$($@OBJ_FILE) : $(SRC)/$(2) $(addprefix $(SRC)/,$(3)) $($@DIR_MARKER)
	$$(call compile_obj,$(1),$(2),$(4))
endef

# Handles the creation of a new recipe in all compilation modes.
#
# Takes arguments:
# 1. File name: name of file without file extension
# 2. Header files: header files of the form %.hpp, without the extension
# 3. Header files: header files of the form %.cc, without the extension
define new_recipe
$(call _new_recipe,debug,$(1),$(2),$(3),-O0 -g)

$(call _new_recipe,release,$(1),$(2),$(3),-O3)

$(call _new_recipe,check,$(1),$(2),$(3),-fsyntax-only)
endef

# -------- RECIPE DEFINITIONS --------

$(eval $(call new_recipe,main.cc,$(HEADERS:=.hpp) $(TEMPLATE_HEADERS:=.hpp.cc)))

$(eval $(call new_recipe,argparse.cc,argread.hpp argparse.hpp output.hpp))

$(eval $(call new_recipe,argread.cc,argread.hpp))

$(eval $(call new_recipe,output.cc,output.hpp))

$(eval $(call new_recipe,maze.cc,maze.hpp))

$(eval $(call new_recipe,path.cc,path.hpp maze.hpp output.hpp))

$(eval $(call new_recipe,genetic.cc,genetic.hpp thread_pool.hpp argparse.hpp path.hpp maze.hpp))

# --- HELPER FUNCTION DEFINITIONS ----

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
define compile_bin
$(eval $@ERROR_PATH := $(call path,ART,$(1))/.error)
$(eval $@OBJ_FILES := $(addprefix $(ART)/$(1)/,$(OBJ_NAMES)))

@printf "Building binary in $(call make_bold,$(1)) mode...$v "
( \
	$(CXX) -o $(OUT) \
		$(FLAGS) -lpthread $(3) \
		$($@OBJ_FILES) \
		2>"$($@ERROR_PATH)" \
	&& printf "$(DONE)" \
	&& cat "$($@ERROR_PATH)" \
) || (printf "$(ERROR)" && cat "$($@ERROR_PATH)" && false)
endef

# Compiles a single .o file from a single C or C++ file.
#
# Takes arguments:
# 1. Compilation mode: either release or debug
# 2. File name: name of single file without file extension
# 3. Flags: additional flags to pass to the compiler
define compile_obj
$(eval $@MODE_PATH := $(call path,ART,$(1)))
$(eval $@OBJ_FILE := $(call path,ART,$(1),$(basename $(2)).o))
$(eval $@ERROR_PATH := $(call path,ART,$(1))/.error)

@printf "Building compilation artifact \`$(basename $(2)).o' in $(call make_bold,$(1)) mode...$v "
@touch "$($@OBJ_FILE)"
( \
	$(CXX) -o "$($@OBJ_FILE)" -c \
		$(FLAGS) -pthread $(3) \
		"$(SRC)/$(2)" 2>"$($@ERROR_PATH)" \
	&& printf "$(DONE)" \
	&& cat "$($@ERROR_PATH)" \
) \
|| ( \
	printf "$(ERROR)" \
	&& cat "$($@ERROR_PATH)" \
	&& rm "$($@OBJ_FILE)" 2>/dev/null \
	&& false \
)
endef

# Builds the directory structure for a specific compilation mode.
#
# Takes arguments:
# 1. Compilation mode: either release or debug
define build_dir
	@if [ $(VERBOSE) ]; then \
		printf "$(call make_bold,VERBOSE): Making the directory associated with \`$(call make_bold,$(1))' mode...$v "; fi
	mkdir -p $(ART)/$(1) && touch $(ART)/$(1)/$(MKR) && touch $(ART)/$(1)/.error
	@if [ $(VERBOSE) ]; then \
		printf "$(DONE)"; fi
endef

$(ART)/%/$(MKR):
	$(call build_dir,$*)
