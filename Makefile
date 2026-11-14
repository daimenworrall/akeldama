SHELL := /bin/bash

.PHONY: help setup editor run \
	export-dev export-prod \
	upload-dev upload-prod clean

help:
	@echo "Available targets:"
	@echo "  make setup        # Download/extract third-party dependencies (GodotSteam)"
	@echo "  make editor       # Open the GodotSteam editor"
	@echo "  make run          # Run game in dev mode"
	@echo "  make export-dev   # Export all dev builds"
	@echo "  make export-prod  # Export all production builds"
	@echo "  make upload-dev  # Upload dev build folders to Steam"
	@echo "  make upload-prod # Upload production build folders to Steam"
	@echo "  make clean        # Remove build outputs"

setup:
	./scripts/setup/setup-third-party.sh

editor:
	./third_party/godotsteam/v4.17.1/GodotSteam.app/Contents/MacOS/Godot --editor --path .

run:
	./scripts/run.sh

export-dev:
	STAGE=dev ./scripts/release/export.sh

export-prod:
	STAGE=prod ./scripts/release/export.sh

upload-dev:
	STAGE=dev ./scripts/release/upload.sh

upload-prod:
	STAGE=prod ./scripts/release/upload.sh

clean:
	rm -rf build
