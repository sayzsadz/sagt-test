create or replace package APEX_FUSION_INTEGRATION_PKG
as  
  G_DIRECTORY varchar2(100) := 'DFILES_PATH';
  
 -- G_DIRECTORY varchar2(100) := 'CSV_PATH';
  
  procedure CREATE_GL_JOURNAL;
  
  procedure DAILY_RATE;
  
  procedure CREATE_SUPPLIER;
  
  procedure CREATE_AP_INVOICE;
  
  procedure CREATE_EMPLOYEE;
  
  procedure GET_SUPERVISOR;
  
  
end APEX_FUSION_INTEGRATION_PKG;
/

create or replace package body APEX_FUSION_INTEGRATION_PKG
as  
  --declare private procedure
  procedure upload_gl_journal_2_fusion(p_content clob, p_group_id number);
  
  procedure upload_file_2_UCM_fusion(p_content clob, p_output out varchar2);
  
  procedure upload_daily_rates_2_fusion(p_content clob);
  
  procedure run_dailyrates_import_process(p_process_id varchar2);
  
  procedure generate_supplier_address_tag(p_supplier_seq number, p_add_tag out clob);
  
  procedure generate_supplier_site_tag(p_supplier_no varchar2, p_add_tag out clob);
  
  procedure generate_ap_inv_line_tag(p_invoice_no varchar2, p_add_tag out clob);

  procedure run_ap_inv_intereface_job;
  
  procedure CREATE_GL_JOURNAL 
  as
  
  L_FILE  UTL_FILE.FILE_TYPE;
  L_CSV_FILENAME varchar2(200) := 'journal.csv';
  L_ZIP_FILENAME varchar2(20) := 'journal';
  L_ZIP_FILE_CLOB CLOB;
  L_GROUP_ID number := 102;
  L_CUR_DATE date := sysdate;
  l_run_web_service number := 0;
  
  cursor JOURNALS(p_group_id number)
  is 
  select --rowid, 
        SOURCE_SYSTEM,
        'NEW' STATUS_CODE,
        '300000001313082' LEDGER_ID,
        TO_CHAR(GL_DATE,'YYYY/MM/DD') EFFECTIVE_DATE_TRANSACTION, 
        'Scienter' JOURNAL_SOURCE, --'Scienter' 
        trim(JOURNAL_SOURCE) JOURNAL_CATEGORY,
        trim(CURRENCY_CODE) CURRENCY_CODE,
        TO_CHAR(nvl(CREATION_DATE,sysdate),'YYYY/MM/DD') JOURNAL_ENTRY_CREATION_DATE, 
        trim(ACTUAL_FLAG) ACTUAL_FLAG,
        decode(trim(COA_COMPANY),'01','11',trim(COA_COMPANY)) SEGMENT1,
        trim(COA_BRANCH) SEGMENT2,
        trim(COA_ACCOUNT) SEGMENT3,
        DECODE(trim(COA_COST_CENTER),'0000','000') SEGMENT4,
        trim(COA_PRODUCT) SEGMENT5,
        trim(COA_LOB) SEGMENT6,
        DECODE(trim(COA_CURRENCY),'LKR','101') SEGMENT7,
        NVL(trim(COA_INTER_BRANCH),'0000') SEGMENT8,
        NVL(trim(COA_FUTURE1),'0000') SEGMENT9,
        NVL(trim(COA_FUTURE2),'000') SEGMENT10,
        null SEGMENT11,
        null SEGMENT12,
        null SEGMENT13,
        null SEGMENT14,
        null SEGMENT15,
        null SEGMENT16,
        null SEGMENT17,
        null SEGMENT18,
        null SEGMENT19,
        null SEGMENT20,
        null SEGMENT21,
        null SEGMENT22,
        null SEGMENT23,
        null SEGMENT24,
        null SEGMENT25,
        null SEGMENT26,
        null SEGMENT27,
        null SEGMENT28,
        null SEGMENT29,
        null SEGMENT30,
        ENTERED_DR ENTERED_DEBIT_AMOUNT,
        ENTERED_CR ENTERED_CREDIT_AMOUNT,
        ACCOUNTED_DR CONVERTED_DEBIT_AMOUNT,
        ACCOUNTED_CR CONVERTED_CREDIT_AMOUNT,
        trim(BATCH_HEADER_NAME) REFERENCE1 , --(Batch Name)
        trim(BATCH_HEADER_DESCRIPTION) REFERENCE2 , --(Batch Description)
        null REFERENCE3,
        --trim(JOURNAL_HEADER_NAME) REFERENCE4 , --(Journal Entry Name)
        trim(front_end_refno)  REFERENCE4 , --(Journal Entry Name)
        trim(JOURNAL_HEADER_DESCRIPTION) REFERENCE5 , --(Journal Entry Description)
        null REFERENCE6 , --(Journal Entry Reference)
        null REFERENCE7 , --(Journal Entry Reversal flag)
        null REFERENCE8 , --(Journal Entry Reversal Period)
        null REFERENCE9 , --(Journal Reversal Method)
        --JOURNAL_LINE_DESCRIPTION REFERENCE10 , --(Journal Entry Line Description)
        trim(CHEQUE_NO) REFERENCE10 , --(Journal Entry Line Description)
        
        null REFERENCE_COLUMN_1,
        null REFERENCE_COLUMN_2,
        null REFERENCE_COLUMN_3,
        null REFERENCE_COLUMN_4,
        null REFERENCE_COLUMN_5,
        null REFERENCE_COLUMN_6,
        null REFERENCE_COLUMN_7,
        null REFERENCE_COLUMN_8,
        null REFERENCE_COLUMN_9,
        null REFERENCE_COLUMN_10,
        null STATISTICAL_AMOUNT,
        trim(CURRENCY_CONVERTION_TYPE) CURRENCY_CONVERTION_TYPE,
        trim(CURRENCY_CONVERTION_DATE) CURRENCY_CONVERTION_DATE,
        trim(CURRENCY_CONVERTION_RATE) CURRENCY_CONVERTION_RATE,
        p_group_id INTERFACE_GROUP_IDENTIFIER,
        null JOURNAL_ENTRY_LINE_DFF, --'GL_JE_LINES'
        trim(TRANSATION_TYPE) ATTRIBUTE1,
        null ATTRIBUTE2,
        null ATTRIBUTE3,
        null ATTRIBUTE4,
        null ATTRIBUTE5,
        null ATTRIBUTE6,
        null ATTRIBUTE7,
        null ATTRIBUTE8,
        null ATTRIBUTE9,
        null ATTRIBUTE10,
        null ATTRIBUTE11,
        null ATTRIBUTE12,
        null ATTRIBUTE13,
        null ATTRIBUTE14,
        null ATTRIBUTE15,
        null ATTRIBUTE16,
        null ATTRIBUTE17,
        null ATTRIBUTE18,
        null ATTRIBUTE19,
        null ATTRIBUTE20,
        null CAPTURED_DFF,
        null AVERAGE_JOURNAL_FLAG,
        null CLEARING_COMPANY,
        'LBF_Ledger' LEDGER_NAME,
        null ENCUMBRANCE_TYPE_ID,
        null ADDITIONAL_INFORMATION,
        
       -- CREATION_DATE,
      --  CREATED_BY,
       -- LAST_UPDATE_DATE,
      --  LAST_UPDATED_BY,
        
        TRANSATION_TYPE,
   
        TRANSACTION_DATE,
        PERIOD_NAME,         
        FRONT_END_REFNO,
        FRONT_END_TRANNO,
        DEPOSIT_SLIP_NO,
        BANK_CODE,
        BANK_BRANCH_CODE,        
        CHEQUE_DATE,
        PAYMENT_TYPE,
        CANCELLATION
    from XX_GL_INTERFACE_INTERIM gl,
        (select REFNO
          from (
          select a.FRONT_END_REFNO REFNO, sum( a.ENTERED_DR) dr,
                 sum( a.ENTERED_CR) cr
          from XX_GL_INTERFACE_INTERIM a
          where trunc(a.CREATION_DATE) = '09-JUN-18'
          and a.STATUS = 'NEW'
          group by a.FRONT_END_REFNO)
          where dr-cr = 0) tl
    where gl.STATUS = 'NEW'
    and gl.front_end_refno = tl.REFNO;
   -- and LOG_DATE < L_CUR_DATE;   
    
    l_count number;
  begin
      --Creat or open the file
      L_FILE := UTL_FILE.FOPEN(location     => G_DIRECTORY,
                               FILENAME     => L_CSV_FILENAME,
                               OPEN_MODE    => 'w',
                               MAX_LINESIZE => 32767);
      --loop the cursor
      for REC in JOURNALS(L_GROUP_ID) LOOP
        UTL_FILE.PUT_LINE(L_FILE,
                            rec.STATUS_CODE || ',' ||
                            rec.LEDGER_ID || ',' ||
                            rec.EFFECTIVE_DATE_TRANSACTION  || ',' ||
                            rec.JOURNAL_SOURCE || ',' ||
                            rec.JOURNAL_CATEGORY || ',' ||
                            rec.CURRENCY_CODE || ',' ||
                            rec.JOURNAL_ENTRY_CREATION_DATE  || ',' ||
                            rec.ACTUAL_FLAG || ',' ||
                            rec.SEGMENT1 || ',' ||
                            rec.SEGMENT2 || ',' ||
                            rec.SEGMENT3 || ',' ||
                            rec.SEGMENT4 || ',' ||
                            rec.SEGMENT5 || ',' ||
                            rec.SEGMENT6 || ',' ||
                            rec.SEGMENT7 || ',' ||
                            rec.SEGMENT8 || ',' ||
                            rec.SEGMENT9 || ',' ||
                            rec.SEGMENT10 || ',' ||
                            rec.SEGMENT11 || ',' ||
                            rec.SEGMENT12 || ',' ||
                            rec.SEGMENT13 || ',' ||
                            rec.SEGMENT14 || ',' ||
                            rec.SEGMENT15 || ',' ||
                            rec.SEGMENT16 || ',' ||
                            rec.SEGMENT17 || ',' ||
                            rec.SEGMENT18 || ',' ||
                            rec.SEGMENT19 || ',' ||
                            rec.SEGMENT20 || ',' ||
                            rec.SEGMENT21 || ',' ||
                            rec.SEGMENT22 || ',' ||
                            rec.SEGMENT23 || ',' ||
                            rec.SEGMENT24 || ',' ||
                            rec.SEGMENT25 || ',' ||
                            rec.SEGMENT26 || ',' ||
                            rec.SEGMENT27 || ',' ||
                            rec.SEGMENT28 || ',' ||
                            rec.SEGMENT29 || ',' ||
                            rec.SEGMENT30 || ',' ||
                            rec.ENTERED_DEBIT_AMOUNT || ',' ||
                            rec.ENTERED_CREDIT_AMOUNT || ',' ||
                            rec.CONVERTED_DEBIT_AMOUNT || ',' ||
                            rec.CONVERTED_CREDIT_AMOUNT || ',' ||
                            rec.REFERENCE1  || ',' ||
                            rec.REFERENCE2  || ',' ||
                            rec.REFERENCE3 || ',' ||
                            rec.REFERENCE4  || ',' ||
                            rec.REFERENCE5  || ',' ||
                            rec.REFERENCE6  || ',' ||
                            rec.REFERENCE7  || ',' ||
                            rec.REFERENCE8  || ',' ||
                            rec.REFERENCE9  || ',' ||
                            rec.REFERENCE10  || ',' ||
                            rec.REFERENCE_COLUMN_1 || ',' ||
                            rec.REFERENCE_COLUMN_2 || ',' ||
                            rec.REFERENCE_COLUMN_3 || ',' ||
                            rec.REFERENCE_COLUMN_4 || ',' ||
                            rec.REFERENCE_COLUMN_5 || ',' ||
                            rec.REFERENCE_COLUMN_6 || ',' ||
                            rec.REFERENCE_COLUMN_7 || ',' ||
                            rec.REFERENCE_COLUMN_8 || ',' ||
                            rec.REFERENCE_COLUMN_9 || ',' ||
                            rec.REFERENCE_COLUMN_10 || ',' ||
                            rec.STATISTICAL_AMOUNT || ',' ||
                            rec.CURRENCY_CONVERTION_TYPE || ',' ||
                            rec.CURRENCY_CONVERTION_DATE || ',' ||
                            rec.CURRENCY_CONVERTION_RATE || ',' ||                           
                            rec.INTERFACE_GROUP_IDENTIFIER || ',' ||
                            rec.JOURNAL_ENTRY_LINE_DFF || ',' ||
                            rec.ATTRIBUTE1 || ',' ||
                            rec.ATTRIBUTE2 || ',' ||
                            rec.ATTRIBUTE3 || ',' ||
                            rec.ATTRIBUTE4 || ',' ||
                            rec.ATTRIBUTE5 || ',' ||
                            rec.ATTRIBUTE6 || ',' ||
                            rec.ATTRIBUTE7 || ',' ||
                            rec.ATTRIBUTE8 || ',' ||
                            rec.ATTRIBUTE9 || ',' ||
                            rec.ATTRIBUTE10 || ',' ||
                            rec.ATTRIBUTE11 || ',' ||
                            rec.ATTRIBUTE12 || ',' ||
                            rec.ATTRIBUTE13 || ',' ||
                            rec.ATTRIBUTE14 || ',' ||
                            rec.ATTRIBUTE15 || ',' ||
                            rec.ATTRIBUTE16 || ',' ||
                            rec.ATTRIBUTE17 || ',' ||
                            rec.ATTRIBUTE18 || ',' ||
                            rec.ATTRIBUTE19 || ',' ||
                            rec.ATTRIBUTE20 || ',' ||
                            rec.CAPTURED_DFF || ',' ||
                            rec.AVERAGE_JOURNAL_FLAG || ',' ||
                            rec.CLEARING_COMPANY || ',' ||
                            rec.LEDGER_NAME || ',' ||
                            rec.ENCUMBRANCE_TYPE_ID || ',' ||
                            rec.ADDITIONAL_INFORMATION || ',' ||
                            'END' --|| chr(13)||chr(10)   
                            );         
         
    
          l_run_web_service := 1;
      end LOOP;
      
       --close the file
      UTL_FILE.FCLOSE(L_FILE);
      
      if l_run_web_service = 1 
      then
      
         --mark as processed
         begin                  
            UPDATE XX_GL_INTERFACE_INTERIM 
            set STATUS = 'VAL'
            where STATUS = 'NEW' 
            and LOG_DATE <= L_CUR_DATE
            and trunc(CREATION_DATE) = '09-JUN-18';
           -- and gl_date = '01-JUN-18'
           -- and front_end_refno = 'H03000567560';
          --  and rowid = 
            
            commit;
          exception
          when others
           then null;
          end;
        
      
        
        --Create zip file
        APEX_FUSION_UTL_PKG.CREATE_ZIP_FILE(
                                              P_FILE_NAME => L_CSV_FILENAME,
                                              P_DIRECTORY => G_DIRECTORY,
                                              P_ZIP_FILE_NAME => L_ZIP_FILENAME
                                            );
        
        --Encode the file                                    
        APEX_FUSION_UTL_PKG.BASE_64_ENCODE(
                                              P_DIRECTORY => G_DIRECTORY,
                                              P_FILE_NAME => L_ZIP_FILENAME || '.zip',
                                              P_CLOB => L_ZIP_FILE_CLOB
                                            );
        
       --call upload procedure 
       upload_gl_journal_2_fusion(L_ZIP_FILE_CLOB, L_GROUP_ID);
      else 
        dbms_output.put_line('No New Data to integrate');
      end if;
  EXCEPTION 
  when OTHERS
  then
   DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
   apex_fusion_utl_pkg.log_event('GL:GL_JOURNAL:ERROR','MSG' || sqlerrm);
  end;
  
  procedure upload_gl_journal_2_fusion(p_content clob, p_group_id number)
  as
    l_url varchar2(1000);
    l_action varchar2(1000);
    l_output clob;
    l_envelope clob;
  begin
    l_url:= 'https://eivt-test.fa.ap1.oraclecloud.com/publicFinancialCommonErpIntegration/ErpIntegrationService?WSDL';
    l_action := 'http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/importBulkData';
    
      
   /* l_envelope := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/" xmlns:erp="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/">
                   <soapenv:Header/>
                   <soapenv:Body>
                      <typ:importBulkData >
                         <!--Optional:-->
                         <typ:document>
                            <!--Optional:-->
                            <erp:Content>'|| p_content ||'</erp:Content>
                            <!--Optional:-->
                            <erp:FileName>xGLJournal.zip</erp:FileName>                          
                         </typ:document>
                      <typ:jobDetails> 
                       <erp:JobName>oracle/apps/ess/financials/generalLedger/programs/common,JournalImportLauncher</erp:JobName> 
                       <erp:ParameterList>300000001313124,Scienter,300000001313082,' || p_group_id || ',N,N,O</erp:ParameterList>
                      </typ:jobDetails>                
                      <typ:notificationCode>30</typ:notificationCode>                        
                      </typ:importBulkData>
                   </soapenv:Body>
                </soapenv:Envelope>';*/
        
        select CONCAT('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/" xmlns:erp="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/">
                   <soapenv:Header/>
                   <soapenv:Body>
                      <typ:importBulkData >
                         <!--Optional:-->
                         <typ:document>
                            <!--Optional:-->
                            <erp:Content>' ,CONCAT(p_content,'</erp:Content>
                            <!--Optional:-->
                            <erp:FileName>xGLJournal.zip</erp:FileName>                          
                         </typ:document>
                      <typ:jobDetails> 
                       <erp:JobName>oracle/apps/ess/financials/generalLedger/programs/common,JournalImportLauncher</erp:JobName> 
                       <erp:ParameterList>300000001313124,Scienter,300000001313082,102,N,N,O</erp:ParameterList>
                      </typ:jobDetails>                
                      <typ:notificationCode>30</typ:notificationCode>                        
                      </typ:importBulkData>
                   </soapenv:Body>
                </soapenv:Envelope>'))
                into l_envelope
                from dual
                ;       
                
    
    --call the web service
    /*l_output := APEX_FUSION_UTL_PKG.CALL_SOAP_WEB_SERVICE(
                                                            P_ENVELOPE => l_envelope,
                                                            P_URL => l_url,
                                                            P_ACTION => l_action,
                                                            P_SOAP_VERSION => '1.1'
                                                          );*/
                                                          
     /*    l_output :=   APEX_FUSION_UTL_PKG.CALL_CHUNK_SOAP_WEB_SERVICE(p_url => l_url, 
              p_envelope => l_envelope,
              p_action => l_action,
              p_soap_version => '1.1'
              );          */                                  
        
       /*   l_output :=   PostRecClob(url => l_url, 
              request => l_envelope,
              p_action => l_action,
              p_soap_version => '1.1'
              );   */                                                          
                                                          
    dbms_output.put_line(l_output);
     
    begin
      insert into xx_xml_output (output) values (l_output);
      commit;
    exception when others
    then null;
    end;
  end;
  
  
  procedure DAILY_RATE 
  as  
    L_FILE  UTL_FILE.FILE_TYPE;
    L_CSV_FILENAME varchar2(200) := 'dailyrates.csv';
    L_ZIP_FILENAME varchar2(20) := 'dailyrates';
    L_ZIP_FILE_CLOB CLOB;
    L_GROUP_ID number := 9999;
    L_CUR_DATE date := sysdate;
    
    cursor rates
    is
    SELECT  SOURCE_SYSTEM,
            STATUS,
            LEDGER_ID,
            CREATION_DATE,
            CREATED_BY,
            LAST_UPDATE_DATE,
            LAST_UPDATED_BY,
            BUSINESS_UNIT,
            FROM_CURRENCY,
            TO_CURRENCY,
            EXCHANGE_RATE,
            EXCHANGE_RATE_DATE,
            FRONT_END_REFERENCE
    FROM XX_EXCHANGE_RATE_INTERIM 
    where log_date < L_CUR_DATE;
  begin
    
     --Creat or open the file
      L_FILE := UTL_FILE.FOPEN(location     => G_DIRECTORY,
                               FILENAME     => L_CSV_FILENAME,
                               OPEN_MODE    => 'w',
                               MAX_LINESIZE => 32767);
      --loop the cursor
      for REC in rates LOOP
        UTL_FILE.PUT_LINE(L_FILE,
                            rec.FROM_CURRENCY || ',' ||
                            rec.TO_CURRENCY || ',' ||
                            to_char(rec.EXCHANGE_RATE_DATE,'YYYY/MM/DD')  || ',' ||
                            to_char(rec.EXCHANGE_RATE_DATE,'YYYY/MM/DD')  || ',' ||
                            'Corporate' || ',' ||
                            rec.EXCHANGE_RATE || ',' ||
                            round(to_number(1/rec.EXCHANGE_RATE),5)  || ',' ||
                            chr(13)||chr(10)   
                            );         
         
          
      end LOOP;
      
       --mark as processed
       begin                  
          UPDATE XX_EXCHANGE_RATE_INTERIM 
          set STATUS = 'VAL'
          where STATUS = 'NEW' 
          and LOG_DATE < L_CUR_DATE;
          
          commit;
        exception
        when others
         then null;
        end;
      
      --close the file
      UTL_FILE.FCLOSE(L_FILE);
      
      --Create zip file
      APEX_FUSION_UTL_PKG.CREATE_ZIP_FILE(
                                            P_FILE_NAME => L_CSV_FILENAME,
                                            P_DIRECTORY => G_DIRECTORY,
                                            P_ZIP_FILE_NAME => L_ZIP_FILENAME
                                          );
      
      --Encode the file                                    
      APEX_FUSION_UTL_PKG.BASE_64_ENCODE(
                                            P_DIRECTORY => G_DIRECTORY,
                                            P_FILE_NAME => L_ZIP_FILENAME || '.zip',
                                            P_CLOB => L_ZIP_FILE_CLOB
                                          );
                                          
      DBMS_OUTPUT.PUT_LINE(L_ZIP_FILE_CLOB);
      
      upload_daily_rates_2_fusion(p_content => L_ZIP_FILE_CLOB);
    
  end;
 
  
  procedure upload_daily_rates_2_fusion(p_content clob)
  as
    l_url varchar2(1000);
    l_action varchar2(1000);
    l_output clob;
    l_envelope clob;
    l_process_id varchar2(100);
  begin
    --upload file to fusion
    upload_file_2_UCM_fusion(p_content => p_content, p_output => l_process_id);
    --run import program
    if l_process_id is not null then
      run_dailyrates_import_process(p_process_id => l_process_id);
      
    end if;
    dbms_output.put_line(l_process_id);
    
 
  end;
  

  procedure upload_file_2_UCM_fusion(p_content clob , p_output out varchar2)
  as
    l_url varchar2(1000);
    l_action varchar2(1000);
    l_output clob;
    l_envelope clob;
  begin
    l_url:= 'https://eivt-test.fa.ap1.oraclecloud.com/publicFinancialCommonErpIntegration/ErpIntegrationService?WSDL';
    l_action := 'http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/uploadFileToUcm';
    
    l_envelope := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/" xmlns:erp="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/">
                   <soapenv:Header/>
                   <soapenv:Body>
                      <typ:uploadFileToUcm>
                         <typ:document>
                            <erp:Content>' || p_content || '</erp:Content>
                            <erp:FileName>dailyrates.zip</erp:FileName>
                            <erp:ContentType>zip</erp:ContentType>
                
                            <erp:DocumentSecurityGroup>FAFusionImportExport</erp:DocumentSecurityGroup>
                            <erp:DocumentAccount>fin/generalLedger/import</erp:DocumentAccount>
                         </typ:document>
                      </typ:uploadFileToUcm>
                   </soapenv:Body>
                </soapenv:Envelope>';
    
    --call the web service
    l_output := APEX_FUSION_UTL_PKG.CALL_SOAP_WEB_SERVICE(
                                                            P_ENVELOPE => l_envelope,
                                                            P_URL => l_url,
                                                            P_ACTION => l_action,
                                                            P_SOAP_VERSION => '1.1'
                                                          );
    dbms_output.put_line(l_output);
    
    begin    
      
      insert into xx_xml_output (output) values (l_output);
      --commit;
    exception when others
    then null;
    end;
    
    begin
    
     select xmltype(substr(substr(output,INSTR(output, '<?xml')),0, INSTR(substr(output,INSTR(output, '<?xml')), '------=') - 1)).extract('//result/text()',
                          'xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"  xmlns:wsa="http://www.w3.org/2005/08/addressing"> '||
                          'xmlns:ns0="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/ ' || 
                          'xmlns="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/"'
                          ).getStringVal()
      into p_output
      from XX_XML_OUTPUT;
      
      commit;
    exception when others
    then p_output := null;
    end;
    
  exception when others
  then 
    dbms_output.put_line(sqlerrm);
  end;
  

  procedure run_dailyrates_import_process(p_process_id varchar2)
  as
    l_url varchar2(1000);
    l_action varchar2(1000);
    l_output clob;
    l_envelope clob;
  begin

    l_url:= 'https://eivt-test.fa.ap1.oraclecloud.com/publicFinancialCommonErpIntegration/ErpIntegrationService?WSDL';
    l_action := 'http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/submitESSJobRequest';
    
    l_envelope := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/">
                   <soapenv:Header/>
                   <soapenv:Body>
                      <typ:submitESSJobRequest>
                         <typ:jobPackageName>/oracle/apps/ess/financials/commonModules/shared/common/interfaceLoader</typ:jobPackageName>
                         <typ:jobDefinitionName>InterfaceLoaderController</typ:jobDefinitionName>
                         <typ:paramList>71</typ:paramList>
                         <typ:paramList>' || p_process_id || '</typ:paramList>
                         <typ:paramList>N</typ:paramList>
                         <typ:paramList>N</typ:paramList>
                      </typ:submitESSJobRequest>
                   </soapenv:Body>
                </soapenv:Envelope>';
    
    --call the web service
    l_output := APEX_FUSION_UTL_PKG.CALL_SOAP_WEB_SERVICE(
                                                            P_ENVELOPE => l_envelope,
                                                            P_URL => l_url,
                                                            P_ACTION => l_action,
                                                            P_SOAP_VERSION => '1.1'
                                                          );
    dbms_output.put_line(l_output);
    
  end;
  
  procedure CREATE_SUPPLIER
  as
  
  L_CUR_DATE date := sysdate;
  l_url varchar2(1000);
  l_action varchar2(1000);
  l_output clob;
  l_envelope clob;
  
  cursor supplier
  is 
  SELECT seq,
          supplier_name,
          supplier_number,
          decode(organization_type,'Organization','Corporation',organization_type) tax_organization_type,
          industry supplier_type,
          
          tax_payer_country,
          tin_number Tax_payer_Id,
          decode(wht_applicable,'Y','true','false') Use_Withholding_Tax_Flag,
          business_reg_no alias,
          
          contact_last_name last_name,
          phone_no phone,
          fax_no fax,
          
          related_party,
          nbt_number nbt_registration_number,
          vat_rate          
         -- tax_registration_number,
          
         -- nature_of_payment
          
    FROM XX_SUPPLIER_INTERFACE_INTERIM 
    WHERE STATUS = 'NEW' and seq =21;
   -- group by SUPPLIER_NAME,SUPPLIER_NUMBER;   
    
    l_address_tag clob;
    l_site_tag clob;
  
  begin
     
    l_url:= 'https://eivt-test.fa.ap1.oraclecloud.com/fscmService/SupplierServiceV2?WSDL';
    l_action := 'http://xmlns.oracle.com/apps/prc/poz/suppliers/supplierServiceV2/createSupplier';
    
    
    for rec in supplier
    loop
        --get address tag
        generate_supplier_address_tag(p_supplier_seq => rec.seq, p_add_tag => l_address_tag);
        
      --  dbms_output.put_line(l_address_tag);
        
        --get site tag
      --  generate_supplier_site_tag(p_supplier_no => rec.SUPPLIER_NUMBER, p_add_tag => l_site_tag);
        
        --dbms_output.put_line(l_site_tag);
        
        l_envelope := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/prc/poz/suppliers/supplierServiceV2/types/" xmlns:sup="http://xmlns.oracle.com/apps/prc/poz/suppliers/supplierServiceV2/" xmlns:sup1="http://xmlns.oracle.com/apps/flex/prc/poz/suppliers/supplierServiceV2/supplierSites/" xmlns:sup2="http://xmlns.oracle.com/apps/flex/prc/poz/suppliers/supplierServiceV2/supplierAddress/" xmlns:sup3="http://xmlns.oracle.com/apps/flex/prc/poz/suppliers/supplierServiceV2/supplier/" xmlns:sup4="http://xmlns.oracle.com/apps/flex/prc/poz/suppliers/supplierServiceV2/supplierContact/">
                       <soapenv:Header/>
                       <soapenv:Body>
                          <typ:createSupplier>
                             <typ:supplierRow>
                                <!--Mandatory:-->
                                <sup:Supplier>' || rec.SUPPLIER_NAME || '</sup:Supplier>
                                <sup:SupplierNumber>' || rec.SUPPLIER_NUMBER || '</sup:SupplierNumber>
                                <!--Mandatory:-->
                                <sup:TaxOrganizationType>' || rec.tax_organization_type || '</sup:TaxOrganizationType>
                                <!--Mandatory:-->
                                <sup:SupplierType>' || rec.supplier_type || '</sup:SupplierType>
                                <sup:TaxPayerCountry>' || rec.tax_payer_country || '</sup:TaxPayerCountry>
                                <sup:TaxpayerId>' || rec.Tax_payer_Id || '</sup:TaxpayerId>
                                <sup:UseWithholdingTaxFlag>' || rec.Use_Withholding_Tax_Flag || '</sup:UseWithholdingTaxFlag>
                                <sup:Alias>' || rec.alias || '</sup:Alias>
                                
                                <sup:SupplierFlexField xmlns:ns3="http://xmlns.oracle.com/apps/flex/prc/poz/suppliers/supplierServiceV2/supplier/">
                                  <ns3:relatedParty>' || rec.related_party || '</ns3:relatedParty>
                                  <ns3:nbtRegistrationNumber>' || rec.nbt_registration_number || '</ns3:nbtRegistrationNumber>
                                  <ns3:vatRate>' || rec.vat_rate ||'</ns3:vatRate>		
                                </sup:SupplierFlexField>
                                
                                <sup:SupplierContacts>
                                 <sup:Operation>Create</sup:Operation>     
                                 <sup:FirstName>' || rec.last_name || '</sup:FirstName>
                                 <sup:LastName>' || rec.last_name || '</sup:LastName>
                                 <sup:Phone>' || rec.phone || '</sup:Phone>
                                 <sup:Fax>' || rec.fax || '</sup:Fax>
                                </sup:SupplierContacts>
                                
                                <!--Mandatory:-->
                                <sup:BusinessRelationship>PROSPECTIVE</sup:BusinessRelationship> 
                                '
                                || l_address_tag 
                                --|| l_site_tag 
                                ||
                             '
                             </typ:supplierRow>
                          </typ:createSupplier>
                       </soapenv:Body>
                    </soapenv:Envelope>'; --PROSPECTIVE/SPEND_AUTHORIZED
        
        dbms_output.put_line(l_envelope);
        
        --call the web service
        l_output := APEX_FUSION_UTL_PKG.CALL_SOAP_WEB_SERVICE(
                                                                P_ENVELOPE => l_envelope,
                                                                P_URL => l_url,
                                                                P_ACTION => l_action,
                                                                P_SOAP_VERSION => '1.1'
                                                              );
        dbms_output.put_line(l_output);
        
      end loop;
      
      
   
  EXCEPTION 
  when OTHERS
  then
   DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
   apex_fusion_utl_pkg.log_event('AP:CREATE_SUPPLIER:ERROR','MSG' || sqlerrm);
  end;
  
  procedure generate_supplier_address_tag(p_supplier_seq number, p_add_tag out clob)
  as
    cursor address
    is 
    SELECT  SUPPLIER_NUMBER,
            trim(ADDRESS_SITE_NAME) ADDRESS_SITE_NAME,
            decode(upper(trim(COUNTRY)),'SRI LANKA','LK') COUNTRY, --Must change
            trim(ADDRESS_LINE1) ADDRESS_LINE1,
            trim(ADDRESS_LINE2) ADDRESS_LINE2,
            trim(ADDRESS_LINE3) ADDRESS_LINE3,
            trim(CITY) CITY
    FROM XX_SUPPLIER_INTERFACE_INTERIM 
    WHERE seq = p_supplier_seq;  
    
    l_add_status varchar2(1) := 'I'; --should be I - Insert, U - Update
    
  begin
    
    for adr in address
    loop
      if l_add_status = 'I' then
        p_add_tag := p_add_tag || 
                         ' <sup:SupplierAddresses>
                           <sup:Operation>Create</sup:Operation>
                           <sup:AddressName>' || nvl(adr.ADDRESS_SITE_NAME,'Address1') ||'</sup:AddressName>                         
                           <sup:Country>' || adr.COUNTRY  ||'</sup:Country>                           
                           <sup:AddressLine1>' || adr.ADDRESS_LINE1  ||'</sup:AddressLine1>                           
                           <sup:AddressLine2>' || adr.ADDRESS_LINE2  ||'</sup:AddressLine2>                           
                           <sup:AddressLine3>' || adr.ADDRESS_LINE3  ||'</sup:AddressLine3>                           
                           <sup:City>' || adr.CITY  ||'</sup:City>                           
                           <sup:OrderingPurposeFlag>True</sup:OrderingPurposeFlag>                           
                           <sup:RemitToPurposeFlag>True</sup:RemitToPurposeFlag>                           
                           <sup:RFQOrBiddingPurposeFlag>True</sup:RFQOrBiddingPurposeFlag>
                       
                           <!--Optional:
                           <sup:Phone>033-123456</sup:Phone>
                           <sup:Fax>033-234567</sup:Fax>
                           <sup:EmailAddress>abc@cde.com</sup:EmailAddress> -->
                           
                        </sup:SupplierAddresses>';
      else
        p_add_tag := p_add_tag || 
                         ' <sup:SupplierAddresses>
                           <sup:Operation>Update</sup:Operation>
                           <sup:AddressName>' || adr.ADDRESS_SITE_NAME ||'</sup:AddressName>
                         
                           <sup:Country>' || adr.COUNTRY  ||'</sup:Country>
                           
                           <sup:AddressLine1>' || adr.ADDRESS_LINE1  ||'</sup:AddressLine1>
                           
                           <sup:AddressLine2>' || adr.ADDRESS_LINE2  ||'</sup:AddressLine2>
                           
                           <sup:AddressLine3>' || adr.ADDRESS_LINE3  ||'</sup:AddressLine3>
                           
                           <sup:City>' || adr.CITY  ||'</sup:City>
                           
                           <sup:OrderingPurposeFlag>True</sup:OrderingPurposeFlag>
                           
                           <sup:RemitToPurposeFlag>True</sup:RemitToPurposeFlag>
                           
                           <sup:RFQOrBiddingPurposeFlag>True</sup:RFQOrBiddingPurposeFlag>
                       
                           <!--Optional:
                           <sup:Phone>033-123456</sup:Phone>
                           <sup:Fax>033-234567</sup:Fax>
                           <sup:EmailAddress>abc@cde.com</sup:EmailAddress> -->
                           
                        </sup:SupplierAddresses>';
      end if;
    
    end loop;
  end;
  
  
  procedure generate_supplier_site_tag(p_supplier_no varchar2, p_add_tag out clob)
  as
    cursor site
    is 
    SELECT  SUPPLIER_NUMBER,
            trim(ADDRESS_SITE_NAME) ADDRESS_SITE_NAME
    FROM XX_SUPPLIER_INTERFACE_INTERIM 
    WHERE SUPPLIER_NUMBER = p_supplier_no;  
    
    l_add_status varchar2(1) := 'I'; --should be I - Insert, U - Update
    
  begin
    
    for site_rec in site
    loop
      if l_add_status = 'I' then
        p_add_tag := p_add_tag || 
                         ' <sup:SupplierSites>
              
                             <sup:Operation>Create</sup:Operation>
                            
                             <sup:SiteName>' || site_rec.ADDRESS_SITE_NAME ||'</sup:SiteName>
                            
                             <sup:AddressName>' || site_rec.ADDRESS_SITE_NAME ||'</sup:AddressName>
                            
                             <sup:ProcurementBU>LB Finance Head Office BU</sup:ProcurementBU>
                           
                             <sup:SourcingOnlyPurposeFlag>False</sup:SourcingOnlyPurposeFlag>
                       
                             <sup:PurchasingPurposeFlag>True</sup:PurchasingPurposeFlag>
                            
                             <sup:ProcurementCardPurposeFlag>False</sup:ProcurementCardPurposeFlag>
                          
                             <sup:PayPurposeFlag>False</sup:PayPurposeFlag>
                          
                          </sup:SupplierSites> ';
      else
        p_add_tag := p_add_tag || 
                         ' <sup:SupplierSites>
              
                             <sup:Operation>Update</sup:Operation>
                            
                             <sup:SiteName>' || site_rec.ADDRESS_SITE_NAME ||'</sup:SiteName>
                            
                             <sup:AddressName>' || site_rec.ADDRESS_SITE_NAME ||'</sup:AddressName>
                            
                             <sup:ProcurementBU>LB Finance Head Office BU</sup:ProcurementBU>
                           
                             <sup:SourcingOnlyPurposeFlag>False</sup:SourcingOnlyPurposeFlag>
                       
                             <sup:PurchasingPurposeFlag>True</sup:PurchasingPurposeFlag>
                            
                             <sup:ProcurementCardPurposeFlag>False</sup:ProcurementCardPurposeFlag>
                          
                             <sup:PayPurposeFlag>False</sup:PayPurposeFlag>
                          
                          </sup:SupplierSites> ';
      end if;
    
    end loop;
  end;
  
  
  procedure CREATE_AP_INVOICE
  as
  
  L_CUR_DATE date := sysdate;
  l_url varchar2(1000);
  l_action varchar2(1000);
  l_output clob;
  l_envelope clob;
  
  cursor ap_invoice
  is 
  SELECT --SOURCE_SYSTEM,
         -- STATUS,
         -- LEDGER_ID,
        --  BUSINESS_UNIT,
        --  AP_INVOICE_ID,
          AP_INVOICE_NUMBER,
          INVOICE_TYPE,
          CURRENCY,
          AP_INVOICE_AMT_WITH_TAX,
          AP_TOTAL_TAX_AMT,
         -- LEASE_NUMBER,
         -- LEASE_DESCRIPTION,
         -- COMMENTS,
          SUPPLIER_NAME,
          SUPPLIER_NUMBER,
          ADDRESS_SITE_NAME,
          INVOICE_DATE,
        --  GL_DATE,
          CURRENCY_CODE,
         -- CURRENCY_CONVERTION_DATE,
         -- CURRENCY_CONVERTION_RATE,
         -- CURRENCY_CONVERTION_TYPE,
          PAYMENT_TERM--,
       --   LINE_NUMBER,
      --    RELATED_LINE_NUM,
      --    LINE_TYPE,
      --    TAX_CODE,
       --   TAX_RATE,
      --    LINE_DESCRIPTION,
      --    ACCOUNT_CODE,
       --   LINE_AMOUNT,
       --   FRONT_END_REFERENCE
    FROM XX_AP_INVOICE_INTERIM 
    WHERE STATUS = 'NEW'
    group by AP_INVOICE_NUMBER,INVOICE_TYPE,CURRENCY,AP_INVOICE_AMT_WITH_TAX,AP_TOTAL_TAX_AMT,SUPPLIER_NAME,SUPPLIER_NUMBER,ADDRESS_SITE_NAME,INVOICE_DATE,CURRENCY_CODE,PAYMENT_TERM;   
    
    l_line_tag clob;
  
  begin
     
    l_url:= 'https://eivt-test.fa.ap1.oraclecloud.com/fscmService/InvoiceInterfaceService?WSDL';
    l_action := 'http://xmlns.oracle.com/apps/financials/payables/invoices/quickInvoices/invoiceInterfaceService/createInvoiceInterface';
    
    
    for rec in ap_invoice
    loop
             
        --get invoice line tag
        generate_ap_inv_line_tag(p_invoice_no => rec.AP_INVOICE_NUMBER, p_add_tag => l_line_tag);
        
        --dbms_output.put_line(l_site_tag);
        
        l_envelope := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/payables/invoices/quickInvoices/invoiceInterfaceService/types/" xmlns:inv="http://xmlns.oracle.com/apps/financials/payables/invoices/quickInvoices/invoiceInterfaceService/">
                       <soapenv:Header/>
                       <soapenv:Body>
                          <typ:createInvoiceInterface>
                             <typ:invoiceInterfaceHeader>
                                <inv:Source>ELECTRONIC INVOICE</inv:Source>
                                <inv:InvoiceNumber>'|| rec.AP_INVOICE_NUMBER ||'</inv:InvoiceNumber>
                                <inv:VendorName>'|| rec.SUPPLIER_NAME ||'</inv:VendorName>
                                <inv:VendorSiteCode>'|| rec.ADDRESS_SITE_NAME ||'</inv:VendorSiteCode>
                                <inv:Description>Web Service</inv:Description>
                                <inv:InvoiceAmount currencyCode="'|| rec.CURRENCY ||'">'|| rec.AP_INVOICE_AMT_WITH_TAX ||'</inv:InvoiceAmount>
                                <inv:InvoiceCurrencyCode>'|| rec.CURRENCY ||'</inv:InvoiceCurrencyCode>
                                <inv:InvoiceDate>' || to_char(rec.INVOICE_DATE,'YYYY-MM-DD')  ||'</inv:InvoiceDate>
                                
                                <inv:InvoiceTypeLookupCode>' || rec.INVOICE_TYPE ||'</inv:InvoiceTypeLookupCode>
                                <inv:LegalEntityId>300000001283110</inv:LegalEntityId>  
                                <inv:LegalEntityName>LB Finance PLC</inv:LegalEntityName> 
                                
                                <inv:TermsDate>'|| to_char(sysdate,'YYYY-MM-DD') ||'</inv:TermsDate>                               
                                <inv:TermsName>' || rec.PAYMENT_TERM ||'</inv:TermsName>
                                <inv:OrgId>300000001283210</inv:OrgId> <!--BU-->
                                <inv:GroupId>99</inv:GroupId> 
                                <inv:PaymentMethodCode>CHECK</inv:PaymentMethodCode> 
                    
                                <!--Mandatory Additional Info-->
                                <inv:AttributeCategory>Branch and Project Name</inv:AttributeCategory>
                                <inv:Attribute3>Admin</inv:Attribute3> 
                                '
                                || l_line_tag 
                                ||
                             '
                             </typ:invoiceInterfaceHeader>
                            </typ:createInvoiceInterface>
                         </soapenv:Body>
                      </soapenv:Envelope>';
        
        dbms_output.put_line(l_envelope);
        
        --call the web service
       /* l_output := APEX_FUSION_UTL_PKG.CALL_SOAP_WEB_SERVICE(
                                                                P_ENVELOPE => l_envelope,
                                                                P_URL => l_url,
                                                                P_ACTION => l_action,
                                                                P_SOAP_VERSION => '1.1'
                                                              );*/
        dbms_output.put_line(l_output);
        
      end loop;
      
      --run ap invoice interface program
      run_ap_inv_intereface_job;
   
  EXCEPTION 
  when OTHERS
  then
   DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
   apex_fusion_utl_pkg.log_event('AP:CREATE_AP_INVOICE:ERROR','MSG' || sqlerrm);
  end;
  
  
  procedure generate_ap_inv_line_tag(p_invoice_no varchar2, p_add_tag out clob)
  as
    cursor inv_lines
    is 
     SELECT 
          CURRENCY,
          LINE_AMOUNT,
          LINE_DESCRIPTION,
          --LINE_TYPE,
          LINE_NUMBER,
          GL_DATE
      FROM XX_AP_INVOICE_INTERIM 
      WHERE STATUS = 'NEW'
      and AP_INVOICE_NUMBER = p_invoice_no;  
    
    l_add_status varchar2(1) := 'I'; --should be I - Insert, U - Update
    
  begin
    
    p_add_tag := null;
    
    for rec in inv_lines
    loop
     -- if l_add_status = 'I' then
        p_add_tag := p_add_tag || 
                         '  <inv:InvoiceInterfaceLine>
                              <inv:InvoiceId></inv:InvoiceId>
                              <inv:Amount currencyCode="'|| rec.CURRENCY ||'">'|| rec.LINE_AMOUNT ||'</inv:Amount>
                              <inv:LineTypeLookupCode>ITEM</inv:LineTypeLookupCode>      
                              <inv:Description>' || rec.LINE_DESCRIPTION || '</inv:Description>
                              <inv:LineNumber>'|| rec.LINE_NUMBER ||'</inv:LineNumber>
                              <inv:InvoiceLineId></inv:InvoiceLineId> 
                              <inv:DistCodeConcatenated></inv:DistCodeConcatenated>
                              <!--<inv:DefaultDistCcid>300000001273848</inv:DefaultDistCcid>
                              <inv:DistCodeCombinationId>300000001273848</inv:DistCodeCombinationId> -->
                              <inv:OrgId>300000001283210</inv:OrgId>
                              <inv:AccountingDate>' || to_char(rec.GL_DATE,'YYYY-MM-DD') ||'</inv:AccountingDate>
                            </inv:InvoiceInterfaceLine> 
                          ';
     -- else
     --  null
    -- end if;
    
    end loop;
  end;
  
  procedure run_ap_inv_intereface_job
  as
    l_url varchar2(1000);
    l_action varchar2(1000);
    l_output clob;
    l_envelope clob;
  begin

    l_url:= 'https://eivt-test.fa.ap1.oraclecloud.com/publicFinancialCommonErpIntegration/ErpIntegrationService?WSDL';
    l_action := 'http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/submitESSJobRequest';
    
    l_envelope := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://xmlns.oracle.com/apps/financials/commonModules/shared/model/erpIntegrationService/types/">
                   <soapenv:Header/>
                   <soapenv:Body>
                      <typ:submitESSJobRequest>
                         <typ:jobPackageName>/oracle/apps/ess/financials/payables/invoices/transactions</typ:jobPackageName>
                         <typ:jobDefinitionName>APXIIMPT</typ:jobDefinitionName>
                         <typ:paramList>?</typ:paramList>
                         <typ:paramList>300000001283210</typ:paramList> <!--legal entity CHN-->
                         <typ:paramList>N</typ:paramList>
                         <typ:paramList>?</typ:paramList>
                         <typ:paramList>?</typ:paramList>
                         <typ:paramList>?</typ:paramList>
                         <typ:paramList>1000</typ:paramList>  <!--CHN-->
                         <typ:paramList>ELECTRONIC INVOICE</typ:paramList>
                         <typ:paramList>?</typ:paramList>
                         <typ:paramList>N</typ:paramList>
                         <typ:paramList>N</typ:paramList>
                         <typ:paramList>300000001313082</typ:paramList>  <!--CHN-->
                         <typ:paramList>?</typ:paramList>
                         <typ:paramList>1</typ:paramList>
                      </typ:submitESSJobRequest>
                   </soapenv:Body>
                </soapenv:Envelope>';
    
    --call the web service
    l_output := APEX_FUSION_UTL_PKG.CALL_SOAP_WEB_SERVICE(
                                                            P_ENVELOPE => l_envelope,
                                                            P_URL => l_url,
                                                            P_ACTION => l_action,
                                                            P_SOAP_VERSION => '1.1'
                                                          );
                                          
    dbms_output.put_line(l_output);
    
  end;

  procedure CREATE_EMPLOYEE
  as
  
  L_CUR_DATE date := sysdate;
  l_url varchar2(1000);
  l_action varchar2(1000);
  l_output clob;
  l_envelope clob;
  L_status varchar(2);
  l_person_id varchar2(100);
  l_assignment_id  varchar2(100);
  
  cursor employee
  is 
  SELECT  emp.SEQ,
          emp.FIRST_NAME ,
          emp.MIDDLE_NAME  ,
          emp.LAST_NAME  ,
          emp.EMAIL_ADDRESS  ,
          emp.LOCATION  ,
          emp.DEPARTMENT  ,
          emp.MANAGER_FIRST_NAME,
          emp.MANAGER_LAST_NAME,
          substr(emp.EMAIL_ADDRESS,0,instr(emp.EMAIL_ADDRESS,'@')-1) USER_NAME,
          SUP.PERSON_ID MANAGER_ID,
          SUP.ASSIGNMENT_ID MANAGER_ASSI_ID,
          loc.location_id,
          dep.organization_id department_id
    FROM XX_EMP_INTERFACE_INTERIM emp
          ,(select MAX(location_id) location_id, upper(trim(location_name)) location_name
            from XX_HR_LOCATION_MAP
            group by upper(trim(location_name))) loc
          , (select ORGANIZATION_ID, upper(trim(DEPARTMENT_NAME)) DEPARTMENT_NAME
             from XX_HR_DEPARTMET_MAP) DEP
          , ( select upper(trim(LAST_NAME)) || '~' || upper(trim(FIRST_NAME)) full_NAME, PERSON_ID, ASSIGNMENT_ID
              from XX_HR_SUPERVISOR_MAP
              ) sup
    WHERE 1=1
    and emp.STATUS = 'NEW'
    and upper(emp.LOCATION) = loc.LOCATION_NAME(+)
    and upper(emp.DEPARTMENT) = DEP.DEPARTMENT_NAME(+)
    AND upper(trim(EMP.MANAGER_LAST_NAME)) || '~' || upper(trim(EMP.MANAGER_FIRST_NAME)) = SUP.FULL_NAME(+)
    AND SUP.PERSON_ID IS NOT NULL
    AND EMP.SEQ < 12
    and emp.EMAIL_ADDRESS is not null
    order by emp.seq;
  
  begin
     
    l_url:= 'https://eivt-test.fa.ap1.oraclecloud.com/hcmRestApi/resources/latest/emps';
    
    
    for rec in employee
    loop
             
               
        l_envelope := '{ 
                        "LastName": "' || rec.LAST_NAME || '", 
                        "FirstName": "' || rec.FIRST_NAME || '", 
                        "WorkEmail" : "' || rec.EMAIL_ADDRESS || '", 
                        "UserName": "' || rec.USER_NAME || '", 
                        "LegalEntityId" : "300000001248489", 
                        "assignments" : 
                            [ { 
                                "BusinessUnitId" : "300000001283210",
                                "ManagerId" : "' || rec.MANAGER_ID || '",
                                "ManagerAssignmentId" : "' || rec.MANAGER_ASSI_ID || '",
                                "DepartmentId" : "' || rec.department_id || '",
                                "LocationId" : "' || rec.location_id || '"
                                
                                }] 
                        }';
        
        dbms_output.put_line(l_envelope);
        
        --call the web service
        l_output := APEX_FUSION_UTL_PKG.CALL_REST_API_SERVICE(
                                                                P_ENVELOPE => l_envelope,
                                                                P_URL => l_url,
                                                               -- P_ACTION => l_action,
                                                                P_SOAP_VERSION => '1.1'
                                                              );
        dbms_output.put_line(l_output);
        
        if l_output is null or l_output not like '{%'
        then 
           L_status := 'E';
           dbms_output.put_line('E');
           l_person_id := null;
           l_assignment_id :=null;
        else
          L_status := 'S';
          
          begin
            select substr(substr(l_output,instr(l_output,'"PersonId" : ') + length('"PersonId" : ')),
                          0,
                          instr(substr(l_output,instr(l_output,'"PersonId" : ') + length('"PersonId" : ')),',') -1) person_id,
                    substr(substr(l_output,instr(l_output,'"AssignmentId" : ') + length('"AssignmentId" : ')),
                          0,
                          instr(substr(l_output,instr(l_output,'"AssignmentId" : ') + length('"AssignmentId" : ')),',') -1) assignment_id
            into l_person_id,l_assignment_id
            from dual;
          exception
          when others then
            l_person_id := null;
            l_assignment_id :=null;
          end;
          
         dbms_output.put_line('S');
        end if;
        
        begin 
         
         update XX_EMP_INTERFACE_INTERIM
         set status = L_status, ERROR_MSG = l_output , person_id = l_person_id, assignment_id = l_assignment_id
         where SEQ = REC.SEQ;
         
         if L_status = 'S' then
          insert into XX_HR_SUPERVISOR_MAP (FIRST_NAME,LAST_NAME,PERSON_ID,assignment_id) values (rec.FIRST_NAME,rec.LAST_NAME,l_person_id,l_assignment_id);
         end if;
         
         COMMIT;
        exception 
        when others 
        then dbms_output.put_line(SQLERRM);
        end;
        
      end loop;
     
   
  EXCEPTION 
  when OTHERS
  then
   DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
   apex_fusion_utl_pkg.log_event('AP:CREATE_EMPLOYEE:ERROR','MSG' || sqlerrm);
  end;
  

  procedure GET_SUPERVISOR
  as
  
  L_CUR_DATE date := sysdate;
  l_url varchar2(1000);
  l_action varchar2(1000);
  l_output clob;
  l_encode clob;
  l_decode clob;
  l_envelope clob;
  L_status varchar(2);
  
  
  begin
     
    l_envelope:= '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:pub="http://xmlns.oracle.com/oxp/service/PublicReportService">
                   <soap:Header/>
                   <soap:Body>
                      <pub:runReport>
                         <pub:reportRequest>
                           
                            <pub:parameterNameValues>
                               <!--Zero or more repetitions:-->
                               <pub:item>
                                  
                             <!--     <pub:name>P_TRX_NO</pub:name>
                                 
                                  <pub:values>
                                     
                                     <pub:item>11001</pub:item>
                                  </pub:values>-->
                               </pub:item>
                            </pub:parameterNameValues>
                            <pub:attributeFormat>xml</pub:attributeFormat>
                            <pub:reportAbsolutePath>/Custom/Amila/Validations/HR_EMPLOYEE_RPT.xdo</pub:reportAbsolutePath>
                            <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
                         </pub:reportRequest>
                         <pub:appParams>?</pub:appParams>
                      </pub:runReport>
                   </soap:Body>
                </soap:Envelope>';
    
    
   
        
        --call the web service
        APEX_FUSION_UTL_PKG.RUN_OTBI_REPORT(
                                                             p_soap_envelop => l_envelope,
                                                             p_output => l_output
                                                              );
      --  dbms_output.put_line(l_output);
        
      insert into xx_xml_supervisor (output) values (l_output);
        
      select  substr(
              substr(output, INSTR(output, '<ns2:reportBytes>')+length('<ns2:reportBytes>'))
              ,0
              ,instr(substr(output, INSTR(output, '<ns2:reportBytes>')+length('<ns2:reportBytes>')),'</ns2:reportBytes>') - 1
              ) 
      into l_encode
      from xx_xml_supervisor;
      
      dbms_output.put_line(l_encode);
        
          APEX_FUSION_UTL_PKG.base_64_Decode (
                            p_encoded_clob => l_encode,
                              p_decoded_clob => l_decode
                          );
        
      insert into xx_xml_supervisor (decoded) values (l_decode); 
        
        
      /*  if l_output is null or l_output not like '{%'
        then 
          L_status := 'E';
           dbms_output.put_line('E');
        else
          L_status := 'S';
         dbms_output.put_line('S');
        end if;
        
        begin 
          
         update XX_EMP_INTERFACE_INTERIM
         set status = L_status, ERROR_MSG = l_output
         where SEQ = REC.SEQ;
         
         COMMIT;
        exception 
        when others 
        then dbms_output.put_line(SQLERRM);
        end;
        
      end loop;*/
     
   
  EXCEPTION 
  when OTHERS
  then
   DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
   apex_fusion_utl_pkg.log_event('AP:GET_SUPERVISOR:ERROR','MSG' || sqlerrm);
  end;

end APEX_FUSION_INTEGRATION_PKG;
/