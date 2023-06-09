# Makefile for pcm8a (convert source code from UTF-8 to Shift_JIS)
#   Do not use non-ASCII characters in this file.

MKDIR_P = mkdir -p
U8TOSJ = u8tosj

SRC_DIR = src
BLD_DIR = build


SRCS = $(wildcard $(SRC_DIR)/*)
SJ_SRCS = $(subst $(SRC_DIR)/,$(BLD_DIR)/,$(SRCS))


.PHONY: all directories clean distclean

all: directories $(SJ_SRCS)

directories: $(BLD_DIR)

$(BLD_DIR):
	$(MKDIR_P) $@


# convert src/* (UTF-8) to build/* (Shift_JIS)
$(BLD_DIR)/%: $(SRC_DIR)/%
	$(U8TOSJ) < $^ >! $@



clean:
	rm -f $(SJ_SRCS)

distclean:
	-rm -f $(SJ_SRCS)
	-rmdir $(BLD_DIR)


# EOF
