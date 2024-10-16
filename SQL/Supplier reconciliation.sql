select "Party", (select vendor_name from apps.PO_Vendors where vendor_id = "Party") Supplier, BegBal, PurchaseInvoice, Payments, Ending
from(
select "Party", sum("Prior") BegBal, sum(PurchaseInvoice) PurchaseInvoice, sum(Payments) Payments, sum("Ending") Ending
from(
SELECT nvl(Pri.party_id, Curr.party_id) "Party"
    , Pri.acctd_rounded_rem_amount*-1 "Prior"
    ,0 as PurchaseInvoice,0 as Payments
    , Curr.acctd_rounded_rem_amount*-1 "Ending"
FROM
    
    (SELECT
		xtb.party_id , 
		SUM (Nvl(xtb.entered_rounded_cr,0)) -  SUM (Nvl(xtb.entered_rounded_dr,0)) entered_rounded_rem_amount,
		SUM (Nvl(xtb.acctd_rounded_cr,0)) -  SUM (Nvl(xtb.acctd_rounded_dr,0)) acctd_rounded_rem_amount
		
   --, xtb.trx_currency_code
   -- ,ae_header_id
		FROM     xla.xla_trial_balances xtb
		where    
    xtb.source_application_id=200
    and code_combination_id = 2105
		and trunc(xtb.gl_date) <= LAST_DAY(UPPER(TO_DATE('Jan-31-2017','Mon-Dd-YYYY')))        
    GROUP BY   xtb.party_id
    
			 --ae_header_id,
       --,xtb.trx_currency_code
		HAVING SUM (Nvl(xtb.acctd_rounded_cr,0)) <> SUM (Nvl(xtb.acctd_rounded_dr,0))) Pri 
    
    full outer join
    
    (SELECT
		xtb.party_id ,
		SUM (Nvl(xtb.entered_rounded_cr,0)) -  SUM (Nvl(xtb.entered_rounded_dr,0)) entered_rounded_rem_amount,
		SUM (Nvl(xtb.acctd_rounded_cr,0)) -  SUM (Nvl(xtb.acctd_rounded_dr,0)) acctd_rounded_rem_amount
		
    --, xtb.trx_currency_code
    -- ,ae_header_id
		FROM     xla.xla_trial_balances xtb
		where    
    xtb.source_application_id=200
    and code_combination_id = 2105
		and trunc(xtb.gl_date) <= LAST_DAY(UPPER(TO_DATE('Feb-28-2017','Mon-Dd-YYYY')))        
    GROUP BY   xtb.party_id

			 --ae_header_id,
       --,xtb.trx_currency_code
		HAVING SUM (Nvl(xtb.acctd_rounded_cr,0)) <> SUM (Nvl(xtb.acctd_rounded_dr,0))) Curr
        
on Pri.party_id = Curr.party_id         
where 1=1
--group by nvl(Pri.party_id, Curr.party_id), Curr.trx_currency_code

union

select party_id, 0,sum(decode(je_category_name, 'Purchase Invoices',Net,0)) as Purchase_inv
                                 , sum(decode(je_category_name, 'Payments',Net,0)) as Payment
                                 ,0
from(
    select Je_category_name, accounted_dr dr, (accounted_cr * -1) cr, (nvl(accounted_dr,0) + nvl((accounted_cr * -1),0)) Net, party_id
    from xla.xla_ae_headers xla, xla.xla_ae_lines lines
    where 1=1
    and xla.ae_header_id = lines.ae_header_id
    --and xla.application_id = 200
    and xla.ledger_id = 2057
    and period_name in ('Feb-17')
    and code_combination_id = 2105
    and gl_transfer_status_code = 'Y'
    and accounting_entry_status_code = 'F'
    ) Act
group by party_id
)
group by "Party"
)