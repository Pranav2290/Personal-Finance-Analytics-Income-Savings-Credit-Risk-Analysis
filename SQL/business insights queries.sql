--------------------------A. Financial Wellness & Stress Analysis-------------------
--1) Financial wellness score by region (Savings strength − Debt stress)
select r.region_name,
       avg(fp.savings_to_income_ratio - debt_to_income_ratio) as wellness
from financial_profiles fp
join users u on u.user_id = fp.user_id
join regions r on u.region_id = r.region_id
group by region_name
order by wellness desc;

--2) Average savings percentage of income (overall)
select user_id, monthly_income_usd,
		avg(savings_to_income_ratio) * 100 as saving_income_ratio
from financial_profiles
group by user_id, monthly_income_usd

--3) Do higher incomes always mean higher savings?
select income_bracket,
       avg(savings_to_income_ratio) as avg_saving_ratio
from (
select
   case
     when monthly_income_usd > (select avg(monthly_income_usd) from financial_profiles) then 'High income'
	 else 'Low income'
	end as income_bracket,
	savings_to_income_ratio
from financial_profiles
) t
group by income_bracket

--4) Financially stressed users (Expenses > income AND poor credit)
select user_id,
	   monthly_expenses_usd,
	   monthly_income_usd,
	   credit_score
from financial_profiles
where monthly_expenses_usd > monthly_income_usd
	and credit_score < 600;

--------------------------------------B. Debt Risk & Credit Strategy-----------------------------------------
--5) Debt risk segmentation using DTI
select 
	case 
	when debt_to_income_ratio < 0.30 then 'Low Risk'
	when debt_to_income_ratio < 0.60 then 'Medium Risk'
	else 'High Risk'
    end as risk,
	count(*) cnt
from financial_profiles	
where has_loan = True
group by risk
order by cnt desc;

--6) Which loan types attract higher-risk users
select l.loan_type,
	   avg(fp.debt_to_income_ratio) as avg_dti,
	   avg(fp.credit_score) as avg_credit
from financial_profiles fp
join loans l on l.user_id = fp.user_id
group by l.loan_type
order by avg_dti desc;

--7) EMI affordability check (EMI > 40% of income)
select fp.user_id, fp.monthly_income_usd, l.monthly_emi_usd,
       (l.monthly_emi_usd / fp.monthly_income_usd)  as emi_ratio
from financial_profiles fp
join loans l on fp.user_id = l.user_id
where (l.monthly_emi_usd / fp.monthly_income_usd) > 0.40

--8) High-risk borrowers (low credit + high DTI)
select fp.user_id, l.loan_amount_usd, 
       fp.debt_to_income_ratio, fp.credit_score
from financial_profiles fp
join loans l on l.user_id = fp.user_id
where credit_score < 600 
     and debt_to_income_ratio > 0.60;

------------------------------C. Regional & Demographic Business Insights------------------------------
--9) Best region overall (credit + savings + debt)
select r.region_name,
       avg(fp.credit_score) as avg_credit,
	   avg(fp.savings_usd) as avg_savings,
	   avg(l.loan_amount_usd) as avg_loan
from financial_profiles fp
join loans l on l.user_id = fp.user_id
join users u on u.user_id = fp.user_id
join regions r on r.region_id = u.region_id
group by r.region_name;

--10) Which age group borrows the most?
select 
    case 
	when fp.age between 18 and 25 then '18-25'
	when fp.age between 26 and 35 then '26-35'
	when fp.age between 36 and 50 then '36-50'
	else '50+'
	end as age_bracket,
avg(loan_amount_usd) as avg_loan,
count(*) as cnt
from financial_profiles fp
join loans l on l.user_id = fp.user_id
group by age_bracket
order by cnt desc;


--11) Job roles with highest financial risk
select u.job_title,
       avg(fp.debt_to_income_ratio) as avg_dti,
	   avg(fp.credit_score) as avg_credit
from users u
join financial_profiles fp
    on fp.user_id = u.user_id
group by job_title
order by avg_dti desc;

--12) Gender-wise financial comparison
select u.gender,
	  avg(fp.monthly_income_usd) as avg_income,
	  avg(fp.savings_usd) as avg_saving,
	  avg(fp.debt_to_income_ratio) as avg_dti
from financial_profiles fp
join users u on u.user_id = fp.user_id
group by gender;

----------------------D. Time-Based Strategic Insights--------------------------------
--13) Credit score trend over years
select extract(year from record_date) as the_year,
       avg(credit_score) as avg_score
from financial_profiles
group by the_year
order by the_year;

--14) Year with maximum loan issuance
select extract(year from record_date) as the_year,
       count(*) as cnt
from loans
group by the_year
order by count(*) desc;

--15)Savings drop after taking loans
with prev_saving as(
	select 
	     user_id,
		 record_date,
		 savings_usd,
		 lag(savings_usd) over(partition by user_id order by record_date) as old_saving
	from financial_profiles	 
) 
select * from prev_saving
where old_saving > savings_usd;  --  users because every user(record) is unique


--16) Customer financial segmentation
select user_id,
	case
		when monthly_income_usd > 8000
		 and savings_to_income_ratio > 0.40
		 and debt_to_income_ratio < 0.30
		then 'Wealthy - Low Risk' 

		when monthly_income_usd < 4000
		 and debt_to_income_ratio > 0.60
		then 'Low income - High Risk' 

		else 'Middle Segment'
	end as customer_segmentation
from financial_profiles;	

