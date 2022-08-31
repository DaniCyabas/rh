CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_PROVISIONES
 BEFORE DELETE OR INSERT OR UPDATE
 ON RH_PROVISIONES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
   v_exist number;
BEGIN
   IF inserting THEN
      -- Las provisiones se generan sin saldo provisionado
      :new.mto_debe   := 0;
      :new.sal_actual := :new.mto_haber;
   ELSIF updating THEN
      IF :new.mto_haber <> :old.mto_haber
      OR nvl(:new.per_desde,0)  <> nvl(:new.per_desde,0)
      OR nvl(:new.per_hasta,0)  <> nvl(:new.per_hasta,0)
      OR :new.cod_tip_provision <> :old.cod_tip_provision THEN
         raise_application_error(-20000,
         'Datos iniciales de provision no pueden modificarse');
      END IF;
      IF :new.mto_debe <> :old.mto_debe THEN
         :new.sal_actual := :new.mto_haber - :new.mto_debe;
      END IF;
   ELSIF deleting THEN
      IF :old.mto_haber <> :new.sal_actual THEN
         raise_application_error(-20000,
         'No pueden eliminarse provisiones cuyo saldo fue modificado');
      END IF;
   END IF;
   --Validar fechas no se solapen
   /*
   IF inserting or updating  THEN
      --
      --Verificar que el año desde no se solape
      --
      v_exist := 0;
      begin
         select 1
         into   v_exist
         from   RH_PROVISIONES
         where  PER_DESDE <= :new.per_desde
         and    PER_HASTA >= :new.per_desde;
      exception
         when no_data_found then
            v_exist := 0;
         when too_many_rows then
            v_exist := 1;
      end;
      IF v_exist = 1 THEN
         raise_application_error(-20000,
         'El Periodo Desde ya se encuentra dentro de un rango de fechas');
      END IF;
      --
      --Verificar que el año desde no se solape
      --
      v_exist := 0;
      begin
         select 1
         into   v_exist
         from   RH_PROVISIONES
         where  PER_DESDE <= :new.per_hasta
         and    PER_HASTA >= :new.per_hasta;
      exception
         when no_data_found then
            v_exist := 0;
         when too_many_rows then
            v_exist := 1;
      end;
      IF v_exist = 1 THEN
         raise_application_error(-20000,
         'El Periodo Hasta ya se encuentra dentro de un rango de fechas');
      END IF;
   END IF;
   */
END;
/
