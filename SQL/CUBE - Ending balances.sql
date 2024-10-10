CREATE MATERIALIZED VIEW FA_Balance
BUILD IMMEDIATE
REFRESH COMPLETE
ON COMMIT
AS

With 
-- These queries create the dimensions in our data
 category_dim as (select category_id, Segment1, Segment2 from fa.fa_categories_b)
 
, account_dim as (select Segment1 CO, Segment2 CC, Segment3 ACCT, Segment4 ICO, chart_of_accounts_id flexfield, code_combination_id ccid from gl.gl_code_combinations ccid )

, time_dim as (select distinct period_counter, period_num, fiscal_year, LAST_DAY(TO_DATE((period_num||'-' ||fiscal_year), 'MM-YYYY')) AS last_day_of_month  from fa_deprn_periods)

-- This query identifies which ledger to include in our analysis
, ledgers as (select book_type_code, ctrl.accounting_flex_structure from fa.fa_book_controls ctrl where book_class = 'CORPORATE' and  accounting_flex_structure = 101)-- where book_type_code in ('OPS CORP'))

-- The following queries create the fact table for the periods specified in the pcounter query
, pcounter as (
    select ledgers.book_type_code
        , period_counter
        ,  accounting_flex_structure
        ,  (select distinct period_counter from  fa.fa_deprn_periods where fiscal_year = 2007 and period_num = 10) as first_per
    from fa.fa_deprn_periods
        , ledgers 
    where period_counter between 
        ((select distinct period_counter from  fa.fa_deprn_periods where fiscal_year = 2007 and period_num = 10)-1)
         and 
         (select distinct period_counter  from  fa.fa_deprn_periods where fiscal_year = 2010 and period_num = 10)
    and ledgers.book_type_code =    fa_deprn_periods.book_type_code
)
 

-- Getting the open and close timestamp for each period from the fa_deprn_periods table
-- These dates are needed to filter SCD in other tables such as the assignment table
-- Required column output: Book, period_counter, period_open_timestamp and period_closed_timestamp
-- Returns al the id(period_counters) for all the periods between 
, per as (
    select dep_per.book_type_code
        , first_per
        , dep_per.period_name
        , dep_per.period_counter
        , dep_per.period_open_date                                  -- When the period actually opened in the subledger
        , nvl(dep_per.PERIOD_CLOSE_DATE, sysdate) PERIOD_CLOSE_DATE -- When the period actually closed in the subledger
        , dep_per.calendar_period_close_date 
        , accounting_flex_structure

    from fa.fa_deprn_periods dep_per
        , pcounter
    where dep_per.book_type_code = pcounter.book_type_code
        and dep_per.period_counter = pcounter.period_counter

  )
  
-- An asset asisgnment determines the location of the asset and the GL account where its expensed
-- units assigned is used by Oracle to pro-rate the same asset accross different location/GL accounts
, assignment as (
    select per.period_name
        , first_per
        , per.period_counter
        , fdh.asset_id
        , fdh.distribution_id
        , fdh.code_combination_id
        , fah.asset_type
        , location_id
        , units_assigned

    from per, fa.fa_asset_history fah 
        join fa.FA_DISTRIBUTION_HISTORY fdh on fah.asset_id = fdh.asset_id
        join fa.FA_BOOKS FAB                on fah.asset_id = fab.asset_id
        
    where 1=1
        and per.PERIOD_CLOSE_DATE BETWEEN fab.date_effective AND NVL (fab.date_ineffective, per.PERIOD_CLOSE_DATE)
        and per.PERIOD_CLOSE_DATE BETWEEN fah.date_effective AND NVL (fah.date_ineffective, per.PERIOD_CLOSE_DATE)
        and per.PERIOD_CLOSE_DATE BETWEEN fdh.date_effective AND NVL (fdh.date_ineffective, per.PERIOD_CLOSE_DATE)
        and fab.book_type_code =   per.book_type_code
        and fdh.book_type_code =   per.book_type_code

)

-- Pulls all transactions other than depreciation ex. additions, cost adjustments.  
-- Use effective_date to filter the transactions

, activity as (

    select  
         per.period_name
       , per.period_counter
       , tran.asset_id
       , adj.source_type_code
       , adj.adjustment_type
       , adj.adjustment_amount
       , tran.book_type_code


   from per, fa.fa_transaction_headers tran --, assignment assign
        left join fa.fa_adjustments adj on tran.transaction_header_id = adj.transaction_header_id 
        left join fa.fa_retirements ret on tran.transaction_header_id = ret.transaction_header_id_in 
        left join fa.fa_additions_b adds on tran.asset_id = adds.asset_id
    
   where 1=1
        and tran.date_effective BETWEEN per.period_open_date AND NVL (per.period_close_date, tran.date_effective)
        and tran.book_type_code = per.book_type_code
        and not (adjustment_type = 'COST CLEARING')

union all

-- Depreciation transactions query.  Instea of using effective dates, period_id is used.
-- Depreciation is pro-rated by expense accounts only so we group them
-- so that they can be aggregated by expense accounts/location combination

    select 
          period_name
        , deprn.period_counter
        , asset_id
        , 'DEPRECIATION'
        , 'DEPRECIATION'
        , sum(deprn.deprn_amount) 
        --, DISTRIBUTION_ID
        , deprn.book_type_code
    from per join fa.FA_DEPRN_DETAIL deprn on deprn.book_type_code = per.book_type_code and deprn.period_counter = per.period_counter
    where deprn_amount !=0
    group by period_name, deprn.period_counter,  asset_id, deprn.book_type_code
)


-- This query joins the activity with the attributes for that asset as defined in the assignment query
, transactions as (

    select act.period_name
        , act.period_counter
        , book_type_code
        , act.asset_id
        , source_type_code
        , adjustment_type
        , adjustment_amount
        , assign.location_id
        , assign.code_combination_id
        ,(round(ratio_to_report(units_assigned) over(partition by act.asset_id, act.period_name),3)) as alloc
    from activity act join assignment assign on act.asset_id = assign.asset_id and act.period_counter = assign.period_counter
    and book_type_code in (select book_type_code from ledgers)
)

-- This query builds a cube with the specified dimension to pre-aggregate totals for faster analical querying
, cube_select as(

    select 
          adim.CO
        , adim.cc
        , adim.acct
        , adim.ico
        , period_num
        , fiscal_year
        ,sum(adjustment_amount)
    from transactions
        , account_dim adim
        , ledgers
        , time_dim
    where 1=1
        and adim.flexfield = ledgers.accounting_flex_structure
        and ledgers.book_type_code = transactions.book_type_code
        and transactions.code_combination_id = adim.ccid
        and time_dim.period_counter = transactions.period_counter
        and source_type_code = 'DEPRECIATION'
    group by cube (adim.CO, adim.cc, adim.acct, adim.ico, period_num, fiscal_year)

)

--SELECT *
--FROM (select * from transactions)
--PIVOT (
--    SUM(alloc*adjustment_amount) FOR source_type_code IN ('ADDITION' AS Additions, 'DEPRECIATION' AS Depr, 'CIP ADJUSTMENT' AS CIP_Adjustment, 'ADJUSTMENT' as Cost_adjust, 'TRANSFER' as Transfer)
--)

select * from cube_select
where 1=1
and co is null
and cc is null
and acct is null
and ico is null
and period_num is null



