CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_HOR_EXTRAS
 BEFORE DELETE OR INSERT OR UPDATE
 ON RH_HOR_EXTRAS
 FOR EACH ROW
DECLARE
   v_exist number;
BEGIN
   IF inserting then
       --
       --Verificar que el año desde no se solape
       --
       v_exist := 0;
       begin
          select 1
          into   v_exist
          from   RH_HOR_EXTRAS
          where  HOR_DESDE <= :new.hor_desde
          and    HOR_HASTA >= :new.hor_desde
          and    trunc(FECHA) = trunc(:new.fecha);
       exception
          when no_data_found then
             v_exist := 0;
          when too_many_rows then
             v_exist := 1;
       end;
       IF v_exist = 1 THEN
          raise_application_error(-20000,
          'La hora desde ya se encuentra dentro de un rango de horas para esta fecha');
       END IF;
       --
       --Verificar que el año desde no se solape
       --
       v_exist := 0;
       begin
          select 1
          into   v_exist
          from   RH_HOR_EXTRAS
          where  HOR_DESDE <= :new.hor_hasta
          and    HOR_HASTA >= :new.hor_hasta
          and    trunc(FECHA) = trunc(:new.fecha) ;
       exception
          when no_data_found then
             v_exist := 0;
          when too_many_rows then
             v_exist := 1;
       end;
       IF v_exist = 1 THEN
          raise_application_error(-20000,
          'La hora hasta ya se encuentra dentro de un rango de horas para esta fecha');
       END IF;
   ---
   ELSIF deleting THEN
      IF :old.ind_procesado = 'S' THEN
         raise_application_error(-20000,
         'No puede eliminar horas extras procesadas '||to_char(:old.fecha,'DD/MM/YYYY')||' del empleado '||:old.cod_persona);
      END IF;
   END IF;
END;
/
