#App Logon Indicator
drop table if exists AppLogons;
create temporary table AppLogons as
select Unique_Member_Identifier
	   ,max(case when AccountHistoryTypeID = 607 then 1 else 0 end) as Scene_App_Logon_Count
from SP_AccountHistory
group by Unique_member_identifier;

#EnrollmentSourceKey_TECHSAVVY
drop table if exists DigitalEnrollment_Ind;
create temporary table DigitalEnrollment_Ind as
select Unique_Member_Identifier
	,case when EnrollmentSourceKey in (2 ,4 ,16 , 21 , 23, 25 , 26 ,27 , 30 , 32 ,33 ,34 ) THEN 1 ELSE 0 end as DigitalEnrollment_Ind
From SP_FactEnrollment
group by Unique_Member_Identifier;

#Marketability
drop table if exists Marketability;
create temporary table Marketability as
select Unique_Member_Identifier
		,isQuality
        ,hasActivity
        ,case when hasActivity = 1 and isMarketable = 0 then 1 else 0 end as DirectMarketingPotentialInd
from SP_QualityActivity
where ActivityMonth = '2017-11-01';

#Online values - tickets purchased and emails (marketing) opened
drop table if exists OnlineValues;
create temporary table OnlineValues as
Select Unique_Member_Identifier
	   ,OnlineTicketPurchaser_value
       ,OpensEmail_value
from SP_FactAttribute;

#Using mobile app to purchase tickets feature
drop table if exists OnlineTicketPurchases;
create temporary table OnlineTicketPurchases as
select Unique_Member_Identifier
	   ,sum(case when ex_transactiondescription like ("online bonus%") then 1 else 0 end) as OnlineTicketPurchases
from Ian_FE
group by Unique_Member_Identifier;

#OnlineShoppingTendencies (potential marketability online)
drop table if exists OnlineShoppingTendencies;
create temporary table OnlineShoppingTendencies as
select Unique_Member_Identifier
	   ,count(1) as TotalOnlineShoppingPurchases
from Ian_FE
where Transaction_Category in ('Online Department Store','Online Fast Food','Online App Store')
group by Unique_Member_Identifier;

#Creating the FE_TechSavvy_Marketability table containing these engineered features
Drop table Tom_FE_TechSavvy_Marketability;
Create table Tom_FE_TechSavvy_Marketability as
Select a.*
		,b.DigitalEnrollment_Ind
        ,c.isQuality
        ,c.hasActivity
        ,c.DirectMarketingPotentialInd
        ,d.OnlineTicketPurchaser_value
        ,d.OpensEmail_value
        ,e.OnlineTicketPurchases
        ,f.TotalOnlineShoppingPurchases
from AppLogons a
join DigitalEnrollment_Ind b on a.Unique_Member_Identifier = b.Unique_Member_Identifier
join Marketability c  on a.Unique_Member_Identifier = c.Unique_Member_Identifier
join OnlineValues d  on a.Unique_Member_Identifier = d.Unique_Member_Identifier
join OnlineTicketPurchases e  on a.Unique_Member_Identifier = e.Unique_Member_Identifier
left join OnlineShoppingTendencies f on a.Unique_Member_Identifier = f.Unique_Member_Identifier
;
