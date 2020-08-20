use MMA_869;

#Percentage of visits that include a child
drop table if exists AttendsWithChildPct;
create temporary table AttendsWithChildPct as
select Unique_Member_Identifier
	,AttendsWithChild_value
From SP_FactAttribute;

#Group Fast food spend indicator (if greater than $15 in one bill at fast food, indication of 2+ people)
drop table if exists FoodGroupSpendInd;
create temporary table FoodGroupSpendInd as
select Unique_Member_Identifier
	,avg(case when TransAmount >= 15 and Transaction_Category = 'Fast Food' then 1 else 0 end) as GroupFastFoodPct
    ,avg(case when TransAmount >= 30 and Transaction_Category = 'Restaurant' then 1 else 0 end) as GroupRestaurantPct
From Ian_FE
where Transaction_Category in ('Fast Food','Restaurant')
group by Unique_Member_Identifier;

#Group Ticket Purchases
drop table if exists GroupTicketPurchases;
create temporary table GroupTicketPurchases as
select Unique_Member_Identifier
	,sum(case when NumTicketsPurchased > 1 then 1 else 0 end)/count(TicketPuchaseDate) as GroupTicketPurchasePct
from
(
select Unique_Member_Identifier
	,date(pointdt) as TicketPuchaseDate
    ,sum(case when points > 0 then 1 else 0 end) as NumTicketsPurchased
From Ian_FE
where Transaction_Category in ('Cineplex Redemption','Cineplex Tickets')
group by Unique_Member_Identifier,date(pointdt)) a
group by Unique_Member_Identifier;

select * from GroupTicketPurchases where Unique_Member_Identifier = '0358865D-396F-416D-97B5-CA6FA9621002';

select * from SP_ProxyPointTransaction limit 10;

select * from SP_PointsType limit 100;

select * from Ian_FE where Unique_member_identifier = '0358865D-396F-416D-97B5-CA6FA9621002';

select distinct points, ex_transactiondescription from Ian_FE where Transaction_Category = 'Cineplex Redemption';

#Creating the FE_Group_Preferences table containing these engineered features
Drop table if exists Tom_FE_Group_Preferences;
Create table Tom_FE_Group_Preferences as
Select a.*
		,b.GroupFastFoodPct
        ,b.GroupRestaurantPct
        ,c.GroupTicketPurchasePct
from AttendsWithChildPct a
left join FoodGroupSpendInd b on a.Unique_Member_Identifier = b.Unique_Member_Identifier
left join GroupTicketPurchases c  on a.Unique_Member_Identifier = c.Unique_Member_Identifier
;

