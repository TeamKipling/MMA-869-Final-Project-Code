use MMA_869;

#First off, determining the total number of theatre visits
#Theatre Visitation Stats - all transactions with "cineplex" in the category are a theatre visit
drop table if exists TheatreVisitsAndSpend;
create temporary table TheatreVisitsAndSpend as
select Unique_Member_Identifier
	,count(distinct date(pointdt)) as TheatreVisits
    ,sum(TransAmount) as NonBlackTransCineplexSpend
From Ian_FE
where Transaction_Category in ('Cineplex Redemption','Cineplex Tickets', 'Cineplex','Cineplex Concessions')
group by Unique_Member_Identifier;

#Black Card attributes - customer earn and burn as an indicator of engagement/cost (1 point ~= $0.0087 cost to Cineplex)
drop table if exists BlackCardAttributes;
create temporary table OnlineValues as
Select Unique_Member_Identifier
	   ,BlackEarnCount
		,BlackEarnPointTotal
		,BlackBurnCount
		,BlackBurnPointTotal
from SP_PointTypeStatistics;

#Concession Stats - how much/often do customers buy concessions? (currently earn on concessions is 5 points per $1).. take concessions % purchase from factattribute table
drop table if exists ConcessionSpendStats;
create temporary table ConcessionSpendStats as
select a.Unique_Member_Identifier
	,a.TotalConcessionSpend
	,b.TheatreVisits
	,a.TotalConcessionSpend/b.TheatreVisits as AvgConcessionSpend
    ,a.ConcessionCount as TotalConcessionTrans
from
(Select Unique_Member_Identifier
		,sum(case when points > 0 then points*0.2 else 0 end) as TotalConcessionSpend
        ,count(1) as ConcessionCount
from Ian_FE
where Transaction_Category in ('Cineplex Concessions')
group by Unique_Member_Identifier) a
join TheatreVisitsAndSpend b on a.Unique_Member_Identifier = b.Unique_Member_Identifier;

#Ticket Spend - total spend and per month (total spend/total transaction months). Ticket prices are obtained via the cineplex website and this link: https://www.redflagdeals.com/latest-news/17/01/11/cineplex-movie-formats-explained-what-are-premium-tickets-and-how-you-can-save-money/

#Adult tickets (regular/IMAX): ~13.50/16.50 (avg 15), costs 1000 points to redeem
#Child tickets 12.95, generates 50/75 points
#Adult Tickets premium - has a wide range: $15.50-24.50 avg(20), costs 1500 to redeem
#Adult Tickets VIP - ~20-25 (avg 22.50), costs 2000 to redeem, generates 200
drop table if exists TicketSpendStats;
create temporary table TicketSpendStats as
select Unique_member_identifier
			, sum(case when points = 100 and ex_transactiondescription like ('child%') then 12.95
				   when points = 100 then 15
				   when points = -100 then -15
                   when points = 50 or points = 75 then 12.95
                   when points = -50 or points = -75 then -12.95
                   when points = 150 then 20
                   when points = -150 then -20
                   when points = 200 then 22.50
                   when points = -200 then -22.50
				   end) as TotalTicketSpend
            , TIMESTAMPDIFF(MONTH, min(pointdt), max(pointdt)) as ActiveTicketMonths
from Ian_FE 
where Transaction_Category in ('Cineplex Tickets')
group by Unique_member_identifier;

#Value related tendencies (Tuesdays are half off ticket prices)
drop table if exists ValueRelatedTendencies;
create temporary table ValueRelatedTendencies as
Select Unique_member_identifier
		,TuesdayAttendee_tendancy
        ,TuesdayAttendee_value
        ,ConcessionPurchaser_tendancy
        ,ConcessionPurchaser_value 
from SP_FactAttribute;

#Customer Cost - sum of total points burned
drop table if exists PointsBurnCostStats;
create temporary table PointsBurnCostStats as
select Unique_Member_Identifier
		,BlackBurnCount
		,BlackBurnPointTotal
from SP_PointTypeStatistics;

#Total Cineplex Spend (Black Card trans on tickets + concessions, + actual Cineplex ex_transactiondescription trans)
drop table if exists TotalCineplexSpend;
Create temporary table TotalCineplexSpend as
Select a.Unique_Member_Identifier
	,ifnull(a.NonBlackTransCineplexSpend,0) + ifnull(b.TotalConcessionSpend,0) + ifnull(c.TotalTicketSpend,0) as CineplexSpend
from TheatreVisitsAndSpend a 
left join ConcessionSpendStats b on a.Unique_Member_Identifier = b.Unique_Member_Identifier 
left join TicketSpendStats c on a.Unique_Member_Identifier = c.Unique_Member_Identifier;

select * from TotalCineplexSpend;

#Putting it all together - Value conscious attributes
#Creating the FE_TechSavvy_Marketability table containing these engineered features
Drop table if exists Tom_FE_ValueConsciousAndCostFeatures;
Create table Tom_FE_ValueConsciousAndCostFeatures as
Select a.*
		,e.TheatreVisits
		,f.CineplexSpend
		,b.BlackBurnCount
        ,b.BlackBurnPointTotal
        ,c.TotalTicketSpend
        ,c.ActiveTicketMonths
        ,case when ActiveTicketMonths= 0 then c.TotalTicketSpend 
			else c.TotalTicketSpend/c.ActiveTicketMonths end as AverageMonthlyTicketSpend
        ,d.TotalConcessionSpend
        ,d.TotalConcessionTrans
        ,d.AvgConcessionSpend
from ValueRelatedTendencies a
join PointsBurnCostStats b on a.Unique_Member_Identifier = b.Unique_Member_Identifier
left join TicketSpendStats c  on a.Unique_Member_Identifier = c.Unique_Member_Identifier
left join ConcessionSpendStats d  on a.Unique_Member_Identifier = d.Unique_Member_Identifier
left join TheatreVisitsAndSpend e on a.Unique_Member_Identifier = e.Unique_Member_Identifier
left join TotalCineplexSpend f on a.Unique_Member_Identifier = f.Unique_Member_Identifier
;

 