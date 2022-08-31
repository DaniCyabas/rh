CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_LIQ_SUELDOS
 BEFORE DELETE OR INSERT OR UPDATE
 ON RH_LIQ_SUELDOS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE

   r_emr            rh_par_empresas%rowtype;
   r_emp            rh_empleados%rowtype;
   v_cod_empleado   rh_empleados.cod_persona%type;
   v_nro_sobre      rh_sobres.nro_sobre%type;
   v_cod_empresa    ba_personas.cod_persona%type;
   v_fecha          rh_sobres.fec_calculo%type;
BEGIN
   IF inserting OR updating THEN
      v_cod_empleado := :new.cod_persona;
      v_nro_sobre    := :new.nro_sobre;
   ELSE
      v_cod_empleado := :old.cod_persona;
      v_nro_sobre    := :old.nro_sobre;
   END IF;
   --- Validar cierre
   SELECT cod_per_empresa
   INTO   v_cod_empresa
   FROM   rh_empleados
   WHERE  cod_persona = v_cod_empleado;

   prh_obt_empresa(v_cod_empresa, r_emr);

   SELECT fec_calculo
   INTO   v_fecha
   FROM   rh_sobres
   WHERE  cod_persona = v_cod_empleado
   AND    nro_sobre   = v_nro_sobre;

   IF v_fecha <= r_emr.fec_ult_cierre THEN
      raise_application_error(-20000,
      'No pueden modificarse liquidaciones cerradas');
   END IF;
END;
/
