CXX := gcc

MSG_START := "Build Started"
MSG_END   := "Build Complete"
MSG_CLEAN := "Cleaning up"

# Directories for build and source files
BUILD_DIR := ./bin
SRC_DIR   := ./src

# Target output binary
TARGET := $(BUILD_DIR)/prog

# Source file
SRC := ${SRC_DIR}/main.c

# All target
all: build

# Build process
build:
	@echo ${MSG_START}
	${CXX} -o ${TARGET} ${SRC} -I.  # Compile source into target binary
	@echo ${MSG_END}
	@${TARGET}  # Run the program after build

# Clean up build artifacts
clean:
	@echo ${MSG_CLEAN}
	rm -f $(TARGET)  # Remove the compiled binary
