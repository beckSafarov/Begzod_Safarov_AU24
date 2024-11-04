/*
 * 1. choose your top-3 favorite movies and add them to the 'film' table 
 * (films with the title film1, film2, etc - will not be taken into account and grade will be reduced)
 * 
 */

select * from film order by last_update desc limit 3;

insert into film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, fulltext)
select 
    'The Message', 
    'A historical epic recounting the life of Prophet Muhammad (pbuh) and the origins of islam.', 
    1976, 
    language_id,  
    null, 
    7, 
    4.99, 
    177, 
    29.99, 
    'PG', 
    '{subtitles, behind the scenes}', 
    '''messag'':1 ''histor'':3 ''epic'':5 ''prophet'':9 ''muhammad'':10 ''islam'':13'
from language
where name = 'English' and not exists (
    select 1 from film where title = 'The Message'
)
limit 1
returning *;

insert into film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, fulltext)
select 
    'The Pursuit of Happyness', 
    'A biographical drama about Chris Gardner''s struggle to overcome hardship and achieve success.', 
    2006, 
    language_id, 
    NULL, 
    14, 
    9.99, 
    117, 
    19.99, 
    'PG-13', 
    '{Deleted Scenes, Commentary}', 
    '''pursuit'':1 ''happynes'':2 ''biograph'':4 ''drama'':5 ''struggl'':8 ''chri'':9 ''gardner'':10 ''hardship'':12 ''success'':14'
from language
where name = 'English' and not exists (
    select 1 from film where title = 'The Pursuit of Happyness'
)
limit 1
returning *;

