select OPERATING_UNIT, INVOICE_NUM, CREATION_DATE, sum(line_amount), INVOICE_CURRENCY_CODE, GL_DATE, INVOICE_DATE, DATE_INVOICE_MARKED_PAID, 
CONCUR_EST_PMT_DATE, EXPENSE_REPORT_NUMBER, CONCUR_REPORT_ID
from(

SELECT DECODE(AI.SET_OF_BOOKS_ID,2038,'CA OU', 'US OU') OPERATING_UNIT,AI.INVOICE_NUM,
  AI.CREATION_DATE,
 -- AI.INVOICE_AMOUNT,
 -- AI.AMOUNT_PAID,
  AIL.AMOUNT LINE_AMOUNT,
  --AIL.LINE_NUMBER,
  AI.INVOICE_CURRENCY_CODE,
  AI.GL_DATE,
  AI.INVOICE_DATE,
  APC.CHECK_DATE DATE_INVOICE_MARKED_PAID,
  AIL.ATTRIBUTE4 CONCUR_EST_PMT_DATE,
  AIL.ATTRIBUTE1  EXPENSE_REPORT_NUMBER, 
  (SELECT DISTINCT REPORT_ID
  FROM XXRHFIN.XXRHFIN_CONCUR_SAE_DTL
  WHERE REPORT_KEY = AIL.ATTRIBUTE1 --REPORT_KEY 
  ) CONCUR_REPORT_ID
FROM APPS.AP_INVOICES_ALL AI,
  APPS.AP_INVOICE_LINES_ALL AIL,
  APPS.AP_INVOICE_PAYMENTS_ALL AIP,
  APPS.AP_CHECKS_ALL APC
WHERE AI.SOURCE        = 'CONCUR'
AND AI.INVOICE_ID      = AIL.INVOICE_ID --1=1 --INVOICE_NUM LIKE '%CONCUR%_142%'
AND AI.INVOICE_ID      = AIP.INVOICE_ID
AND AIP.CHECK_ID       = APC.CHECK_ID
AND AI.VENDOR_ID       = 2908190 -- concur
--AND AI.SET_OF_BOOKS_ID = 2057 --AND AI.GL_DATE  > '01-DEC-2018'
AND AI.INVOICE_AMOUNT <> 0
--AND AI.CREATION_DATE  > '01-Jul-2019' --SYSDATE-45 -- < '01-DEC-2018'
and apc.CHECK_date between '01-AUG-2019' and '31-SEP-2019'
)

group by
  OPERATING_UNIT,
  INVOICE_NUM,
  CREATION_DATE,
  --INVOICE_AMOUNT,
  --AMOUNT_PAID,
  --AIL.AMOUNT LINE_AMOUNT,
  --AIL.LINE_NUMBER,
  INVOICE_CURRENCY_CODE,
  GL_DATE,
  INVOICE_DATE,
  DATE_INVOICE_MARKED_PAID,
  CONCUR_EST_PMT_DATE,
  EXPENSE_REPORT_NUMBER, 
  CONCUR_REPORT_ID