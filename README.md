# PostLife - A tricky-to-develop GameOfLife in PL/pgSQL

GameOfLife is an awesome thing, this is a not as awesome implementation using some naïve PL/pgSQL code. It's of course
all developed using TDD, because that's the modern way to code\*!

## Run environment

* Docker Desktop or Docker Engine

## How to use

1. Do a quick `docker compose up -d` to start PostgreSQL
2. Run `install-pgtap.sh` to install unit testing framework into PostgreSQL
3. Issue `postlife.sql` followed by `postlife_tests.sql` and...
4. Be amazed at the test results!
5. Success!

## License

All code licensed under GPL-3.0-only, license text in COPYING file in the repo root.

## Have fun

Please do.

----

\* Not a jab at PostgreSQL or PL/pgSQL, only critique towards my own approach to picking a suitable stack.
