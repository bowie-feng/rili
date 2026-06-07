.PHONY: build run clean app install

build:
	swift build

run:
	swift run

clean:
	swift package clean
	rm -rf .build
	rm -rf rili.app

release:
	swift build -c release
	@echo "Release binary: .build/release/rili"

app:
	bash scripts/create-app.sh

install: app
	@if [ -d "/Applications/rili.app" ]; then \
		echo "⚠️  Removing existing installation..."; \
		rm -rf /Applications/rili.app; \
	fi
	cp -R rili.app /Applications/
	@echo "✅ Installed to /Applications/rili.app"
	@echo "📌 Launch from Finder or: open /Applications/rili.app"
