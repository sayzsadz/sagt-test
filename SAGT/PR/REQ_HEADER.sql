     ----------------------------------------------------------------------------------------------
      -- Create requisition header
      ----------------------------------------------------------------------------------------------
      PROCEDURE Create_Requistion (
        p_po_header_id      IN  NUMBER
      , x_org_id OUT NUMBER
      , x_requisition_header_id    OUT NUMBER    
      , x_vendor_id           OUT NUMBER
      , x_vendor_site_id      OUT NUMBER
      , x_requisition_number   OUT VARCHAR2  
      , x_error_code        OUT VARCHAR2
      , x_error_msg         OUT VARCHAR2
      )
      IS
        CURSOR C_Vendor
        (
          cp_header_id  PO_HEADERS.PO_Header_Id%TYPE
        )
        IS
        SELECT H.Vendor_Id
        ,      H.Vendor_Site_Id
        ,      H.Org_Id
        FROM   PO_HEADERS_ALL  H
        WHERE  H.PO_Header_Id    = cp_header_id
        ;
        
      BEGIN
        x_error_code := NULL;
        x_requisition_number := NVL (FND_PROFILE.Value ('XXX_MY_PREFIX'),'XLS-') || to_char (Sysdate,'DDMMYYYYHH24MISS');
        
        SELECT PO_REQUISITION_HEADERS_S.NEXTVAL     
        INTO   x_requisition_header_id
        FROM   DUAL;
        
        OPEN  C_Vendor (cp_header_id => p_po_header_id);
        FETCH C_Vendor INTO x_vendor_id, x_vendor_site_id,x_org_id;
        CLOSE C_Vendor;
                
      END Create_Requistion;
/


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



l_request_id :=
                fnd_request.submit_request (application => 'PO' --Application, 
                , program => 'REQIMPORT' --Program, 
                 ,argument1 => 'SCAN' --Interface Source code,              
                 ,argument2 => '' --Batch ID, 
                 ,argument3 => 'ALL'--Group By, 
                 ,argument4 => ''--Last Req Number, 
                 ,argument5 => 'N'--Multi Distributions, 
                 ,argument6 => 'Y' --Initiate Approval after ReqImport 
                 ); 
                 COMMIT;



l_conc_status := APPS.FND_CONCURRENT.WAIT_FOR_REQUEST
                                (request_id => l_request_id
                                ,interval   => 5            -- Sleep 5 seconds between checks.
                                ,max_wait   => 600            
                                ,phase      => l_phase
                                ,status     => l_status
                                ,dev_phase  => l_dev_phase
                                ,dev_status => l_dev_status
                                ,message    => l_message
                                );
