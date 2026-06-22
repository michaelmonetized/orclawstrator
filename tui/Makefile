.PHONY: build run install clean

# Binary name
BINARY=orclawstrator

# Build the binary
build:
	go build -o $(BINARY) ./cmd/orclawstrator

# Run the TUI
run: build
	./$(BINARY)

# Install to /usr/local/bin
install: build
	cp $(BINARY) /usr/local/bin/

# Clean build artifacts
clean:
	rm -f $(BINARY)
	go clean

# Development: rebuild on file changes (requires entr)
dev:
	find . -name '*.go' | entr -r make run
