/* Part 1
 * Condition: All animation movies released between 2017 and 2019 with rate more than 1, alphabetical*/
/*how I did: nothing special, fairly straightforward. */
select * 
from film
where release_year between 2017 and 2019
	  and rental_rate > 1
order by title asc;

/*Condition: The revenue earned by each rental store since March 2017 (columns: address and address2 – as one column, revenue)*/
/* joined staff and payment tables, did some row filtering with when clause. Had to join the tables to access all the values */
select s.store_id, sum(p.amount) as total_earned
from staff s
left join payment p 
on s.staff_id = p.staff_id
where extract(year from p.payment_date) >= 2017 and extract(month from p.payment_date) >= 3
group by s.store_id


/*Condition: Top-5 actors by number of movies (released since 2015) 
 * they took part in (columns: first_name, last_name, number_of_movies, 
 * sorted by number_of_movies in descending order)*/

/* joined film_actor and actor tables. Grouped by the first_name and the last_name */

select a.first_name, a.last_name, count(*) as number_of_movies
from film_actor f
left join actor a
on f.actor_id  = a.actor_id 
where extract(year from f.last_update) >= 2015
group by a.first_name, a.last_name 
order by number_of_movies desc

/*Condition: 
 * Number of Drama, Travel, Documentary per year (columns: release_year, 
 * number_of_drama_movies (id: 7, Drama), 
 * number_of_travel_movies (id: 16, Travel), 
 * number_of_documentary_movies (id: 6, Documentary), 
 * sorted by release year in descending order. Dealing with NULL values is encouraged)
 * */

/*Made a cte table to prepare the values that were otherwise tedious to access and process in a single query. 
 * I thought this would simplify my main query
 * */

with films_cte as (
	select f.title, f.release_year, fc.category_id
	from film f
	left join film_category fc 
	on f.film_id = fc.film_id
)

/*used subqueries in select as it seemed logical for displaying the specific data for the columns */
select f.release_year, (
	select count(*) 
	from films_cte fc
	left join category cat
	on fc.category_id = cat.category_id
	where cat.name = 'Drama' and release_year = f.release_year
	) as drama_movies_count,
	(
	select count(*) 
	from films_cte fc
	left join category cat
	on fc.category_id = cat.category_id
	where cat.name = 'Travel' and release_year = f.release_year
	) as travel_movies_count,
	(
	select count(*) 
	from films_cte fc
	left join category cat
	on fc.category_id = cat.category_id
	where cat.name = 'Documentary' and release_year = f.release_year
	) as documentary_movies_count
from film f
group by f.release_year
order by release_year asc


/*For each client, display a list of horrors that he had ever rented 
 * (in one column, separated by commas), and the amount of money that he paid for it*/
select r.customer_id, 
	STRING_AGG(f.title, ', ') AS horror_movie_titles,
	SUM(p.amount) "amount"
from rental r
left join inventory i
on r.inventory_id = i.inventory_id 
left join film_category fc
on i.film_id = fc.film_id
left join category cat
on fc.category_id = cat.category_id 
left join film f
on i.film_id = f.film_id 
left join payment p
on r.rental_id  = p.payment_id 
where cat.name = 'Horror' and p.amount is not null 
group by r.customer_id
order by r.customer_id ASC

/* Part 2
 * Condition: 
 * Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance. 
Assumptions: 
staff could work in several stores in a year, please indicate which store the staff worked in (the last one);
if staff processed the payment then he works in the same store; 
take into account only payment_date

how I did: 

I just made a query for employees with the most earning. In the next query also tried to get the store the staff worked, 
though my attempts were unsuccessful and resorted to using window functions as I did not know the condition not to
 * */

select staff_id, sum(amount) as total_earned
from payment 
where extract(year from payment_date) = 2017
group by staff_id
order by total_earned desc 
limit 3


select staff_id, 
       store_id, 
       max(last_update) as last_date,
       total_amount
from (
    select 
        p.staff_id,
        i.store_id,
        r.last_update,
/*        sum(p.amount) as total_earned,*/
        sum(p.amount) over(partition by p.staff_id, i.store_id) as total_amount,
        row_number() over (partition by p.staff_id, i.store_id order by r.last_update desc) as rn
    from 
        payment p
    left join 
        rental r on p.rental_id = r.rental_id 
    left join 
        inventory i on r.inventory_id = i.inventory_id
) as ranked
where rn = 1
group by staff_id, store_id, total_amount, last_update
order by staff_id, last_update


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
left join inventory i 
on r.inventory_id = i.inventory_id 
left join film f
on i.film_id = f.film_id 
group by f.title, f.rating
order by rented_times desc
limit 5


/*Part 3*/
/*Which actors/actresses didn't act for a longer period of time than the others? */

/*V1: gap between the latest release_year and current year per each actor;
V2: gaps between sequential films per each actor;
*/

/*only did the v1. If I understood it correctly, feels like V2 is only doable using window functions*/
/* went straightforward to join some tables and subtracted the latest release year from the current year, i.e. 2024 */

with actors_cte as (
	select actor_id, concat(first_name, ' ', last_name) as full_name
	from actor
)

select act.full_name, extract(year from current_date) - max(f.release_year) as since_last_release 
from film f
inner join film_actor fa
on f.film_id = fa.film_id 
left join actors_cte as act
on fa.actor_id = act.actor_id
group by act.full_name
order by since_last_release desc 




