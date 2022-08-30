CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_REPOSOS
 BEFORE INSERT OR UPDATE
 ON RH_REPOSOS
 FOR EACH ROW
DECLARE
   v_exist number;
BEGIN
   if inserting then
      --
      --Verificar que el a?o desde no se solape
      --
        v_exist := 0;
        begin
           select 1
           into   v_exist
           from   RH_REPOSOS
           where  trunc(FEC_INICIO) < trunc(:new.fec_inicio)
           and    nvl(FEC_FINAL,trunc(:new.fec_inicio)) > trunc(:new.fec_inicio);
        exception
           when no_data_found then
              v_exist := 0;
           when too_many_rows then
              v_exist := 1;
        end;
        IF v_exist = 1 THEN
           raise_application_error(-20000,
           'La fecha inicio ya se encuentra dentro de un rango de fechas');
        END IF;
        --
        --Verificar que el a?o desde no se solape
        --
        v_exist := 0;
        begin
           select 1
           into   v_exist
           from   RH_REPOSOS
           where  trunc(FEC_INICIO) < trunc(:new.fec_final)
           and    nvl(FEC_FINAL,trunc(:new.fec_final)) > trunc(:new.fec_final);
        exception
           when no_data_found then
              v_exist := 0;
           when too_many_rows then
              v_exist := 1;
        end;
        IF v_exist = 1 THEN
           raise_application_error(-20000,
           'La fecha final ya se encuentra dentro de un rango de fechas');
        END IF;
    end if;
END;
/
