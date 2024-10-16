With A As (
SELECT GB.PERIOD_NAME
,       ledger_id
,       GCC.Account_type
,      SEGMENT3
,      GCC.SEGMENT1||'-'||GCC.SEGMENT3 "Account"
,SUM( NVL(GB.BEGIN_BALANCE_DR,0) - NVL(GB.BEGIN_BALANCE_CR,0))"OPEN BAL"
,SUM( NVL(GB.PERIOD_NET_DR,0) - NVL(GB.PERIOD_NET_CR,0))"NET MOVEMENT"
,SUM(( NVL(GB.PERIOD_NET_DR,0) + NVL(GB.BEGIN_BALANCE_DR,0))) - SUM(NVL(GB.PERIOD_NET_CR,0)+NVL(GB.BEGIN_BALANCE_CR,0))"CLOSE BAL"
,      GB.CURRENCY_CODE
,      GB.TRANSLATED_FLAG
FROM GL.GL_BALANCES GB, GL.GL_CODE_COMBINATIONS GCC
WHERE GCC.CODE_COMBINATION_ID = GB.CODE_COMBINATION_ID
AND  GB.ACTUAL_FLAG = 'A'
--AND    GB.CURRENCY_CODE = SOB.CURRENCY_CODE
AND  GB.TEMPLATE_ID IS NULL
--AND GB.ledger_id = SOB.SET_OF_BOOKS_ID
AND  GB.PERIOD_NAME = 'Jun-16'
AND GB.ledger_id = 2358
GROUP BY GB.PERIOD_NAME
,      ledger_id
,       GCC.Account_type
,      GCC.SEGMENT3 
,      GCC.SEGMENT1||'-'||GCC.SEGMENT3 
,      GB.CURRENCY_CODE
,      GB.TRANSLATED_FLAG
HAVING SUM(( NVL(GB.PERIOD_NET_DR,0) + NVL(GB.BEGIN_BALANCE_DR,0))) - SUM(NVL(GB.PERIOD_NET_CR,0)+NVL(GB.BEGIN_BALANCE_CR,0)) <> 0
),

B As (
select "Account", "CLOSE BAL", "NET MOVEMENT" 
from A 
where translated_flag = 'Y' and currency_code ='USD'
) ,

C As (
select Func.Period_name, Func.ledger_id, Func.SEGMENT3 ,"Account", Func.Account_Type, Func.Currency_code
, case Func.Account_type when 'L' then Func."CLOSE BAL"
                         when 'A' then Func."CLOSE BAL"
                         when 'O' then Func."CLOSE BAL"
                         When 'R' then Func."NET MOVEMENT"
                         when 'E' then Func."NET MOVEMENT"
                         else 0 END "Functional"
                       
,'USD'
, case Func.Account_type when 'L' then (select "CLOSE BAL" FROM B where Func."Account" = B."Account")
                         when 'A' then (select "CLOSE BAL" FROM B where Func."Account" = B."Account")
                         when 'O' then (select "CLOSE BAL" FROM B where Func."Account" = B."Account")
                         When 'R' then (select "NET MOVEMENT" FROM B where Func."Account" = B."Account")
                         when 'E' then (select "NET MOVEMENT" FROM B where Func."Account" = B."Account")
                         else 0 END "RPT BAL"


from A Func,  APPS.GL_SETS_OF_BOOKS SOB
where SOB.Set_of_books_id = ledger_id
and SOB.CURRENCY_CODE = Func.currency_code)



select Period_name, ledger_id, Segment3, "Account"
, Account_type, currency_code
, "Functional", 'USD', "RPT BAL"
, round("RPT BAL"/"Functional",4) "fx"
from C
where "Functional" != 0
order by 3
