--1. Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.
SELECT CAST(DATE_TRUNC('month', creation_date) AS date) AS month_posts,
         SUM(views_count) AS views_count
    FROM stackoverflow.posts
   WHERE EXTRACT (YEAR FROM creation_date) = '2008'
GROUP BY month_posts
ORDER BY views_count DESC;

--2.Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. Отсортируйте результат по полю с именами в лексикографическом порядке.
SELECT u.display_name,
         COUNT(DISTINCT p.user_id)
    FROM stackoverflow.users u
    JOIN stackoverflow.posts p 
      ON u.id = p.user_id
    JOIN stackoverflow.post_types pt 
      ON p.post_type_id = pt.id
   WHERE p.creation_date::date BETWEEN u.creation_date::date AND u.creation_date::date + INTERVAL '1 month' AND pt.type = 'Answer'
GROUP BY u.display_name
  HAVING COUNT(DISTINCT p.id) > 100

--3.Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.

SELECT CAST(DATE_TRUNC('month', p.creation_date) AS date) AS month_posts,
         COUNT (DISTINCT id) AS user_count
    FROM stackoverflow.posts AS p 
   WHERE user_id IN (
                  SELECT DISTINCT u.id
                    FROM stackoverflow.users AS u
                    JOIN stackoverflow.posts AS p
                      ON p.user_id = u.id
                   WHERE u.creation_date :: date BETWEEN '2008-09-01' AND '2008-09-30'
                     AND p.creation_date :: date BETWEEN '2008-12-01' AND '2008-12-31'
                    )
     AND p.creation_date :: date BETWEEN '2008-01-01' AND '2008-12-31'
GROUP BY month_posts
ORDER BY month_posts DESC

--4. Используя данные о постах, выведите несколько полей:
--идентификатор пользователя, который написал пост;
--дата создания поста;
--количество просмотров у текущего поста;
--сумма просмотров постов автора с накоплением.
--Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.
SELECT user_id,
         creation_date,
         views_count,
         SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date)
    FROM stackoverflow.posts 
ORDER BY user_id, 
         creation_date;
--5. Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число — не забудьте округлить результат.
SELECT ROUND(AVG (active_days))
FROM (
      SELECT user_id,
             COUNT(DISTINCT creation_date :: date) AS active_days
        FROM stackoverflow.posts 
       WHERE creation_date :: date BETWEEN '2008-12-01' AND '2008-12-07'
    GROUP BY user_id 
    ) AS cnt;
   
-- 6. На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
--Номер месяца.
--Количество постов за месяц.
--Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
--Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.
--Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз. Чтобы этого избежать, переведите делимое в тип numeric.
WITH posts_month AS (
      SELECT EXTRACT (MONTH FROM creation_date) AS month_number,
             COUNT(id) AS posts_cnt
        FROM stackoverflow.posts 
       WHERE creation_date :: date BETWEEN '2008-09-01' AND '2008-12-31'
    GROUP BY EXTRACT (MONTH FROM creation_date) 
    ORDER BY month_number
)
                     
SELECT *,
       ROUND(( posts_cnt -LAG(posts_cnt) OVER () ) * 100 / LAG(posts_cnt) OVER () :: numeric, 2)
  FROM posts_month
  
-- 7. Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. Выведите данные его активности за октябрь 2008 года в таком виде:
--номер недели;
--дата и время последнего поста, опубликованного на этой неделе.
  WITH week AS (   
      SELECT EXTRACT(WEEK FROM creation_date) AS week_number,
             MAX(creation_date) OVER (ORDER BY EXTRACT(WEEK FROM creation_date))
        FROM stackoverflow.posts 
       WHERE user_id = (
                 SELECT user_id
                   FROM stackoverflow.posts 
               GROUP BY user_id 
               ORDER BY COUNT(id) DESC
                  LIMIT 1
                     ) 
        AND creation_date :: date BETWEEN '2008-10-01' AND '2008-10-31'          
   ORDER BY creation_date
             )
   
  SELECT DISTINCT *
    FROM week
ORDER BY week_number


