WITH families AS (
SELECT UID1 AS p1, UID2 AS p2
FROM UserRelation
WHERE Type LIKE 'Family'
),
visit_together AS(
SELECT d1.UID as p1, d2.UID as p2, 'DINE' AS outing
FROM UserDineRestaurant as d1
JOIN UserDineRestaurant as d2 ON d1.UID < d2.UID
                     AND d1.OID = d2.OID
                     AND d1.DateTimeIn <= d2.DateTimeOut
                     AND d1.DateTimeOut >= d2.DateTimeIn
UNION ALL
SELECT s1.UID as p1, s2.UID as p2, 'SHOP' AS outing
FROM UserShopInMall as s1
  JOIN UserShopInMall as s2 ON s1.UID < s2.UID
                     AND s1.SID = s2.SID
                     AND s1.DateTimeIn <= s2.DateTimeOut
                     AND s1.DateTimeOut >= s2.DateTimeIn
),
families_together AS(
SELECT F.p1, F.p2, outing
FROM families AS F
JOIN visit_together AS V
ON (F.p1 = V.p1 AND F.p2 = V.p2) OR (F.p2 = V.p1 AND F.p1 = V.p2)
),
families_day_package AS(
SELECT FT.p1, FT.p2
FROM families_together AS FT
JOIN UserUsesDayPackage AS U
ON U.UID = FT.p1 OR U.UID = FT.p2
GROUP BY FT.p1, FT.p2
),
times_shopped AS(
SELECT S.UID, COUNT(*) as num
FROM UserShopInMall AS S
GROUP BY S.UID
),
times_dined AS(
SELECT D.UID, COUNT(*) AS num
FROM UserDineRestaurant AS D
GROUP BY D.UID
),
total_dined_count_per_family AS(
SELECT FT.p1, FT.p2, TD1.num + TD2.num AS total_times
FROM families_together AS FT
JOIN times_dined AS TD1
ON FT.p1 = TD1.UID
JOIN times_dined AS TD2
ON FT.p2 = TD2.UID
WHERE outing = 'DINE'
),

total_shopped_count_per_family AS(
SELECT FT.p1, FT.p2, Ts1.num + Ts2.num AS total_times
FROM families_together AS FT
JOIN times_shopped AS Ts1
ON FT.p1 = Ts1.UID
JOIN times_shopped AS Ts2
ON FT.p2 = Ts2.UID
WHERE outing = 'SHOP'
),
dined_and_shopped_together AS(
SELECT * FROM total_dined_count_per_family
UNION ALL
SELECT * FROM total_shopped_count_per_family
),
total_dined_and_shopped_together AS(
SELECT FT.p1, FT.p2, FT.total_times, COUNT(*)*2 AS times_together
FROM dined_and_shopped_together AS FT
GROUP BY FT.p1, FT.p2, FT.total_times
),
package_or_not AS(
SELECT DISTINCT TD.p1, TD.p2, TD.total_times, TD.times_together, COUNT(FDP.p1) AS
package FROM total_dined_and_shopped_together AS TD
JOIN families_day_package AS FDP
ON TD.p1 = TD.p1 AND FDP.p2 = FDP.p2
GROUP BY TD.p1, TD.p2, TD.total_times, TD.times_together
)
SELECT DISTINCT FT.p1 AS Person1, FT.p2 AS Person2,
CASE
    WHEN FT.package = 0 THEN 'No Package'
    ELSE 'Package'
END AS Package_Used
FROM package_or_not AS FT
WHERE CAST(FT.times_together AS FLOAT)/CAST(FT.total_times AS FLOAT) > 0.5




