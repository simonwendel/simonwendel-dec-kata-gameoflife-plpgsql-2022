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

SET SCHEMA 'postlife';

DROP FUNCTION IF EXISTS setup_fixture;
CREATE FUNCTION setup_fixture()
    RETURNS SETOF TEXT
    LANGUAGE plpgsql AS
$FUN$
BEGIN
    PERFORM reset_game();
    PERFORM add_generation(array [[0,0,0],[0,1,1],[1,1,1]]);
    PERFORM add_generation(array [[1,0,1],[1,0,1],[0,1,0]]);
    PERFORM add_generation(array [[0,0,0],[1,0,1],[0,1,0]]);
END
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

DROP FUNCTION IF EXISTS test_function_reset_game;
CREATE FUNCTION test_function_reset_game()
    RETURNS SETOF TEXT
    LANGUAGE plpgsql AS
$FUN$
BEGIN
    PERFORM reset_game();
    RETURN NEXT is_empty(
            $$ SELECT * FROM universe $$,
            'reset_game() should clear all generations from universe');
END
$FUN$;

DROP FUNCTION IF EXISTS test_function_add_generation;
CREATE FUNCTION test_function_add_generation()
    RETURNS SETOF TEXT
    LANGUAGE plpgsql AS
$FUN$
BEGIN
    RETURN NEXT results_eq(
            $$ SELECT * FROM universe $$,
            $$ VALUES
                (1,array [[0,0,0],[0,1,1],[1,1,1]]),
                (2,array [[1,0,1],[1,0,1],[0,1,0]]),
                (3,array [[0,0,0],[1,0,1],[0,1,0]])
            $$,
            'universe should contain two generations');
END
$FUN$;

DROP FUNCTION IF EXISTS test_function_current_generation;
CREATE FUNCTION test_function_current_generation()
    RETURNS SETOF TEXT
    LANGUAGE plpgsql AS
$FUN$
BEGIN
    RETURN NEXT results_eq(
            $$ SELECT * FROM current_generation() $$,
            $$ VALUES (array [[0,0,0],[1,0,1],[0,1,0]]) $$,
            'current_generation() should return state of last added generation');
END
$FUN$;

SELECT *
FROM runtests();
