--1) Count how many rows exist in each table.
select count(*) from regions; -- 5 rows
select count(*) from users;   --32,424 rows
select count(*) from financial_profiles;  --32,424 rows
select count(*) from loans; -- 12,995 rows

--2) Check for missing user demographics (gender, education, job_title).
select * from users;

select 'gender' as table_name, count(user_id) from users where gender is null
union all
select 'education_level', count(user_id) from users where education_level is null
union all
select 'job_title', count(user_id) from users where job_title is null

--3) Check for missing financial values (income/expenses/savings)
select * from financial_profiles;

select * from financial_profiles
where monthly_income_usd is null or
	  monthly_expenses_usd is null or
	  savings_usd is null;

--4) Find users with negative income/expenses
select profile_id, user_id from financial_profiles
where monthly_income_usd < 0 or
	  monthly_expenses_usd < 0 ; -- 0 users

--5) Find unrealistic credit scores (not between 300 and 850)	  
select profile_id, user_id from financial_profiles
where (credit_score < 300) or (credit_score > 850); -- 0 users

--6) Identify users where expenses are more than 3× income
select profile_id, user_id from financial_profiles
where (monthly_income_usd * 3) < monthly_expenses_usd

  --6.1) users where the monthly expenses than the income
  select user_id from financial_profiles
  where monthly_expenses_usd < monthly_income_usd;

--7) Check users who have loan data but has_loan = false  
select fp.*, l.loan_id
from financial_profiles fp
join loans l
on fp.user_id = l.user_id
where fp.has_loan = 'false'; -- 0 users

select * from loans;

--8) Check duplicate user_id in users
select user_id, count(*) as dup_count
from users
group by user_id
having count(*) >1 -- no duplicate user_id

--9) Find loans without matching users (orphan records)
select * from loans;
select * from financial_profiles;

select l.*
from loans l
left join users u
on l.user_id = u.user_id
where u.user_id is null;  -- 0 users

--10) Check for region IDs in users that don’t exist in regions
select distinct u.region_id
from users u
left join regions r
on u.region_id = r.region_id
where r.region_id is null;  -- no record with region_id not exist in regions

--11) Validate financial record dates (years too old or in future)
select * from financial_profiles;
  -- extract distinct year from feature
select  distinct date_part('year', record_date) from financial_profiles; --2021 to 2024

select * from financial_profiles
where record_date < '2021-01-01' or
	  record_date > current_date;
	  