--Create a new user with the username "rentaluser" and the password "rentalpassword". 
--Give the user the ability to connect to the database but no other permissions
create role rental_user with login password 'rentalpassword';


--Grant "rentaluser" SELECT permission for the "customer" table. 
--Сheck to make sure this permission works correctly—write a SQL query to select all customers.

grant select on table customer to rental_user;

select session_user, current_user

set role rental_user;

select * from customer; --gives result
select * from film; -- fails


--Create a new user group called "rental" and add "rentaluser" to the group
set role a1234;

create role rental; 
grant rental to rental_user;


--Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. 
--Insert a new row and update one existing row in the "rental" table under that role. 
SELECT current_user;

grant insert, update on table public.rental to rental;
grant usage, select on sequence rental_rental_id_seq to rental; --http://tiny.cc/6j7xzz

set role rental_user;

insert into public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
	values ('01-01-2017'::date, 1, 1, '01-06-2017'::date, 1)


select * from rental;



--Revoke the "rental" group's INSERT permission for the "rental" table. 
--Try to insert new rows into the "rental" table make sure this action is denied.
set role a1234;
revoke insert on table public.rental from rental;
set role rental_user;

insert into public.rental (rental_date, inventory_id, customer_id, return_date, staff_id)
	values ('01-01-2017'::date, 1, 1, '01-06-2017'::date, 1)

--Create a personalized role for any customer already existing in the dvd_rental database. 
--The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
---The customer's payment and rental history must not be empty.
set role a1234;

create role client_Mary_Smith;

/*
 * Read about row-level security (https://www.postgresql.org/docs/12/ddl-rowsecurity.html) 
Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. 
Write a query to make sure this user sees only their own data.
 * */

select current_user;
alter table rental enable row level security;
alter table payment enable row level security;

create policy client_access on rental to client_Mary_Smith
    using (customer_id = 1);

create policy client_access on payment to client_Mary_Smith
    using (customer_id = 1);
