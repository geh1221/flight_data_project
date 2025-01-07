#1) Find maximal departure delay in minutes for each airline. Sort results from smallest to largest maximum delay. Output airline names and values of the delay.
SELECT i.Name as airline, max(d.DepDelayMinutes) as departure_delay
from L_AIRLINE_ID i, al_perf d
where i.ID = d.DOT_ID_Reporting_Airline
GROUP BY i.Name
ORDER BY max(d.DepDelayMinutes);
#rows returned: 17

#2) Find maximal early departures in minutes for each airline. Sort results from largest to smallest. Output airline names.
SELECT i.Name as airline, abs(min(d.DepDelay)) as early_departure
from L_AIRLINE_ID i, al_perf d
where i.ID = d.DOT_ID_Reporting_Airline
GROUP BY i.Name
ORDER BY min(d.DepDelay);
#rows returned: 17

#3)Rank days of the week by the number of flights performed by all airlines on that day (1 is the busiest). Output the day of the week names, number of flights and ranks in the rank increasing order.
SELECT 
    b.Day, 
    COUNT(*) AS flights,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS f_rank
FROM 
    al_perf a, L_WEEKDAYS b
WHERE a.DayOfWeek = b.Code
GROUP BY 
    b.Day
ORDER BY 
    f_rank;
#rows returned: 7

#4) Find the airport that has the highest average departure delay among all airports. Consider 0 minutes delay for flights that departed early. Output one line of results: the airport name, code, and average delay.
SELECT b.Name, a.Origin as Code, avg(a.DepDelayMinutes) as average_dep_delay
FROM al_perf a, L_AIRPORT_ID b
WHERE a.OriginAirportID = b.ID
GROUP BY a.OriginAirportID
ORDER BY avg(a.DepDelayMinutes) DESC
LIMIT 1;
#rows returned: 1

#5) For each airline find an airport where it has the highest average departure delay. Output an airline name, a name of the airport that has the highest average delay, and the value of that average delay.

WITH dep_delays_airline(airline, airport, avg_dep_delay) as (
SELECT DOT_ID_Reporting_Airline, OriginAirportID, avg_dep_delay
FROM (
    SELECT 
        DOT_ID_Reporting_Airline, 
        OriginAirportID, 
        AVG(DepDelayMinutes) AS avg_dep_delay,
        RANK() OVER (PARTITION BY DOT_ID_Reporting_Airline ORDER BY AVG(DepDelayMinutes) DESC) AS rank_delay
    FROM al_perf
    GROUP BY DOT_ID_Reporting_Airline, OriginAirportID
) AS ranked_delays
WHERE rank_delay = 1)
SELECT a.Name as airline, b.Name as airport, c.avg_dep_delay as avg_dep_delay
FROM L_AIRLINE_ID a, L_AIRPORT_ID b, dep_delays_airline c
WHERE a.ID = c.airline AND b.ID = c.airport;
#Rows returned: 17

#6a) Check if your dataset has any canceled flights.
SELECT count(*)
FROM al_perf
WHERE Cancelled = 1;
#rows returned: 1

#6b) If it does, what was the most frequent reason for each departure airport? Output airport name, the most frequent reason, and the number of cancelations for that reason

WITH ranked_reasons(airport, CancellationCode, count) as (
SELECT OriginAirportID, CancellationCode, count
FROM(
SELECT  OriginAirportID, CancellationCode, count(CancellationCode) as count, RANK() OVER (PARTITION BY OriginAirportID ORDER BY count(CancellationCode) DESC) AS rank_reason
FROM al_perf
WHERE CancellationCode IS NOT NULL AND NOT CancellationCODE = ""
GROUP BY OriginAirportID, CancellationCode) as ranked_reasons
WHERE rank_reason = 1)
SELECT b.Name as airport, c.Reason as reason, a.count as cancellations
FROM ranked_reasons a, L_AIRPORT_ID b, L_CANCELATION c
WHERE a.airport = b.ID AND a.CancellationCode = c.Code;
#rows returned: 305


#7) Build a report that for each day output average number of flights over the preceding 3 days.
WITH DailyFlightCounts AS (
    SELECT
        FlightDate,
        COUNT(*) AS FlightCount
    FROM
        al_perf
    GROUP BY
        FlightDate
)
SELECT
    FlightDate,
    AVG(FlightCount) OVER (
        ORDER BY FlightDate
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS avg_flights_3_days
FROM
    DailyFlightCounts
ORDER BY
    FlightDate;
#Rows returned: 29