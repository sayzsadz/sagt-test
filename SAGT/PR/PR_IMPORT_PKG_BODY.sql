CREATE OR REPLACE PACKAGE BODY req_po_load_pkg
IS
  PROCEDURE SUBMIT_REQUEST
    (
      pn_batch_id        IN NUMBER,
      pv_int_source_code IN VARCHAR2
    )
  IS
    ln_request_id NUMBER;
    ln_max_wait   NUMBER;
    lv_phase      VARCHAR2(10);
    lv_status     VARCHAR2(10);
    lv_dev_status VARCHAR2(10);
    lv_message    VARCHAR2(100);
    ln_interval   NUMBER;
    lv_dev_phase  VARCHAR2(10);
    rphase        VARCHAR2(10);
    rstatus       VARCHAR2(10);
    dphase        VARCHAR2(10);
    dstatus       VARCHAR2(10);
    MESSAGE       VARCHAR2(100);
    callv_status  BOOLEAN ;
    wait_status   BOOLEAN ;
  BEGIN
    fnd_global.apps_initialize(0, 20634, 401, NULL, NULL );
    ln_request_id:= fnd_request.submit_request('PO' ,'REQIMPORT' ,NULL ,NULL ,FALSE ,pv_int_source_code ---arg1
    ,pn_batch_id ,'All' ,NULL ,'N' ,'Y' );
    COMMIT;
    wait_status:=fnd_concurrent.wait_for_request (ln_request_id, 60 , 0, lv_phase , lv_status , lv_dev_phase, lv_dev_status, lv_message);
    -- callv_status :=fnd_concurrent.get_request_status(ln_request_id, '', '',
    --          rphase,rstatus,dphase,dstatus, message);
    fnd_file.put_line(fnd_file.log,'dphase = '||lv_dev_phase||'and '||'dstatus ='||lv_dev_status) ;
    IF UPPER(lv_dev_phase)='COMPLETE' AND UPPER(lv_dev_status)= 'NORMAL' THEN
      dbms_output.put_line ('Requisition Import program completed successfully');
      fnd_file.put_line(fnd_file.log,'Requisition Import program completed successfully');
    END IF;
  EXCEPTION
  WHEN OTHERS THEN
    fnd_file.put_line(fnd_file.log,'Error occure in procedure submit_request'||SQLERRM);
  END SUBMIT_REQUEST;
  PROCEDURE MAIN
    (
      errbuf OUT VARCHAR2,
      retcode OUT NUMBER,
      pn_batch_id        IN NUMBER,
      pv_int_source_code IN VARCHAR2
    )
  IS
    CURSOR c_requistion_rec
    IS
      SELECT *
      FROM xx_req_po_stg
      WHERE batch_id           =pn_batch_id
      AND interface_source_code=pv_int_source_code
      AND authorization_status ='APPROVED'
      AND NVL(error_flag,'N')  = 'N';
    -- AND batch_id not in (select substr(attribute14,12) from po_requisition_lines_all);
    lv_error_flag            VARCHAR2 (1);
    lv_error_msg             VARCHAR2 (1000);
    ln_record_id             NUMBER;
    ln_item_id               NUMBER;
    ln_category_id           NUMBER;
    ln_emp_id                NUMBER;
    ln_location_id           NUMBER;
    ln_organization_id       NUMBER;
    ld_need_by_date          DATE;
    ln_org_id                NUMBER;
    ln_vendor_id             NUMBER;
    ln_site_id               NUMBER;
    ln_requestor_id          NUMBER;
    ln_charge_account_id     NUMBER;
    lv_req_number_segment1   VARCHAR2(20);
    ln_distribution_num      NUMBER :=0;
    ln_requisition_line_id   NUMBER;
    lv_concatenated_segments VARCHAR2(50);
    lv_company               VARCHAR2(20);
    --l_request_stat varchar2 (10);
  BEGIN
    /*BEGIN
    SELECT NVL(MAX(record_id),0)
    INTO ln_record_id
    FROM  xx_req_po_stg
    WHERE batch_id=pn_batch_id;
    UPDATE  xx_req_po_stg
    SET record_id=ln_record_id+ROWNUM;
    COMMIT;
    END;*/
