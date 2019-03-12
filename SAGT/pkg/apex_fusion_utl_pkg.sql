CREATE OR REPLACE PACKAGE apex_fusion_utl_pkg
AS
  g_wallet_path varchar2(500) := 'file:/home/oracle/wallet2'; 
 -- g_wallet_path varchar2(500) := 'file:/home/oracle/wallet3'; 
  
  FUNCTION call_soap_web_service(
      p_envelope CLOB,
      p_url varchar2,
      p_action varchar2,
      p_soap_version varchar2 default '1.1')
    RETURN CLOB;
    
  FUNCTION call_chunk_soap_web_service(
      p_envelope CLOB,
      p_url varchar2,
      p_action varchar2,
      p_soap_version varchar2 default '1.1')
    RETURN CLOB;
    
  FUNCTION call_rest_api_service(
      p_envelope CLOB,
      p_url varchar2,
     -- p_action varchar2,
      p_soap_version varchar2 default '1.1')
    RETURN CLOB;
    
  procedure create_zip_file (
      p_file_name VARCHAR2,
      p_directory VARCHAR2,
      p_zip_file_name VARCHAR2
  );
  
  procedure  base_64_Encode (
                            p_directory  IN VARCHAR2,
                            p_file_name IN VARCHAR2,
                            p_clob IN OUT NOCOPY CLOB
  );
  
  procedure  base_64_Decode (
                            p_encoded_clob clob,
                              p_decoded_clob out clob
  );
  
  procedure run_otbi_report (
                            p_soap_envelop varchar2, 
                            p_output out clob
  );
  
  procedure log_event (
                            p_procedure varchar2, 
                            p_msg varchar2
  );
  
END apex_fusion_utl_pkg;
/

