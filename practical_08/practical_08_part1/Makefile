CXX         := gcc

MSG_START   := "Build Started"
MSG_END     := "Build Complete"
MSG_CLEAN   := "Cleaning up"

BUILD_DIR   := ./bin
SRC_DIR     := ./src

ifeq ($(OS),Windows_NT)
    TARGET  := $(BUILD_DIR)/prog.exe
    RM      := del /Q
    SEP     := \\
else
    TARGET  := $(BUILD_DIR)/prog
    RM      := rm -f
    SEP     := /
endif

SRC         := ${SRC_DIR}/main.c

all         := build

build:
	@echo	${MSG_START}
	${CXX}	-o	${TARGET}	${SRC}	-I.
	@echo	${MSG_END}
	${TARGET}

clean:
	@echo	${MSG_CLEAN}
	$(RM) $(subst /,$(SEP),$(TARGET))