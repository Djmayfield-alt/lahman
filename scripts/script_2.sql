-- 1. What range of years for baseball games played does the provided database cover? 

select
	min(debut),
	max(finalgame)
from people

-- earliest - 1871-05-04	latest - 2017-04-03

select	
	min(yearid),
	max(yearid),
	count(distinct yearid)
from appearances

-- 1871	2016 146



-- 2. Find the name and height of the shortest player in the database. How many games did he play in? What is the name of the team for which he played?

select 
	distinct p.namefirst,
	p.namelast,
	round(cast(p.height / 12 as numeric),2) as height_in_feet,
	a.G_all,
	t.name
from people p
inner join appearances a
	on p.playerid = a.playerid
inner join teams t
	on a.teamid = t.teamid
where height is not null
     and p.namefirst like 'Eddie'
order by height_in_feet
limit 1



-- Eddie Gaedel, 3.58ft, 1 game played, St. Louis Browns

-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each player’s first and last names as well as the total salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?

select
	distinct p.namefirst,
	p.namelast,
	sum(s2.salary) over(partition by p.playerid) as salary
from people p
inner join collegeplaying c
	on p.playerid = c.playerid
inner join schools s1
	on c.schoolid = s1.schoolid
inner join salaries s2
	on p.playerid = s2.playerid
where s1.schoolname like ('Vanderbilt University')
and s2.salary is not null
-- group by 1,2
order by salary desc


-- David Price $245,553,888


-- Walkthrough

select
	namefirst,
	namelast,
	sum(s.salary) as total_salary
from people p	
inner join(
	select
		distinct playerid
	from collegeplaying
	where schoolid = 'vandy'
) cp
	on p.playerid=cp.playerid
left join salaries s 
on p.playerid = s.playerid
group by 1,2
order by total_salary desc nulls last

-- 4. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in 2016.

SELECT
	CASE WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos IN('SS','1B','2B','3B') THEN 'Infield'
		WHEN pos IN('P','C') THEN 'Battery'
		ELSE '?' END AS position,
	SUM(po)
FROM fielding
WHERE yearid=2016
GROUP BY 1;

-- Battery	41424
-- Infield	58934
-- Outfield 29560
   
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?



select
    (yearid / 10) * 10 as decade,
	round((sum(so)::decimal)/(sum(g)::decimal/2),2) as strikeouts,
	round(sum(hr)::decimal/(sum(g)::decimal/2),2) as homeruns
from teams
where yearid >= 1920
group by 1
order by 1 desc;

-- walkthrough 

select 
	yearid / 10 * 10 as decade,
	round(sum(so::numeric) / (sum(g::numeric)/2),2) as avg_strikeout,
	round(sum(hr::numeric) / (sum(g::numeric)/2),2) as avg_homerun
from teams
where yearid >= 1920
group by 1
order by 1 desc

-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.



select
	p.namefirst,
	p.namelast,
	b.sb,
	b.cs,
	round((((b.sb - b.cs)*1.0 / b.sb) *100),2) as successful_sb
from people p
left join batting b
	on p.playerid = b.playerid
where b.sb >= 20
	and b.yearid = 2016
group by 1,2,3,4
order by successful_sb desc


-- Chris Owings 90.48%

-- walkthrough 
with cte as (
select 
	playerid,
	round((sum(sb::numeric)/ (sum(sb::numeric)+(sum(cs::numeric)))) * 100,2) as sb_success
from batting
where yearid = 2016
group by 1
having sum(sb + cs) > 19
order by sb_success desc
limit 1
)

select
p.namefirst,
p.namelast,
c.sb_success
from people p 
inner join cte c
	on p.playerid = c.playerid

-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world series? 

select
	teamid,
	yearid,
	w,
	wswin
from teams
where yearid >= 1970
	and yearid <=2016
	and wswin = 'N'
order by w desc

-- Sea - 116

-- What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion – determine why this is the case. Then redo your query, excluding the problem year. 

select
	teamid,
	yearid,
	w,
	wswin
from teams
where yearid >= 1970
	and yearid <=2016
	and wswin = 'Y'
order by w 

-- LAN 63 wins 


-- How often from 1970 – 2016 was it the case that a team with the most wins also won the world series? 

with wsw as 
(select
	count(teamid) as ws_winner
from teams
where yearid >=1970
and yearid <=2016
and wswin ='Y')


mwsw as select
	count(*) as all_ws_winner
from teams t
where t.wswin = 'Y'
and t.yearid >= 1970
and t.yearid <=2016
and t.w =
	(select
		max(t2.w)
		from teams t2
		where t.yearid=t2.yearid)