--    SELECT segment1
--    INTO lv_req_number_segment1
--    FROM po_requisition_headers_all
--    WHERE requisition_header_id IN
--      (SELECT MAX(requisition_header_id) FROM po_requisition_headers_all
--      );
    fnd_file.put_line(fnd_file.log,'Validating the staging table data..');
    FOR v_requistion_rec IN c_requistion_rec
    LOOP
      ----initializtion local varibale to null-----------
      lv_error_flag            := NULL;
      lv_error_msg             := NULL;
      ln_item_id               :=NULL ;
      ln_category_id           :=NULL ;
      ln_emp_id                :=NULL;
      ln_location_id           :=NULL;
      ln_organization_id       :=NULL;
      ld_need_by_date          :=NULL;
      ln_org_id                :=NULL;
      ln_vendor_id             :=NULL;
      ln_site_id               :=NULL;
      ln_requestor_id          :=NULL;
      ln_charge_account_id     :=NULL;
      lv_req_number_segment1   :=NULL;
      ln_requisition_line_id   :=NULL;
      lv_concatenated_segments :=NULL;
      lv_company               :=NULL;
      -- lv_req_number_segment1 :=lv_req_number_segment1+1;
      ln_distribution_num := ln_distribution_num+1;
      -----------VALIDATION STARTS HERE------------------
      /* IF v_requistion_rec.INTERFACE_SOURCE_CODE IS NULL THEN
      lv_error_flag := 'E';
      lv_error_msg  := 'INTERFACE_SOURCE_CODE Can not be Null';
      END IF;  */
      IF v_requistion_rec.requisition_type IS NULL THEN
        lv_error_flag                      := 'E';
        retcode                            :=2;
        lv_error_msg                       := lv_error_msg||'REQUISITION_TYPE Can not be Null';
      END IF;
      fnd_file.put_line(fnd_file.log,'Requisition type is '||' '||v_requistion_rec.requisition_type);
      IF v_requistion_rec.destination_type_code IS NULL THEN
        lv_error_flag                           := 'E';
        retcode                                 :=2;
        lv_error_msg                            := lv_error_msg||'DESTINATION_TYPE_CODE Can not be Null';
      END IF;
      fnd_file.put_line(fnd_file.log,'Destination type is '||' '||v_requistion_rec.destination_type_code);
      IF v_requistion_rec.item_name IS NULL THEN
        lv_error_flag               := 'E';
        retcode                     :=2;
        lv_error_msg                := lv_error_msg||'ITEM_NAME Can not be Null';
      ELSE
        BEGIN
          SELECT DISTINCT inventory_item_id
          INTO ln_item_id
          FROM mtl_system_items_b
          WHERE UPPER(segment1)=UPPER(v_requistion_rec.item_name);
        EXCEPTION
        WHEN OTHERS THEN
          -- ln_item_id:=NULL
          lv_error_flag := 'E';
          retcode       :=2;
          lv_error_msg  := lv_error_msg||'error occure while retreiving ITEM id :'|| ln_item_id || SQLERRM;
          fnd_file.put_line(fnd_file.log,'Step1'||' '||lv_error_msg);
        END;
      END IF;
      /* IF v_requistion_rec.category_name IS NULL THEN
      lv_error_flag := 'E';
      lv_error_msg  := 'category_id can not be Null';
      ELSE
      BEGIN
      SELECT DISTINCT category_id
      INTO ln_category_id
      FROM MTL_CATEGORIES_TL
      WHERE UPPER(DESCRIPTION)=UPPER(v_requistion_rec.category_name)
      and language='US';
      EXCEPTION WHEN others THEN
      -- ln_item_id:=NULL
      lv_error_flag := 'E';
      lv_error_msg  := 'error occure while retreiving ITEM id :'|| ln_item_id || SQLERRM;
      DBMS_OUTPUT.PUT_LINE('Step1'||' '||lv_error_msg);
      END;
      END IF; */
      IF v_requistion_rec.quantity IS NULL THEN
        lv_error_flag              := 'E';
        retcode                    :=2;
        lv_error_msg               := lv_error_msg||'QUANTITY Can not be Null';
      END IF;
      fnd_file.put_line(fnd_file.log,'Quantity is '||' '||v_requistion_rec.quantity);
      IF v_requistion_rec.preparer_full_name IS NULL THEN
        lv_error_flag                        := 'E';
        retcode                              :=2;
        lv_error_msg                         := lv_error_msg||'PREPARER_FULL_NAME Can not be Null';
      ELSE
        BEGIN
          SELECT DISTINCT per.person_id
          INTO ln_emp_id
          FROM per_all_people_f per,
            per_all_assignments_f paaf
          WHERE UPPER(per.full_name)=UPPER(v_requistion_rec.preparer_full_name )
          AND TRUNC(SYSDATE) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
          AND per.person_id=paaf.person_id;
          --   AND per.person_id=228207;
        EXCEPTION
        WHEN OTHERS THEN
          --ln_emp_id:=NULL
          lv_error_flag := 'E';
          retcode       :=2;
          lv_error_msg  := lv_error_msg||'Error occured while retreiving emp_id :'|| ln_emp_id || SQLERRM;
          fnd_file.put_line(fnd_file.log,'Step2' ||lv_error_msg);
        END;
      END IF;
      IF v_requistion_rec.uom_code IS NULL THEN
        lv_error_flag              := 'E';
        retcode                    :=2;
        lv_error_msg               := lv_error_msg||'UOM_CODE Can not be Null';
      END IF;
      IF v_requistion_rec.destination_organization IS NULL THEN
        lv_error_flag                              := 'E';
        retcode                                    :=2;
        lv_error_msg                               := lv_error_msg||'DESTINATION_ORGANIZATION Can not be Null';
      ELSE
        BEGIN
          SELECT organization_id
          INTO ln_organization_id
          FROM ORG_ORGANIZATION_DEFINITIONS OOD
          WHERE UPPER(ORGANIZATION_NAME)=UPPER(v_requistion_rec.DESTINATION_ORGANIZATION);
        EXCEPTION
        WHEN OTHERS THEN
          --ln_organization_id:=NULL;
          lv_error_flag := 'E';
          retcode       :=2;
          lv_error_msg  := lv_error_msg||'Error occure while retreiving inventory org_id :'|| ln_organization_id || SQLERRM;
          fnd_file.put_line(fnd_file.log,'Step3' ||lv_error_msg);
        END;
      END IF;
      IF v_requistion_rec.deliver_to_location IS NULL THEN
        lv_error_flag                         := 'E';
        retcode                               :=2;
        lv_error_msg                          := lv_error_msg||'DELIVER_TO_LOCATION can not be null';
      ELSE
        BEGIN
          SELECT location_id
          INTO ln_location_id
          FROM HR_LOCATIONS
          WHERE UPPER(location_code)=UPPER(v_requistion_rec.deliver_to_location);
        EXCEPTION
        WHEN OTHERS THEN
          --ln_location_id:=NULL;
          lv_error_flag := 'E';
          retcode       :=2;
          lv_error_msg  := lv_error_msg||'Error occure while retreiving the deliver_to_location_id :'|| ln_location_id || SQLERRM;
          fnd_file.put_line(fnd_file.log,'Step4' ||lv_error_msg);
        END ;
      END IF;
      IF v_requistion_rec.deliver_to_requestor IS NULL THEN
        lv_error_flag                          := 'E';
        retcode                                :=2;
        lv_error_msg                           := lv_error_msg||'DELIVER_TO_REQUESTOR can not be null';
      ELSE
        BEGIN
          SELECT DISTINCT per.person_id
          INTO ln_requestor_id
          FROM per_all_people_f per,
            per_all_assignments_f paaf,
            fnd_user fu
          WHERE UPPER(fu.user_name)=UPPER(v_requistion_rec.deliver_to_requestor)
          AND TRUNC(SYSDATE) BETWEEN paaf.effective_start_date AND paaf.effective_end_date
          AND per.person_id =paaf.person_id
          AND fu.employee_id=per.person_id;
          --  AND per.person_id=228207;
        EXCEPTION
        WHEN OTHERS THEN
          --ln_emp_id:=NULL
          lv_error_flag := 'E';
          retcode       :=2;
          lv_error_msg  := lv_error_msg||'Error occure while retreiving requestor_id :'|| ln_requestor_id || SQLERRM;
          fnd_file.put_line(fnd_file.log,'Step5' ||lv_error_msg);
        END;
      END IF;
      /* BEGIN
      SELECT organization_id
      INTO ln_org_id
      FROM hr_operating_units
      WHERE UPPER(NAME)=UPPER(v_requistion_rec.ou_name);
      EXCEPTION WHEN OTHERS THEN
      --ln_org_id:=NULL;
      lv_error_flag := 'E';
      lv_error_msg  := 'Error occure while retrieving the org_id :'|| ln_org_id || SQLERRM;
      DBMS_OUTPUT.PUT_LINE('Step6' ||lv_error_msg);
      END;  */
      BEGIN
        SELECT gcc.segment1
        INTO lv_company
        FROM gl_sets_of_books sob,
          gl_code_combinations gcc,
          org_organization_definitions ood
        WHERE sob.set_of_books_id    = ood.set_of_books_id
        AND gcc.chart_of_accounts_id = sob.chart_of_accounts_id
        AND ood.organization_code    = v_requistion_rec.ou_name
        AND gcc.segment2             = v_requistion_rec.cost_center
        AND gcc.segment3             = v_requistion_rec.natural_account
        AND gcc.segment4             = v_requistion_rec.sub_analysis_1
        AND gcc.segment6             = v_requistion_rec.inter_company;
      EXCEPTION
      WHEN no_data_found THEN
        fnd_file.put_line(fnd_file.log,'No Data found for company segment value');
      WHEN OTHERS THEN
        retcode :=2;
        fnd_file.put_line(fnd_file.log,'Error occure while retrieving the Company value'||''||sqlerrm);
      END;
      BEGIN
        SELECT lv_company
          ||'-'
          || v_requistion_rec.cost_center
          ||'-'
          || v_requistion_rec.natural_account
          ||'-'
          || v_requistion_rec.sub_analysis_1
          ||'-'
          || '000'
          ||'-'
          || v_requistion_rec.inter_company
          ||'-'
          || '00000'
          ||'-'
          || '000'
          ||'-'
          || '000'
        INTO lv_concatenated_segments
        FROM dual;
      END;
      fnd_file.put_line(fnd_file.log,'Concatenated segment value is '||' '||lv_concatenated_segments);
      IF lv_concatenated_segments IS NULL THEN
        lv_error_flag             := 'E';
        retcode                   :=2;
        lv_error_msg              := lv_error_msg||'CHARGE_ACCOUNT values can not be null';
      ELSE
        BEGIN
          SELECT DISTINCT code_combination_id
          INTO ln_charge_account_id
          FROM gl_code_combinations_kfv a,
            GL_SETS_OF_BOOKS gl
          WHERE TO_CHAR(concatenated_segments)=TO_CHAR(lv_concatenated_segments)
          AND gl.chart_of_accounts_id         =a.chart_of_accounts_id ;
        EXCEPTION
        WHEN OTHERS THEN
          --l_chanrge_account_id:=NULL;
          lv_error_flag := 'E';
          retcode       :=2;
          lv_error_msg  := lv_error_msg||'Error occure while retrieving the charge_account_id :'|| ln_charge_account_id || SQLERRM;
          fnd_file.put_line(fnd_file.log,'Step7' ||lv_error_msg);
        END;
      END IF;
      -----------Charge_account validation ends here----------------
      IF v_requistion_rec.need_by_date IS NULL THEN
        ld_need_by_date                := SYSDATE+1;
      ELSE
        ld_need_by_date:=v_requistion_rec.need_by_date;
      END IF;
      IF v_requistion_rec.ou_name IS NULL THEN
        lv_error_flag             := 'E';
        retcode                   :=2;
        lv_error_msg              := lv_error_msg||'OU_NAME can not be null';
      ELSE
        BEGIN
          SELECT ho.organization_id
          INTO ln_org_id
          FROM org_organization_definitions ood,
            hr_operating_units ho,
            --apps.tncus_customizations tc,
            gl_sets_of_books sb
          WHERE ood.operating_unit = ho.organization_id
          AND TRUNC (SYSDATE) BETWEEN NVL (ho.date_from, TRUNC (SYSDATE)) AND NVL (ho.date_to, TRUNC (SYSDATE))
          --AND tc.org_id                   = ho.organization_id
          AND upper(ood.organization_code)=UPPER(v_requistion_rec.ou_name)
          AND ood.set_of_books_id         = sb.set_of_books_id;
        EXCEPTION
        WHEN OTHERS THEN
          --ln_org_id:=NULL;
          lv_error_flag := 'E';
          retcode       :=2;
          lv_error_msg  := lv_error_msg||'Error occure while retrieving the org_id :'|| ln_org_id || SQLERRM;
          fnd_file.put_line(fnd_file.log,'Step8' ||lv_error_msg);
        END;
      END IF;
      IF v_requistion_rec.unit_price IS NULL THEN
        lv_error_flag                := 'E';
        retcode                      :=2;
        lv_error_msg                 := lv_error_msg||'UNIT_PRICE can not be null';
      END IF;
      IF v_requistion_rec.suggested_vendor_name IS NULL THEN
        lv_error_flag                           := 'E';
        retcode                                 :=2;
        lv_error_msg                            := lv_error_msg||'SUGGESTED_VENDOR_NAME can not be null';
      ELSE
        BEGIN
          SELECT vendor_id
          INTO ln_vendor_id
          FROM po_vendors
          WHERE UPPER(vendor_name)=UPPER(v_requistion_rec.suggested_vendor_name);
        EXCEPTION
        WHEN OTHERS THEN
          --ln_vendor_id:=NULL;
          lv_error_flag := 'E';
          retcode       :=2;
          lv_error_msg  := lv_error_msg||'Error occure while retrieving the vendor_id :'|| ln_vendor_id || SQLERRM;
          fnd_file.put_line(fnd_file.log,'Step9' ||lv_error_msg);
        END;
      END IF;
      IF v_requistion_rec.suggested_vendor_site IS NULL THEN
        lv_error_flag                           := 'E';
        retcode                                 :=2;
        lv_error_msg                            := lv_error_msg||'SUGGESTED_VENDOR_SITE can not be null';
      ELSE
        BEGIN
          SELECT vendor_site_id
          INTO ln_site_id
          FROM po_vendor_sites_all
          WHERE UPPER(vendor_site_code)=UPPER(v_requistion_rec.suggested_vendor_site)
          AND vendor_id                =ln_vendor_id
          AND org_id                   =ln_org_id;
        EXCEPTION
        WHEN OTHERS THEN
          lv_error_flag := 'E';
          retcode       :=2;
          lv_error_msg  := lv_error_msg||'Error occure while retrieving the vendor site_id :'|| ln_site_id || SQLERRM;
          fnd_file.put_line(fnd_file.log,'Step10' ||lv_error_msg);
        END;
      END IF;
      -------VALIDATION ENDS HERE------------------
      ------STARTING THE INSERTION IN REQUSITION INTERFACE -------------------------
      IF lv_error_flag IS NULL THEN
        INSERT
        INTO PO_REQUISITIONS_INTERFACE_ALL
          (
            batch_id ,
            TRANSACTION_ID ,
            interface_source_code ,
            source_type_code ,
            requisition_type ,
            destination_type_code ,
            item_id
            --,item_description
            -- ,CATEGORY_ID
            ,
            quantity ,
            authorization_status ,
            preparer_id
            --,category_id
            ,
            uom_code ,
            destination_organization_id ,
            deliver_to_location_id ,
            deliver_to_requestor_id ,
            charge_account_id ,
            need_by_date ,
            org_id ,
            unit_price ,
            autosource_flag ,
            suggested_vendor_id ,
            suggested_vendor_site_id
            --   ,req_number_segment1
            --  ,multi_distributions
            ,
            req_dist_sequence_id
          )
          VALUES
          (
            v_requistion_rec.batch_id ,
            PO_REQUISITIONS_INTERFACE_S.nextval ,
            v_requistion_rec.interface_source_code ,
            'VENDOR' ,
            v_requistion_rec.requisition_type ,
            v_requistion_rec.destination_type_code ,
            ln_item_id
            --   ,v_requistion_rec.item_description
            --   ,ln_category_id
            ,
            v_requistion_rec.quantity ,
            v_requistion_rec.authorization_status ,
            ln_emp_id ,
            v_requistion_rec.uom_code ,
            ln_organization_id ,
            ln_location_id ,
            ln_requestor_id ,
            ln_charge_account_id ,
            ld_need_by_date ,
            ln_org_id ,
            v_requistion_rec.unit_price ,
            'Y' ,
            ln_vendor_id ,
            ln_site_id
            --    ,lv_req_number_segment1
            --  ,v_requistion_rec.multiple_lines   -- Added column for multi lines   --'Y'
            ,
           PO_REQ_DIST_INTERFACE_S.nextval
          );
        INSERT
        INTO po_req_dist_interface_all
          (
            batch_id,
            transaction_id,
            interface_source_code,
            charge_account_id,
            distribution_number,
            dist_sequence_id,
            requisition_line_id,
            quantity
          )
          VALUES
          (
            v_requistion_rec.batch_id,
            PO_REQUISITIONS_INTERFACE_S.currval,
            v_requistion_rec.interface_source_code,
            ln_charge_account_id,
            ln_distribution_num,
            PO_REQ_DIST_INTERFACE_S.currval,
            ln_requisition_line_id,
            v_requistion_rec.quantity
          );
        lv_error_flag := 'N';
        UPDATE xx_req_po_stg
        SET ERROR_FLAG=lv_error_flag
        WHERE batch_id=v_requistion_rec.batch_id;
      ELSE
        lv_error_flag := 'E';
        retcode       :=2;
        lv_error_msg  := lv_error_msg||'Error while inserting into interface table '||SQLERRM;
        fnd_file.put_line(fnd_file.log,'Step11' ||' '||lv_error_msg||' '||SQLERRM);
        UPDATE xx_req_po_stg
        SET ERROR_FLAG=lv_error_flag,
          ERROR_MSG   =lv_error_msg
        WHERE batch_id=v_requistion_rec.batch_id;
        --  AND record_id =v_requistion_rec.record_id;
      END IF;
      COMMIT;
    END LOOP;
    SUBMIT_REQUEST (pn_batch_id,pv_int_source_code);
    --- Deleting the successfull lines lessthan two months---
    DELETE
    FROM xx_req_po_stg
    WHERE error_flag         ='N'
    AND TRUNC(creation_date)<=TRUNC(sysdate)-60;
  END MAIN;
END req_po_load_pkg;