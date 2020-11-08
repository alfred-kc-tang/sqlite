-- Setup.
.headers on
.separator ','

DROP TABLE IF EXISTS sets;
DROP TABLE IF EXISTS themes;
DROP TABLE IF EXISTS parts;
DROP VIEW IF EXISTS top_level_themes;
DROP VIEW IF EXISTS sets_years;
DROP TABLE IF EXISTS parts_fts;

-- Create tables.
CREATE TABLE sets(set_num TEXT, name TEXT, year INTEGER, theme_id INTEGER, num_parts INTEGER);
CREATE TABLE themes(id INTEGER, name TEXT, parent_id INTEGER);
CREATE TABLE parts(part_num TEXT, name TEXT, part_cat_id INTEGER, part_material_id INTEGER);

.tables
.print '~~~~~'

-- Import LEGO data.
.import data/sets.csv sets
.import data/themes.csv themes
.import data/parts.csv parts

.headers off
SELECT COUNT(*) FROM sets;
SELECT COUNT(*) FROM parts;
.headers on
.print '~~~~~'

-- Create indexes for speeding up the subsequent operations.
CREATE INDEX sets_index ON sets(set_num);
CREATE INDEX parts_index ON parts(part_num);
CREATE INDEX themes_index ON themes(id);

.indexes
.print '~~~~~'

-- Create the top_level themes VIEW.
CREATE VIEW top_level_themes AS
SELECT id, name FROM themes
WHERE parent_id = '';

.headers off
PRAGMA table_info(top_level_themes);
.headers on
.print '~~~~~'

-- Count the top level themes in the top_level_themes VIEW.
SELECT COUNT(*)
AS count
FROM top_level_themes;

.print '~~~~~'

-- Find the top 10 level themes with the most sets.
SELECT t1.name AS theme, COUNT(t2.set_num) AS num_sets
FROM top_level_themes t1 INNER JOIN sets t2 ON t1.id = t2.theme_id
GROUP BY theme ORDER BY num_sets DESC LIMIT 10;

.print '~~~~~'

-- Show the percentage of the number of sets that belong to the top level themes.
SELECT t1.name AS theme, printf("%.2f", COUNT(t2.set_num) * 100.0 / (SELECT COUNT(*) FROM top_level_themes t1 INNER JOIN sets t2 ON t1.id = t2.theme_id)) AS percentage
FROM top_level_themes t1 INNER JOIN sets t2 on t1.id = t2.theme_id
GROUP BY theme HAVING (COUNT(t2.set_num) * 100.0 / (SELECT COUNT(*) FROM top_level_themes t1 INNER JOIN sets t2 ON t1.id = t2.theme_id)) >= 5.00
ORDER BY percentage DESC;

.print '~~~~~'

-- Summarize the sub-theme of the "Castle" theme.
SELECT t1.name AS sub_theme, COUNT(t2.set_num) AS num_sets
FROM (SELECT * FROM themes WHERE parent_id = 186) t1
INNER JOIN sets t2 ON t1.id = t2.theme_id
GROUP BY sub_theme ORDER BY num_sets DESC, sub_theme;

.print '~~~~~'

-- Create the LEGO sets that have been released over time VIEW
CREATE VIEW sets_years AS
SELECT ROWID, year, COUNT(set_num) AS sets_count
FROM sets GROUP BY year;

.headers off
PRAGMA table_info(sets_years);
SELECT AVG(sets_count) FROM sets_years;
.headers on
.print '~~~~~'

-- Find the running total of sets in the Rebrickable database each year.
SELECT year, SUM(sets_count) OVER (ORDER BY year) AS running_total
FROM sets_years;

.print '~~~~~'

-- Create the Full Text Search (FTS) table and import data.
CREATE VIRTUAL TABLE parts_fts USING fts4(part_num TEXT, name TEXT, part_cat_id INTEGER, part_material_id INTEGER);
.import data/parts.csv parts_fts

.headers off
PRAGMA table_info(parts_fts);
.headers on
.print '~~~~~'

-- Count the number of unique parts whose name field begins with the prefix ‘mini’.
SELECT COUNT(DISTINCT part_num) AS count_overview
FROM (SELECT * FROM parts_fts WHERE name MATCH '^mini*');

.print '~~~~~'

-- List the part_num’s of the unique parts that contain the terms ‘minidoll’ and ‘boy’ in the name field with no more than 5 intervening terms.
SELECT DISTINCT part_num AS part_num_boy_minidoll
FROM (SELECT * FROM parts_fts WHERE name MATCH 'minidoll NEAR/5 boy');

.print '~~~~~'

-- List the part_num’s of the unique parts that contain the terms ‘minidoll’ and ‘girl’ in the name field with no more than 5 intervening terms.
SELECT DISTINCT part_num AS part_num_girl_minidoll
FROM (SELECT * FROM parts_fts WHERE name MATCH 'minidoll NEAR/5 girl');

.print '~~~~~'