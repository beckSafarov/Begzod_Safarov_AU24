

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








