.PHONY: test test-integration format snippets

test:
	@fail=0; \
	for t in $$(find tests -name 'test_*.lua' ! -path 'tests/winbar/*' | sort); do \
		echo "== $$t"; \
		luajit "$$t" || fail=1; \
	done; \
	exit $$fail

# Real-nvim integration tests (require headless nvim, not luajit mocks).
test-integration:
	@fail=0; \
	for t in $$(find tests -name 'test_*.lua' -path 'tests/winbar/*' | sort); do \
		echo "== $$t"; \
		nvim --headless -u NONE -l "$$t" || fail=1; \
	done; \
	exit $$fail

format:
	stylua .

snippets:
	ln -s typescript.json ./snippets/javascript.json
	ln -s typescript.json ./snippets/jsx.json
	ln -s typescript.json ./snippets/tsx.json
