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

DROP TABLE IF EXISTS universe;
CREATE TABLE universe
(
    generation serial,
    state      integer[][]
);

DROP FUNCTION IF EXISTS add_generation;
CREATE FUNCTION add_generation(new_state integer[][])
    RETURNS TABLE
            (
                generation integer,
                state      integer[][]
            )
    LANGUAGE sql
AS
$FUN$
INSERT INTO universe (state)
VALUES (new_state)
RETURNING *;
$FUN$;

DROP FUNCTION IF EXISTS test_schema;
CREATE FUNCTION test_schema()
    RETURNS SETOF TEXT
    LANGUAGE plpgsql AS
$FUN$
BEGIN
    RETURN NEXT has_table('universe');
    RETURN NEXT (SELECT columns_are('universe', array [ 'generation', 'state' ]));
END
$FUN$;

DROP FUNCTION IF EXISTS test_function_add_generation;
CREATE FUNCTION test_function_add_generation()
    RETURNS SETOF TEXT
    LANGUAGE plpgsql AS
$FUN$
BEGIN
    PERFORM add_generation(array [[0,0,0],[0,1,1],[1,1,1]]);
    PERFORM add_generation(array [[1,0,1],[1,0,1],[0,1,0]]);
    RETURN NEXT results_eq(
            $$ SELECT * FROM universe $$,
            $$ VALUES
                (1,array [[0,0,0],[0,1,1],[1,1,1]]),
                (2,array [[1,0,1],[1,0,1],[0,1,0]])
            $$,
            'universe should contain two generations');
END
$FUN$;

SELECT *
FROM runtests();
