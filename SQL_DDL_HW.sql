create type exprange as enum ('0', '1-3', '3-5', '6+');
-- i realized my mistake too late. I made an exprange data type, though it can't be queried for comparative analysis. Could fix it with an additional bridge table that assigns exprange values to corresponding numbers
create type jobtype as enum ('Remote', 'On-site', 'Hybrid');
create type gender as enum ('Male', 'Female');


-- company related 
create table if not exists company (
  id serial primary key,
  name varchar(32) unique
)

-- leaving this and similar alter table statements for record_ts column as per the requirements of the task
alter table company 
add record_ts timestamp default now() not null;


-- skills related 
create table if not exists skills (
  id smallserial primary key,
  name varchar(32) unique not null
)

alter table skills 
add record_ts timestamp default now() not null; 


-- location related
create table if not exists location (
  id serial primary key,
  city varchar(32),
  state varchar(32),
  country varchar(32) not null,
  address_1 varchar(32) not null,
  address_2 varchar(32),
  postcode varchar(10) not null,
  -- both city and state can't be null, though one of them can be
  constraint city_or_state_not_null check (city is not null or state is not null)
  constraint unique_location unique (city, state, country, address_1, address_2, postcode)
)

alter table location 
add record_ts timestamp default now() not null; 


-- job related 
create table if not exists job (
	id serial primary key, 
	title varchar(32) not null,
	experience exprange default '0' not null,
	location_id int4 not null , 
	work_hours numeric(2) not null,
	company_id int4 not null, 
	posting_date timestamp DEFAULT now() not null,
	constraint check_work_hours check (work_hours between 1 and 8),
	constraint check_posting_date check (posting_date > '2000-01-01'::date),
	constraint job_location_fkey foreign key (location_id) references location(id),
	constraint job_company_fk foreign key (company_id) references company(id)
);



alter table job 
add record_ts timestamp default now() not null; 


-- job_skills related 

create table if not exists job_skills (
  job_id int4 references job(id),
  skill_id int2 references skills(id),
  constraint job_skills_pkey primary key (job_id, skill_id),
  constraint unique_job_skills unique(job_id, skill_id)
)


alter table job_skills 
add record_ts timestamp default now() not null;


-- preferences related
create table if not exists preferences (
  id serial primary key,
  min_salary decimal(10, 2),
  max_work_hours numeric(2),
  job_type jobtype default 'On-site' not null,
  constraint check_max_work_hours check (max_work_hours between 1 and 8)
)



alter table preferences  
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
  pref_id int4,
  constraint candidate_location_fkey foreign key (location_id) references location(id),
  constraint candidate_prefs_fkey foreign key (pref_id) references preferences(id),
  constraint unique_candidate unique(first_name, last_name, title, gender, location_id);
);


alter table candidate 
add record_ts timestamp default now() not null; 


-- candidate_skills related 

create table if not exists candidate_skills (
  skill_id int2 references skills(id),
  candidate_id int4 references candidate(id),
  constraint candidate_skills_pkey primary key (skill_id, candidate_id),
  constraint unique_candidate_skill unique(skill_id, candidate_id)
)

alter table candidate_skills
add record_ts timestamp default now() not null; 


-- application related
create table if not exists application (
  id serial primary key,
  candidate_id serial references candidate(id),
  job_id serial references job(id),
  date timestamp default now() not null,
  is_active boolean default true,
  constraint check_date check (date > '2000-01-01'::date),
  constraint unique_application unique (candidate_id, job_id, date)
)

alter table application 
add record_ts timestamp default now() not null; 



-- placement related
create table if not exists placement (
  id serial primary key,
  app_id serial references application(id),
  salary_min decimal(10, 2) default null,
  salary_max decimal(10, 2) default null,
  constraint unique_placement unique (app_id, salary_min, salary_max)
)

alter table placement 
add record_ts timestamp default now() not null; 



-- commission related
create table if not exists commission (
  id serial primary key,
  placement_id serial references placement(id),
  amount decimal(10, 2),
  commission_date timestamp default now() not null,
  constraint check_amount check (amount >= 0),
  constraint commission_date check (commission_date > '2000-01-01'::date)
)

alter table commission 
add record_ts timestamp default now() not null; 


-- services related
create table if not exists services (
  id smallserial primary key,
  description varchar(32) unique 
)



alter table services 
add record_ts timestamp default now() not null; 


-- orders related
create table if not exists orders (
  id serial primary key,
  service_id int2 references services(id),
  customer_id int4 references candidate(id),
  order_date timestamp default now() not null,
  constraint order_date check (order_date > '2000-01-01'::date)
)

alter table orders 
add record_ts timestamp default now() not null; 


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
insert into location (city, state, country, address_1, address_2, postcode)
	values ('Tashkent', null, 'Uzbekistan', '25 Amir Temur Avenue', null, '100000'),
			('Almaty', null, 'Kazakhstan', '123 Abay Avenue', null, '050000'),
			('Samarkand', 'Samarkand', 'Uzbekistan', '123 Amir Temur Street', null, '140100')
returning *;



-- adding companies
insert into company (name)
	values ('ZERO Technologies'),
			('Arkan Soft'),
			('AB Digital')
	returning *;




with new_jobs as (
    insert into job (title, experience, location_id, work_hours, company_id)
    values 
        ('web developer', '1-3', 1, 6, 1),
        ('java developer', '0', 2, 8, 2),
        ('SMM manager', '6+', 3, 8, 3)
    returning id, title
),
new_skills AS (
    insert into skills (name)
    values 
        ('Web Development'),
        ('Java'),
        ('Marketing')
    on conflict(name) do nothing
    returning id, name
);

