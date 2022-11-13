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

DROP FUNCTION IF EXISTS reset_game;
CREATE FUNCTION reset_game()
    RETURNS VOID LANGUAGE sql AS
$FUN$
DELETE FROM universe WHERE 1=1
$FUN$;

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
RETURNING *
$FUN$;

DROP FUNCTION IF EXISTS current_generation;
CREATE FUNCTION current_generation()
    RETURNS integer[][] LANGUAGE sql AS
$FUN$
SELECT state  FROM universe
ORDER BY generation DESC
LIMIT 1
$FUN$;
