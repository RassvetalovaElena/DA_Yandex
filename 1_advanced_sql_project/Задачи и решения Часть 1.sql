--1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».
SELECT COUNT(p.id)
     FROM stackoverflow.posts AS p 
LEFT JOIN stackoverflow.post_types AS pt
       ON p.post_type_id = pt.id
WHERE pt.type = 'Question' AND (score > 300 OR  favorites_count >= 100);

--2.Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.
SELECT ROUND(AVG(question_cnt))
FROM (
   SELECT creation_date :: date AS question_date,
          COUNT(p.id) AS question_cnt
     FROM stackoverflow.posts AS p 
LEFT JOIN stackoverflow.post_types AS pt
       ON p.post_type_id = pt.id
    WHERE pt.type = 'Question' AND creation_date :: date BETWEEN '2008-11-01' AND '2008-11-18'
 GROUP BY creation_date :: date
      ) AS Question
--3. Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
      SELECT COUNT(DISTINCT u.id) AS user    
    FROM stackoverflow.users AS u
    JOIN stackoverflow.badges AS b
      ON u.id = b.user_id
    WHERE u.creation_date :: date = b.creation_date :: date
--4. Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
    WITH votes_cnts AS (
  SELECT p.id AS id_post,
         COUNT(v.id) AS votes_cnt
    FROM stackoverflow.users AS u
    JOIN stackoverflow.posts AS p
      ON p.user_id = u.id
    JOIN stackoverflow.votes AS v 
      ON v.post_id = p.id
    WHERE display_name = 'Joel Coehoorn'
GROUP BY p.id 
    )
SELECT COUNT(id_post)
  FROM votes_cnts
  WHERE votes_cnt > 0;
  
 --5.Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.
 
 SELECT *,
         RANK() OVER (ORDER BY id DESC)
    FROM stackoverflow.vote_types 
ORDER BY id ;
--6.Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
SELECT v.user_id AS user_votes,
         COUNT (v.id) AS votes_cnt
    FROM stackoverflow.votes AS v
    JOIN stackoverflow.vote_types AS vt
      ON vt.id = v.vote_type_id
   WHERE name = 'Close'  
GROUP BY v.user_id
ORDER BY votes_cnt DESC,
         v.user_id DESC
   LIMIT 10;
  
--7.Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
--Отобразите несколько полей:
--идентификатор пользователя;
--число значков;
--место в рейтинге — чем больше значков, тем выше рейтинг.
--Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
--Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.
SELECT user_id,
         COUNT (id) AS badges_cnt,
         DENSE_RANK() OVER (ORDER BY COUNT (id) DESC )
    FROM stackoverflow.badges
   WHERE creation_date :: date BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY user_id
ORDER BY badges_cnt DESC,
         user_id
   LIMIT 10; 
  
  --8.Сколько в среднем очков получает пост каждого пользователя?
--Сформируйте таблицу из следующих полей:
--заголовок поста;
--идентификатор пользователя;
--число очков поста;
--среднее число очков пользователя за пост, округлённое до целого числа.
--Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
   SELECT title,
       user_id, 
       score,
       ROUND(AVG(score) OVER (PARTITION BY user_id))
   FROM stackoverflow.posts
   WHERE title IS NOT NULL
         AND score != 0;
        
--9.Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.
SELECT title
FROM stackoverflow.posts
WHERE user_id IN (
              SELECT user_id 
              FROM stackoverflow.badges
              GROUP BY user_id
              HAVING COUNT(id) > 1000)
   AND title IS NOT NULL;
--10. Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
--пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
--пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
--пользователям с числом просмотров меньше 100 — группу 3.
--Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.
  SELECT  id,
       views,
       CASE
          WHEN views < 100 THEN 3
          WHEN views >= 100 AND views < 350  THEN 2
          ELSE 1
       END AS group
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND views != 0
ORDER BY views DESC;
--11. Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. Выведите поля с идентификатором пользователя, группой и количеством просмотров. Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.
  WITH us_users AS (
    SELECT id AS user_id,
           views AS views_cnt,
           CASE
              WHEN views < 100 THEN 3
              WHEN views >= 100 AND views < 350  THEN 2
              ELSE 1
           END AS groups
      FROM stackoverflow.users
     WHERE location LIKE '%Canada%' AND views != 0
                )

 SELECT user_id,
        groups,
        views_cnt
   FROM (   
          SELECT user_id,
                 views_cnt,
                 groups,
                 MAX(views_cnt) OVER (PARTITION BY groups ORDER BY views_cnt DESC) AS max_views
            FROM us_users
         ) AS max_us
   WHERE views_cnt =  max_views
ORDER BY views_cnt DESC, user_id;

--12.Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
--номер дня;
--число пользователей, зарегистрированных в этот день;
--сумму пользователей с накоплением.
SELECT days,
       users_cnt,
       SUM(users_cnt) OVER (ORDER BY days)
  FROM (
SELECT EXTRACT (DAY FROM creation_date) AS days,
            COUNT(id) AS users_cnt
       FROM stackoverflow.users
      WHERE creation_date :: date BETWEEN '2008-11-01' AND '2008-11-30'
   GROUP BY EXTRACT (DAY FROM creation_date)
        ) AS user_november;
-- 13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
--идентификатор пользователя;
--разницу во времени между регистрацией и первым постом.
       
SELECT DISTINCT p.user_id,
          MIN(p.creation_date ) OVER (PARTITION BY p.user_id) - u.creation_date  AS interval
     FROM stackoverflow.posts  AS p
LEFT JOIN stackoverflow.users AS u
       ON p.user_id =  u.id;
  
  