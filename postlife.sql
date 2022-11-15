-- PostLife - A tricky-to-develop GameOfLife in PL/pgSQL
-- Copyright (C) 2022  Simon Wendel
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

CREATE SCHEMA IF NOT EXISTS postlife;
SET SCHEMA 'postlife';

DROP SEQUENCE IF EXISTS generation_seq CASCADE;
CREATE SEQUENCE generation_seq AS integer;

DROP TABLE IF EXISTS universe;
CREATE TABLE universe
(
    generation integer DEFAULT nextval('generation_seq'),
    state      integer[]
);

DROP FUNCTION IF EXISTS reset_game;
CREATE FUNCTION reset_game()
    RETURNS VOID
    LANGUAGE sql AS
$FUN$
TRUNCATE TABLE universe;
ALTER SEQUENCE generation_seq RESTART WITH 1;
$FUN$;

DROP FUNCTION IF EXISTS add_generation;
CREATE FUNCTION add_generation(new_state integer[])
    RETURNS TABLE
            (
                generation integer,
                state      integer[]
            )
    LANGUAGE sql
AS
$FUN$
INSERT INTO universe (state)
VALUES (new_state)
RETURNING *;
$FUN$;

DROP FUNCTION IF EXISTS current_generation;
CREATE FUNCTION current_generation()
    RETURNS integer[]
    LANGUAGE sql AS
$FUN$
SELECT state
FROM universe
ORDER BY generation DESC
LIMIT 1;
$FUN$;

DROP FUNCTION IF EXISTS current_generation_rank;
CREATE FUNCTION current_generation_rank()
    RETURNS integer
    LANGUAGE sql AS
$FUN$
SELECT generation
FROM universe
ORDER BY generation DESC
LIMIT 1;
$FUN$;

DROP FUNCTION IF EXISTS number_of_neighbors;
CREATE FUNCTION number_of_neighbors(x integer, y integer, state integer[])
    RETURNS integer
    LANGUAGE sql AS
$FUN$
SELECT (SUM(res) - (SELECT state[y][x]))
FROM UNNEST(state[y - 1:y + 1][x - 1:x + 1]) res;
$FUN$;

DROP FUNCTION IF EXISTS policy;
CREATE FUNCTION policy(curr integer, neighbors integer)
    RETURNS integer
    LANGUAGE sql AS
$FUN$
SELECT CASE
           WHEN curr = 0 AND neighbors = 3 THEN 1
           WHEN curr = 1 AND neighbors = ANY (ARRAY [2, 3]) THEN 1
           ELSE 0
           END;
$FUN$;

DROP FUNCTION IF EXISTS step_next;
CREATE FUNCTION step_next()
    RETURNS integer[]
    LANGUAGE plpgsql AS
$FUN$
DECLARE
    curr_state integer[] := current_generation();
    next_state integer[] := current_generation();
    width      integer   := array_upper(curr_state, 2);
    height     integer   := array_upper(curr_state, 1);
    neighbors  integer;
BEGIN
    FOR y IN 1..height
        LOOP
            FOR x IN 1..width
                LOOP
                    neighbors := number_of_neighbors(x, y, curr_state);
                    next_state[y][x] := policy(curr_state[y][x], neighbors);
                END LOOP;
        END LOOP;
    RETURN (SELECT state FROM add_generation(next_state));
END
$FUN$;
