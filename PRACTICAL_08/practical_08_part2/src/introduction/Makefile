# Compiler and build messages
CXX := gcc
MSG_START := "Build Started"
MSG_END := "Build Complete"
MSG_CLEAN := "Cleaning up"

# Directories for build and source files
BUILD_DIR := ./bin
SRC_DIR := ./lesson_01

TARGET := $(BUILD_DIR)/prog

# Source file
SRC := $(SRC_DIR)/main.c

# All target
all: build

# Build process
build:
	@mkdir -p ${BUILD_DIR}
	@echo ${MSG_START}

	${CXX} -o ${TARGET} ${SRC} -I. 
	@echo ${MSG_END}
	@${TARGET}

# Clean up build artifacts
clean:
	@echo ${MSG_CLEAN}
	rm -f $(TARGET) $(BUILD_DIR)/*