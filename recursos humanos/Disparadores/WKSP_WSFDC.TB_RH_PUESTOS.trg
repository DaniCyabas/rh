CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_PUESTOS
 BEFORE INSERT OR UPDATE
 ON RH_PUESTOS
 FOR EACH ROW
DECLARE
   v_exist number;
BEGIN
   if inserting then
       --- Actualizar primero el anterior
        v_exist := 0;
        begin
           select 1
           into   v_exist
           from   RH_PUESTOS
           where  cod_persona = :new.cod_persona
           and    fec_hasta is null;
        exception
           when no_data_found then
              v_exist := 0;
           when too_many_rows then
              v_exist := 1;
        end;
        IF v_exist = 1 THEN
           raise_application_error(-20000,
           'Existe fecha abierta. Ingrese primero la fecha hasta');
        END IF;
      --
      --Verificar que el a?o desde no se solape
      --
        v_exist := 0;
        begin
           select 1
           into   v_exist
           from   RH_PUESTOS
           where  trunc(FEC_DESDE) < trunc(:new.fec_desde)
           and    cod_persona = :new.cod_persona
           and    nvl(FEC_HASTA,trunc(:new.fec_desde)) > trunc(:new.fec_desde);
        exception
           when no_data_found then
              v_exist := 0;
           when too_many_rows then
              v_exist := 1;
        end;
        IF v_exist = 1 THEN
           raise_application_error(-20000,
           'La fecha desde ya se encuentra dentro de un rango de fechas');
        END IF;
        --
        --Verificar que el a?o desde no se solape
        --
        v_exist := 0;
        begin
           select 1
           into   v_exist
           from   RH_PUESTOS
           where  trunc(FEC_DESDE) < trunc(:new.fec_hasta)
           and    cod_persona = :new.cod_persona
           and    nvl(FEC_HASTA,trunc(:new.fec_hasta)) > trunc(:new.fec_hasta);
        exception
           when no_data_found then
              v_exist := 0;
           when too_many_rows then
              v_exist := 1;
        end;
        IF v_exist = 1 THEN
           raise_application_error(-20000,
           'La fecha hasta ya se encuentra dentro de un rango de fechas');
        END IF;
    end if;
END;
/
