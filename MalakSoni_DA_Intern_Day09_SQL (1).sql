SELECT * FROM artist;
SELECT * FROM canvas_size;
SELECT * FROM museum;
SELECT * FROM museum_hours;
SELECT * FROM product_size;
SELECT * FROM subject;
SELECT * FROM workk;
SELECT * FROM image_link;

SELECT w.work_id, w.name
FROM workk w
LEFT JOIN museum m ON w.museum_id = m.museum_id
WHERE m.museum_id IS NULL;

SELECT m.museum_id, m.name
FROM museum m
LEFT JOIN workk w ON m.museum_id = w.museum_id
WHERE w.museum_id IS NULL;

SELECT COUNT(*)
FROM product_size
WHERE sale_price > regular_price;

SELECT ps.work_id
FROM product_size ps
WHERE sale_price < 0.5 * regular_price;


SELECT ps.size_id, MAX(ps.sale_price) AS max_price
FROM product_size ps
GROUP BY ps.size_id
ORDER BY max_price DESC
LIMIT 1;

DELETE FROM workk
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM workk
    GROUP BY work_id
);

DELETE FROM product_size
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM product_size
    GROUP BY work_id, size_id
);

DELETE FROM subject
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM subject
    GROUP BY work_id, subject
);

DELETE FROM image_link
WHERE ctid NOT IN (
    SELECT MIN(ctid)
    FROM image_link
    GROUP BY work_id, url, thumbnail_small_url, thumbnail_large_url
);

SELECT museum_id, name, city
FROM museum
WHERE city IS NULL OR city = '';



DELETE FROM museum_hours
WHERE (museum_id, day, open, close) IN (
    SELECT museum_id, day, open, close
    FROM (
        SELECT museum_id, day, open, close, COUNT(*) OVER (PARTITION BY museum_id, day, open, close) AS cnt
        FROM museum_hours
    ) sub
    WHERE cnt > 1
    LIMIT 1
);

SELECT subject, COUNT(work_id) AS subject_count
FROM subject
GROUP BY subject
ORDER BY subject_count DESC
LIMIT 10;


SELECT m.name, m.city
FROM museum m
JOIN museum_hours mh1 ON m.museum_id = mh1.museum_id AND mh1.day = 'Sunday'
JOIN museum_hours mh2 ON m.museum_id = mh2.museum_id AND mh2.day = 'Monday';



SELECT COUNT(DISTINCT m.museum_id) AS open_everyday_count
FROM museum m
JOIN museum_hours mh ON m.museum_id = mh.museum_id
GROUP BY m.museum_id
HAVING COUNT(DISTINCT mh.day) = 7;


SELECT m.name, COUNT(w.work_id) AS painting_count
FROM museum m
JOIN workk w ON m.museum_id = w.museum_id
GROUP BY m.name
ORDER BY painting_count DESC
LIMIT 5;

SELECT a.full_name, COUNT(w.work_id) AS painting_count
FROM artist a
JOIN workk w ON a.artist_id = w.artist_id
GROUP BY a.full_name
ORDER BY painting_count DESC
LIMIT 5;


SELECT 
    *,
    to_timestamp(open, 'HH:MI AM') as open_time,
    to_timestamp(close, 'HH:MI AM') as close_time,
    to_timestamp(close, 'HH:MI AM') - to_timestamp(open, 'HH:MI AM') as duration
FROM 
    museum_hours
ORDER BY 
    (to_timestamp(close, 'HH:MI AM') - to_timestamp(open, 'HH:MI AM'));



WITH popular_styles AS (
    SELECT style
    FROM workk
    GROUP BY style
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
SELECT 
    m.name, 
    m.state, 
    COUNT(w.work_id) AS style_count
FROM 
    museum m
JOIN 
    workk w ON m.museum_id = w.museum_id
JOIN 
    popular_styles ps ON w.style = ps.style
GROUP BY 
    m.name, 
    m.state
ORDER BY 
    style_count DESC;



SELECT 
    a.full_name, 
    COUNT(DISTINCT m.country) AS countries_count
FROM 
    artist a
JOIN 
    workk w ON a.artist_id = w.artist_id
JOIN 
    museum m ON w.museum_id = m.museum_id
GROUP BY 
    a.full_name
HAVING 
    COUNT(DISTINCT m.country) > 1;

SELECT 
    country, 
    city
FROM (
    SELECT 
        country, 
        city, 
        RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking
    FROM 
        museum
    GROUP BY 
        country, 
        city
) AS ranked_museums
WHERE 
    ranking = 1;

SELECT 
    a.full_name AS artist_name, 
    ps.sale_price, 
    w.name AS painting_name, 
    m.name AS museum_name, 
    m.city AS museum_city, 
    cs.label AS canvas_label
FROM 
    product_size ps
JOIN 
    workk w ON ps.work_id = w.work_id
JOIN 
    artist a ON w.artist_id = a.artist_id
JOIN 
    museum m ON w.museum_id = m.museum_id
JOIN 
    canvas_size cs ON ps.size_id::bigint = cs.size_id
WHERE 
    ps.sale_price = (
        SELECT 
            MAX(sale_price)
        FROM 
            product_size
    )
    OR 
    ps.sale_price = (
        SELECT 
            MIN(sale_price)
        FROM 
            product_size
    );


SELECT 
    country
FROM (
    SELECT 
        country, 
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS ranking
    FROM 
        museum m
    JOIN 
        workk w ON m.museum_id = w.museum_id
    GROUP BY 
        country
) AS ranked_countries
WHERE 
    ranking = 5;


SELECT 
    a.full_name, 
    COUNT(w.work_id) AS num_paintings, 
    a.nationality
FROM 
    artist a
JOIN 
    workk w ON a.artist_id = w.artist_id
JOIN 
    museum m ON w.museum_id = m.museum_id
JOIN 
    subject s ON w.work_id = s.work_id
WHERE 
    s.subject = 'Portrait' 
    AND 
    m.country != 'USA'
GROUP BY 
    a.full_name, 
    a.nationality
ORDER BY 
    num_paintings DESC;
