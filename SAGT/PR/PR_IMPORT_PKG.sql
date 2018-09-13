select *
from xx_req_po_stg;

CREATE TABLE xx_req_po_stg
  (
    batch_id NUMBER -- To identify the loaded records
    ,
    requisition_type VARCHAR2(50) -- Internal or Purchase
    ,
    interface_source_code    VARCHAR2(50) ,
    destination_type_code    VARCHAR2(50) ,
    item_name                VARCHAR2(240) ,
    quantity                 NUMBER ,
    authorization_status     VARCHAR2(30) ,
    preparer_full_name       VARCHAR2(50) ,
    uom_code                 VARCHAR2(10) ,
    destination_organization VARCHAR2(50) ,
    deliver_to_location      VARCHAR2(50) ,
    deliver_to_requestor     VARCHAR2(50) ,
    cost_center              VARCHAR2(50) ,
    natural_account          VARCHAR2(50) ,
    sub_analysis_1           VARCHAR2(50) ,
    inter_company            VARCHAR2(50) ,
    need_by_date             DATE ,
    ou_name                  VARCHAR2(50) ,
    unit_price               NUMBER ,
    suggested_vendor_name    VARCHAR2(50) ,
    suggested_vendor_site    VARCHAR2(50) ,
    multiple_lines           VARCHAR2(1) ,
    line_num                 NUMBER ,
    supplier_number          NUMBER ,
    created_by               NUMBER ,
    creation_date            DATE ,
    error_flag               VARCHAR2(1) DEFAULT NULL ,
    error_msg                VARCHAR2(250) DEFAULT NULL
  );
  /
CREATE OR REPLACE PACKAGE req_po_load_pkg
IS
  PROCEDURE SUBMIT_REQUEST    (
      pn_batch_id        IN NUMBER,
      pv_int_source_code IN VARCHAR2
    );
PROCEDURE MAIN
    (
      errbuf OUT VARCHAR2,
      retcode OUT NUMBER,
      pn_batch_id        IN NUMBER,
      pv_int_source_code IN VARCHAR2
    );
END;    
/