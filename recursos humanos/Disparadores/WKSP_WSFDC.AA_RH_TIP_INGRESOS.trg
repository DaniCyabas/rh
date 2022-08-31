CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_TIP_INGRESOS
 AFTER DELETE OR UPDATE
 ON RH_TIP_INGRESOS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_TIP_INGRESOS';
  v_registro.clave := to_char( :old.cod_tip_ingreso);
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;

  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TRANSACCION', :old.cod_transaccion, :new.cod_transaccion, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_MODULO', :old.cod_modulo, :new.cod_modulo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_MODALIDAD', :old.cod_modalidad, :new.cod_modalidad, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'DESCRIPCION', :old.descripcion, :new.descripcion );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'IND_IMPONIBLE', :old.ind_imponible, :new.ind_imponible );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'IND_ACU_AGUINALDO', :old.ind_acu_aguinaldo, :new.ind_acu_aguinaldo );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
