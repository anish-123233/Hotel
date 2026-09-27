select * from fact_bookings;
select * from fact_aggregated_bookings;
select * from dim_hotels;

with property_metrics as(
select d.property_id,d.property_name,round((100.00 * sum(f.revenue_realized) / sum(f.revenue_generated)::numeric),2) as realization_perc,
round(sum(f.revenue_realized) / count(*) filter(where booking_status = 'Checked Out')::numeric,2) as adr,
round(avg(f.ratings_given)::numeric,2) as avg_ratings,count(*) filter(where booking_status = 'Checked Out')
as checkk	from dim_hotels d
join fact_bookings f on d.property_id = f.property_id
group by 1,2
order by 5 desc
	),
occupancy as(
	select p.*,round(100.00 * p.checkk::numeric/sum(f.capacity),2) as occ_perc from property_metrics p 
	join fact_aggregated_bookings f on p.property_id = f.property_id
	group by 1,2,3,4,5,6
	)
select case when avg_ratings>=4 then 'Top (>=4.0)' when avg_ratings>=3 then 'Mid (=>3.0)' else 'Bottom (<3.0)' end as "Rating Tier",
count(*) as "Properties", round(avg(occ_perc),2)||'%' as "Avg Occupancy",round(avg(realization_perc),2)||'%' as "Avg Realization %",
round(avg(adr)) as "Avg ADR" from occupancy
	group by 1
	order by 2 desc;