----------------------------A. Demographics Insights -------------------------------------
--1)Total users by region.
select r.region_name, count(u.user_id)
from users u
join regions r
on r.region_id = u.region_id
group by r.region_name

--2)Age distribution (min, max, avg).
select min(age) as min_age, max(age) as max_age, avg(age) avg_age
from financial_profiles; 

--3)Count of users by education level.
select education_level, count(user_id) as total_users from users
group by education_level
order by total_users desc;

--4)Count of users by employment status.
select * from users;
select employment_status, count(*) as total_users from users
group by employment_status
order by total_users desc; 

--5)Top 10 most common job titles.
select job_title, count(*) as total_users
from users
group by job_title
order by total_users desc

--------------------B. Income Analysis ----------------------------------------
select * from financial_profiles;
select * from users;
--6)Average income by region
select r.region_name, round(avg(fp.monthly_income_usd),2) as avg_income
from financial_profiles fp
join users u on u.user_id = fp.user_id -- join fin_pro user_id with user's user_id
join regions r on r.region_id = u.region_id -- join user's region_is with region's region_id
group by region_name 
order by avg_income desc;

-- ChatGPT's query
SELECT r.region_name,
       AVG(fp.monthly_income_usd) AS avg_income
FROM financial_profiles fp
JOIN users u ON fp.user_id = u.user_id
JOIN regions r ON u.region_id = r.region_id
GROUP BY r.region_name
ORDER BY avg_income DESC;

--7) income by age group(18-25, 26-35.....)
select min(age), max(age) from financial_profiles; --min age=18, max=69
select * from financial_profiles;

select
	case
		when age between 18 and 25 then '18-25'
		when age between 26 and 35 then '26-35'
		when age between 36 and 45 then '36-50'
		else '50+'
	end as age_groups,
	round(avg(monthly_income_usd), 2) as avg_income
from financial_profiles
group by age_groups
order by age_groups;

--8) Top 10% high-income users
select * from financial_profiles
where monthly_income_usd >
	(
		select percentile_cont(0.90)
		within group(order by monthly_income_usd)
		from financial_profiles
	);

--9) Income variation per region (standard deviation)	
select r.region_name, round(stddev(fp.monthly_income_usd),2) as income_veriation
from financial_profiles fp
join users u on u.user_id = fp.user_id
join regions r on r.region_id = u.region_id
group by region_name
order by income_veriation desc;

--10) Average income by gender
select * from users;
select * from financial_profiles;

select u.gender, round(avg(fp.monthly_income_usd),2) as avg_income
from financial_profiles fp
join users u on u.user_id = fp.user_id
group by gender
order by avg_income desc;

   --10.1) how many users per gender
   select gender, count(*) as gender_count from users
   group by gender
   order by gender_count desc


------------------------------C.Expenses & Budget Behavior ---------------------------------

--11)Expense-to-income ratio per user.
select user_id, monthly_income_usd, monthly_expenses_usd,
	   (monthly_income_usd / nullif(monthly_expenses_usd, 0)) as Expense_to_income
from financial_profiles;	   
	   

--12)Count of users spending > 90% of income.
select user_id, monthly_income_usd, monthly_expenses_usd
from financial_profiles
where (monthly_expenses_usd / nullif(monthly_income_usd,0)) > 0.90
	   

--13)Top 10 saving users (income – expenses).
select user_id, monthly_income_usd, monthly_expenses_usd,
       (monthly_income_usd - monthly_expenses_usd) as money_left
from financial_profiles
order by money_left desc limit 10;


--14)Who overspends? (expenses > income)   
select user_id, monthly_income_usd, monthly_expenses_usd
from financial_profiles
where monthly_expenses_usd > monthly_income_usd;  -- no one


--------------------------------D. Savings Trends------------------------------------
select * from regions;
select * from financial_profiles;
select * from users;

--15)Average savings by region.
select r.region_name, round(avg(fp.savings_usd),2) as avg_savings
from financial_profiles fp
join users u on u.user_id = fp.user_id
join regions r on r.region_id = u.region_id
group by r.region_name
order by avg_savings desc;


--16)Savings rate by education level.
select u.education_level, avg(fp.savings_usd) as avg_savings
from financial_profiles fp
join users u on u.user_id = fp.user_id
group by education_level
order by avg_savings desc;

