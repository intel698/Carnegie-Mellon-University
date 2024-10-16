 --Find AP Invoice Summary Data:
select distinct invoice_num, gl.segment2
FROM ap.AP_INVOICES_ALL ai,ap.AP_INVOICE_LINES_ALL lines, ap.AP_INVOICE_DISTRIBUTIONS_ALL dist, ap_holds_all hold, gl.gl_code_combinations gl
where 1=1 
and gl.chart_of_accounts_id = 50355
--and invoice_num = 'INV-8100-92622'
and ai.invoice_id = lines.invoice_id
and ai.invoice_id = dist.invoice_id
and ai.invoice_id = hold.Invoice_id
and lines.line_number = dist.invoice_line_number
and gl.code_combination_id = dist.dist_code_combination_id
and release_reason is null



--XLA

--Find AP Invoice data in XLA_EVENTS table:
SELECT DISTINCT XE.*
FROM AP_INVOICES_ALL AI ,
  XLA_EVENTS XE ,
  XLA.XLA_TRANSACTION_ENTITIES XTE
WHERE XTE.APPLICATION_ID        =200
AND XE.APPLICATION_ID           =200
AND AI.INVOICE_ID               ='&Invoice_ID'
AND XTE.LEDGER_ID               =AI.SET_OF_BOOKS_ID
AND XTE.ENTITY_CODE             ='AP_INVOICES'
AND NVL(XTE.SOURCE_ID_INT_1,-99)=AI.INVOICE_ID
AND XTE.ENTITY_ID               =XE.ENTITY_ID
order by XE.ENTITY_ID ,
  XE.EVENT_NUMBER;

--Find AP Invoice data in XLA_AE_HEADERS table:

SELECT DISTINCT XEH.*
FROM XLA_AE_HEADERS XEH ,
  AP_INVOICES_ALL AI ,
  XLA_EVENTS XE ,
  XLA.XLA_TRANSACTION_ENTITIES XTE
WHERE XTE.APPLICATION_ID        =200
AND XEH.APPLICATION_ID          =200
AND XE.APPLICATION_ID           =200
AND XE.ENTITY_ID                =XTE.ENTITY_ID
AND XE.EVENT_ID                 =XEH.EVENT_ID
AND XTE.ENTITY_ID               =XEH.ENTITY_ID
AND AI.INVOICE_ID               ='&Invoice_ID'
AND XTE.LEDGER_ID               =AI.SET_OF_BOOKS_ID
AND XTE.ENTITY_CODE             ='AP_INVOICES'
AND NVL(XTE.SOURCE_ID_INT_1,-99)=AI.INVOICE_ID
order by XEH.EVENT_ID ,
  XEH.AE_HEADER_ID ASC;

--Find AP Invoice data in XLA_AE_LINES table:

 select distinct XEL.*
  FROM XLA_AE_LINES XEL ,
  XLA_AE_HEADERS XEH ,
  AP_INVOICES_ALL AI ,
  XLA_EVENTS XE ,
  XLA.XLA_TRANSACTION_ENTITIES XTE
WHERE XTE.APPLICATION_ID        =200
AND XEL.APPLICATION_ID          =200
AND XEH.APPLICATION_ID          =200
AND XE.APPLICATION_ID           =200
AND AI.INVOICE_ID               ='&Invoice_ID'
AND XE.ENTITY_ID                =XTE.ENTITY_ID
AND XE.EVENT_ID                 =XEH.EVENT_ID
AND XEL.AE_HEADER_ID            =XEH.AE_HEADER_ID
AND XTE.ENTITY_CODE             ='AP_INVOICES'
AND NVL(XTE.SOURCE_ID_INT_1,-99)=AI.INVOICE_ID
AND XTE.ENTITY_ID               =XEH.ENTITY_ID
AND XTE.LEDGER_ID               =AI.SET_OF_BOOKS_ID
order by XEL.AE_HEADER_ID ,
  XEL.AE_LINE_NUM ASC;


--General Ledger:
--Find AP Invoice Data in GL_JE_BATCHES table:
SELECT DISTINCT GJB.*
FROM GL_IMPORT_REFERENCES GIR,
  GL_JE_BATCHES GJB,
  XLA_AE_LINES AEL,
  XLA_AE_HEADERS AEH,
  XLA_EVENTS AEA
WHERE AEA.EVENT_ID IN
  (SELECT AID.ACCOUNTING_EVENT_ID
  FROM AP_INVOICE_DISTRIBUTIONS_ALL AID
  WHERE AID.INVOICE_ID = '&Invoice_ID'
  )
AND AEL.GL_SL_LINK_ID    = GIR.GL_SL_LINK_ID
AND AEL.GL_SL_LINK_TABLE =GIR.GL_SL_LINK_TABLE
AND AEA.APPLICATION_ID   = 200
AND AEH.APPLICATION_ID   = 200
AND AEL.APPLICATION_ID   = 200
AND AEA.EVENT_ID         = AEH.EVENT_ID
AND AEH.AE_HEADER_ID     = AEL.AE_HEADER_ID
AND GJB.JE_BATCH_ID      = GIR.JE_BATCH_ID;

--Find AP Invoice data in GL_JE_HEDAERS Table:

SELECT DISTINCT GJH.*
FROM GL_IMPORT_REFERENCES GIR,
  GL_JE_HEADERS GJH,
  XLA_AE_LINES AEL,
  XLA_AE_HEADERS AEH,
  XLA_EVENTS AEA
WHERE AEA.EVENT_ID IN
  (SELECT AID.ACCOUNTING_EVENT_ID
  FROM AP_INVOICE_DISTRIBUTIONS_ALL AID
  WHERE AID.INVOICE_ID = '&Invoice_ID'
  )
