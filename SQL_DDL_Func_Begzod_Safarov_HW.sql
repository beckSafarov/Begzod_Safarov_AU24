/*
 * Task 1. Create a view
Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue 
for the current quarter and year. 
The view should only display categories with at least one sale in the current quarter. 
Note: when the next quarter begins, it will be considered as the current quarter. 
 */

select * from sales_by_film_category sbfc;

create or replace view public.sales_revenue_by_category_qtr
as select c.name as category,
    sum(p.amount) as total_sales
   from payment p
     join rental r on p.rental_id = r.rental_id
     join inventory i on r.inventory_id = i.inventory_id
     join film f on i.film_id = f.film_id
     join film_category fc on f.film_id = fc.film_id
     join category c on fc.category_id = c.category_id
  WHERE date_part('year', p.payment_date) = date_part('year', current_date)
  	AND date_part('quarter', p.payment_date) = date_part('quarter', current_date)
  group by c.name
  having count(p.payment_id) > 0
  order by (sum(p.amount)) desc;
  
 
 /*
  * Task 2. Create a query language functions
Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one 
parameter representing the current quarter and year and returns the same result as the 
'sales_revenue_by_category_qtr' view.
  */
 create function get_sales_revenue_by_category_qtr (in cur_date timestamp)
   returns table (category text, total_sales numeric)
	 as $$
	 select c.name as category,
	    sum(p.amount) as total_sales
	   from payment p
	     join rental r on p.rental_id = r.rental_id
	     join inventory i on r.inventory_id = i.inventory_id
	     join film f on i.film_id = f.film_id
	     join film_category fc on f.film_id = fc.film_id
	     join category c on fc.category_id = c.category_id
	  where date_part('year', p.payment_date) = date_part('year', cur_date)
	  	and date_part('quarter', p.payment_date) = date_part('quarter', cur_date)
	  group by c.name
	  having count(p.payment_id) > 0
	  order by (sum(p.amount)) desc;
$$ 
language sql; 


/*
 * Task 3. Create procedure language functions
Create a function that takes a country as an input parameter and returns the most popular film in that specific country. 
The function should format the result set as follows:
Query (example):select * from core.most_popular_films_by_countries(array['Afghanistan','Brazil','United States’]);
 */

create or replace function most_popular_films_by_countries(countries text[])
returns table (title text, country text, rating mpaa_rating, language text, release_year int) 
language plpgsql as $$
begin
	return query 
    
    
	with customer_countries as (
		select distinct c.customer_id, co.country
		from customer c
		join address a on c.address_id = a.address_id 
		join city ci on ci.city_id = a.city_id 
		join country co on co.country_id = ci.country_id
		order by c.customer_id
		), 
	film_from_rental as (
		select distinct p.rental_id, f.title, f.rating, l.name as language, f.length, f.release_year
		from payment p 
		join rental r on p.rental_id = r.rental_id
		join inventory i on r.inventory_id = i.inventory_id 
		join film f on i.film_id = f.film_id
		join language l on f.language_id = l.language_id
		order by p.rental_id
	)
	
	--select * from customer_countries;
	select distinct on (cc.country) cc.country::text, ffr.title::text, ffr.rating::mpaa_rating, ffr.language::text, ffr.release_year::int
	from payment p 
	join customer_countries cc on p.customer_id  = cc.customer_id
	join film_from_rental ffr on p.rental_id = ffr.rental_id
	where cc.country in (select unnest(countries))
	group by cc.country, ffr.title,  ffr.rating, ffr.language, ffr.release_year
	order by cc.country, count(ffr.title) desc;
END;
$$;



/*
 * Task 4. Create procedure language functions
Create a function that generates a list of movies available in stock based on a partial title match 
(e.g., movies containing the word 'love' in their title). 
The titles of these movies are formatted as '%...%', and if a movie with the specified title is not in stock, 
return a message indicating that it was not found.
The function should produce the result set in the following format (note: the 'row_num' field is an automatically 
generated counter field, starting from 1 and incrementing for each entry, e.g., 1, 2, ..., 100, 101, ...).

                    Query (example):select * from core.films_in_stock_by_title('%love%’);
*/



create or replace function films_in_stock_by_title(term text)
returns table (row_num bigint, title text, language text, customer text, rental_date timestamp) 
language plpgsql as $$
begin
	return query 
    
	with latest_rented_movies as (
		select 
		    distinct on (film_id)
			f.film_id, 
			p.rental_id, 
			concat(c.first_name, ' ', c.last_name) as customer, 
			max(r.rental_date) as rental_date
		from payment p 
		join rental r on p.rental_id = r.rental_id
		join inventory i on r.inventory_id = i.inventory_id 
		join film f on i.film_id = f.film_id
		join language l on f.language_id = l.language_id
		join customer c on r.customer_id = c.customer_id
		group by f.film_id, p.rental_id, c.first_name, c.last_name, r.rental_date
		order by f.film_id asc, r.rental_date desc 
	)

	select 
		ROW_NUMBER() OVER () AS row_num, 
		f.title::text, 
		l.name::text as language, 
		lrm.customer::text, 
		max(lrm.rental_date::timestamp) as rental_date
	from inventory i 
    join film f on i.film_id = f.film_id
	join language l on f.language_id = l.language_id
	join latest_rented_movies lrm on f.film_id = lrm.film_id
	where lower(f.title) like concat('%', term, '%')
	group by f.title, l.name, lrm.customer
	order by f.title;

	if not found then 
		raise notice 'The movie with term % was not found', term;
	end if; 	
end;
$$;

	
/*Create procedure language functions
Create a procedure language function called 'new_movie' that takes a movie title as a 
parameter and inserts a new movie with the given title in the film table. The function should generate a 
new unique film ID, set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99. 
The release year and language are optional and by default should be current year and Klingon respectively. 
The function should also verify that the language exists in the 'language' table. Then, ensure that no such function 
has been created before; if so, replace it.
*/


create or replace function add_new_film(in title text, release_year int default extract(year from current_date)::int, lang_name text default 'Klingon')
returns bigint
language plpgsql
as $$
declare 
	lang_id int;
	new_film_id bigint;
begin 
	select language_id into lang_id
    from language
    where name = lang_name;

    if not found then
        raise exception 'language "%" does not exist in the language table.', lang_name;
    end if;
   
   	select coalesce(max(film_id), 0) + 1 into new_film_id
    from film;
   
	insert into film (
		film_id,
		title, 
		description, 
		release_year, 
		language_id, 
		original_language_id, 
		rental_duration, 
		rental_rate,
		length, 
		replacement_cost,
		rating, 
		special_features,
		fulltext
	)
	values (
		new_film_id,
		title, 
		null, 
		release_year,
		lang_id,
		NULL,
		3,
		4.99,
		null,
		19.99,
		'G',
		null,
		to_tsvector(concat_ws(' ', title, release_year::text, lang_name))
	);
	
	raise notice 'New film titled "%" has been added with film id %.', title, new_film_id;

	return new_film_id;
end;
$$;

--select add_new_film('Fast and Furious', 2018, 'English');

