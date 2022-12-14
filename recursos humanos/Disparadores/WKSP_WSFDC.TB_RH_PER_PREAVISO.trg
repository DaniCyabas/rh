CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_PER_PREAVISO
 BEFORE INSERT
 ON RH_PER_PREAVISO
 FOR EACH ROW
DECLARE
   v_exist number;
BEGIN
   --
   --Verificar que el a?o desde no se solape
   --
   v_exist := 0;
   begin
      select 1
      into   v_exist
      from   RH_PER_PREAVISO
      where  ANO_DESDE <= :new.ano_desde
      and    ANO_HASTA >= :new.ano_desde;
   exception
      when no_data_found then
         v_exist := 0;
      when too_many_rows then
         v_exist := 1;
   end;
   IF v_exist = 1 THEN
      raise_application_error(-20000,
      'El a?o desde ya se encuentra dentro de un rango de fechas');
   END IF;
   --
   --Verificar que el a?o desde no se solape
   --
   v_exist := 0;
   begin
      select 1
      into   v_exist
      from   RH_PER_PREAVISO
      where  ANO_DESDE <= :new.ano_hasta
      and    ANO_HASTA >= :new.ano_hasta;
   exception
      when no_data_found then
         v_exist := 0;
      when too_many_rows then
         v_exist := 1;
   end;
   IF v_exist = 1 THEN
      raise_application_error(-20000,
      'El a?o hasta ya se encuentra dentro de un rango de fechas');
   END IF;
END;
/
