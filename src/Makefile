# Makefile for pcm8a

ifeq ($(notdir $(CURDIR)),src)
$(error do not execute make in src directory)
endif

AS	= has060
ASFLAGS	=
LD	?= hlkx
LDFLAGS	=
U8TOSJ	= u8tosj

BINDIR	= /usr/local/bin
MANDIR	= /usr/local/man/cat1

SRCS	= pcm8a.s
OBJS	= $(SRCS:.s=.o)
PCM8A_X	= pcm8a.x
DOCS	= CHANGELOG.txt README.txt

ARCHIVE_ZIP = pcm8a.zip


.PHONY: all archive clean

all: $(PCM8A_X)


$(PCM8A_X): $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)

%.o: %.s
	$(AS) $(ASFLAGS) $<


ifdef SRC_DIR
archive: $(ARCHIVE_ZIP)
else
archive: ../srcdir.txt
	$(if $(SRC_DIR_IS_DEFINED),$(error SRC_DIR is empty.))
	make $@ SRC_DIR_IS_DEFINED=yes SRC_DIR=$(shell cat ../srcdir.txt)
../srcdir.txt:
	$(error file 'srcdir.txt' created by src2build is required.)
endif

$(ARCHIVE_ZIP): $(DOCS) $(PCM8A_X)
	rm -f $@
	zip -9 $@ $^

%.txt: $(SRC_DIR)/../%.md
	rm -f $@
	$(U8TOSJ) < $^ > $@


install:
	cp -p $(PCM8A_X) $(BINDIR)
	cp -p $(DOCS) $(MANDIR)

clean:
	rm -f $(PCM8A_X) $(OBJS) $(ARCHIVE_ZIP)


# EOF