insert into film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features, fulltext)
select 
    'Braveheart', 
    'The story of William Wallace, who leads the Scots in a rebellion against English oppression.', 
    1995, 
    language_id, 
    NULL, 
    21, 
    19.99, 
    178, 
    24.99, 
    'R', 
    '{Trailers, Deleted Scenes, Commentary}', 
    '''braveheart'':1 ''william'':3 ''wallac'':4 ''rebellion'':7 ''scot'':8 ''english'':11 ''oppress'':12'
from language
where name = 'English' and not exists (
    select 1 from film where title = 'Braveheart'
)
limit 1
returning *;


/*
 * Add the actors who play leading roles in your favorite movies to the 'actor' and 'film_actor' tables 
 * (6 or more actors in total). 
 * 
 * */

with new_actors as (
    select * from (values 
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
    ) as vals(first_name, last_name)
)
insert into actor (first_name, last_name)
select first_name, last_name
from new_actors
where not exists (
    select 1 from actor 
    where actor.first_name = new_actors.first_name 
      and actor.last_name = new_actors.last_name
)
returning *;




insert into film_actor(actor_id, film_id)
select 
	a.actor_id, 
	f.film_id 
from actor a 
join film f on f.title = 'Braveheart'
where a.first_name in ('Mel', 'Sophie', 'Patrick', 'Angus', 'Brendan',  'David') and 
	  a.last_name in ('Gibson', 'Marceau', 'McGoohan', 'Macfadyen', 'Gleeson', 'O`Hara')
	  and not exists (
	      select 1 
	      from film_actor fa 
	      where fa.actor_id = a.actor_id 
	        and fa.film_id = f.film_id
      )
returning *;



insert into film_actor(actor_id, film_id)
select 
	a.actor_id, 
	f.film_id 
from actor a 
join film f on f.title like 'The P%'
where a.first_name in ('Will', 'Jaden', 'Thandie', 'Brian', 'James',  'Dan') and 
	  a.last_name in ('Smith', 'Smith', 'Newton', 'Howe', 'Karen', 'Castellaneta')
	  and not exists (
	      select 1 
	      from film_actor fa 
	      where fa.actor_id = a.actor_id 
	        and fa.film_id = f.film_id
      )
returning *;



insert into film_actor(actor_id, film_id)
select 
	a.actor_id, 
	f.film_id 
from actor a 
join film f on f.title like 'The M%'
where a.first_name in ('Anthony', 'Irene', 'Michael', 'Johnny', 'Garrick',  'Damien') and 
	  a.last_name in ('Quinn', 'Papadopoulos', 'Ansara', 'Sekka', 'Hagon', 'Thomas')
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
join store s on s.store_id = (select store_id from store order by random() limit 1)
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
	inner join payment p on r.rental_id = p.rental_id 
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

delete from payment where customer_id = (select customer_id from customer where first_name = 'Begzod')
and exists (
    select 1 from payment p 
    where p.customer_id = (select customer_id from customer where first_name = 'Begzod')
);

delete from rental where customer_id = (select customer_id from customer where first_name = 'Begzod')
and exists (
    select 1 from rental r 
    where r.customer_id = (select customer_id from customer where first_name = 'Begzod')
);


/*
 * Rent you favorite movies from the store they are in and pay for them 
 * (add corresponding records to the database to represent this activity)
(Note: to insert the payment_date into the table payment, you can create a 
new partition (see the scripts to install the training database ) or add records for the
first half of 2017)
 * */
insert into rental (rental_date, inventory_id, customer_id, return_date, staff_id)
	select '2017-05-15 14:30:00' as rental_date,
			i.inventory_id,
			(select customer_id from customer where first_name = 'Begzod') as customer_id,
			'2017-05-22 14:30:00' as return_date,
			(select staff_id from staff order by staff_id limit 1)
	from inventory i
	inner join film f on i.film_id = f.film_id
	where f.title like 'The M%' and not exists (
		select 1 from rental r2
	    where r2.rental_date = '2017-05-15 14:30:00' and r2.return_date = '2017-05-22 14:30:00'
	)
returning *;


insert into payment (customer_id, staff_id, rental_id, amount, payment_date)
	select  customer_id,
			(select staff_id from staff order by staff_id limit 1) as staff_id,
			rental_id,
			4.99,
			rental.rental_date 
	from rental 
	where customer_id = (select customer_id from customer where first_name = 'Begzod') and
			rental_date = '2017-05-15 14:30:00'
			and not exists (
				select 1 from payment p2
			    where p2.payment_date = rental.rental_date and p2.amount = 4.99
			)
	returning *;

insert into rental (rental_date, inventory_id, customer_id, return_date, staff_id)
	select '2017-05-15 14:30:00' as rental_date,
			i.inventory_id,
			(select customer_id from customer where first_name = 'Begzod') as customer_id,
			'2017-05-29 14:30:00' as return_date,
			(select staff_id from staff order by staff_id limit 1)
	from inventory i
	inner join film f on i.film_id = f.film_id
	where f.title like 'The P%' and not exists (
		select 1 from rental r2
	    where r2.rental_date = '2017-05-15 14:30:00' and r2.return_date = '2017-05-29 14:30:00'
	)
returning *;


insert into payment (customer_id, staff_id, rental_id, amount, payment_date)
	select  customer_id,
			(select staff_id from staff order by staff_id limit 1) as staff_id,
			rental_id,
			9.99,
			rental.rental_date 
	from rental 
	where customer_id = (select customer_id from customer where first_name = 'Begzod') and not exists (
				select 1 from payment p2
			    where p2.payment_date = rental.rental_date and p2.amount = 9.99
			)
	order by last_update desc 
	limit 1
returning *;



insert into rental (rental_date, inventory_id, customer_id, return_date, staff_id)
	select '2017-05-15 14:30:00' as rental_date,
			i.inventory_id,
			(select customer_id from customer where first_name = 'Begzod') as customer_id,
			'2017-06-05 14:30:00' as return_date,
			(select staff_id from staff order by staff_id limit 1)
	from inventory i
	inner join film f on i.film_id = f.film_id
	where f.title = 'Braveheart' and not exists (
		select 1 from rental r2
	    where r2.rental_date = '2017-05-15 14:30:00' and r2.return_date = '2017-06-05 14:30:00'
	)
returning *;


insert into payment (customer_id, staff_id, rental_id, amount, payment_date)
	select  customer_id,
			(select staff_id from staff order by staff_id limit 1) as staff_id,
			rental_id,
			19.99,
			rental.rental_date 
	from rental 
	where customer_id = (select customer_id from customer where first_name = 'Begzod') and not exists (
				select 1 from payment p2
			    where p2.payment_date = rental.rental_date 
			    and p2.amount = 19.99
			)
	order by last_update desc 
	limit 1
	returning *;