--17)Users with 0 savings.
select user_id, savings_usd from financial_profiles
where savings_usd = 0;

--18)Identify users with savings decreasing over years.
with x as(
	select user_id,
		record_date,
		savings_usd,
		lag(savings_usd ) over(
		partition by user_id
		order by record_date
		) as prev_saving
	from financial_profiles
)
select * from x
where prev_saving is not null
	and savings_usd  < prev_saving;

--18) Savings-to-income ratio ranking
select user_id, monthly_income_usd, monthly_expenses_usd,
	   savings_usd, savings_to_income_ratio,
	   rank() over(order by savings_to_income_ratio desc )
from financial_profiles;	   

--19) Find users with unusually high savings (>50% of income)
select user_id, monthly_income_usd, monthly_expenses_usd,
	   savings_usd, savings_to_income_ratio
from financial_profiles
where savings_to_income_ratio > 0.50;

--20) Average savings by age group
select 
	case
		when age between 18 and 25 then '18-25'
		when age between 26 and 35 then '26-35'
		when age between 36 and 45 then '36-45'
		when age between 46 and 55 then '46-55'
		else '56+'
	end as age_groups,
round(avg(savings_usd),2) as avg_saving
from financial_profiles
group by age_groups
order by avg_saving desc;

--21)Users whose savings are consistently increasing (positive trend)
with u as(
select user_id,
	   monthly_income_usd,
	   monthly_expenses_usd,
	   savings_usd,
	   lag(savings_usd) over(
		partition by user_id
		order by record_date
	   ) as savings
from financial_profiles
),
trend as(
 select user_id,
 		count(*) filter(where savings > savings_usd) as increses,
		count(*) filter(where savings_usd is not null) as total_periods
	from u
	group by user_id
)
select * from trend
where increses = total_periods and total_periods > 0;

--22) Average savings by job title
select u.job_title, avg(fp.savings_usd) avg_saving
from financial_profiles fp
join users u on u.user_id = fp.user_id
group by job_title
order by avg_saving desc;

-----------------------------E.Loan and debt insights --------------------------------
select * from loans;
select * from financial_profiles;
select * from users;

--23) % of users who have at least one loan
select (count(distinct l.user_id)::decimal / (select count(*) from users)) * 100 as pct_users_with_loan
from users u
join loans l on u.user_id = l.user_id  --40%

--24) Distribution of loan types (counts)
select loan_type, count(*) as loan_count
from loans
group by loan_type
order by loan_count desc;

--25) Average EMI by loan type
select loan_type,
	   avg(monthly_emi_usd) as avg_emi,
	   avg(monthly_income_usd) / nullif(avg(monthly_emi_usd),0) as avg_emi_over_avg_income
from loans l
left join financial_profiles fp
on l.user_id = fp.user_id and l.record_date = fp.record_date
group by loan_type
order by avg_emi desc;

--26) Average loan amount by credit score band
select 
	case
	  	when fp.credit_score >=750 then 'Excellent'
		when fp.credit_score >=650 then 'Good'  
		when fp.credit_score >=550 then 'Fair'
		else 'Poor'
	end as score_band,
    avg(l.loan_amount_usd) as avg_loan_amount,
	count(*) as loan_count
from financial_profiles fp
left join loans l on l.user_id = fp.user_id  and l.record_date = fp.record_date
group by score_band
order by avg_loan_amount desc;

--27) High-interest loans (interest rate > 15%)
select loan_type, loan_amount_usd, loan_interest_rate_pct
from loans
where loan_interest_rate_pct > 15.00
order by loan_interest_rate_pct desc;

--28) Average Debt-to-Income (DTI) among borrowers by region
select r.region_name,
	avg(fp.debt_to_income_ratio) as avg_dti,
	count(distinct l.user_id) as borrowers
from financial_profiles fp
join loans l on l.user_id = fp.user_id and l.record_date = fp.record_date
join users u on u.user_id = fp.user_id
join regions r on u.region_id = r.region_id
group by region_name
order by avg_dti desc;

--29) Top 20 single loan amounts (largest loans)
SELECT loan_type, loan_amount_usd
from loans
order by loan_amount_usd desc limit 20;
	
