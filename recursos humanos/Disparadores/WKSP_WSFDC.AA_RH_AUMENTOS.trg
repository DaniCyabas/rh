CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_AUMENTOS
 AFTER DELETE OR UPDATE
 ON RH_AUMENTOS
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_AUMENTOS';
  v_registro.clave := :old.cod_empresa;
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;

  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_CEN_COSTO', :old.cod_cen_costo, :new.cod_cen_costo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_PER_DESDE', :old.cod_per_desde, :new.cod_per_desde );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_PER_HASTA', :old.cod_per_hasta, :new.cod_per_hasta );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'FECHA', :old.fecha, :new.fecha, 'F' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'MONTO', :old.monto, :new.monto, 'M' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'PORCENTAJE', :old.porcentaje, :new.porcentaje, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'IND_PROCESADO', :old.ind_procesado, :new.ind_procesado );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_PER_AUTORIZADOR', :old.cod_per_autorizador, :new.cod_per_autorizador );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'IND_AFECTACION', :old.ind_afectacion, :new.ind_afectacion );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_INGRESO', :old.cod_tip_ingreso, :new.cod_tip_ingreso, 'N' );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
