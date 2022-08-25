CREATE OR REPLACE FUNCTION WKSP_WSFDC.FUG_OBT_IGUAL_SN
 (
  PAR IN varchar2
 )
 RETURN VARCHAR2
 IS
  v_par  varchar(50);
begin  
--if par is not null and instr(par,'Igual',1) = 0 then
   --raise_application_error(-20000,'Solo está permitido el parámetro Igual_a'); 
   --v_par := 'ERROR';
--else
   if ( instr(par,'SI',1) > 0 and  instr(par,'NO',1) > 0 ) or ( par is null ) then
      v_par := 'TODOS';
   elsif  (instr(par,'SI',1) > 0 and  instr(par,'NO',1) = 0 ) then    
      v_par := 'SI';
   elsif  (instr(par,'SI',1) = 0 and  instr(par,'NO',1) > 0 ) then         
      v_par := 'NO';
   end if;      
--end if;
   return (v_par);
end ;
/
