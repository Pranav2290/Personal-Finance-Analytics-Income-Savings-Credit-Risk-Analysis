CREATE TABLE staging_finance_raw (
    user_id                  VARCHAR(50),
    age                      INT,
    gender                   VARCHAR(20),
    education_level          VARCHAR(100),
    employment_status        VARCHAR(100),
    job_title                VARCHAR(150),
    monthly_income_usd       NUMERIC(12,2),
    monthly_expenses_usd     NUMERIC(12,2),
    savings_usd              NUMERIC(12,2),
    has_loan                 VARCHAR(10),
    loan_type                VARCHAR(100),
    loan_amount_usd          NUMERIC(14,2),
    loan_term_months         INT,
    monthly_emi_usd          NUMERIC(12,2),
    loan_interest_rate_pct   NUMERIC(5,2),
    debt_to_income_ratio     NUMERIC(6,3),
    credit_score             INT,
    savings_to_income_ratio  NUMERIC(6,3),
    region                   VARCHAR(100),
    record_date              DATE
);

select * from staging_finance_raw;

-- load the data locally using copy method
copy staging_finance_raw (
	user_id,
	age,
	gender,
	education_level,
	employment_status,
	job_title,
	monthly_income_usd,
	monthly_expenses_usd,
	savings_usd,
	has_loan,
	loan_type,
	loan_amount_usd,
	loan_term_months,
	monthly_emi_usd,
	loan_interest_rate_pct,
	debt_to_income_ratio,
	credit_score,
	savings_to_income_ratio,
	region,
	record_date
)
from 'D:\Data Analytics\Financial Analysis\personal_finance_dataset.csv'
delimiter ','
csv header;

select * from staging_finance_raw limit 10;


--now we pull data from staging_finance_raw to our normalised tables 
--1. regions
insert into regions (region_name)
select distinct region
from staging_finance_raw
where region is not null;

--2. users 
select * from users;

insert into users(user_id, gender, education_level, employment_status, job_title, region_id)
select distinct 
	s.user_id,
	s.gender,
	s.education_level,
	s.employment_status,
	s.job_title,
	r.region_id
from staging_finance_raw s
join regions r
on r.region_name = s.region;

select count(*) from users;

--3. financial_profiles
select * from financial_profiles;

insert into financial_profiles(user_id, record_date, age, monthly_income_usd, 
			monthly_expenses_usd, savings_usd, has_loan, debt_to_income_ratio, 
			savings_to_income_ratio, credit_score)
select 
	s.user_id,
    s.record_date,
    s.age,
    s.monthly_income_usd,
    s.monthly_expenses_usd,
    s.savings_usd,
    (CASE WHEN LOWER(s.has_loan) IN ('yes', 'true', '1') THEN TRUE ELSE FALSE END),
    s.debt_to_income_ratio,
    s.savings_to_income_ratio,
    s.credit_score
FROM staging_finance_raw s;

select * from 

--4.loans
select * from loans

insert into loans(user_id, record_date, loan_type, loan_amount_usd,
			loan_term_months, monthly_emi_usd, loan_interest_rate_pct)
SELECT
    s.user_id,
    s.record_date,
    s.loan_type,
    s.loan_amount_usd,
    s.loan_term_months,
    s.monthly_emi_usd,
    s.loan_interest_rate_pct
from staging_finance_raw s
where lower(s.has_loan) in ('yes', 'true', '1');
			
-- check all the tables
select * from regions;
select * from users;
select * from financial_profiles;
select * from loans;