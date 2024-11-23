/* ---------- CREATING THE DATABASE & TABLES ------------*/
create database recruitment_agency;


create type exprange as enum ('0', '1-3', '3-5', '6+');
-- i realized my mistake too late. I made an exprange data type, though it can't be queried for comparative analysis. Could fix it with an additional bridge table that assigns exprange values to corresponding numbers
create type jobtype as enum ('Remote', 'On-site', 'Hybrid');
create type gender as enum ('Male', 'Female');


-- job related 
create table if not exists job (
	id serial primary key, 
	title varchar(32) not null,
	experience exprange not null,
	location_id int4 not null, 
	work_hours numeric(2) not null,
	company_id int4 not null, 
	posting_date timestamp DEFAULT now() not null
)

alter table job 
alter column posting_date
set default now();

alter table job
add constraint check_work_hours check (work_hours between 1 and 8)

alter table job 
add constraint check_posting_date check (posting_date > '2000-01-01'::date)

alter table job 
alter column experience 
set default '0'


alter table job
add constraint job_location_fkey 
foreign key (location_id) 
references location(id);

alter table job
add constraint job_company_fk 
foreign key (company_id) 
references company(id);

alter table job 
add record_ts timestamp default now() not null; 



-- skills related 

create table if not exists skills (
  id smallserial primary key,
  name varchar(32)
)

alter table skills 
add record_ts timestamp default now() not null; 

alter table skills
add constraint unique_name unique (name);


alter table skills
alter column name set not null; 


-- job_skills related 

create table if not exists job_skills (
  job_id int4 references job(id),
  skill_id int2 references skills(id),
  constraint job_skills_pkey primary key (job_id, skill_id)
)

alter table job_skills 
add record_ts timestamp default now() not null; 


-- candidate related 

create table if not exists candidate (
  id serial primary key,
  first_name varchar(32),
  last_name varchar(32),
  title varchar(32),
  gender gender not null, 
  location_id int4, 
  experience exprange,
  pref_id int4
)

alter table candidate 
add record_ts timestamp default now() not null; 

alter table candidate
add constraint candidate_location_fkey 
foreign key (location_id) 
references location(id);

alter table candidate
add constraint candidate_prefs_fkey 
foreign key (pref_id) 
references preferences(id);


-- candidate_skills related 

create table if not exists candidate_skills (
  skill_id int2 references skills(id),
  candidate_id int4 references candidate(id),
  constraint candidate_skills_pkey primary key (skill_id, candidate_id)
)

alter table candidate_skills
add record_ts timestamp default now() not null; 

-- company related 
create table if not exists company (
  id serial primary key,
  name varchar(32)
)

alter table company 
add record_ts timestamp default now() not null; 

-- location related
create table if not exists location (
  id serial primary key,
  city varchar(32),
  state varchar(32),
  country varchar(32) not null,
  address_1 varchar(32) not null,
  address_2 varchar(32),
  postcode varchar(10) not null
)


alter table location
add constraint city_or_state_not_null check (
    city is not null or state is not null
);-- both city and state can't be null, though one of them can be


alter table location 
add record_ts timestamp default now() not null; 

-- preferences related
create table if not exists preferences (
  id serial primary key,
  min_salary decimal(10, 2),
  max_work_hours numeric(2),
  job_type jobtype default 'On-site' not null
)

alter table preferences  
add record_ts timestamp default now() not null; 


alter table preferences
add constraint check_max_work_hours check (max_work_hours between 1 and 8)

-- application related
create table if not exists application (
  id serial primary key,
  candidate_id serial references candidate(id),
  job_id serial references job(id),
  date timestamp default now() not null,
  is_active boolean default true
)

alter table application 
add record_ts timestamp default now() not null; 


alter table application 
add constraint check_date check (date > '2000-01-01'::date)


-- placement related
create table if not exists placement (
  id serial primary key,
  app_id serial references application(id),
  salary_min decimal(10, 2) default null,
  salary_max decimal(10, 2) default null
)

alter table placement 
add record_ts timestamp default now() not null; 

-- commission related
create table if not exists commission (
  id serial primary key,
  placement_id serial references placement(id),
  amount decimal(10, 2),
  commission_date timestamp default now() not null
)

alter table commission 
add record_ts timestamp default now() not null; 


alter table commission
add constraint check_amount check (amount >= 0);


alter table commission 
add constraint commission_date check (commission_date > '2000-01-01'::date)

-- services related
create table if not exists services (
  id smallserial primary key,
  description varchar(32) 
)

alter table services 
add record_ts timestamp default now() not null; 


alter table services
add constraint unique_service unique (description);

-- orders related
create table if not exists orders (
  id serial primary key,
  service_id int2 references services(id),
  customer_id int4 references candidate(id),
  order_date timestamp default now() not null
)

alter table orders 
add record_ts timestamp default now() not null; 


alter table orders 
add constraint order_date check (order_date > '2000-01-01'::date)

-- payment related
create table if not exists payment (
  id serial primary key,
  amount int2 NOT NULL, 
  date timestamp DEFAULT now() NOT NULL, 
  order_id int4 references orders(id) 
)

alter table payment 
add record_ts timestamp default now() not null; 



/* ---------- INSERTING STUFF ------------*/

-- adding locations
with new_locs(city, state, country, address_1, address_2, postcode) as (values 
	('Tashkent', null, 'Uzbekistan', '25 Amir Temur Avenue', null, '100000'),
	('Almaty', null, 'Kazakhstan', '123 Abay Avenue', null, '050000'),
	('Samarkand', 'Samarkand', 'Uzbekistan', '123 Amir Temur Street', null, '140100')
)

