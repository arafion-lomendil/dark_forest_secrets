-- Информация о таблицах. Выведем названия всех таблиц схемы fantasy.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'fantasy';

-- Данные в таблице users. Получим информацию о названии полей таблицы и типе данных в них, а также присоединим информацию о первичных и внешних ключах.
SELECT 
    c.table_schema,
    c.table_name,
    c.column_name,
    c.data_type,
    kcu.constraint_name
FROM information_schema.columns c
LEFT JOIN information_schema.key_column_usage kcu
    ON c.table_schema = kcu.table_schema
    AND c.table_name = kcu.table_name
    AND c.column_name = kcu.column_name
WHERE c.table_schema = 'fantasy'
    AND c.table_name = 'users';

-- Вывод первых строк таблицы users. Выведем первые пять строк таблицы, а также добавим поле row_count с подсчётом общего количества строк в таблице. 
SELECT *,
       COUNT(*) OVER() AS row_count
FROM fantasy.users
ORDER BY id
LIMIT 5;

-- Проверка пропусков в таблице users. Посчитаем общее количество строк с пропусками в любом из полей, которые понадобятся при анализе.
SELECT COUNT(*)
FROM fantasy.users
WHERE class_id IS NULL
      OR ch_id IS NULL
      OR pers_gender IS NULL
      OR server IS NULL
      OR race_id IS NULL
      OR payer IS NULL
      OR loc_id IS NULL;

-- Знакомство с категориальными данными таблицы users. Выведем уникальные значения в поле server таблицы users и для каждого сервера найдём количество строк.
SELECT DISTINCT server,
       COUNT(*)
FROM fantasy.users
GROUP BY server;

-- Знакомство с таблицей events. Выведем названия всех полей, их тип данных и информацию о ключевых полях таблицы.
SELECT c.table_schema,
       c.table_name,
       c.column_name,
       c.data_type,
       k.constraint_name
FROM information_schema.columns AS c 
-- Присоединяем данные с ограничениями полей.
LEFT JOIN information_schema.key_column_usage AS k 
    USING(table_name, column_name, table_schema)
-- Фильтруем результат по названию схемы и таблицы.
WHERE table_schema = 'fantasy' AND table_name = 'events'
ORDER BY c.table_name;

-- Выведем первые пять строк таблицы events и добавим поле с количеством строк.
SELECT *,
       COUNT(*) OVER () AS row_count
FROM fantasy.events
LIMIT 5;

-- Проверка пропусков в таблице events. Посмотрим, есть ли строки с пропусками в полях, которые будут использоваться при анализе.
SELECT
    COUNT(*) FILTER (WHERE date IS NULL) AS missing_date,
    COUNT(*) FILTER (WHERE time IS NULL) AS missing_time,
    COUNT(*) FILTER (WHERE amount IS NULL) AS missing_amount,
    COUNT(*) FILTER (WHERE seller_id IS NULL) AS missing_seller_id
FROM fantasy.events;
