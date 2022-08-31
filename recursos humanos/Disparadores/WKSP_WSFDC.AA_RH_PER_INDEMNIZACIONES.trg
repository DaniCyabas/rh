CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_PER_INDEMNIZACIONES
 AFTER DELETE OR UPDATE
 ON RH_PER_INDEMNIZACIONES
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_PER_INDENMIZACIONES';
  v_registro.clave := to_char( :old.ano_desde) || '#' || to_char( :old.ano_hasta);
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;

  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'DESCRIPCION', :old.descripcion, :new.descripcion );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'DIAS_INDEMNIZACION', :old.DIAS_INDEMNIZACION, :new.DIAS_INDEMNIZACION, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'DIAS_INDEMNIZACION', :old.DIAS_INDEMNIZACION, :new.DIAS_INDEMNIZACION, 'N' );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
