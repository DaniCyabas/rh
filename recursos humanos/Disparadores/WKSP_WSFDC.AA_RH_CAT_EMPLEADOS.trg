CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_CAT_EMPLEADOS
 AFTER DELETE OR UPDATE
 ON RH_CAT_EMPLEADOS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
 v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_CAT_EMPLEADOS';
  v_registro.clave := to_char( :old.cod_cat_empleado);
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;
  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'DESCRIPCION', :old.descripcion, :new.descripcion );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
