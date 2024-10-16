select Com, Acct, Currency, name, fecha, je_source, je_category, invoice_num, sum(dr), sum(cr)
from
(select  nvl(alls.segment1, pay.segment1) Com,
        nvl(alls.segment3, pay.segment3)Acct,
        nvl(alls.currency_code, pay.currency_code) Currency, 
        Name, 
        Default_effective_date fecha, 
        JE_source, 
        je_category, 
        invoice_num, 
        nvl(accounted_dr, dr) DR, 
        nvl(accounted_cr, cr)*-1 CR
from
(
SELECT  distinct 
        segment1,
        segment3,
        GJH.currency_code,
        GJH.je_header_id,
        GJL.JE_LINE_NUM,
        GJH.je_header_id||GJL.JE_LINE_NUM bid,
        AIA.INVOICE_NUM Invoice_num,
        xal.accounted_dr,
        xal.accounted_cr

  FROM 
       gl.GL_JE_HEADERS GJH,
       gl.GL_JE_LINES GJL,
       gl.GL_CODE_COMBINATIONS GCC,
       gl.GL_IMPORT_REFERENCES GIR,
       xla.XLA_AE_LINES XAL,
       xla.XLA_AE_HEADERS XAH,
       XLA.XLA_TRANSACTION_ENTITIES XTE,
       ap.AP_INVOICES_ALL AIA
      
 WHERE 1=1
   AND GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
   AND GJL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
   AND GJL.JE_HEADER_ID = GIR.JE_HEADER_ID
   AND GJL.JE_LINE_NUM = GIR.JE_LINE_NUM
   AND GIR.GL_SL_LINK_ID = XAL.GL_SL_LINK_ID
   AND GIR.GL_SL_LINK_TABLE = XAL.GL_SL_LINK_TABLE
   AND XAL.AE_HEADER_ID = XAH.AE_HEADER_ID
   AND XTE.APPLICATION_ID = XAH.APPLICATION_ID
   AND XTE.ENTITY_ID = XAH.ENTITY_ID
   AND AIA.INVOICE_ID(+) = XTE.SOURCE_ID_INT_1
   AND GJL.STATUS = 'P'
   AND GCC.CODE_COMBINATION_ID in (select code_combination_id ccid from gl.GL_CODE_COMBINATIONS GCC where gcc.segment1 in (101, 102, 125) and segment3 = 200500) -- and segment8 = '1264')
   AND GJH.JE_SOURCE = 'Payables'
   and gjh.DEFAULT_EFFECTIVE_DATE between '01-Mar-2019' and '31-Mar-2019'
  
  ) Pay
  
  right outer JOIN


   (SELECT distinct segment1, segment3,
       GJH.NAME,
       GJH.DESCRIPTION,
       gjh.DEFAULT_EFFECTIVE_DATE,
       GJH.currency_code,
       GJH.JE_SOURCE,
       GJH.JE_CATEGORY,
       nvl(ACCOUNTED_DR, 0) dr,
       nvl(ACCOUNTED_CR, 0) cr,
       GJH.PERIOD_NAME,
       gcc.segment8
       ,gjh.je_header_id
       ,GJL.JE_LINE_NUM
  FROM gl.GL_JE_BATCHES GJB,
       gl.GL_JE_HEADERS GJH,
       gl.GL_JE_LINES GJL,
       gl.GL_CODE_COMBINATIONS GCC
       
   WHERE GJB.JE_BATCH_ID = GJH.JE_BATCH_ID
   AND GJH.JE_HEADER_ID = GJL.JE_HEADER_ID
   AND GJL.CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
   AND GJL.STATUS = 'P'
   AND GCC.code_combination_id in (select code_combination_id ccid from gl.GL_CODE_COMBINATIONS GCC where gcc.segment1 in (101, 102, 125) and segment3 = 200500) -- and segment8 = '1264')
   --and  GJH.JE_SOURCE != 'Assets'
   and gjh.DEFAULT_EFFECTIVE_DATE between to_date('01-Mar-2019','dd-Mon-YYYY') and to_date('31-Mar-2019','dd-Mon-YYYY')
   ) Alls
   
   on Pay.je_header_id = Alls.je_header_id and Pay.JE_LINE_NUM = Alls.je_line_num
   order by 1, 2
   )
   group by Com, Acct, Currency, name, fecha, je_source, je_category, invoice_num