CREATE OR REPLACE PACKAGE body apex_fusion_utl_pkg
AS
  FUNCTION call_soap_web_service(
      p_envelope CLOB,
      p_url varchar2,
      p_action varchar2,
      p_soap_version varchar2 default '1.1')
    RETURN CLOB
  AS
    -- Construct xml payload to invoke the service.
    l_result  clob; --VARCHAR2(32767) := NULL;
    l_http_request UTL_HTTP.req;
    l_http_response UTL_HTTP.resp;
    l_counter PLS_INTEGER;
    l_length PLS_INTEGER;
    l_content_type varchar2(100);
    
    req_length      binary_integer;
    offset          pls_integer := 1;
    amount          pls_integer := 2000;
    buffer          varchar2 (2000);
  BEGIN
   
    -- Construct xml payload to invoke the service. In this example, it is a hard coded string.
    --Set Certificate folder
    UTL_HTTP.set_wallet(g_wallet_path, NULL);
    
    --dbms_output.put_line ('g_wallet_path:'||g_wallet_path);
    UTL_HTTP.set_proxy ('10.1.150.206:3128');
    
    -- Creates a new HTTP request
    l_http_request := UTL_HTTP.begin_request(p_url , method => 'POST' , http_version => 'HTTP/1.1');
        
    -- Configure the authentication details
    UTL_HTTP.SET_AUTHENTICATION(l_http_request, 'umarsaleem@kpmg.com', 'Nmksup@123');
    
    --check for SOAP version
    if p_soap_version = '1.1' then
      l_content_type := 'text/xml';
    elsif p_soap_version = '1.2' then
      l_content_type := 'application/soap+xml';
    end if;
    
    dbms_output.put_line('3');
    req_length := DBMS_LOB.getlength (p_envelope);
    dbms_output.put_line('req_length' || req_length);
    
    -- Configure the request content type to be xml and set the content length
    UTL_HTTP.set_header(l_http_request, 'Content-Type', l_content_type || ';charset=UTF-8'); --'text/xml;charset=UTF-8');
    UTL_HTTP.set_header(l_http_request, 'Connection', 'Keep-Alive');
    UTL_HTTP.set_header(l_http_request, 'User-Agent', 'Mozilla/4.0');
     dbms_output.put_line('3');
     
       
    UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(p_envelope));
   -- UTL_HTTP.set_header(l_http_request, 'Content-Length', dbms_lob.getlength(p_envelope));
    
    
    -- Set the SOAP action to be invoked; while the call works without this, the value is expected to be set based on
    --standards
    UTL_HTTP.set_header(l_http_request, 'SOAPAction', p_action);
    
    -- Write the xml payload to the request
    UTL_HTTP.write_text(l_http_request, p_envelope);
    
    
    -- Get the response and process it. 
    l_http_response := UTL_HTTP.get_response(l_http_request);
     dbms_output.put_line('5');
    UTL_HTTP.read_text(l_http_response, l_result);
    --dbms_output.put_line('4');
    -- End response
    UTL_HTTP.end_response(l_http_response);
    
    return l_result;
  EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm);
  END;
  
  FUNCTION call_rest_api_service(
      p_envelope CLOB,
      p_url varchar2,
   --   p_action varchar2,
      p_soap_version varchar2 default '1.1')
    RETURN CLOB
  AS
    -- Construct xml payload to invoke the service.
    l_result  clob; --VARCHAR2(32767) := NULL;
    l_http_request UTL_HTTP.req;
    l_http_response UTL_HTTP.resp;
    l_counter PLS_INTEGER;
    l_length PLS_INTEGER;
    l_content_type varchar2(100);
    
    req_length      binary_integer;
    offset          pls_integer := 1;
    amount          pls_integer := 2000;
    buffer          varchar2 (2000);
  BEGIN
   
    -- Construct xml payload to invoke the service. In this example, it is a hard coded string.
    --Set Certificate folder
    UTL_HTTP.set_wallet(g_wallet_path, NULL);
    
    --dbms_output.put_line ('g_wallet_path:'||g_wallet_path);
    UTL_HTTP.set_proxy ('10.1.150.206:3128');
    
    -- Creates a new HTTP request
    l_http_request := UTL_HTTP.begin_request(p_url , method => 'POST' , http_version => 'HTTP/1.1');
        
    -- Configure the authentication details
    UTL_HTTP.SET_AUTHENTICATION(l_http_request, 'umarsaleem@kpmg.com', 'Nmksup@123');
    
    --check for SOAP version
    if p_soap_version = '1.1' then
      l_content_type := 'text/xml';
    elsif p_soap_version = '1.2' then
      l_content_type := 'application/soap+xml';
    end if;
   
    -- Configure the request content type to be xml and set the content length
    UTL_HTTP.set_header(l_http_request, 'Content-Type', 'application/json'); --'text/xml;charset=UTF-8');
    UTL_HTTP.set_header(l_http_request, 'Connection', 'Keep-Alive');
    UTL_HTTP.set_header(l_http_request, 'User-Agent', 'Mozilla/4.0');
     dbms_output.put_line('3');
     
       
    UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(p_envelope));
   -- UTL_HTTP.set_header(l_http_request, 'Content-Length', dbms_lob.getlength(p_envelope));
    
    
   
    -- Write the xml payload to the request
    UTL_HTTP.write_text(l_http_request, p_envelope);
    
    
    -- Get the response and process it. 
    l_http_response := UTL_HTTP.get_response(l_http_request);
     dbms_output.put_line('5');
    UTL_HTTP.read_text(l_http_response, l_result);
    --dbms_output.put_line('4');
    -- End response
    UTL_HTTP.end_response(l_http_response);
    
    return l_result;
  EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(sqlerrm);
  END;
  
  
  FUNCTION call_chunk_soap_web_service(
      p_envelope CLOB,
      p_url varchar2,
      p_action varchar2,
      p_soap_version varchar2 default '1.1')
    RETURN CLOB
  as
    req utl_http.req;
    resp utl_http.resp;
    length binary_integer;
    response clob;
    buffer varchar2(32767);
    amount pls_integer := 32767;
    offset pls_integer := 1;
  begin
    
    --Set Certificate folder
    UTL_HTTP.set_wallet(g_wallet_path, NULL);
    
    --dbms_output.put_line ('g_wallet_path:'||g_wallet_path);
    UTL_HTTP.set_proxy ('10.1.150.206:3128');
    dbms_output.put_line('1' || p_url);
    req := utl_http.begin_request(p_url, 'POST', 'HTTP/1.1');
    dbms_output.put_line('1.5');
    -- Configure the authentication details
    UTL_HTTP.SET_AUTHENTICATION(req, 'umarsaleem@kpmg.com', 'Nmksup@123');
 
    utl_http.set_header(req, 'Content-Type', 'text/xml');    
    utl_http.set_header(req, 'Transfer-Encoding', 'chunked');
    
    length := dbms_lob.getlength(p_envelope);
    
    while(offset < length) loop
      dbms_lob.read(p_envelope, amount, offset, buffer);
      utl_http.write_text(req, buffer);
      offset := offset + amount;
    end loop;
    dbms_output.put_line('2');
    resp := utl_http.get_response(req);
      
      dbms_output.put_line('3');
    -- Code to read the response in 32k chunks
      dbms_lob.createtemporary(response, false);
      begin
       loop
        utl_http.read_text(resp, buffer);
        dbms_lob.writeappend(response, dbms_lob.getlength(buffer), buffer);
       end loop;
      utl_http.end_response(resp);
    --  exception
     --  when utl_http.end_of_body then
    --   utl_http.end_response(resp);
      end;
    return response;
  
  end;
  
  procedure create_zip_file (
      p_file_name VARCHAR2,
      p_directory VARCHAR2,
      p_zip_file_name VARCHAR2
  )
  as
    l_zipped_blob blob;
  begin
     -- dbms_output.put_line('p_directory p_file_name' || p_directory || ' '|| p_file_name);
  
      ZIP_FILE_PKG.add1file( l_zipped_blob, p_file_name, ZIP_FILE_PKG.file2blob(p_directory, p_file_name));
      
     -- dbms_output.put_line('2');
      ZIP_FILE_PKG.finish_zip( l_zipped_blob );
    --  dbms_output.put_line('3');
      ZIP_FILE_PKG.save_zip( l_zipped_blob, p_directory, p_zip_file_name || '.zip' );
    -- dbms_output.put_line('4');
      dbms_lob.freetemporary( l_zipped_blob );
  exception 
  when others
   then
    DBMS_OUTPUT.PUT_LINE('create_zip_file :' || sqlerrm);
  end;
    
  
  PROCEDURE base_64_Encode(
      p_directory IN VARCHAR2,
      p_file_name IN VARCHAR2,
      p_clob      IN OUT NOCOPY CLOB)
  AS
    l_bfile BFILE;
    l_step PLS_INTEGER := 12000; --24573;   --earlier 12000
  BEGIN
    --open file
    l_bfile := BFILENAME(p_directory, p_file_name);
    DBMS_LOB.fileopen(l_bfile, DBMS_LOB.file_readonly);
    
    --encode to base64
    FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(l_bfile) - 1 )/l_step)
    LOOP
      p_clob := p_clob || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(l_bfile, l_step, i * l_step + 1)));
    END LOOP;
    --cose the file
    DBMS_LOB.fileclose(l_bfile);
    
  exception 
  when others
   then
    DBMS_OUTPUT.PUT_LINE('base_64_Encode: ' || sqlerrm);
  END;
  
  procedure  base_64_Decode (p_encoded_clob clob,
                              p_decoded_clob out clob)
  as
    l_raw     RAW(32767);
    l_amt     NUMBER := 7700;
    l_offset  NUMBER := 1;
    l_temp    VARCHAR2(32767);
  BEGIN
    BEGIN
      DBMS_LOB.createtemporary (p_decoded_clob, FALSE, DBMS_LOB.CALL);
      LOOP
        DBMS_LOB.read(p_encoded_clob, l_amt, l_offset, l_temp);
        l_offset := l_offset + l_amt;
        l_raw    := UTL_ENCODE.base64_decode(UTL_RAW.cast_to_raw(l_temp));
        DBMS_LOB.append (p_decoded_clob, TO_CLOB(l_raw));
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('base_64_Decode: ' || sqlerrm);
    END;
    
  end;
  
  procedure run_otbi_report(p_soap_envelop varchar2,
                            p_output out clob)
  as
    l_url varchar2(200) := 'https://eivt-test.fa.ap1.oraclecloud.com/xmlpserver/services/ExternalReportWSSService?wsdl';
    l_action varchar2(200) := 'http://xmlns.oracle.com/oxp/service/PublicReportService/ExternalReportWSSService/runReportRequest';
    --l_output clob;
  begin
    p_output := call_soap_web_service(
                                      p_envelope => p_soap_envelop,
                                      p_url => l_url,
                                      p_action => l_action,
                                      p_soap_version => '1.2');
    --dbms_output.put_line(l_output);
  end;
  
  
  procedure log_event (
                            p_procedure varchar2, 
                            p_msg varchar2
  )
  as
  begin
      insert into xx_event_log 
      (methods,error_msg)
      values
      (p_procedure,p_msg);
      commit;
  exception
  when others
   then null;
  end;
END apex_fusion_utl_pkg;
/