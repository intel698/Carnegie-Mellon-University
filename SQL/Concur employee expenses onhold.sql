SELECT * FROM
 (SELECT
    ail.attribute7          Batch_id,
    ai.invoice_date,
    ai.invoice_num,
    (CASE WHEN ail.project_id is not null THEN 'PROJECT' ELSE 'NON-PROJECT' END) inv_validation_type,
    aps.segment1            supplier_num,
    aps.vendor_name supplier,
    apss.vendor_site_code   site_name,
    ah.hold_lookup_code hold_name,
    ail.line_type_lookup_code,
    ail.line_number,
    ail.attribute1          report_key,
    ail.attribute2          employee,
    ail.attribute3          employee_party_id,
    pa.segment1             project_number,
    pt.task_number,
    pt.chargeable_flag      task_chargeable_flag, 
    hu.name expenditure_organization,
    ptc.chargeable_flag     control_chargeable_flag,
    ail.expenditure_item_date,
    ptc.start_date_active,
    ptc.end_date_active,
    ail.amount invoice_line_amount,        
    nvl(total_dist_amount,0) total_dist_amount,
    pt.billable_flag      task_billable_flag,
    pa.project_status_code,
    phou.name project_operating_unit,
    pa.allow_cross_charge_flag,
    ptc.employees_only_flag task_employee_type,
    nvl2(ptc.person_id,'Yes','No') Is_employee_in_Trans_Control,
    (select effective_start_date  from apps.XXRH_PER_ALL_ASSIGNMENTS_V where person_id = ptc.person_id and trunc(sysdate) between effective_start_date and effective_end_Date) latest_hr_assgn_start_Date,
    (select file_name from xxrhfin.xxrhfin_concur_sae_hdr where batch_id = ail.attribute7) file_name
    --,pt.*
FROM
    apps.ap_holds_all              ah,
    apps.ap_invoices_all           ai,
    apps.ap_invoice_lines_all      ail,
    apps.ap_suppliers              aps,
    apps.ap_supplier_sites_all     apss,
    apps.pa_transaction_controls   ptc,
    apps.pa_projects_all           pa,
    ( SELECT invoice_id            dist_invoice_id, invoice_line_number   dist_line_num,SUM(total_dist_amount) total_dist_amount
        FROM apps.ap_invoice_distributions_all GROUP BY invoice_id, invoice_line_number) aida,
    apps.hr_all_organization_units hu,
    apps.hr_operating_units phou,
    apps.pa_tasks                  pt
WHERE 1 = 1
    AND ai.source = 'CONCUR'
    AND aps.vendor_id = ai.vendor_id
    AND aps.vendor_id = apss.vendor_id
    AND ai.vendor_site_id = apss.vendor_site_id
    AND ai.invoice_id = ah.invoice_id
    AND ai.invoice_id = ail.invoice_id
    AND ah.release_lookup_code IS NULL
    AND ah.hold_lookup_code = 'DIST VARIANCE'
    AND ail.project_id = ptc.project_id
    AND ail.task_id = ptc.task_id
    AND ptc.project_id = pa.project_id
    AND ptc.task_id = pt.task_id
    AND aps.party_id = ai.party_id
    AND aps.employee_id = nvl(ptc.person_id,aps.employee_id) 
    AND ail.invoice_id = aida.dist_invoice_id (+)
    AND ail.line_number = aida.dist_line_num (+)
 --   AND ai.invoice_num = 'US_CONCUR_SVCS_byarger_25APR19_319_USD'
 --and pa.segment1 = '37858' and pt.task_number = '7.0'
  -- and pt.carrying_out_organization_id = hu1.organization_id
   and ail.expenditure_organization_id = hu.organization_id
   and pa.org_id = phou.organization_id
    AND ail.amount <> nvl(total_dist_amount, 0)
    and trunc(ai.invoice_date) <= TO_DATE('31-JUL-19','DD-MON-RR')
)
UNION
-- NON-SVCS (NON PROJECT RELATED HOLDS)
(SELECT
    ail.attribute7          Batch_id,
    ai.invoice_date,
    ai.invoice_num,
    (CASE WHEN ail.project_id is not null THEN 'PROJECT' ELSE 'NON-PROJECT' END) inv_validation_type,
    aps.segment1            supplier_num,
    aps.vendor_name,
    apss.vendor_site_code   site_name,
    ah.hold_lookup_code hold_name,
    ail.line_type_lookup_code,
    ail.line_number,
    ail.attribute1          report_key,
    ail.attribute2          employee,
    ail.attribute3          employee_party_id,
    null             project_number,
    null task_number,
    null task_chargeable_flag,
    null expenditure_organization,
    null control_chargeable_flag,
    ail.expenditure_item_date,
    null start_date_active,
    null end_date_active,
    ail.amount invoice_line_amount,              
    nvl(total_dist_amount,0) total_dist_amount,
    null task_billable_flag,
    'NON-PROJECT' project_status_code,
    hou.name operating_unit,
    null allow_cross_charge_flag,
    null task_employees_type,
    null Is_employee_in_Trans_Control,
    ( select MAX(EFFECTIVE_START_DATE) from apps.XXRH_PER_ALL_ASSIGNMENTS_V where person_id IN (SELECT distinct person_id FROM APPS.XXRH_EMP_BASIC_DATA_V WHERE PARTY_ID = ail.attribute3) 
    and trunc(sysdate) between effective_start_date and effective_end_Date ) latest_hr_assgn_start_Date,
    (select file_name  from xxrhfin.xxrhfin_concur_sae_hdr where batch_id = ail.attribute7) file_name
FROM
    apps.ap_holds_all              ah,
    apps.ap_invoices_all           ai,
    apps.ap_invoice_lines_all      ail,
    apps.ap_suppliers              aps,
    apps.ap_supplier_sites_all     apss,
    ( SELECT invoice_id            dist_invoice_id, invoice_line_number   dist_line_num,SUM(total_dist_amount) total_dist_amount
        FROM apps.ap_invoice_distributions_all GROUP BY invoice_id, invoice_line_number) aida,
    apps.hr_operating_units hou
WHERE 1 = 1
    AND ai.source = 'CONCUR'
    AND aps.vendor_id = ai.vendor_id
    AND aps.vendor_id = apss.vendor_id
    AND ai.vendor_site_id = apss.vendor_site_id
    AND ai.invoice_id = ah.invoice_id
    AND ai.invoice_id = ail.invoice_id
    AND ah.release_lookup_code IS NULL
    AND ah.hold_lookup_code = 'DIST VARIANCE'
    AND ail.project_id IS NULL
    AND ail.invoice_id = aida.dist_invoice_id (+)
    AND ail.line_number = aida.dist_line_num (+)
     and ai.org_id = hou.organization_id
    AND ail.amount <> nvl(total_dist_amount, 0)
 --   AND ai.invoice_num = 'US_CONCUR_30APR19_324_USD'
    and trunc(ai.invoice_date) <= TO_DATE('31-JUL-19','DD-MON-RR')
 )
ORDER BY  1,2,3,5,6