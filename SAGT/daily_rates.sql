create or replace procedure DAILY_RATE 
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
 
  
create or replace procedure upload_daily_rates_2_fusion(p_content clob)
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
  

create or replace procedure upload_file_2_UCM_fusion(p_content clob , p_output out varchar2)
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
  

create or replace procedure run_dailyrates_import_process(p_process_id varchar2)
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