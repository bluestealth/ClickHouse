DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS t2_nullable;
DROP TABLE IF EXISTS t2_lc;

CREATE TABLE t1 (`id` Int32, key String, key2 String) ENGINE = TinyLog;
CREATE TABLE t2 (`id` Int32, key String, key2 String) ENGINE = TinyLog;
CREATE TABLE t2_nullable (`id` Int32, key String, key2 Nullable(String)) ENGINE = TinyLog;
CREATE TABLE t2_lc (`id` Int32, key String, key2 LowCardinality(String)) ENGINE = TinyLog;

INSERT INTO t1 VALUES (1, '111', '111'),(2, '222', '2'),(2, '222', '222'),(3, '333', '333');
INSERT INTO t2 VALUES (2, 'AAA', 'AAA'),(2, 'AAA', 'a'),(3, 'BBB', 'BBB'),(4, 'CCC', 'CCC');
INSERT INTO t2_nullable VALUES (2, 'AAA', 'AAA'),(2, 'AAA', 'a'),(3, 'BBB', NULL),(4, 'CCC', 'CCC');
INSERT INTO t2_lc VALUES (2, 'AAA', 'AAA'),(2, 'AAA', 'a'),(3, 'BBB', 'BBB'),(4, 'CCC', 'CCC');

SELECT '-- hash_join --';

SELECT '--';
SELECT t1.key, t1.key2 FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2;
SELECT '--';
SELECT t1.key, t1.key2 FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2;

SELECT '--';
SELECT t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2;

SELECT '--';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t2.id > 2;
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t2.id == 3;
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t2.key2 == 'BBB';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t1.key2 == '333';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2_nullable as t2 ON t1.id == t2.id AND (t2.key == t2.key2 OR isNull(t2.key2)) AND t1.key == t1.key2 AND t1.key2 == '333';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2_lc as t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t1.key2 == '333';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2_nullable as t2 ON t1.id == t2.id AND isNull(t2.key2);
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2_nullable as t2 ON t1.id == t2.id AND t1.key2 like '33%';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t1.id >= length(t1.key);

-- DISTINCT is used to remove the difference between 'hash' and 'merge' join: 'merge' doesn't support `any_join_distinct_right_table_keys`

SELECT '--';
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2_nullable as t2 ON t1.id == t2.id AND t2.key2 != '';
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toNullable(t2.key2 != '');
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toLowCardinality(t2.key2 != '');
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toLowCardinality(toNullable(t2.key2 != ''));
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toNullable(toLowCardinality(t2.key2 != ''));
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toNullable(t1.key2 != '');
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toLowCardinality(t1.key2 != '');
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toLowCardinality(toNullable(t1.key2 != ''));
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toNullable(toLowCardinality(t1.key2 != ''));

SELECT '--';
SELECT DISTINCT t1.key, toUInt8(t1.id) as e FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND e; 
-- `e + 1` is UInt16
SELECT DISTINCT t1.key, toUInt8(t1.id) as e FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND e + 1; -- { serverError 403 }
SELECT DISTINCT t1.key, toUInt8(t1.id) as e FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toUInt8(e + 1); 

SELECT '--';
SELECT t1.id, t1.key, t1.key2, t2.id, t2.key, t2.key2  FROM t1 FULL JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 ORDER BY t1.id, t2.id;

SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t1.id; -- { serverError 403 }
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t2.id; -- { serverError 403 }
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t1.id + 2; -- { serverError 403 }
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t2.id + 2; -- { serverError 403 }
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t1.key; -- { serverError 403 }
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t2.key; -- { serverError 403 }
SELECT * FROM t1 JOIN t2 ON t2.key == t2.key2 AND (t1.id == t2.id OR isNull(t2.key2)); -- { serverError 403 }
SELECT * FROM t1 JOIN t2 ON t2.key == t2.key2 OR t1.id == t2.id; -- { serverError 403 }
SELECT * FROM t1 JOIN t2 ON (t2.key == t2.key2 AND (t1.key == t1.key2 AND t1.key != 'XXX' OR t1.id == t2.id)) AND t1.id == t2.id; -- { serverError 403 }
-- non-equi condition containing columns from different tables doesn't supported yet
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t1.id >= t2.id; -- { serverError 403 }
SELECT * FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t1.id >= length(t2.key); -- { serverError 403 }

