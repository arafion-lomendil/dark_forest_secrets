/* Проект «Секреты Тёмнолесья»
 Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 на покупку внутриигровой валюты «райские лепестки», а также оценить 
 активность игроков при совершении внутриигровых покупок
 
 Автор: Денис Рубцов
 Дата: 20.11.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT COUNT(id) AS total_users,
	   SUM(payer) AS payers,
	   ROUND(AVG(payer),4) AS paying_users_share
FROM fantasy.users;
-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT race, 
	   SUM(payer) AS payers,
	   COUNT(id) AS total_users,
	   ROUND(AVG(payer),4) AS paying_users_share
FROM fantasy.users
LEFT JOIN fantasy.race
USING (race_id)
GROUP BY 1
ORDER BY 4 DESC;
-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT COUNT(amount) AS total_amt,
	   SUM(amount) AS sum_amt,
	   MIN(amount) AS min_amt,
	   MAX(amount) AS max_amt,
	   ROUND(AVG(amount)::NUMERIC,4) AS average_amt,
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS amt_mediane,
	   ROUND(STDDEV(amount)::NUMERIC,4) AS amt_deviation
FROM fantasy.events
UNION
SELECT COUNT(amount),
	   SUM(amount),
	   MIN(amount),
	   MAX(amount),
	   ROUND(AVG(amount)::NUMERIC,4),
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount),
	   ROUND(STDDEV(amount)::NUMERIC,4)
FROM fantasy.events
WHERE amount > 0
ORDER BY 1 DESC;
-- 2.2: Аномальные нулевые покупки:
SELECT COUNT(*) AS total_pay,
	   COUNT(*) FILTER (WHERE amount = 0) AS null_pay,
	   ROUND(COUNT(*) FILTER (WHERE amount = 0) / COUNT(*)::NUMERIC,4) AS perc_pay
FROM fantasy.events;
--Подсчет пользователей, совершивших нулевые покупки:
WITH total_zero AS (
SELECT COUNT(game_items) AS total_zero
FROM fantasy.items
LEFT JOIN fantasy.events e USING (item_code)
WHERE amount = 0
)
SELECT id,
	   game_items,
	   COUNT(game_items)	 AS zero_item_count,	   
	   ROUND(COUNT(game_items) / total_zero::NUMERIC,4) AS zero_item_share
FROM fantasy.items i
LEFT JOIN fantasy.events e USING (item_code)
CROSS JOIN total_zero
WHERE amount = 0
GROUP BY id, 
		 game_items,
		 total_zero
ORDER BY 3 DESC;
-- 2.3: Популярные эпические предметы:
WITH total_amt_users AS (
SELECT COUNT(amount) AS total_amt,
	   COUNT(DISTINCT id) AS total_users
FROM fantasy.events
WHERE amount <> 0
)
SELECT game_items,
	   COUNT(transaction_id) AS absolute_amt,
	   ROUND(COUNT(*) / total_amt::NUMERIC,4) AS relative_amt,
	   COUNT(DISTINCT id) AS users_per_item,
	   ROUND(COUNT(DISTINCT id) / total_users::NUMERIC,4) AS users_share
FROM fantasy.items
LEFT JOIN fantasy.events e USING (item_code)
CROSS JOIN total_amt_users
WHERE amount <> 0
GROUP BY game_items,
		 total_amt,
		 total_users
ORDER BY 2 DESC;
-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:
WITH ingame_purchase_players AS (
SELECT race,
	   COUNT(DISTINCT e.id) AS ingame_purc_users,
	   COUNT(amount)/ COUNT(DISTINCT e.id) AS avg_cnt_per_user,
	   ROUND(AVG(amount)::NUMERIC,4) AS avg_amt_per_user,
	   ROUND((SUM(amount)/ COUNT(DISTINCT e.id))::NUMERIC,4) AS avg_total_amt_pet_user
FROM fantasy.race r
JOIN fantasy.users u  USING (race_id)
JOIN fantasy.events e USING (id)
WHERE amount <> 0
GROUP BY race
),
paying_players AS (
SELECT race,
	   COUNT(DISTINCT u.id) AS paying_users
FROM fantasy.race r
JOIN fantasy.users u  USING (race_id)
JOIN fantasy.events e USING (id)
WHERE payer = 1 AND amount <> 0
GROUP BY race
)
SELECT r.race,
	   COUNT(u.id) AS total_users,
	   ingame_purc_users,
	   ROUND(ingame_purc_users / COUNT(u.id)::NUMERIC,4) AS ingame_purc_users_share,
	   paying_users,
	   ROUND(paying_users / ingame_purc_users::NUMERIC,4) AS paying_users_share,
	   avg_cnt_per_user,
	   avg_amt_per_user,
	   avg_total_amt_pet_user
FROM fantasy.race r
JOIN fantasy.users u USING (race_id)
JOIN ingame_purchase_players ing USING (race)
JOIN paying_players p USING (race)
GROUP BY r.race,
	  	 ingame_purc_users, 
	  	 paying_users, 
	  	 avg_cnt_per_user,
	  	 avg_amt_per_user,
	  	 avg_total_amt_pet_user
ORDER BY 8 DESC;

