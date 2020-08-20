#unique "other" category spend locations
drop table if exists UniqueOtherVendorsVisited;
create temporary table UniqueOtherVendorsVisited as
select Unique_member_identifier
	,count(distinct ex_transactiondescription) as UniqueOtherVendorsVisited
from Ian_FE
where Transaction_Category = 'other'
group by Unique_member_identifier;

#amount spent in entertainment (alcohol, entertainment,travel)
drop table if exists TotalEntertainmentSpend;
create temporary table TotalEntertainmentSpend as
select Unique_member_Identifier
		,sum(TransAmount) as TotalEntertainmentSpend
 from Ian_FE
 where Transaction_Category in ('alcohol', 'entertainment','travel')
 group by Unique_member_identifier;
 
 select distinct Transaction_Category from Ian_FE;
 
Drop table if exists Tom_FE_SeeksEntertainment;
Create table Tom_FE_SeeksEntertainment as
Select a.*
		,b.TotalEntertainmentSpend
from UniqueOtherVendorsVisited a
left join TotalEntertainmentSpend b on a.Unique_Member_Identifier = b.Unique_Member_Identifier
;