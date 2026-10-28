.PHONY: help apk apk-debug bundle clean test analyze

v ?=

help:
	@echo "Available commands:"
	@echo "  make apk [v=1.0.3+5]       - Build Release APK with App Name + Version + Timestamp"
	@echo "  make apk-debug [v=1.0.3+5] - Build Debug APK with App Name + Version + Timestamp"
	@echo "  make bundle [v=1.0.3+5]    - Build Release AAB for Play Store"
	@echo "  make test                  - Run all tests"
	@echo "  make analyze               - Run Flutter analyzer"
	@echo "  make clean                 - Clean build artifacts"

apk:
	@./build.sh release $(v)

apk-debug:
	@./build.sh debug $(v)

bundle:
	@./build.sh bundle $(v)

test:
	@flutter test

analyze:
	@flutter analyze

clean:
	@flutter clean
