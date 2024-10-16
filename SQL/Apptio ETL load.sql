with per as(
select period_counter, PERIOD_CLOSE_DATE, calendar_period_close_date, book_type_code
from fa.fa_deprn_periods per
where 1=1
and last_day(to_date(:MonYY, 'Mon-yy')) between per.calendar_period_open_date and per.calendar_period_close_date
)

select 
  Asset_Number, 
  v.description,
  FAB.Date_Placed_In_Service,
  Assets.currency_code,
  fah.asset_type,
  FAB.life_in_months LIFE,
  (rr * fab.cost) as Cost,
  (rr * deprn.deprn_amount) as DEPRN_AMOUNT,
  (rr * deprn.ytd_deprn) as YTD_DEPRN,
  (rr * deprn.deprn_reserve) as  DEPRN_RESERVE ,
  (rr * (fab.cost - deprn.deprn_reserve)) as NET,
  ccid.Segment1 CO,
  ccid.Segment2 CC,
  ccid.Segment3 ACCT,
  ccid.Segment4 ICO,
  ccid.Segment5 PROD,
  ccid.Segment6 SC,
  ccid.Segment7 LOC,
  ccid.Segment8 PROJ,
  loc.segment1 COUNTRY,
  loc.segment2 STATE,
  loc.segment3 COUNTY,
  loc.segment4 CITY,
  loc.segment5 BUILDING,
  loc.segment6 OTHER,
  fac.ASSET_COST_ACCT
  

from    
       (
      select fdh.asset_id, fdh.book_type_code, round(ratio_to_report(units_assigned) over(partition by asset_id),3) as rr ,code_combination_id, currency_code, Location_id
      from fa.FA_DISTRIBUTION_HISTORY fdh,  fa.fa_book_controls ctrl, gl.gl_ledgers gl, per
      where 1=1
      and ctrl.set_of_books_id = gl.ledger_id
      and ctrl.book_class = 'CORPORATE'
      and fdh.book_type_code = ctrl.book_type_code
      and fdh.book_type_code = per.book_type_code
      and per.PERIOD_CLOSE_DATE BETWEEN fdh.date_effective AND NVL (fdh.date_ineffective, per.PERIOD_CLOSE_DATE)
      ) Assets, 

     (
     select asset_id, dep.book_type_code, deprn_reserve
     , (case when per.period_counter = dep.period_counter then deprn_amount else 0 end) as deprn_amount
     , (case when per.period_counter = dep.period_counter then ytd_deprn else 0 end) as ytd_deprn
     from(
        select asset_id, deprn.book_type_code, calendar_period_close_date, deprn_amount, ytd_deprn, deprn_reserve, deprn.period_counter
        , rank () OVER (PARTITION BY asset_id, deprn.book_type_code order by calendar_period_close_date DESC) "Ranking"
        from fa.fa_deprn_periods peri, FA.FA_DEPRN_SUMMARY deprn
        where calendar_period_close_date <= last_day(to_date(:MonYY, 'Mon-yy'))
        and deprn.period_counter = peri.period_counter
        and deprn.book_type_code = peri.book_type_code
     ) dep, per
     where "Ranking" = 1 
     and per.book_type_code = dep.book_type_code
     
    )deprn,
  
  
        fa.FA_CATEGORY_BOOKS FAC,                                                                                         -- natural accounts by asset category
        apps.fa_additions_v v,
        fa.FA_BOOKS FAB,
        fa.fa_asset_history fah,
        gl.gl_code_combinations ccid,
        fa.fa_locations loc,
        per
        

  where 1=1
  and fab.asset_id = deprn.asset_id
  and fab.asset_id = fah.asset_id
  and fab.asset_id = v.asset_id
  and fab.asset_id = assets.asset_id
  and fab.book_type_code = deprn.book_type_code
  and fab.book_type_code = fac.book_type_code
  and fab.book_type_code = per.book_type_code
  and fab.book_type_code = assets.book_type_code
  and loc.location_id = assets.location_id
  and ccid.chart_of_accounts_id = 50355
  and Assets.Code_Combination_ID = ccid.code_combination_id 
  and Assets.rr != 0
  and fac.category_id = fah.category_id
  and fah.asset_type = 'CAPITALIZED'
  and (fab.period_counter_fully_retired > per.period_counter or fab.period_counter_fully_retired is null)
  
  and per.PERIOD_CLOSE_DATE BETWEEN fab.date_effective AND NVL (fab.date_ineffective, per.PERIOD_CLOSE_DATE)
  and per.PERIOD_CLOSE_DATE BETWEEN fah.date_effective AND NVL (fah.date_ineffective, per.PERIOD_CLOSE_DATE)


