CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_DESCUENTOS
 AFTER DELETE OR UPDATE
 ON RH_DESCUENTOS
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_DESCUENTOS';
  v_registro.clave := to_char( :old.numero) || '#' || :old.cod_persona;
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;
  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'FECHA', :old.fecha, :new.fecha, 'F' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_DESCUENTO', :old.cod_tip_descuento, :new.cod_tip_descuento, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'MONTO', :old.monto, :new.monto, 'M' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_MONEDA', :old.cod_moneda, :new.cod_moneda );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'PORCENTAJE', :old.porcentaje, :new.porcentaje, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'IND_AUTOMATICO', :old.ind_automatico, :new.ind_automatico );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'IND_PROCESADO', :old.ind_procesado, :new.ind_procesado );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
