--Accounted after specified period, and transacted in or before the specified period: Should have been accrued in the period specified

WITH ABC AS 
        (select sum(dist.AMOUNT) as Amount, 
        segment2,
        to_char(Lines.ACCOUNTING_DATE,'YYYYMM') as AcctDate,
        Lines.Accounting_date,
        to_char(Lines.Start_Expense_Date, 'YYYYMM') as TranMonth,
        Headr.INVOICE_NUM as Invoice

from AP.AP_INVOICE_LINES_ALL Lines, AP.AP_INVOICES_ALL Headr, ap.ap_invoice_distributions_all dist, gl.gl_code_combinations coa
where     Lines.Invoice_ID = Headr.Invoice_ID
      and Lines.invoice_id = dist.invoice_id
      and lines.line_number = dist.invoice_line_number
      and Headr.INVOICE_TYPE_LOOKUP_CODE= 'EXPENSE REPORT' 
      and Lines.ACCOUNTING_DATE > add_months(to_date(:FechaMonYY,'Mon-YY'),-18) and Lines.accounting_date <= last_day(to_date(:FechaMonYY,'Mon-YY')) 
      and Headr.SET_OF_BOOKS_ID=2057
      and coa.chart_of_accounts_id = 50355
      and dist.dist_code_combination_id = coa.code_combination_id
      and lines.start_expense_date is not null
group by to_char(Lines.ACCOUNTING_DATE,'YYYYMM'), to_char(Lines.Start_Expense_Date, 'YYYYMM'), Headr.Invoice_num, segment2, lines.Accounting_date
)



SELECT Amount, AcctDate, TranMonth, Invoice,null 
        ,round(months_between(to_date(AcctDate,'YYYYMM'),to_date(TranMonth, 'YYYYMM')),0) MonthBetween,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-1),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-1),'YYYYMM')) then amount else 0 end) as PRIOR_MONTH,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-2),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-2),'YYYYMM')) then amount else 0 end) as MO_PRIOR2,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-3),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-3),'YYYYMM')) then amount else 0 end) as MO_PRIOR3,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-4),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-4),'YYYYMM')) then amount else 0 end) as MO_PRIOR4,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-5),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-5),'YYYYMM')) then amount else 0 end) as MO_PRIOR5,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-6),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-6),'YYYYMM')) then amount else 0 end) as MO_PRIOR6,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-7),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-7),'YYYYMM')) then amount else 0 end) as MO_PRIOR7,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-8),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-8),'YYYYMM')) then amount else 0 end) as MO_PRIOR8,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-9),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-9),'YYYYMM')) then amount else 0 end) as MO_PRIOR9,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-10),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-10),'YYYYMM')) then amount else 0 end) as MO_PRIOR10,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-11),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-11),'YYYYMM')) then amount else 0 end) as MO_PRIOR11,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-12),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-12),'YYYYMM')) then amount else 0 end) as MO_PRIOR12,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-13),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-13),'YYYYMM')) then amount else 0 end) as MO_PRIOR13,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-14),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-14),'YYYYMM')) then amount else 0 end) as MO_PRIOR14,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-15),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-15),'YYYYMM')) then amount else 0 end) as MO_PRIOR15,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-16),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-16),'YYYYMM')) then amount else 0 end) as MO_PRIOR16,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-17),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-17),'YYYYMM')) then amount else 0 end) as MO_PRIOR17,
      (case when (AcctDate > to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-18),'YYYYMM') and TranMonth <= to_char(add_months(to_date(:FechaMonYY,'Mon-YY'),-18),'YYYYMM')) then amount else 0 end) as MO_PRIOR18
      
FROM ABC

union
select ratio_to_report(sum(amount)) over () as ratio, 'RATIO','RATIO', 'RATIO', Segment2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
from abc
where to_char(Accounting_date, 'Mon-YY') = :FechaMonYY
and segment2 not in ('100', '150', '160', '170')
group by segment2


