.PHONY: test format snippets 

test:
	./scripts/test

format:
	stylua .

snippets:
	ln -s typescript.json ./snippets/javascript.json
	ln -s typescript.json ./snippets/jsx.json
	ln -s typescript.json ./snippets/tsx.json
