CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_LIQ_SUELDOS
 AFTER DELETE OR UPDATE
 ON RH_LIQ_SUELDOS
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_LIQ_SUELDOS';
  v_registro.clave := to_char( :old.cod_cen_costo);
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
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_PERSONA', :old.cod_persona, :new.cod_persona );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'NRO_SOBRE', :old.nro_sobre, :new.nro_sobre, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'MONTO', :old.monto, :new.monto, 'M' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_MONEDA', :old.cod_moneda, :new.cod_moneda );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COMPUTABLE', :old.computable, :new.computable, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'VAC_FEC_DESDE', :old.vac_fec_desde, :new.vac_fec_desde, 'F' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'ING_NUMERO', :old.ing_numero, :new.ing_numero, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'HEX_FEC_HOR_EXTRA', :old.hex_fec_hor_extra, :new.hex_fec_hor_extra, 'H' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'DES_NUMERO', :old.des_numero, :new.des_numero, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_INGRESO', :old.cod_tip_ingreso, :new.cod_tip_ingreso, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'HOR_COMPUTABLE', :old.hor_computable, :new.hor_computable, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_DESCUENTO', :old.cod_tip_descuento, :new.cod_tip_descuento, 'N' );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
