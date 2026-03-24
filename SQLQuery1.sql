-- membuat tabel untuk analisis
select * 
into dbo.hotel
from (
	select * from dbo.['2018$']
	union all
	select * from dbo.['2019$']
	union all
	select * from dbo.['2020$']
) h;

-- menambahkan discount dan meal cost
alter table dbo.hotel
add  discount float
	,meal_cost float

update h
set
	 h.discount = ms.Discount
	,h.meal_cost = mc.Cost
from dbo.hotel h
left join dbo.market_segment$ ms
	on h.market_segment = ms.market_segment
left join dbo.meal_cost$ mc
	on h.meal = mc.meal

-- mengubah null menjadi 0
update dbo.hotel
set agent = 0
where agent is NULL

update dbo.hotel
set company = 0
where company = 'NULL'

-- standarisasi yes dan no
alter table dbo.hotel
alter column is_canceled varchar(3)
update dbo.hotel
set is_canceled = case when is_canceled = 0 then 'No' else 'Yes' end

alter table dbo.hotel
alter column is_repeated_guest varchar(3)
update dbo.hotel
set is_repeated_guest = case when is_repeated_guest = 0 then 'No' else 'Yes' end


-- menambahkan date
alter table dbo.hotel
add arrival_date date

update dbo.hotel
set arrival_date = datefromparts(
		arrival_date_year,
		case arrival_date_month
		when 'January' then 1
		when 'February' then 2
		when 'March' then 3
		when 'April' then 4
		when 'May' then 5
		when 'June' then 6
		when 'July' then 7
		when 'August' then 8
		when 'September' then 9
		when 'October' then 10
		when 'November' then 11
		when 'December' then 12
	end,
	arrival_date_day_of_month
)

-- total booking
select 
	count(*) as total_booking
from dbo.hotel

-- cancelation rate (KPI)
select
	is_canceled, 
	count(*) as total,
	round(
		count(is_canceled) * 100 / 
		sum(count(is_canceled)) over(), 2) as percentage
from dbo.hotel
group by is_canceled

-- booking lead time (KPI)
select
	avg(lead_time) as average_lead_time
from dbo.hotel
where is_canceled = 'No'

-- highest average daily rate (KPI)
select
	hotel,
	arrival_date_year,
	avg(adr) as average_daily_rate
from dbo.hotel
where is_canceled = 'No'
group by hotel, arrival_date_year
order by Average_Daily_Rate desc

-- length of stay (KPI)
select
	hotel,
	arrival_date_year,
	avg(stays_in_week_nights+stays_in_weekend_nights) as average_LOS
from dbo.hotel
where is_canceled = 'No'
group by hotel, arrival_date_year
order by arrival_date_year

-- repeat guest ratio (KPI)
select
	is_repeated_guest as repeat_guest, 
	count(*) as total,
	round(
		count(is_repeated_guest) * 100 / 
		sum(count(is_repeated_guest)) over(), 2) as percentage
from dbo.hotel
group by is_repeated_guest

-- revenue hotel
alter table dbo.hotel
add revenue float

update h
set revenue = 
		round(
			(stays_in_week_nights+stays_in_weekend_nights)*adr*(1-Discount/1) + 
			(stays_in_week_nights+stays_in_weekend_nights)*meal_cost*(1-Discount/1),
	2)	
from dbo.hotel h

select
	hotel
	,arrival_date_year
	,round(sum(revenue),2) as revenue
from dbo.hotel
where is_canceled = 'No'
group by hotel,arrival_date_year
order by sum(revenue) desc

select * from dbo.hotel