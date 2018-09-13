select *
from XX_CL_JOURNAL_TL;
--group by JE_HEADER_ID;
where XX_JOURNAL_STAGING;

select *
from XX_JOURNAL_STAGING
where ;

select *
from xx_fahad_header_id;

delete from xx_fahad_header_id where XXHEADER_ID = 3185305;

delete from XX_JOURNAL_STAGING;

delete from XX_CL_JOURNAL_TL;



insert into xx_fahad_header_id values(3208307);
insert into xx_fahad_header_id values(3208306);
insert into xx_fahad_header_id values(3205337);
insert into xx_fahad_header_id values(3199360);
insert into xx_fahad_header_id values(3199304);
insert into xx_fahad_header_id values(3200325);
insert into xx_fahad_header_id values(3200322);
insert into xx_fahad_header_id values(3185354);
insert into xx_fahad_header_id values(3185351);
insert into xx_fahad_header_id values(3185342);
3185342
3185351
3185354
3200322
3200325
3199304
3199360
3205331
3205337
3208306
3208307)

exec XX_CL_JOURNAL_PRC;

SELECT --XXSAGT_JE_SEQ.nextval SEQUENCE_ID,
  distinct gjh.JE_HEADER_ID--,
  
FROM apps.GL_JE_HEADERS GJH,
  apps.GL_JE_LINES GJL,
  apps.GL_JE_BATCHES GJB,
  apps.GL_JE_CATEGORIES gjc,
  apps.gl_ledgers gl,
  apps.gl_code_combinations_kfv gcc
  --xx_journal_staging stg--,
  --XX_CL_JOURNAL_TL stt
WHERE GJH.JE_HEADER_ID     = GJL.JE_HEADER_ID
AND GJB.JE_BATCH_ID        = GJH.JE_BATCH_ID
AND gcc.CODE_COMBINATION_ID= GJL.CODE_COMBINATION_ID
AND gjc.JE_CATEGORY_NAME   = GJH.JE_CATEGORY
AND gl.LEDGER_ID           = GJH.LEDGER_ID
--and stt.JE_HEADER_ID       = stg.JE_HEADER_ID
--AND stg.status not in ('S')
AND GJH.JE_SOURCE          = 'Manual'
--AND gjh.je_header_id  not in (
--select je_header_id from xx_journal_staging
--)
AND gjh.JE_CATEGORY = 'Adjustment'
  --AND GJB.NAME LIKE 'GLbatchName%'
  --and gjh.name like 'JUN-12 Inventory LKR 2';
AND gjh.POSTED_DATE > '01-AUG-2018'
and gjh.currency_code = 'USD' 
--and gjh.JE_HEADER_ID IN (
--select xxheader_id from xx_fahad_header_id
--);
;
/


SELECT *
FROM GL_JE_HEADERS GJH

SELECT *
FROM GL_JE_HEADERS
WHERE BATCH_DESCRIPTION = '3199360'
WHERE 
1=1
AND GJH.JE_SOURCE          = 'Manual'
AND gjh.JE_CATEGORY 	   = 'Adjustment'
and gjh.currency_code 	   = 'USD' 
and JE_HEADER_ID is not null
and rownum < 50
order by JE_HEADER_ID  desc