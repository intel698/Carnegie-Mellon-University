With AA as (
select distinct
(select name from hr_operating_units where organization_id = a.org_id ) "Unit"   
, to_char(a.GL_DATE, 'MM') "MM"
, to_char(a.GL_Date, 'YY') "YY"
, c.Segment1 "Co"
, c.Segment2 "CC"
, b.amount 
, A.invoice_currency_code
, invoice_num
, case 
when C.Segment1 between '100' and '199' then 'AMER'
when C.Segment1 between '200' and '299' then 'LATAM'
when C.Segment1 between '400' and '699' then 'EMEA'
when C.Segment1 between '700' and '999' then 'APAC'
end Region
, nvl((select category from rgiro_cat where C.Segment3 = Account), 'Other') "Category"
, nvl((select subcategory from rgiro_cat where C.Segment3 = Account),'Other') "Subcategory"
, nvl((select Master_supplier from Rgiro_vendor where supplier = D.vendor_name)
, D.vendor_name) "Supplier"
, D.Segment1 "Supplier Num"
, (select CLT from RGIRO where C.Segment2 = CostCenter) CLT
, case 
when a.invoice_currency_code != 'USD' then
Round((
  (select distinct conversion_rate 
  from GL_Daily_Rates
  where trunc(conversion_date) = trunc(b.accounting_DATE)
  and a.invoice_currency_code = from_currency
  and to_currency = 'USD'
  and conversion_type = 'Corporate') * B.AMOUNT),2)
else B.AMOUNT
end "USD"
   
FROM AP.AP_INVOICES_ALL A,   
AP_INVOICE_DISTRIBUTIONS_ALL B,  
gl_code_combinations C,
ap_suppliers D


where 1=1
and a.vendor_id = D.vendor_id
and a.invoice_id = b.invoice_id   
and B.dist_code_combination_id = C.code_combination_id
and (invoice_type_lookup_code not in ('PAYMENT REQUEST', 'AWT','EXPENSE REPORT'))
and b.line_type_lookup_code = 'ITEM'
and not C.segment3 < 300000
and D.vendor_type_lookup_code != 'EMPLOYEE'
and D.vendor_name not like 'Red Hat%'

and (a.gl_date between to_date('01-Jan-2016','dd-Mon-YYYY') and to_date('31-Oct-2016','dd-Mon-YYYY')
or (a.gl_date between to_date('01-Jan-2015','dd-Mon-YYYY') and to_date('31-Oct-2015','dd-Mon-YYYY'))
)

),

BB As (
select "Unit", "MM", "YY", "Co", "CC", amount, invoice_currency_code, invoice_num, Region, "Category", "Subcategory"
, "Supplier", "Supplier Num", CLT, sum("USD") "USD"
from AA
group by "Unit", "MM", "YY", "Co", "CC", amount, invoice_currency_code, invoice_num, Region, "Category", "Subcategory"
, "Supplier", "Supplier Num", CLT),

CC as (
select F."Supplier", F."Category", ratio_to_report("USD") over (partition by "Category") "TopSupplier"
from (select "Supplier", "Category", sum ("USD") "USD"
      from AA
      group by "Supplier", "Category") F)



, DD as (
select G."Subcategory", count(*) conteo
From
(select "Supplier" ,"Category", "Subcategory"
from BB
group by "Supplier", "Category", "Subcategory") G
group by "Subcategory")



select "Unit", "MM", "YY", "Co", "CC", amount, invoice_currency_code, invoice_num, Region, BB."Category", BB."Subcategory"
, BB."Supplier", BB."Supplier Num", CLT, "USD", round(CC."TopSupplier",4), (select conteo from DD where DD."Subcategory" = BB."Subcategory") Conteo,
case 
when CC."TopSupplier" >= .02 then BB."Supplier"
else 'Other'
end "AdjSupplier"

from BB, CC
where BB."Supplier" = CC."Supplier"
and BB."Category" = CC."Category"