--30) Total outstanding loan amount per user (sum of their loans at snapshot)
select user_id, sum(loan_amount_usd) as total_loan
from loans
group by user_id
order by total_loan desc;

--31) Loan counts per user (how many loans each user holds in that snapshot)
select user_id, count(*) total_loans
from loans
group by user_id
order by total_loans desc;

--32) Average loan term (months) by loan type
select loan_type, avg(loan_term_months)
from loans
group by loan_type;


--33) Is EMI unaffordable? (EMI > 40% of income)
select fp.user_id, fp.monthly_income_usd, l.monthly_emi_usd,
      round((l.monthly_emi_usd / nullif(fp.monthly_income_usd, 0)) * 100,2) as emi_to_income_ratio
from financial_profiles fp
join loans l on l.user_id = fp.user_id
where round((l.monthly_emi_usd / nullif(fp.monthly_income_usd, 0)) * 100,2) > 40.00
order by emi_to_income_ratio desc;

--34)Loans where borrower DTI is high (DTI > 0.6) AND credit_score is low (<600)
select fp.user_id, l.loan_type, fp.monthly_income_usd, l.loan_amount_usd,
       fp.debt_to_income_ratio, fp.credit_score
from financial_profiles fp
join loans l on l.user_id = fp.user_id
where fp.debt_to_income_ratio > 0.6
	and fp.credit_score < 600
order by fp.debt_to_income_ratio desc;	

--35) Correlation-style check: loan amount vs credit score (summary)
select corr(l.loan_amount_usd, fp.credit_score) as loan_credit_corr
from loans l
join financial_profiles fp 
on l.user_id = fp.user_id;

--34) Median loan amount overall (robust centre)
select percentile_cont(0.5) within group(order by loan_amount_usd) as median_loan_amount
from loans;

--35) Users who have loan records but zero EMI recorded (possible data issue)
select * from loans
where monthly_emi_usd is null or monthly_emi_usd = 0;

--36) Loan take-rate by age group (who borrows more)
select 
case
	when fp.age < 30 then 'Below 30'
	when fp.age between 30 and 45 then '30-45'
    else '46+'	
end as age_group,
count(l.*) as loan_count
from financial_profiles fp
join loans l on l.user_id = fp.user_id
group by age_group
order by loan_count desc;

--37) Average interest rate charged by credit score bucket
select 
case
	when fp.credit_score >= 750 then 'Excellent'
	when fp.credit_score >= 650 then 'Good'
	when fp.credit_score >= 550 then 'Fair'
	else 'Poor'
  end as credit_band,
avg(l.loan_interest_rate_pct) as avg_interest_rate
from financial_profiles fp
join loans l on l.user_id = fp.user_id
group by credit_band
order by avg_interest_rate desc;

--38) Regional average loan amount and EMI burden
select r.region_name,
	  avg(l.loan_amount_usd) as avg_loan_amount,
	  avg(l.monthly_emi_usd / nullif(fp.monthly_income_usd,0)) as avg_emi_to_loan_ratio
from loans l
join financial_profiles fp
     on fp.user_id = l.user_id and fp.record_date = l.record_date
join users u
     on u.user_id = fp.user_id
join regions r
     on r.region_id = u.region_id
group by r.region_name
order by avg_emi_to_loan_ratio desc;

----------------------------F.Credit Score Analysis ---------------------------
--39)Credit score distribution (counts per score) 
select credit_score, count(*)
from financial_profiles
group by credit_score
order by count(*) desc;

--40)Credit score buckets (Excellent → Poor)
select * 
from (
SELECT CASE
         WHEN credit_score >= 750 THEN 'Excellent'
         WHEN credit_score >= 700 THEN 'Very Good'
         WHEN credit_score >= 650 THEN 'Good'
         WHEN credit_score >= 600 THEN 'Fair'
         ELSE 'Poor'
       END AS score_bucket,
       COUNT(*) AS cnt
FROM financial_profiles
GROUP BY score_bucket
) as t
order by array_position(array['Excellent','Very Good','Good','Fair','Poor'],score_bucket)

--41) Average credit score by age
select age, avg(credit_score) as avg_crd
from financial_profiles
group by age
order by avg_crd desc;

--42) Average credit score by region
select r.region_name, avg(fp.credit_score) as credit_score
from financial_profiles fp
join users u 
     on u.user_id = fp.user_id