AND AEL.GL_SL_LINK_ID    = GIR.GL_SL_LINK_ID
AND AEL.GL_SL_LINK_TABLE =GIR.GL_SL_LINK_TABLE
AND AEA.APPLICATION_ID   = 200
AND AEH.APPLICATION_ID   = 200
AND AEL.APPLICATION_ID   = 200
AND AEA.EVENT_ID         = AEH.EVENT_ID
and AEH.AE_HEADER_ID     = AEL.AE_HEADER_ID
AND GJH.JE_HEADER_ID     = GIR.JE_HEADER_ID;

--Find AP Invoice Data in GL_JE_LINES Table:

SELECT DISTINCT GLL.*
FROM gl.GL_IMPORT_REFERENCES GIR,
  gl.GL_JE_LINES GLL,
  xla.XLA_AE_LINES AEL,
  xla.XLA_AE_HEADERS AEH,
  xla.XLA_EVENTS AEA
WHERE AEA.EVENT_ID IN
  (SELECT AID.ACCOUNTING_EVENT_ID
  FROM ap.AP_INVOICE_DISTRIBUTIONS_ALL AID
  WHERE 1=1

  )
AND AEL.GL_SL_LINK_ID    = GIR.GL_SL_LINK_ID
AND AEL.GL_SL_LINK_TABLE =GIR.GL_SL_LINK_TABLE
AND AEA.APPLICATION_ID   = 200
AND AEH.APPLICATION_ID   = 200
AND AEL.APPLICATION_ID   = 200
AND AEA.EVENT_ID         = AEH.EVENT_ID
AND AEH.AE_HEADER_ID     = AEL.AE_HEADER_ID
and GLL.JE_HEADER_ID     = GIR.JE_HEADER_ID
AND GLL.JE_LINE_NUM      = GIR.JE_LINE_NUM
and GLL.Description like '%rgiro%'
;

--Find AP Invoice Data in GL_IMPORT_REFERENCES Table:

SELECT DISTINCT GIR.*
FROM GL_IMPORT_REFERENCES GIR,
  XLA_AE_LINES AEL,
  XLA_AE_HEADERS AEH,
  XLA_EVENTS AEA
WHERE AEA.EVENT_ID IN
  (SELECT AID.ACCOUNTING_EVENT_ID
  FROM AP_INVOICE_DISTRIBUTIONS_ALL AID
  WHERE AID.INVOICE_ID = '&Invoice_ID'
  )
AND AEL.GL_SL_LINK_ID    = GIR.GL_SL_LINK_ID
AND AEL.GL_SL_LINK_TABLE =GIR.GL_SL_LINK_TABLE
AND AEA.APPLICATION_ID   = 200
AND AEH.APPLICATION_ID   = 200
AND AEL.APPLICATION_ID   = 200
and AEA.EVENT_ID         = AEH.EVENT_ID
AND AEH.AE_HEADER_ID     = AEL.AE_HEADER_ID;

--Find The Account Code Combinations used for a specific AP Invoice:

SELECT DISTINCT GCC.*
FROM GL_CODE_COMBINATIONS GCC
WHERE GCC.CODE_COMBINATION_ID IN
  ( SELECT DISTINCT XEL.CODE_COMBINATION_ID
  FROM XLA_AE_LINES XEL ,
    XLA_AE_HEADERS XEH ,
    AP_INVOICES_ALL AI ,
    XLA.XLA_TRANSACTION_ENTITIES XTE
  WHERE XTE.APPLICATION_ID        =200
  AND XEH.APPLICATION_ID          =200
  AND XEL.APPLICATION_ID          =200
  AND AI.INVOICE_ID               ='1317327'
  AND XEL.AE_HEADER_ID            =XEH.AE_HEADER_ID
  AND XTE.ENTITY_CODE             ='AP_INVOICES'
  AND NVL(XTE.SOURCE_ID_INT_1,-99)=AI.INVOICE_ID
  AND XTE.LEDGER_ID               =AI.SET_OF_BOOKS_ID
  AND XTE.ENTITY_ID               =XEH.ENTITY_ID
  UNION ALL
  SELECT DISTINCT XEL.CODE_COMBINATION_ID
  FROM XLA_AE_LINES XEL ,
    XLA_AE_HEADERS XEH ,
    AP_INVOICE_PAYMENTS_ALL AIP ,
    XLA.XLA_TRANSACTION_ENTITIES XTE
  WHERE XTE.APPLICATION_ID        =200
  AND XEL.APPLICATION_ID          =200
  AND XEH.APPLICATION_ID          =200
  AND AIP.INVOICE_ID              ='1317327'
  AND XEL.AE_HEADER_ID            =XEH.AE_HEADER_ID
  AND XTE.ENTITY_CODE             ='AP_PAYMENTS'
  AND XTE.LEDGER_ID               =AIP.SET_OF_BOOKS_ID
  AND NVL(XTE.SOURCE_ID_INT_1,-99)=AIP.CHECK_ID
  AND XTE.ENTITY_ID               =XEH.ENTITY_ID
  UNION ALL
  SELECT DISTINCT PO.CODE_COMBINATION_ID
  FROM AP_INVOICE_DISTRIBUTIONS_ALL AID ,
    PO_DISTRIBUTIONS_ALL PO
  WHERE AID.INVOICE_ID        ='1317327'
  AND AID.PO_DISTRIBUTION_ID IS NOT NULL
  and PO.PO_DISTRIBUTION_ID   =AID.PO_DISTRIBUTION_ID
  );