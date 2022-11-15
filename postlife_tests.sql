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
    RETURN NEXT has_sequence('generation_seq');
    RETURN NEXT has_table('universe');
    RETURN NEXT columns_are('universe', array [ 'generation', 'state' ]);
    RETURN NEXT col_type_is('universe', 'generation', 'integer');
    RETURN NEXT col_type_is('universe', 'state', 'integer[]');
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
    RETURN NEXT is(
            current_generation(),
            array [[0,0,0],[1,0,1],[0,1,0]],
            'current_generation() should return state of last added generation');
END
$FUN$;

DROP FUNCTION IF EXISTS test_function_current_generation_rank;
CREATE FUNCTION test_function_current_generation_rank()
    RETURNS SETOF TEXT
    LANGUAGE plpgsql AS
$FUN$
BEGIN
    RETURN NEXT is(
            current_generation_rank(), 3, 'current_generation_rank() should return rank of last added generation');
END
$FUN$;

DROP FUNCTION IF EXISTS test_function_number_of_neighbors;
CREATE FUNCTION test_function_number_of_neighbors()
    RETURNS SETOF TEXT
    LANGUAGE plpgsql AS
$FUN$
BEGIN
    RETURN NEXT is(
            number_of_neighbors(1, 2, array [[0,0,0],[0,1,1],[1,1,1]]),
            3,
            'number_of_neighbors() should return number of living neighbors at (x,y)');
END
$FUN$;

DROP FUNCTION IF EXISTS test_function_policy;
CREATE FUNCTION test_function_policy()
    RETURNS SETOF TEXT
    LANGUAGE plpgsql AS
$FUN$
BEGIN
    RETURN NEXT is(policy(1, 0), 0, 'policy() should return off cell if on cell with 0 neighbors');
    RETURN NEXT is(policy(1, 1), 0, 'policy() should return off cell if on cell with 1 neighbor');

    RETURN NEXT is(policy(1, 2), 1, 'policy() should return on cell if on cell with 2 neighbors');
    RETURN NEXT is(policy(1, 3), 1, 'policy() should return on cell if on cell with 3 neighbors');

    FOR n IN 4..9
        LOOP
            RETURN NEXT is(policy(1, n), 0,
                           'policy() should return off cell if on cell with ' || n::text || ' neighbors');
        END LOOP;

    RETURN NEXT is(policy(0, 3), 1, 'policy() should return on cell if off cell with 3 neighbors');
END
$FUN$;

DROP FUNCTION IF EXISTS test_function_step_next;
CREATE FUNCTION test_function_step_next()
    RETURNS SETOF TEXT
    LANGUAGE plpgsql AS
$FUN$
BEGIN
    PERFORM reset_game();
    PERFORM add_generation(array [
        [0,0,0],
        [0,1,1],
        [1,1,1],
        [0,0,0]]);

    PERFORM step_next();
    RETURN NEXT is(
            current_generation(),
            array [
                [0,0,0],
                [1,0,1],
                [1,0,1],
                [0,1,0]],
            'step_next() should update state with new generation');

    RETURN NEXT is(
            step_next(),
            array [
                [0,0,0],
                [0,0,0],
                [1,0,1],
                [0,1,0]],
            'step_next() should return new generation');

    RETURN NEXT is(
            step_next(),
            array [
                [0,0,0],
                [0,0,0],
                [0,1,0],
                [0,1,0]],
            'step_next() should return new generation');

    RETURN NEXT is(
            step_next(),
            array [
                [0,0,0],
                [0,0,0],
                [0,0,0],
                [0,0,0]],
            'step_next() should return new generation');

END
$FUN$;

SELECT *
FROM runtests();
