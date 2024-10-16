SELECT DISTINCT 
  c.book_type_code, book_type_name, book_class, a.segment1||'-'||a.segment2 CATEGORY,
a.segment1 MAJOR_CATEGORY, a.segment2 MINOR_CATEGORY,
nvl(NET,0),
nvl(GROSS,0),
gl1.segment1||'-'||gl1.SEGMENT2||'-'||gl1.SEGMENT3||'-'||gl1.SEGMENT4||'-'||gl1.SEGMENT5 ASSET_COST,
gl2.segment1||'-'||gl2.SEGMENT2||'-'||gl2.SEGMENT3||'-'||gl2.SEGMENT4||'-'||gl2.SEGMENT5 ASSET_COST_CLEARING,
c.DEPRN_EXPENSE_ACCT,
gl3.segment1||'-'||gl3.SEGMENT2||'-'||gl3.SEGMENT3||'-'||gl3.SEGMENT4||'-'||gl3.SEGMENT5 DEPRN_RESERVE_ACCOUNT,
deprn_method, life_in_months, (life_in_months/12) life_years, prorate_convention_code
FROM apps.FA_CATEGORIES_VL a,
( select c.book_type_code, DEPRN_EXPENSE_ACCT, c.category_id, ASSET_COST_ACCOUNT_CCID, ASSET_CLEARING_ACCOUNT_CCID, RESERVE_ACCOUNT_CCID, prorate_convention_code
, life_in_months, deprn_method
  from fa.FA_CATEGORY_BOOK_DEFAULTS b, fa.fa_category_books c
  where c.category_id = b.category_id
  AND   c.book_type_code = b.book_type_code ) c,
  
gl.gl_code_combinations gl1,
gl.gl_code_combinations gl2,
gl.gl_code_combinations gl3,
fa.fa_book_controls ctrl,
(
select fab.book_type_code,
       fah.asset_type,
       fah.category_id,
       sum(fab.cost) as GROSS,
       sum(deprn.deprn_amount),
       sum(deprn.deprn_reserve),
       sum((fab.cost - deprn.deprn_reserve)) as NET
from  (
        select asset_id, dep.book_type_code, deprn_reserve, PERIOD_CLOSE_DATE, per.period_counter
     , (case when per.period_counter = dep.period_counter then deprn_amount else 0 end) as deprn_amount
     , (case when per.period_counter = dep.period_counter then ytd_deprn else 0 end) as ytd_deprn
     from(
        select asset_id, deprn.book_type_code, calendar_period_close_date, deprn_amount, ytd_deprn, deprn_reserve, deprn.period_counter
        , rank () OVER (PARTITION BY asset_id, deprn.book_type_code order by calendar_period_close_date DESC) "Ranking"
        from fa.fa_deprn_periods peri, FA.FA_DEPRN_SUMMARY deprn
        where calendar_period_close_date <= to_date('31-dec-18, 11:59 P.M.', 'dd-Mon-yy, HH:MI P.M.')
        and deprn.period_counter = peri.period_counter
        and deprn.book_type_code = peri.book_type_code
     ) dep, 
        (select period_counter, PERIOD_CLOSE_DATE, calendar_period_close_date, book_type_code
        from fa.fa_deprn_periods per
        where 1=1
        and to_date('31-dec-18', 'dd-Mon-yy') between per.calendar_period_open_date and per.calendar_period_close_date
        ) per
     where "Ranking" = 1 
     and per.book_type_code = dep.book_type_code
     
    )deprn,

        fa.FA_BOOKS FAB,
        fa.fa_asset_history fah
        
  where 1=1
  and fab.asset_id = deprn.asset_id
  and fab.asset_id = fah.asset_id
  and fab.book_type_code = deprn.book_type_code
  and fah.asset_type = 'CAPITALIZED'
  and (fab.period_counter_fully_retired > deprn.period_counter or fab.period_counter_fully_retired is null)
  
  and deprn.PERIOD_CLOSE_DATE BETWEEN fab.date_effective AND NVL (fab.date_ineffective, deprn.PERIOD_CLOSE_DATE)
  and deprn.PERIOD_CLOSE_DATE BETWEEN fah.date_effective AND NVL (fah.date_ineffective, deprn.PERIOD_CLOSE_DATE)
  
  group by fab.book_type_code, fah.asset_type, category_id
) balance

WHERE 1=1

AND c.category_id = a.category_id
AND a.ENABLED_FLAG = 'Y'
AND c.ASSET_COST_ACCOUNT_CCID = gl1.CODE_COMBINATION_ID
AND c.ASSET_CLEARING_ACCOUNT_CCID = gl2.CODE_COMBINATION_ID
AND c.RESERVE_ACCOUNT_CCID = gl3.CODE_COMBINATION_ID
--AND c.WIP_COST_ACCOUNT_CCID = gl4.CODE_COMBINATION_ID
--AND c.WIP_CLEARING_ACCOUNT_CCID = gl5.CODE_COMBINATION_ID

and c.book_type_code = ctrl.book_type_code
and c.category_id = balance.category_id(+)
and c.book_type_code = balance.book_type_code(+)
--and c.book_type_code = 'RH US CORP BOOK'