SELECT '--';
-- length(t1.key2) == length(t2.key2) is expression for columns from both tables, it works because it part of joining key
SELECT t1.*, t2.* FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND length(t1.key2) == length(t2.key2) AND t1.key != '333';

SET join_algorithm = 'partial_merge';

SELECT '-- partial_merge --';

SELECT '--';
SELECT t1.key, t1.key2 FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2;
SELECT '--';
SELECT t1.key, t1.key2 FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2;

SELECT '--';
SELECT t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2;

SELECT '--';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t2.id > 2;
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t2.id == 3;
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t2.key2 == 'BBB';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t1.key2 == '333';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2_nullable as t2 ON t1.id == t2.id AND (t2.key == t2.key2 OR isNull(t2.key2)) AND t1.key == t1.key2 AND t1.key2 == '333';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2_lc as t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t1.key2 == '333';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2_nullable as t2 ON t1.id == t2.id AND isNull(t2.key2);
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2_nullable as t2 ON t1.id == t2.id AND t1.key2 like '33%';
SELECT '333' = t1.key FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t1.id >= length(t1.key);

-- DISTINCT is used to remove the difference between 'hash' and 'merge' join: 'merge' doesn't support `any_join_distinct_right_table_keys`

SELECT '--';
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2_nullable as t2 ON t1.id == t2.id AND t2.key2 != '';
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toNullable(t2.key2 != '');
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toLowCardinality(t2.key2 != '');
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toLowCardinality(toNullable(t2.key2 != ''));
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toNullable(toLowCardinality(t2.key2 != ''));
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toNullable(t1.key2 != '');
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toLowCardinality(t1.key2 != '');
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toLowCardinality(toNullable(t1.key2 != ''));
SELECT DISTINCT t1.id FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toNullable(toLowCardinality(t1.key2 != ''));

SELECT '--';
SELECT DISTINCT t1.key, toUInt8(t1.id) as e FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND e; 
-- `e + 1` is UInt16
SELECT DISTINCT t1.key, toUInt8(t1.id) as e FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND e + 1; -- { serverError 403 }
SELECT DISTINCT t1.key, toUInt8(t1.id) as e FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND toUInt8(e + 1); 

SELECT '--';
SELECT t1.id, t1.key, t1.key2, t2.id, t2.key, t2.key2  FROM t1 FULL JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 ORDER BY t1.id, t2.id;

SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t1.id; -- { serverError 403 }
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t2.id; -- { serverError 403 }
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t1.id + 2; -- { serverError 403 }
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t2.id + 2; -- { serverError 403 }
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t1.key; -- { serverError 403 }
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t2.key; -- { serverError 403 }
SELECT * FROM t1 JOIN t2 ON t2.key == t2.key2 AND (t1.id == t2.id OR isNull(t2.key2)); -- { serverError 403 }
SELECT * FROM t1 JOIN t2 ON t2.key == t2.key2 OR t1.id == t2.id; -- { serverError 403 }
SELECT * FROM t1 JOIN t2 ON (t2.key == t2.key2 AND (t1.key == t1.key2 AND t1.key != 'XXX' OR t1.id == t2.id)) AND t1.id == t2.id; -- { serverError 403 }
-- non-equi condition containing columns from different tables doesn't supported yet
SELECT * FROM t1 INNER ALL JOIN t2 ON t1.id == t2.id AND t1.id >= t2.id; -- { serverError 403 }
SELECT * FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND t2.key == t2.key2 AND t1.key == t1.key2 AND t1.id >= length(t2.key); -- { serverError 403 }

SELECT '--';
-- length(t1.key2) == length(t2.key2) is expression for columns from both tables, it works because it part of joining key
SELECT t1.*, t2.* FROM t1 INNER ANY JOIN t2 ON t1.id == t2.id AND length(t1.key2) == length(t2.key2) AND t1.key != '333';

DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS t2_nullable;
DROP TABLE IF EXISTS t2_lc;
