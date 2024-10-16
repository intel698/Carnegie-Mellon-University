--SQL Statement – Retrieve all Journal Entries for a Transaction 

select inv.invoice_num, 
       ael.entered_dr,  
       ael.entered_cr,  
       ael.accounted_dr,  
       ael.accounted_cr 
from ap_invoices_all          inv, 
     xla_transaction_entities ent, 
     xla_ae_headers           aeh, 
     xla_ae_lines             ael 
where ent.application_id = 200 
  and inv.invoice_id     = ent.source_id_int_1 
  and ent.entity_code    = 'AP_INVOICES' 
  and ent.entity_id      = aeh.entity_id 
  and aeh.ae_header_id   = ael.ae_header_id 
  and inv.invoice_id     = 1234 


--SQL Statement – Retrieve Invalid Journal Entries for a Transaction 

select inv.invoice_num,  
       aeh.ledger_id, 
       ael.entered_dr,  
       ael.entered_cr,  
       ael.accounted_dr,  
       ael.accounted_cr 
from ap_invoices_all          inv, 
     xla_transaction_entities ent, 
     xla_events               evt, 
     xla_ae_headers           aeh, 
     xla_ae_lines             ael 
where ent.application_id = 200 
  and inv.invoice_id     = ent.source_id_int_1 
  and ent.entity_code    = 'AP_INVOICES' 
  and ent.entity_id      = evt.entity_id 
  and evt.event_id       = aeh.event_id 
  and aeh.ae_header_id   = ael.ae_header_id 
  and inv.invoice_id     = 1234 
  and evt.process_status_code = 'I' 
  
--Retrieve Journal Entries for an Event  (It is assumed that users already know the event identifier)
--If users do not have the event identifier, it can be retrieved by using event APIs.


select inv.invoice_num, 
       ael.entered_dr,  
       ael.entered_cr,  
       ael.accounted_dr,  
       ael.accounted_cr 
from ap_invoices_all          inv, 
     xla_transaction_entities ent, 
     xla_events               evt, 
     xla_ae_headers           aeh, 
     xla_ae_lines             ael 
where ent.application_id = 200 
  and inv.invoice_id     = ent.source_id_int_1 
  and ent.entity_code    = 'AP_INVOICES' 
  and ent.entity_id      = evt.entity_id 
  and evt.event_id       = aeh.event_id 
  and aeh.ae_header_id   = ael.ae_header_id 
  and inv.invoice_id     = 1234 
  and evt.event_id       = 201 
  

--Retrieve journal entries for invalid events. 
select inv.invoice_num,  
       ael.entered_dr,  
       ael.entered_cr,  
       ael.accounted_dr,  
       ael.accounted_cr 
from ap_invoices_all          inv, 
     xla_transaction_entities ent, 
     xla_events               evt, 
     xla_ae_headers           aeh, 
     xla_ae_lines             ael 
where ent.application_id = 200 
  and inv.invoice_id     = ent.source_id_int_1 
  and ent.entity_code    = 'AP_INVOICES' 
  and ent.entity_id      = evt.entity_id 
  and evt.event_id       = aeh.event_id 
  and aeh.ae_header_id   = ael.ae_header_id 
  and evt.process_status_code = 'I' 
  

--SQL Statement – Retrieve journal entries for the primary ledger 
--The assumption here is that the inv.set_of_books_id contains the primary ledger identifier. 

select inv.invoice_num,  
       ael.entered_dr,  
       ael.entered_cr,  
       ael.accounted_dr,  
       ael.accounted_cr 
from ap_invoices_all          inv, 
     xla_transaction_entities ent, 
     xla_events               evt, 
     xla_ae_headers           aeh, 
     xla_ae_lines             ael 
where ent.application_id = 200 
  and inv.invoice_id     = ent.source_id_int_1 
  and ent.entity_code    = 'AP_INVOICES' 
  and ent.entity_id      = evt.entity_id 
  and evt.event_id       = aeh.event_id 
  and aeh.ae_header_id   = ael.ae_header_id 
  and aeh.ledger_id      = inv.set_of_books_id 
  
  

--Retrieve journal entries for a transaction and a secondary ledger. 
--Users must retrieve the secondary ledger identifier from the accounting setup before using this query. 
--Users can use the same query to retrieve journal entries for reporting currencies. 

select inv.invoice_num,  
       ael.entered_dr,  
       ael.entered_cr,  
       ael.accounted_dr,  
       ael.accounted_cr 
from ap_invoices_all          inv, 
     xla_transaction_entities ent, 
     xla_ae_headers           aeh, 
     xla_ae_lines             ael 
where ent.application_id = 200 
  and inv.invoice_id     = ent.source_id_int_1 
  and ent.entity_code    = 'AP_INVOICES' 
  and ent.entity_id      = aeh.entity_id 
  and aeh.ae_header_id   = ael.ae_header_id 
  and aeh.ledger_id      = <secondary_ledger_id> 
 
--The distribution links table maintains a link between the subledger transaction distributions and subledger journal entry lines. 
--Users can use this information for audit purposes or to inquire upon subledger journal lines related to a particular distribution. 
--Use the following SQL statement to retrieve journal entries lines related to transaction distributions. 

select inv.invoice_num, 
       dis.invoice_distribution_id 
       ael.entered_dr,  
       ael.entered_cr,  
       ael.accounted_dr,  
       ael.accounted_cr 
from ap_invoices_all          inv, 
     ap_invoice_distributions_dis_all, 
     xla_distribution_links   lnk, 
     xla_ae_headers           aeh, 
     xla_ae_lines             ael 
where inv.invoice_id                 = dis.invoice_id 
  AND inv.invoice_id                 = 1234 
  AND lnk.application_id             = 200 
  AND lnk.SOURCE_DISTRIBUTION_TYPE   = 'AP_INVOICE_DISTRIBUTIONS' 
  AND dis.invoice_distribution_id    = lnk.source_distribution_id_num_1 
  AND lnk.ae_header_id               = ael.ae_header_id 
  AND lnk.ae_line_num                = ael.ae_line_num 
  AND aeh.ae_header_id               = ael.ae_header_id 
  
--SQL Statement – Retrieve Journal Entry Lines Related to Distributions/Event 
--Use the following SQL statement to retrieve journal entries lines related to transaction distributions if the application stores the event identifier on the distribution. 

select inv.invoice_num, 
       dis.invoice_distribution_id 
       ael.entered_dr,  
       ael.entered_cr,  
       ael.accounted_dr,  
       ael.accounted_cr 
from ap_invoices_all          inv, 
     ap_invoice_distributions_dis_all, 
     xla_distribution_links   lnk, 
     xla_ae_headers           aeh, 
     xla_ae_lines             ael 
where inv.invoice_id                 = dis.invoice_id 
AND inv.invoice_id                 = 1234  
AND lnk.application_id             = 200 
  AND dis.accounting_event_id        = lnk.event_id 

AND lnk.ae_header_id               = ael.ae_header_id 
  AND lnk.ae_line_num                = ael.ae_line_num 
  AND aeh.ae_header_id               = ael.ae_header_id 

