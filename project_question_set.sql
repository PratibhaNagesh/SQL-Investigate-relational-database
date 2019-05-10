/* Project
S1 Q1 : We want to understand more about the movies that families are watching. The following categories are considered family movies: Animation, Children, Classics, Comedy, Family and Music.

Create a query that lists each movie, the film category it is classified in, and the number of times it has been rented out.*/

SELECT t1.film_title, t1.category_name, t2.rental_count
FROM (SELECT f.title AS film_title, c.name AS category_name
			FROM film f
			JOIN film_category fc
			ON f.film_id = fc.film_id
			JOIN category c
			ON fc.category_id = c.category_id
	 		WHERE c.name = 'Animation' OR c.name = 'Children' OR c.name = 'Classics' OR
	  		c.name = 'Comedy' OR c.name = 'Family' OR c.name = 'Music') t1
JOIN (SELECT f.title AS film_title, COUNT(*) AS rental_count
			FROM film f
			JOIN inventory i
			ON f.film_id = i.film_id
			JOIN rental r
			ON i.inventory_id = r.inventory_id
			GROUP BY film_title) t2
ON t2.film_title = t1.film_title
ORDER BY 2, 1

/* S1 Q3: Finally, provide a table with the family-friendly film category, each of the quartiles, and the corresponding count of movies within each combination of film category for each corresponding rental duration category. The resulting table should have three columns:
Category
Rental length category
Count*/

WITH t1 AS (SELECT f.title AS film_title, c.name AS category_name, f.rental_duration,
									 NTILE(4) OVER (PARTITION BY rental_duration ORDER BY rental_duration) AS standard_quartile
						FROM film f
						JOIN film_category fc
						ON f.film_id = fc.film_id
						JOIN category c
						ON fc.category_id = c.category_id
						WHERE c.name = 'Animation' OR c.name = 'Children' OR c.name = 'Classics' OR
						c.name = 'Comedy' OR c.name = 'Family' OR c.name = 'Music')

SELECT category_name, standard_quartile, COUNT(*) AS movie_count
FROM t1
GROUP BY 1, 2
ORDER BY 1, 2;


/*S2, Q2: We would like to know who were our top 10 paying customers, how many payments they made on a monthly basis during 2007, and what was the amount of the monthly payments. Can you write a query to capture the customer name, month and year of payment, and total payment amount for each month by these top 10 paying customers?*/


WITH t1 AS (SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name, SUM(p.amount) AS payment_amount
				FROM customer c
				JOIN payment p
				ON c.customer_id = p.customer_id
				GROUP BY 1, 2
				ORDER BY 3 DESC
				LIMIT 10)

SELECT t1.customer_name, DATE_PART('month', p.payment_date) AS month, DATE_PART('year', p.payment_date) AS month,
	   COUNT(*) AS pay_count_permonth, SUM(p.amount) AS payment_amount
FROM t1
JOIN payment p
ON t1.customer_id = p.customer_id
GROUP BY 1, 2
ORDER BY 1, 2;


/*S2, Q3:  Finally, for each of these top 10 paying customers, I would like to find out the difference across their monthly payments during 2007. Please go ahead and write a query to compare the payment amounts in each successive month. Repeat this for each of these 10 paying customers. Also, it will be tremendously helpful if you can identify the customer name who paid the most difference in terms of payments.*/


WITH t1 AS (SELECT c.customer_id, c.first_name || ' ' || c.last_name AS customer_name, SUM(p.amount) AS payment_amount
						FROM customer c
						JOIN payment p
						ON c.customer_id = p.customer_id
						GROUP BY 1, 2
						ORDER BY 3 DESC
						LIMIT 10),

	t2 AS (SELECT t1.customer_name, DATE_TRUNC('month', p.payment_date) AS payment_month_year, SUM(p.amount) AS payment_amount
						FROM t1
						JOIN payment p
						ON t1.customer_id = p.customer_id
						GROUP BY 1, 2
						ORDER BY 1, 2 DESC)

SELECT t2.customer_name, t2.payment_month_year, t2.payment_amount,
			 Coalesce(LAG(t2.payment_amount) OVER (PARTITION BY t2.customer_name ORDER BY t2.payment_month_year), 0) AS lag,
			 t2.payment_amount -  Coalesce(LAG(t2.payment_amount) OVER (PARTITION BY t2.customer_name ORDER BY t2.payment_month_year), 0) AS diff_monthly_payment
FROM t2
