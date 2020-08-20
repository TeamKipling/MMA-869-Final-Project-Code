drop table if exists NightTimeAndWeekend;
create temporary table NightTimeAndWeekend as
Select Unique_Member_Identifier
		,sum(NightTimeVisitInd) as NightTimeVisits
        ,sum(WeekendVisitInd) as WeekendVisits
        ,sum(WeekendNightTimeVisitInd) as WeekendNightTimeVisits
from 
(
select Unique_Member_Identifier
	,date(pointdt) as TransDates
    ,max(night_time) as NightTimeVisitInd
    ,max(case when DayofWeek in (1,6,7) then 1 else 0 end) as WeekendVisitInd
    ,max(case when DayofWeek in (1,6,7) and night_time = 1 then 1 else 0 end) as WeekendNightTimeVisitInd
From Ian_FE
where Transaction_Category in ('Cineplex Redemption','Cineplex Tickets', 'Cineplex','Cineplex Concessions')
group by Unique_Member_Identifier
		,date(pointdt)) a
group by Unique_Member_Identifier;

drop table if exists Tom_NightTimeAndWeekendTheaterVisits;
create table Tom_NightTimeAndWeekendTheaterVisits as
Select b.*
		,a.TheatreVisits
		,NightTimeVisits/TheatreVisits as NightTimePct
        ,WeekendVisits/TheatreVisits as WeekendPct
        ,WeekendNightTimeVisits/TheatreVisits as WeekendNightTimePct
from
(
select Unique_Member_Identifier
	,count(distinct date(pointdt)) as TheatreVisits
From Ian_FE
where Transaction_Category in ('Cineplex Redemption','Cineplex Tickets', 'Cineplex','Cineplex Concessions')
group by Unique_Member_Identifier) a
join NightTimeAndWeekend b on a.Unique_Member_Identifier = b.Unique_Member_Identifier;

select * from Ian_FE where HourofDay >= 18 limit 100 ;

select * from NightTimeAndWeekendTheaterVisits;