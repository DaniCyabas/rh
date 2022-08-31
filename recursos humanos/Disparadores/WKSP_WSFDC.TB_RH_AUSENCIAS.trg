CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_AUSENCIAS
 BEFORE DELETE OR INSERT OR UPDATE
 ON RH_AUSENCIAS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE

   v_exist number;
BEGIN
   IF deleting THEN
      IF :old.ind_procesado = 'S' THEN
         raise_application_error(-20000,
         'No puede eliminar ausencia procesada '||to_char(:old.fec_inicio,'DD/MM/YYYY')||' del empleado '||:old.cod_persona);
      END IF;
   elsif inserting then
      --
      --Verificar que el a?o desde no se solape
      --
        v_exist := 0;
        begin
           select 1
           into   v_exist
           from   RH_AUSENCIAS
           where  trunc(FEC_INICIO) < trunc(:new.fec_inicio)
           and    nvl(FEC_FIN,trunc(:new.fec_inicio)) > trunc(:new.fec_inicio);
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
           from   RH_AUSENCIAS
           where  trunc(FEC_INICIO) < trunc(:new.FEC_FIN)
           and    nvl(FEC_FIN,trunc(:new.FEC_FIN)) > trunc(:new.FEC_FIN);
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
