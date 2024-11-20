/*
 * 1. choose your top-3 favorite movies and add them to the 'film' table 
 * (films with the title film1, film2, etc - will not be taken into account and grade will be reduced)
 * 
 */

with new_films as (
    select * from (values 
    ( 
	'The Message', 
    'A historical epic recounting the life of Prophet Muhammad (pbuh) and the origins of islam.', 
    1976, 
    null, 
    7, 
    4.99, 
    177, 
    29.99, 
    'PG', 
    '{subtitles, behind the scenes}', 
    '''messag'':1 ''histor'':3 ''epic'':5 ''prophet'':9 ''muhammad'':10 ''islam'':13'
    ),
    (
	'The Pursuit of Happyness', 
    'A biographical drama about Chris Gardner''s struggle to overcome hardship and achieve success.', 
    2006, 
    NULL, 
    14, 
    9.99, 
    117, 
    19.99, 
    'PG-13', 
    '{Deleted Scenes, Commentary}', 
    '''pursuit'':1 ''happynes'':2 ''biograph'':4 ''drama'':5 ''struggl'':8 ''chri'':9 ''gardner'':10 ''hardship'':12 ''success'':14'
    ),
    (
    'Braveheart', 
    'The story of William Wallace, who leads the Scots in a rebellion against English oppression.', 
    1995, 
    NULL, 
    21, 
    19.99, 
    178, 
    24.99, 
    'R', 
    '{Trailers, Deleted Scenes, Commentary}', 
    '''braveheart'':1 ''william'':3 ''wallac'':4 ''rebellion'':7 ''scot'':8 ''english'':11 ''oppress'':12'
    )
    ) as vals(title, description, release_year, original_language_id, rental_duration, rental_rate, 
length, replacement_cost, rating, special_features, fulltext)
)

insert into film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, 
length, replacement_cost, rating, special_features, fulltext)
select 
	n.title, 
    n.description, 
    n.release_year, 
    l.language_id, 
    cast(n.original_language_id as smallint), 
    n.rental_duration, 
    n.rental_rate, 
    n.length, 
    n.replacement_cost, 
    n.rating::mpaa_rating, 
    n.special_features::text[], 
    cast(n.fulltext as tsvector)
from new_films n
join language l on l.name = 'English'
where not exists ( 
    select 1 
    from film f
    where f.title = n.title and f.release_year = n.release_year
)
returning *;



/*
 * Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables 
 * (6 or more actors in total). 
 * */


with ins_actors as (
    insert into actor (first_name, last_name)
    values 
        ('Anthony', 'Quinn'),
        ('Irene', 'Papadopoulos'),
        ('Michael', 'Ansara'),
        ('Johnny', 'Sekka'),
        ('Garrick', 'Hagon'),
        ('Damien', 'Thomas'),
        ('Will', 'Smith'),
        ('Jaden', 'Smith'),
        ('Thandie', 'Newton'),
        ('Brian', 'Howe'),
        ('James', 'Karen'),
        ('Dan', 'Castellaneta'),
        ('Mel', 'Gibson'),
        ('Sophie', 'Marceau'),
        ('Patrick', 'McGoohan'),
        ('Angus', 'Macfadyen'),
        ('Brendan', 'Gleeson'),
        ('David', 'O`Hara')
--     on conflict (concat(first_name, ' ', last_name)) do nothing

-- i kept having problems with ON CONFLICT clause here. Using first_name and last_name in the ON CONFLICT
-- statement kept throwing errors. Did some search and in the end could not come up with any better solution than changing
-- the very table schema 
     returning actor_id, first_name, last_name
),

ins_film_actors as (
    insert into film_actor (actor_id, film_id)
    select
        a.actor_id,
        f.film_id
    from ins_actors a
    join film f on f.title in ('The Message', 'The Pursuit of Happyness', 'Braveheart')
    where
        (f.title = 'The Message' and a.first_name in ('Anthony', 'Irene', 'Michael', 'Johnny', 'Garrick', 'Damien'))
        or (f.title = 'The Pursuit of Happyness' and a.first_name in ('Will', 'Jaden', 'Thandie', 'Brian', 'James', 'Dan'))
        or (f.title = 'Braveheart' and a.first_name in ('Mel', 'Sophie', 'Patrick', 'Angus', 'Brendan', 'David'))
    on conflict (actor_id, film_id) do nothing 
    returning actor_id, film_id
)

select * from ins_film_actors;




-- adding the first film actors to film_actor. I tried using a subquery to get film id, but the `not exists` subquery could
-- not excess the result of the other subquery
insert into film_actor(actor_id, film_id)
select 
	a.actor_id, 
	f.film_id 
from actor a 
join film f on f.title = 'Braveheart'
where concat(a.first_name, ' ', a.last_name) 
in ('Mel Gibson', 'Sophie Marceau', 'Patrick McGoohan', 'Angus Macfadyen', 'Brendan Gleeson', 'David O`Hara')
	  and not exists ( -- making sure that the (actor_id, film_id) do not already exist in film_actor
	      select 1 
	      from film_actor fa 
	      where fa.actor_id = a.actor_id 
	        and fa.film_id = f.film_id
      )
returning *;

-- adding the second film actors to film_actor
insert into film_actor(actor_id, film_id)
select 
	a.actor_id, 
	f.film_id 
from actor a 
join film f on f.title = 'The Pursuit of Happyness'
where concat(a.first_name, ' ', a.last_name) 
in ('Will Smith', 'Jaden Smith', 'Thandie Newton', 'Brian Howe', 'James Karen', 'Dan Castellaneta')
  and not exists (
      select 1 
      from film_actor fa 
      where fa.actor_id = a.actor_id 
        and fa.film_id = f.film_id
  )
returning *;

-- adding the third film actors to film_actor
insert into film_actor(actor_id, film_id)
select 
	a.actor_id, 
	f.film_id 
from actor a 
join film f on f.title = 'The Message'
where concat(a.first_name, ' ', a.last_name) 
	in ('Anthony Quinn', 'Irene Papadopoulos', 'Michael Ansara', 'Johnny Sekka', 'Garrick Hagon', 'Damien Thomas')
    and not exists (
      select 1 
      from film_actor fa 
      where fa.actor_id = a.actor_id 
        and fa.film_id = f.film_id
 	 )
returning *;


-- Add your favorite movies to any store's inventory.
insert into inventory(film_id, store_id)
select f.film_id, s.store_id 
from film f
join store s on s.store_id = 1 
where f.title in ('Braveheart', 'The Pursuit of Happyness', 'The Message') and not exists (
    select 1 
    from inventory i
    where i.film_id = f.film_id and i.store_id = s.store_id
)
returning *;


/*
 * Alter any existing customer in the database with at least 43 rental and 43 payment records. 
 * Change their personal data to yours (first name, last name, address, etc.). 
 * You can use any existing address from the "address" table. 
 * Please do not perform any updates on the "address" table, 
 * as this can impact multiple records with the same address.*/

update customer 
set first_name = 'Begzod',
	last_name = 'Safarov',
	email = 'becksafarov@gmail.com',
	address_id = (select address_id from address order by random() limit 1)
where customer_id = (
	select r.customer_id 
	from rental r 
	join payment p on r.rental_id = p.rental_id 
	group by r.customer_id
	having count(r.rental_id) >= 43 and count(p.payment_id) >= 43
	limit 1
) and not exists (
    select 1 from customer where first_name = 'Begzod' and last_name = 'Safarov'
)
returning *;

/*
 * Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'
 * */
delete 
from payment 
where customer_id = (select customer_id from customer where first_name = 'Begzod') 
returning *;

delete 
from rental 
where customer_id = (select customer_id from customer where first_name = 'Begzod')
returning *; 


/*
 * Rent you favorite movies from the store they are in and pay for them 
 * (add corresponding records to the database to represent this activity)
(Note: to insert the payment_date into the table payment, you can create a 
new partition (see the scripts to install the training database ) or add records for the
first half of 2017)
 * */

 -- bulk inserting into rental followed by payment. 

with inventories as (
   select inventory_id, store_id
   from inventory 
   where film_id in (
   	select film_id 
   	from film 
   	where title in ('The Message', 'The Pursuit of Happyness', 'Braveheart')
   )
   order by film_id
  )
  , customer_data as (
  	select customer_id
  	from customer 
  	where concat(first_name, ' ', last_name) = 'Begzod Safarov' 
  )
  , staff_data as ( -- this returns staff that work in the store that sell the very inventories of the films
  	 select s.staff_id
	  from staff s
	  join inventories i on s.store_id = i.store_id
	  group by i.store_id, s.staff_id
	  order by staff_id
	  limit 1
  ) 
  , rental_data AS (
	   select 
	      '2017-02-14 14:30:00'::timestamptz as rental_date,
	      i.inventory_id,
	      c.customer_id,
	      '2017-02-21 14:30:00'::timestamptz as return_date,
	      s.staff_id
	   from inventories i
	   cross join customer_data c
	   cross join staff_data s
	)
	
  insert into rental (rental_date, inventory_id, customer_id, return_date, staff_id)
  select rental_date, inventory_id, customer_id, return_date, staff_id
  from rental_data;
  
 with film_rental_data as (
		select 
		r.rental_id, 
		f.rental_duration, 
		f.rental_rate,
		r.return_date::date - r.rental_date::date as actual_duration,
		r.return_date::date - (r.rental_date::date + f.rental_duration) as overdue_days,
		f.replacement_cost
		from rental r
		join inventory i on i.inventory_id = r.inventory_id 
		join film f on i.film_id = f.film_id  
	)
 
 insert into payment (customer_id, staff_id, rental_id, amount, payment_date)
 select 
	    r.customer_id,
	    r.staff_id,
	    r.rental_id,
	    case when frd.actual_duration > frd.rental_duration and frd.actual_duration <= frd.rental_duration * 3 then frd.replacement_cost
	    	 when frd.actual_duration <= frd.rental_duration then frd.rental_rate
	    	 when frd.rental_duration < frd.actual_duration and frd.actual_duration  <= frd.rental_duration * 3
	    	 then frd.rental_rate + frd.overdue_days * (frd.actual_duration - frd.rental_duration)
	   		 end as amount,
	   	current_date as payment_date
	from rental r
	join film_rental_data frd on r.rental_id = frd.rental_id
	where r.rental_date = '2017-05-15 14:30:00'