insert into job_skills (job_id, skill_id)
    select nj.id, ns.id
    from new_jobs nj
    join new_skills ns 
        on (ns.name in ('Web Development', 'Java', 'Marketing'))
    where 
        (nj.title = 'web developer' and ns.name = 'Web Development') or 
        (nj.title = 'java developer' and ns.name = 'Java') or 
        (nj.title = 'SMM manager' and ns.name = 'Marketing')
    on conflict(job_id, skill_id) do nothing
    returning *

--adding preferences 
with new_prefs as (
    insert into preferences (min_salary, max_work_hours, job_type)
    values
		 (500, 8, 'Hybrid'::jobtype),
		 (1000, 6, 'Remote'::jobtype),
		 (800, 6, 'On-site'::jobtype)
    returning *
),

new_candidates(first_name, last_name, title, gender, location_id, experience, pref_id) as (values 
	('Toshmat', 'Eshmatov', 'web developer', 'Male'::gender, null, '3-5'::exprange, null),
	('Nurlan', 'Serikov', 'java developer', 'Male'::gender, null, '6+'::exprange, null),
	('Tohir', 'Sharipov', 'SMM manager', 'Male'::gender, null, '1-3'::exprange, null)
), 

new_candidates_added as(
	insert into candidate (first_name, last_name, title, gender, location_id, experience, pref_id)
	select nc.first_name, nc.last_name, nc.title, nc.gender, l.id, nc.experience, p.id
	from new_candidates nc
	join location l on l.city in ('Tashkent', 'Almaty', 'Samarkand') 
		and l.postcode in ('100000', '050000', '140100')
	join new_prefs p on p.job_type in ('Hybrid', 'Remote', 'On-site')
	where (concat(nc.first_name, ' ', nc.last_name) = 'Toshmat Eshmatov' and l.city = 'Tashkent' and p.job_type = 'Hybrid') or
		  (concat(nc.first_name, ' ', nc.last_name) = 'Nurlan Serikov' and l.city = 'Almaty' and p.job_type = 'Remote') or
		  (concat(nc.first_name, ' ', nc.last_name) = 'Tohir Sharipov' and l.city = 'Samarkand' and p.job_type = 'On-site')
	returning *
)

insert into candidate_skills (skill_id, candidate_id) 
	select s.id, nc.id 
	from new_candidates_added nc
	join skills s on (s.name in ('Web Development', 'Java', 'Marketing'))
	where (concat(nc.first_name, ' ',  nc.last_name) = 'Toshmat Eshmatov' and s.name = 'Web Development')
		or (concat(nc.first_name, ' ', nc.last_name) = 'Nurlan Serikov' and s.name = 'Java')
		or (concat(nc.first_name,' ',  nc.last_name) = 'Tohir Sharipov' and s.name = 'Marketing')
	on conflict(skill_id, candidate_id) do nothing
	returning *;



--adding applications 
with new_applications as (
	insert into application (candidate_id, job_id)
	select c.id, j.id 
	from candidate c
	join job j on c.title = j.title 
	returning *
),

applicant_jobs as (
	select na.*, c.title as customer_job
	from new_applications na
	join candidate c on na.candidate_id = c.id
),


new_placements(app_id, salary_min, salary_max) as (values 
	(null, 1500, 3000),
	(null, 2000, 4000),
	(null, 800, 1500)
),

add_new_placements as (
	insert into placement (app_id, salary_min, salary_max)
	select aj.id as app_id,
		   np.salary_min, 
		   np.salary_max
	from new_placements np
	join applicant_jobs aj on (aj.customer_job in ('web developer', 'java developer', 'SMM manager'))
	where aj.customer_job = 'web developer' and np.salary_min = 1500 or
		  aj.customer_job = 'java developer' and np.salary_min = 2000 or 
		  aj.customer_job = 'SMM manager' and np.salary_min = 800
	returning *
),
 
new_commission(placement_id, amount) as (values 
	(null, 150),
	(null, 200),
	(null, 80)
),

insert into commission (placement_id, amount)
	select anp.id as placement_id, nc.amount
	from new_commission nc
	join applicant_jobs aj on (aj.customer_job in ('web developer', 'java developer', 'SMM manager'))
	join add_new_placements as anp on anp.app_id = aj.id
	where aj.customer_job = 'web developer' and nc.amount = 150 or 
		  aj.customer_job = 'java developer' and nc.amount = 200 or 
		  aj.customer_job = 'SMM manager' and nc.amount = 80
	returning *


-- services
with new_services as (
	insert into services (description)
	values ('resume writing'),
			('interview coaching'),
			('skills development')
	returning *
),

new_orders as (
	insert into orders (service_id, customer_id)
	select s.id as service_id, c.id as customer_id
	from candidate c
	join new_services s on (s.description in ('resume writing', 'interview coaching', 'skills development'))
	where (c.first_name = 'Toshmat' and c.last_name = 'Eshmatov' and s.description = 'resume writing') or
		  (c.first_name = 'Nurlan' and c.last_name = 'Serikov' and s.description = 'interview coaching') or
		  (c.first_name = 'Tohir' and c.last_name = 'Sharipov' and s.description = 'skills development')
	returning *
)



--payments
insert into payment(order_id, amount)
select o.id as order_id,   
		case when s.description = 'resume writing' then 50
			 when s.description = 'interview coaching' then 100 
		else 200 end as amount
from new_orders o 
join candidate c on o.customer_id = c.id
join new_services s on (s.description in ('resume writing', 'interview coaching', 'skills development'))
where (c.first_name = 'Toshmat' and s.description = 'resume writing') or
	  (c.first_name = 'Nurlan' and s.description = 'interview coaching') or
	  (c.first_name = 'Tohir' and s.description = 'skills development')
returning *



