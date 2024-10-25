# Name of the output executable
EXECUTABLE = simulator

# Bison and Flex files
BISON_FILE = ca.y
FLEX_FILE = ca.l

# Generated files
BISON_C_FILE = ca.tab.c
FLEX_C_FILE = lex.yy.c
BISON_HEADER = ca.tab.h

# Compiler
CC = gcc

# Default target
all: $(EXECUTABLE)

# Build the executable
$(EXECUTABLE): $(BISON_C_FILE) $(FLEX_C_FILE)
	$(CC) $(BISON_C_FILE) $(FLEX_C_FILE) -ll -o $(EXECUTABLE)

# Generate Bison C file and header
$(BISON_C_FILE): $(BISON_FILE)
	bison -d $(BISON_FILE)

# Generate Flex C file
$(FLEX_C_FILE): $(FLEX_FILE)
	flex $(FLEX_FILE)

# Clean up generated files
clean:
	rm -f $(EXECUTABLE) $(BISON_C_FILE) $(BISON_HEADER) $(FLEX_C_FILE)

.PHONY: all clean