insert into location (city, state, country, address_1, address_2, postcode)
	select *
	from new_locs nl
	where not exists (
		select 1
	    from location l
	    where nl.address_1 = l.address_1 
	    and  nl.postcode = l.postcode
	    -- i could do intersect with all the columns, though I suspect it would get too slow
	)
returning *;



-- adding companies
with new_company(name) as (values 
	('ZERO Technologies'),
	('Arkan Soft'),
	('AB Digital')
)

insert into company (name)
	select *
	from new_company nc
	where not exists (
		select 1
	    from company c
	    where nc.name = c.name
	    -- i could have done intersect with all the columns, 
	    -- though I suspected it would get too slow
	)
returning *;


-- adding jobs

-- no duplicates validation here supposing companies could make the same job post again over time
-- now I realize should have made start and end dates for a single job post, so no duplicate job post would be allowed during that period
insert into job (title, experience, location_id, work_hours, company_id)
values 
	('web developer', '1-3', 1, 6, 1),
	('java developer', '0', 2, 8, 2),
	('SMM manager', '6+', 3, 8, 3)
returning *;



-- adding skills 

with new_skill(name) as (values 
	('Java'),
	('Web Development'),
	('Marketing')
)

insert into skills (name)
	select *
	from new_skill ns
	where not exists (
		select 1
	    from skills s
	    where ns.name = s.name
	)
returning *;


-- adding job_skills
with new_job_skills(job_id, skill_id) as (values 
	(3, 1), --java
	(2, 2), -- web
	(4, 3) -- marketing
)

insert into job_skills (job_id, skill_id)
	select *
	from new_job_skills ns
	where not exists (
		select 1
	    from job_skills js
	    where ns.job_id = js.job_id and ns.skill_id = js.skill_id
	)
returning *;


--adding preferences 
-- did not allow duplicates in new preferences as per the requirements of the task, though does not make much sense to me. I guess the same candidate preference could be added and it would be no problem
with new_prefs(min_salary, max_work_hours, job_type) as (values 
	(500, 8, 'Hybrid'::jobtype),
	(1000, 6, 'Remote'::jobtype),
	(800, 6, 'On-site'::jobtype)
)

insert into preferences (min_salary, max_work_hours, job_type)
	select *
	from new_prefs np
	where not exists (
		select 1
	    from preferences p
	    where p.min_salary = np.min_salary
	    and p.max_work_hours = np.max_work_hours
	    and p.job_type= np.job_type
	)
returning *;


-- adding candidates 
with new_candidates(first_name, last_name, title, gender, location_id, experience, pref_id) as (values 
	('Toshmat', 'Eshmatov', 'web developer', 'Male'::gender, 1, '3-5'::exprange, 3),
	('Nurlan', 'Serikov', 'java developer', 'Male'::gender, 2, '6+'::exprange, 2),
	('Tohir', 'Sharipov', 'SMM manager', 'Male'::gender, 3, '1-3'::exprange, 1)
)

insert into candidate (first_name, last_name, title, gender, location_id, experience, pref_id)
	select *
	from new_candidates nc
	where not exists (
		select 1
	    from candidate c
	    where nc.first_name = c.first_name
	    and nc.last_name = c.last_name
	    and nc.title = c.title
	)
returning *;


-- adding candidate_skills
with new_candidate_skills(skill_id, candidate_id) as (values 
	(1, 2),
	(2, 1),
	(3, 3)
)

insert into candidate_skills (skill_id, candidate_id)
	select *
	from new_candidate_skills ncs
	where not exists (
		select 1
	    from candidate_skills cs
	    where cs.skill_id = ncs.skill_id and cs.candidate_id = ncs.candidate_id
	)
returning *;




--adding applications 
with new_applications(candidate_id, job_id) as (values 
	(1, 2),
	(2, 3),
	(3, 4)
)

insert into application (candidate_id, job_id)
	select *
	from new_applications na
	where not exists (
		select 1
	    from application a
	    where a.candidate_id = na.candidate_id and a.job_id = na.job_id
	)
returning *;


-- placement
with new_placements(app_id, salary_min, salary_max) as (values 
	(1, 1500, 3000),
	(2, 2000, 4000),
	(3, 800, 1500)
)

insert into placement (app_id, salary_min, salary_max)
	select *
	from new_placements np
	where not exists (
		select 1
	    from placement p
	    where p.app_id = np.app_id
	)
returning *;


-- commission 
with new_commission(placement_id, amount) as (values 
	(1, 150),
	(2, 200),
	(3, 80)
)

insert into commission (placement_id, amount)
	select *
	from new_commission nc
	where not exists (
		select 1
	    from commission c
	    where c.placement_id = nc.placement_id
	)
returning *;

-- services
with new_services(description) as (values 
	('resume writing'),
	('interview coaching'),
	('skills development')
)

insert into services (description)
	select *
	from new_services ns
	where not exists (
		select 1
	    from services s
	    where s.description = ns.description
	)
returning *;


--orders 
with new_orders(service_id, customer_id) as (values 
	(1, 1),
	(1, 2),
	(3, 1)
)

insert into orders (service_id, customer_id)
	select *
	from new_orders no
	where not exists (
		select 1
	    from orders o
	    where o.service_id = no.service_id and o.customer_id = no.customer_id
	)
returning *;


--payments
with new_payments(order_id, amount) as (values 
	(1, 50),
	(1, 50),
	(3, 200)
)

insert into payment (order_id, amount)
	select *
	from new_payments np
	where not exists (
		select 1
	    from payment p
	    where p.order_id = np.order_id
	)
returning *;







