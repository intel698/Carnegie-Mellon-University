
select invoice_id, sum("Prior"), sum(Payments), sum(PurchaseInvoice), sum("Ending")
from(


(
SELECT 
     nvl(Pri.invoice_id, Curr.invoice_id) invoice_id
     ,(Pri.acctd_rounded_rem_amount*-1) "Prior"
     ,0 as Payments,0 as PurchaseInvoice
    , (Curr.acctd_rounded_rem_amount*-1) "Ending"
FROM
    
    (
    SELECT
		source_id_int_1 invoice_id,
		SUM (Nvl(xtb.entered_rounded_cr,0)) -  SUM (Nvl(xtb.entered_rounded_dr,0)) entered_rounded_rem_amount,
		SUM (Nvl(xtb.acctd_rounded_cr,0)) -  SUM (Nvl(xtb.acctd_rounded_dr,0)) acctd_rounded_rem_amount
		
   --, xtb.trx_currency_code
   -- ,ae_header_id
		FROM     xla.xla_trial_balances xtb, xla.xla_transaction_entities xla
		where    
    xtb.source_application_id=200
    and code_combination_id = 2105
    and nvl(xtb.applied_to_entity_id, xtb.source_entity_id) = xla.entity_id
		and trunc(xtb.gl_date) <= LAST_DAY(UPPER(TO_DATE('Dec-31-2016','Mon-Dd-YYYY')))        
    GROUP BY   source_id_int_1
		HAVING SUM (Nvl(xtb.acctd_rounded_cr,0)) <> SUM (Nvl(xtb.acctd_rounded_dr,0))
    ) Pri 
    
    full outer join
    
    (
    SELECT
		source_id_int_1 invoice_id,
		SUM (Nvl(xtb.entered_rounded_cr,0)) -  SUM (Nvl(xtb.entered_rounded_dr,0)) entered_rounded_rem_amount,
		SUM (Nvl(xtb.acctd_rounded_cr,0)) -  SUM (Nvl(xtb.acctd_rounded_dr,0)) acctd_rounded_rem_amount
		
   --, xtb.trx_currency_code
   -- ,ae_header_id
		FROM     xla.xla_trial_balances xtb, xla.xla_transaction_entities xla
		where    
    xtb.source_application_id=200
    and code_combination_id = 2105
    and nvl(xtb.applied_to_entity_id, xtb.source_entity_id) = xla.entity_id
		and trunc(xtb.gl_date) <= LAST_DAY(UPPER(TO_DATE('Jan-31-2017','Mon-Dd-YYYY')))        
    GROUP BY   source_id_int_1
		HAVING SUM (Nvl(xtb.acctd_rounded_cr,0)) <> SUM (Nvl(xtb.acctd_rounded_dr,0))
    ) Curr
        
on Pri.invoice_id  = Curr.invoice_id         
where 1=1
)

union all

(
select source_id_int_1 ,(select vendor_id from ap_invoices_all where source_id_int_1= invoice_id), (select invoice_num from ap_invoices_all where source_id_int_1= invoice_id) invoice_num, 0 ,0 as NetDr,(Nvl(ael.accounted_dr,0) + nvl(ael.accounted_cr,0)) NetCr,0
from xla.xla_transaction_entities ent, 
     xla.xla_ae_headers           aeh, 
     xla.xla_ae_lines             ael 
where 1=1
  and ent.entity_code    = 'AP_INVOICES' 
  and ent.entity_id      = aeh.entity_id 
  and aeh.ae_header_id   = ael.ae_header_id 
  and ael.code_combination_id = 2105
  and period_name = 'Jan-17'
  and ((ael.accounted_dr != 0 or ael.accounted_dr is not null) or (ael.accounted_cr != 0 or ael.accounted_cr is not null))
  
  --and (nvl(ael.accounted_dr,0) * nvl(ael.accounted_cr, 0))!=0
  
union all

select invoice_id, (select vendor_id from ap_invoices_all where source_id_int_1= invoice_id) party, (select invoice_num from ap_invoices_all where source_id_int_1= invoice_id) invoice_num, 0 , chk.amount, 0, 0
from xla.xla_transaction_entities ent, 
     xla.xla_ae_headers           aeh, 
     ap_invoice_payments_all      chk
where 1=1
  and ent.entity_code    = 'AP_PAYMENTS' 
  and ent.entity_id      = aeh.entity_id 
  and chk.period_name = 'Jan-17'
  and SET_OF_BOOKS_ID = 2057
  and aeh.event_id = chk.accounting_event_id
  and ent.legal_entity_id = 23304

  )

)

group by invoice_id




