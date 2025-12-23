-- Below are columns we have
/* 
user_id -
age-
gender-
education_level-
employment_status -
job_title -
monthly_income_usd -
monthly_expenses_usd -
savings_usd -
has_loan  -
loan_type -
loan_amount_usd -
loan_term_months-
monthly_emi_usd-
loan_interest_rate_pct-
debt_to_income_ratio  -
credit_score -
savings_to_income_ratio -
region -
record_date -
*/

-- we are normalising the above features as follows

-- regions
create table regions(
	region_id serial primary key,
	region_name varchar(100) unique not null
);

--users
create table users(
	user_id varchar(50) primary key,
	gender varchar(50),
	education_level varchar(100),
	employment_status varchar(100),
	job_title varchar(100),
	region_id int references regions(region_id)
)

-- financial_profiles
create table financial_profiles(
	profile_id 			serial primary key,
	user_id 			varchar(50) references users(user_id),
	record_date			date not null,

	age 				 int,
	monthly_income_usd	 numeric(12,2),
	monthly_expenses_usd numeric(12,2),
	savings_usd 		 numeric(12,2),

	has_loan  				 bool,
	debt_to_income_ratio 	numeric(6,3),
	savings_to_income_ratio numeric(6,3),
	credit_score 			int
);

--lons
create table loans(
	loan_id 				serial primary key,
	user_id 				varchar(50) references users(user_id),
	record_date 			date not null,

	loan_type 				varchar(100),
	loan_amount_usd 		numeric(14,2),
    loan_term_months 		int,
	monthly_emi_usd	  		numeric(12,2),
	loan_interest_rate_pct  numeric(5,2)
);