WITH ranks AS (
	SELECT -- selects information to connect with other tables and creates a rank based on wins from greates to least for each year.
		teamid,
		yearid,
		wswin,
		RANK() OVER(PARTITION BY yearid ORDER BY w DESC) AS wrank
	FROM teams
	WHERE yearid>=1970
),
total_count AS( -- selects all wswins
	SELECT
		COUNT(*) AS tot_count
	FROM ranks AS r
	WHERE wswin='Y'
		AND yearid>=1970
),
part AS( -- selects all wswins AND most points
	SELECT
		COUNT(*) AS part_count
	FROM ranks AS r
	WHERE wswin='Y'
		AND wrank=1
		AND yearid>=1970
)
SELECT
	t.tot_count,
	p.part_count,
	ROUND((p.part_count::decimal/t.tot_count::decimal)*100,2) AS percent
FROM total_count AS t, part AS p
GROUP BY 1,2



-- What percentage of the time?

-- 46	12	26.09


-- walkthrough
with most_wins as(
select
	name,
	yearid,
	w,
	wswin,
	rank() over(partition by yearid order by w desc) as rank_wins
from teams
where yearid >= 1970
	and yearid <=2016
	and yearid not in (1981)
order by yearid
),

set_up as (select 
	sum(case when wswin = 'Y' and rank_wins = 1 then 1
	else 0
end) as ws_and_mostwins,
count (distinct yearid) as numyears
from most_wins)

select 
ws_and_mostwins,
numyears,
round(ws_and_mostwins::numeric / numyears::numeric,2)*100
from set_up

-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the top 5 average attendance per game in 2016 (where average attendance is defined as total attendance divided by number of games). Only consider parks where there were at least 10 games played. Report the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.


select
	park,
	team,
	round(((attendance)*1.0 / games),2) as avg_att
from homegames
where games >=10
and year = 2016
group by 1,2,3
order by avg_att desc
limit 5

-- top 5 

-- LOS03	LAN	45719.90
-- STL10	SLN	42524.57
-- TOR02	TOR	41877.77
-- SFO03	SFN	41546.37
-- CHI11	CHN	39906.42

-- bottom 5 

-- STP01	TBA	15878.56
-- OAK01	OAK	18784.02
-- CLE08	CLE	19650.21
-- MIA02	MIA	21405.21
-- CHI12	CHA	21559.17

-- wlakthrough
with highest as
(select
p.park_name,
t.name,
round(sum(h.attendance::numeric) / sum(h.games::numeric),0) as avg_attendance,
'top 5'
from homegames h
inner join parks p
on h.park = p.park
inner join teams t
on h.team = t.teamid
and h.year = t.yearid
where year = 2016
group by 1,2
order by avg_attendance desc
limit 5),



lowest as (select
p.park_name,
t.name,
round(sum(h.attendance::numeric) / sum(h.games::numeric),0) as avg_attendance,
'bottom 5'
from homegames h
inner join parks p
on h.park = p.park
inner join teams t
on h.team = t.teamid
and h.year = t.yearid
where year = 2016
group by 1,2
order by avg_attendance 
limit 5)

select
*
from highest
union
select
*
from lowest
order by avg_attendance desc


-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.


select
	playerid
from awardsmanagers
where awardid = 'TSN Manager of the Year'
and lgid in ('NL', 'AL')
group by 1
having count(distinct lgid) > 1


select
	distinct 
	concat(p.namefirst,' ',p.namelast) as full_name,
	t.name,
	a.lgid
from awardsmanagers a
inner join people p
	on a.playerid = p.playerid 
inner join managers m
	on a.playerid = m.playerid
	and a.lgid = m.lgid
	and a.yearid = m.yearid
inner join teams t
	on m.teamid = t.teamid
	and m.lgid = t.lgid
	and m.yearid = t.yearid
where a.awardid = 'TSN Manager of the Year'
and a.lgid in ('NL', 'AL')
and p.playerid in 
	(select
		playerid
	from awardsmanagers
	where awardid = 'TSN Manager of the Year'
	and lgid in ('NL', 'AL')
	group by 1
	having count(distinct lgid) = 2)

-- Davey Johnson Baltimore Orioles	AL
-- Davey Johnson Washington Nationals	NL
-- Jim Leyland Detroit Tigers	AL
-- Jim Leyland	Pittsburgh Pirates	NL


-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.

-- with max_high as
-- 	(select
-- 	playerid,
-- 	max(hr) as max_hr
-- 	from batting
-- 	group by 1),

with rank_hr as 
	(select
	playerid,
	hr,
	yearid,
	rank() over(partition by playerid  order by hr desc) as ranked_hr
	from batting
	where hr>=1),


debut as 
(select
playerid,
extract (year from age(finalgame::date,debut::date)) as years_active
from people)


select
p.namefirst,
p.namelast,
b.hr,
b.yearid,
r.ranked_hr
from people p
inner join batting b
	on p.playerid = b.playerid 
inner join rank_hr r 
	on b.playerid = r.playerid 
	and b.yearid = r.yearid
	and b.hr = r.hr
inner join debut d
	on p.playerid = d.playerid
where b.yearid = 2016
and b.hr>=1
and r.ranked_hr = 1
and d.years_active >=10










