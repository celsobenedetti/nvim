.PHONY: test format snippets 

test:
	@fail=0; \
	for t in $$(find tests -name 'test_*.lua' | sort); do \
		echo "== $$t"; \
		luajit "$$t" || fail=1; \
	done; \
	exit $$fail

format:
	stylua .

snippets:
	ln -s typescript.json ./snippets/javascript.json
	ln -s typescript.json ./snippets/jsx.json
	ln -s typescript.json ./snippets/tsx.json
