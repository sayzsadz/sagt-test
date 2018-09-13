select *
from XXSAGT_REQUESTION_V;

SELECT *
        FROM   PO_HEADERS_ALL  H
        where AUTHORIZATION_STATUS = 'IN PROCESS'
        ;
        
        SELECT *
        FROM   PO_LINES_ALL  H        
order by LAST_UPDATE_DATE desc;

1484810	2245
--        WHERE  H.PO_Header_Id    = cp_header_id
        
        select *
        from all_objects
        where object_name like '%PO_%DIS%_S';
        
        
        PO_REQ_DISTRIBUTIONS_S
      SELECT PO_REQUISITION_LINES_S.NEXTVAL     
        --INTO   x_requisition_header_id
        FROM   DUAL;
        
        select *
        from MTL_UNITS_OF_MEASURE_TL;
        
        select *
        from all_tables
        where table_name like upper('%Unit%');
        
        select *
        from FND_ID_FLEX_STRUCTURES_VL s
        where s.id_flex_structure_code        = 'PO_ITEM_CATEGORY';
        
        select  m.inventory_item_id
              --r.segment_value     
            from    mtl_item_categories_v           c
            ,       FND_ID_FLEX_STRUCTURES_VL       s
            --,       po_rule_expense_accounts        r  
            , MTL_SYSTEM_ITEMS_B m
            where   1 =1
            and s.id_flex_num                   = c.structure_id
            --and     s.id_flex_structure_code        = 'PO_ITEM_CATEGORY'
            --and     r.rule_value_id                 = c.category_id
            and     c.organization_id               = (select master_organization_id from mtl_parameters where organization_id = m.organization_id)
            --and     r.org_id                        = fnd_profile.value ('ORG_ID')
            and        c.inventory_item_id                = m.inventory_item_id  
            ;
            
            
            select *
            from MTL_SYSTEM_ITEMS_B
            where rownum < 10
            order by last_update_date desc;
            
            select  r.segment_value     
            from    mtl_item_categories_v           c
            ,       FND_ID_FLEX_STRUCTURES_VL       s
            ,       po_rule_expense_accounts        r            
            where   s.id_flex_num                   = c.structure_id
            and     s.id_flex_structure_code        = 'PO_ITEM_CATEGORY'
            and     r.rule_value_id                 = c.category_id
            and     c.organization_id               = (select master_organization_id from mtl_parameters where organization_id = m.organization_id)
            and     r.org_id                        = fnd_profile.value ('ORG_ID')
            and        c.inventory_item_id                = m.inventory_item_id          

select *
from po_rule_expense_accounts;

INSERT INTO PO_REQUISITIONS_INTERFACE_ALL
             (interface_source_code
             ,source_type_code
             ,requisition_type
             ,destination_type_code
             ,item_id
             ,item_description
             ,quantity
             ,authorization_status
             ,preparer_id            
             , requisition_header_id
             ,req_number_segment1         
             ,uom_code
             ,destination_organization_id
             ,destination_subinventory
             ,deliver_to_location_id
             ,deliver_to_requestor_id
             ,need_by_date
             ,gl_date
             --,charge_account_id
             , charge_account_segment1
             , charge_account_segment2
             , charge_account_segment3
             , charge_account_segment4
             , charge_account_segment5
             , charge_account_segment6
             , charge_account_segment7
             , charge_account_segment8
             , charge_account_segment9
             ,accrual_account_id
             --,variance_account_id
             ,org_id
             ,suggested_vendor_id
             ,suggested_vendor_site_id
             ,unit_price
             ,creation_date
             ,created_by
             ,last_update_date
             ,last_updated_by
             , header_description
             , category_id
             --, category_segment1
            , autosource_doc_header_id                    -- 24-Sep-2015
             , autosource_doc_line_num                    -- 24-Sep-2015
             , autosource_flag                            -- 24-Sep-2015
             )
            VALUES ('SCAN'
             ,'VENDOR'
             ,'PURCHASE'
             ,I.destination_type_code -- 'EXPENSE' -- depends on whether it's an article or not ..
             ,I.inventory_item_id
             ,l_description
             ,I.Quantity
             ,'INCOMPLETE'
             ,l_emp_id            
             , p_requisition_header_id
             , p_requisition_number        
             , I.Primary_Unit_Of_Measure
             , p_item_org_id
             ,null -- rec_get_lines_info.subinventory
             , I.Location_Id -- rec_get_lines_info.location_id
             ,l_emp_id
             ,sysdate
             ,SYSDATE
             , l_segment1
             , l_segment2
             , l_segment3
             , l_segment4
             , l_segment5
             , l_segment6
             , l_segment7
             , l_segment8
             , l_segment9
             , null -- rec_get_lines_info.ap_accrual_account
             , p_org_id
             , p_vendor_id 
             , p_vendor_site_id 
             , COALESCE (I.Price_From_Blanket,l_cost_price,I.Unit_Price)
             ,SYSDATE
             ,fnd_global.user_id
             ,SYSDATE
             ,fnd_global.user_id
             , 'Description ...'
             , I.Category_Id
             --, I.category_segment
             , p_blanket_id 
             , p_blanket_line_num
             , p_autosource_flag
             );  