join regions r
     on r.region_id = u.region_id
group by r.region_name
order by credit_score desc;

--43) Average credit score by income bucket
select
 case
 	when monthly_income_usd < 2000 then '<2k'
	when monthly_income_usd between 2000 and 4999 then '2k - 4.9k' 
	when monthly_income_usd between 5000 and 9999 then '5k - 9.9k'
	else '10k+'
end as income_bucket,
avg(credit_score) as avg_crd_score,
count(*) as cnt
from financial_profiles
group by income_bucket
order by avg_crd_score desc;

--44) Median credit score overall
select percentile_cont(0.5) within group(order by credit_score) as median_credit_score
from financial_profiles;

--45) Top 50 users with highest credit scores (ties included)
select user_id, credit_score
from financial_profiles
order by credit_score desc limit 50;

--46) Bottom 50 users (worst credit)
select user_id, credit_score
from financial_profiles
order by credit_score asc limit 50;

--47)Correlation: credit score vs debt-to-income ratio
select corr(credit_score::float, debt_to_income_ratio::float) as corr_credit_dti
from financial_profiles;

--48) Credit score by education level
select u.education_level,
       avg(fp.credit_score) as avg_score,
	   count(*) as cnt
from financial_profiles fp
join users u
     on u.user_id = fp.user_id
group by u.education_level
order by avg_score desc;

--49) Credit score trend over years (time series)
select date_part('year', record_date) as record_year,
       avg(credit_score) as avg_score,
	   count(*) as cnt
from financial_profiles
group by record_year
order by record_year;

--50) Average credit score for borrowers vs non-borrowers
select has_loan,
       avg(credit_score) as avg_score
from financial_profiles
group by has_loan;

--51) Average credit score by loan product (join loans) loan type
select l.loan_type,
       avg(fp.credit_score) as avg_score
from financial_profiles fp
join loans l on l.user_id = fp.user_id
group by loan_type;
	   
--52) Credit score improvement/worsening per user between snapshots
select user_id,
	   record_date,
	   credit_score,
	   lag(credit_score) over(partition by user_id order by record_date) as previ_score,
	   credit_score - lag(credit_score) over(partition by user_id order by record_date) as changed_score
from financial_profiles
order by user_id, record_date

--53) Users with consistent credit improvement (improved every period)
with changes as(
	select user_id,
	case
	when credit_score > lag(credit_score) over (partition by user_id order by record_date) then 1
	when credit_score = lag(credit_score) over (partition by user_id order by record_date) then 0
	else -1 
	end as change_flag
from financial_profiles	
)
select user_id
from changes
group by user_id
having min(change_flag) >= 1;

--54) Users with volatile credit scores (high stddev)
select user_id,
		stddev(credit_score) as score_stddev,
		count(*) as observ
from financial_profiles
group by user_id
having count(*) > 1
order by score_stddev desc;

--55) Average credit score by age group & region (two-dimensional)
select region_name, avg(credit_score) as avg_credit_score, count(*) as cnt
from(
     select fp.*,
	 r.region_name,
	 case
	 when fp.age between 18 and 25 then '18-25'
	 when fp.age between 26 and 35 then '26-35'
	 when fp.age between 36 and 50 then '36-50'
	 else '50+'
	 end as age_group
	from financial_profiles fp
	join users u on u.user_id = fp.user_id
	join regions r on r.region_id = u.region_id
) t
group by region_name, age_group
order by region_name, age_group


--56) Percentile cutoffs for credit score (25%, 50%, 75%, 90%)
select percentile_cont(0.25) within group(order by credit_score) as p25,
	   percentile_cont(0.50) within group(order by credit_score) as p50,
	   percentile_cont(0.75) within group(order by credit_score) as p75,
	   percentile_cont(0.90) within group(order by credit_score) as p90
from financial_profiles	   

--57) Relationship between credit score and savings behaviour
select corr(credit_score, savings_to_income_ratio) as corr_
from financial_profiles;

select * from financial_profiles;
select * from users;
select * from loans;


select monthly_income_usd, monthly_expenses_usd
from financial_profiles
where monthly_expenses_usd > monthly_income_usd

select has_loan, avg(credit_score)
from financial_profiles
group by has_loan

