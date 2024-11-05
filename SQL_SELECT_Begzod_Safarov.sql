/* Part 1
 * Condition: All animation movies released between 2017 and 2019 with rate more than 1, alphabetical*/
/*how I did: hopefully fixed my previous mistakes: used inner join to join film and film category, subquery to get category name by id */
select * 
from film f
inner join film_category fc
on f.film_id = fc.film_id
where release_year between 2017 and 2019
	  and rental_rate > 1
	  and fc.category_id = (
	  	select category_id
	  	from category
	  	where name = 'Animation'
	  )
order by title asc;



/*Condition: The revenue earned by each rental store since March 2017 (columns: address and address2 – as one column, revenue)*/
/* added the missing columns */
select 
	s.store_id, 
	sum(p.amount) as total_earned,
	concat(address, address2) as "address"
from staff s
inner join payment p 
on s.staff_id = p.staff_id
inner join address a
on s.address_id = a.address_id 
where extract(year from p.payment_date) >= 2017 and extract(month from p.payment_date) >= 3
group by s.store_id, address, address2;


/*Condition: Top-5 actors by number of movies (released since 2015) 
 * they took part in (columns: first_name, last_name, number_of_movies, 
 * sorted by number_of_movies in descending order)*/

/* fixing: added true record identifier (actor_id) to the groupping*/

select a.actor_id, a.first_name, a.last_name, count(*) as number_of_movies
from film_actor f
inner join actor a
on f.actor_id  = a.actor_id 
where extract(year from f.last_update) >= 2015
group by a.actor_id, a.first_name, a.last_name 
order by number_of_movies desc;

/*Condition: 
 * Number of Drama, Travel, Documentary per year (columns: release_year, 
 * number_of_drama_movies (id: 7, Drama), 
 * number_of_travel_movies (id: 16, Travel), 
 * number_of_documentary_movies (id: 6, Documentary), 
 * sorted by release year in descending order. Dealing with NULL values is encouraged)
 * */

with films_cte as (
	select f.film_id, f.release_year, c."name" as category
	from film f
	inner join film_category fc
	on f.film_id = fc.film_id 
	inner join category c
	on fc.category_id = c.category_id 
)

select
	release_year as year,
	sum(case when category = 'Drama' then 1 else 0 end) as number_of_drama_movies,
	sum(case when category = 'Travel' then 1 else 0 end) as number_of_travel_movies,
	sum(case when category = 'Documentary' then 1 else 0 end) as number_of_documentary_movies
from films_cte
group by year
order by year asc;




/*For each client, display a list of horrors that he had ever rented 
 * (in one column, separated by commas), and the amount of money that he paid for it*/

select r.customer_id, 
	STRING_AGG(distinct fl.title, ', ') AS horror_movie_titles,
	SUM(fl.price) "amount"
from rental r
inner join inventory i
on r.inventory_id = i.inventory_id 
inner join film_list fl
on i.film_id = fl.fid 
where fl.category = 'Horror'
group by r.customer_id; 



/* Part 2
 * Condition: 
 * Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance. 
Assumptions: 
staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
if staff processed the payment then he works in the same store; 
take into account only payment_date
 * */

/*payment, rental, inventory*/


with staff_cte as (
    select 
        p2.staff_id, 
        i.store_id, 
        p2.amount, 
        p2.payment_date
    from payment p2
    inner join rental r on p2.rental_id = r.rental_id 
    inner join inventory i on r.inventory_id = i.inventory_id
),
last_store_cte as (
    select distinct on (staff_id) 
        staff_id, 
        store_id
    from staff_cte
    order by staff_id, payment_date desc
)

select 
    sc.staff_id, 
    ls.store_id, 
    sum(sc.amount) as total_earned
from staff_cte sc
inner join last_store_cte ls on sc.staff_id = ls.staff_id
group by sc.staff_id, ls.store_id
order by total_earned desc 
limit 3;



/*
 * Which 5 movies were rented more than others (number of rentals), and what's the expected age of the audience 
 * for these movies? 
 * To determine expected age please use 'Motion Picture Association film rating system
 * */

/*felt logical to use case clause along with table joins */
select 
	f.title, 
	count(r.rental_id) as rented_times, 
	case when f.rating = 'PG' then 10
	when f.rating = 'PG-13' then 13
	when f.rating = 'R' then 17
	else 18 end as expected_age
from rental r
inner join inventory i 
on r.inventory_id = i.inventory_id 
inner join film f
on i.film_id = f.film_id 
group by f.title, f.rating
order by rented_times desc
limit 5;


/*Part 3*/
/*Which actors/actresses didn't act for a longer period of time than the others? */

/*V1: gap between the latest release_year and current year per each actor;
V2: gaps between sequential films per each actor;
*/



/*v1*/
select act.full_name, extract(year from current_date) - max(f.release_year) as since_last_release 
from film f
inner join film_actor fa
on f.film_id = fa.film_id 
inner join (select actor_id, concat(first_name, ' ', last_name) as full_name
	from actor) as act
on fa.actor_id = act.actor_id
group by act.full_name
order by since_last_release desc 


/* v2: tried different ways to do v2 using lateral joins, but still couldn't figure out how to calculate max difference between
 * consecutive rows. Would appreciate if you could give more hints:))) 
 * */



