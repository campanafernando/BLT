.PHONY: setup api web htmx test check up down logs seed clean

setup:
	cd blt-project && make setup

api:
	cd blt-project && make api

web:
	cd blt-project && make web

htmx:
	@echo "Cliente HTMX: http://127.0.0.1:8000/app/ (a API precisa estar rodando)"

test:
	cd blt-project && make test

check:
	cd blt-project && make check

up:
	cd blt-project && make up

down:
	cd blt-project && make down

logs:
	cd blt-project && docker compose logs -f --tail=100

seed:
	cd blt-project && make seed

clean:
	cd blt-project && make clean
