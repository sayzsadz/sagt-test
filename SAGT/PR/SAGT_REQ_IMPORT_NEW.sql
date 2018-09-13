
  CREATE OR REPLACE FORCE VIEW XXSAGT_REQUESTION_V
  as
  SELECT prh.requisition_header_id,
  prl.requisition_line_id,
  pda.req_distribution_id,
  --PRL.LINE_NUM,
  prh.segment1 PR_NUMBER,
  prh.creation_date,
  prh.created_by,
  poh.segment1 PO_NUMBER,
  ppx.full_name REQUESTER_NAME,
  prh.description PR_DESCRIPTION,
  --prh.authorization_status,
  --prh.note_to_authorizer,
  --prh.type_lookup_code,
  prl.line_num,
  prl.line_type_id,
  prl.item_description,
  prl.unit_meas_lookup_code,
  prl.unit_price,
  prl.quantity,
  prl.need_by_date,
  prl.note_to_agent,
  prl.currency_code,
  prl.item_id,
  prl.VENDOR_ID,
  prl.VENDOR_SITE_ID,
  prl.VENDOR_CONTACT_ID,
  'New' STATUS
FROM po_requisition_headers_all prh,
  po_requisition_lines_all prl,
  po_req_distributions_all prd,
  per_people_x ppx,
  po_headers_all poh,
  po_distributions_all pda
WHERE prh.requisition_header_id = prl.requisition_header_id
AND ppx.person_id               = prh.preparer_id
AND prh.type_lookup_code        = 'PURCHASE'
AND prd.requisition_line_id     = prl.requisition_line_id
AND pda.req_distribution_id     = prd.distribution_id
AND pda.po_header_id            = poh.po_header_id
AND prh.requisition_header_id in (select REQ_HEADER_ID from REQ_HEADER_IDS_TL)
AND prh.requisition_header_id not in (select REQ_HEADER_ID from XX_REQUESTION_STAGING)
;


select * from XX_REQUESTION_STAGING;

insert into REQ_HEADER_IDS_TL values (3126);

select *
from XXSAGT_REQUESTION_V;