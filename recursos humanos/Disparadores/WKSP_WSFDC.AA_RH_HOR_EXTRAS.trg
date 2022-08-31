CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_HOR_EXTRAS
 AFTER DELETE OR UPDATE
 ON RH_HOR_EXTRAS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_HOR_EXTRAS';
  v_registro.clave := :old.cod_persona || '#' || to_char( :old.fecha, 'DD/MM/YYYY HH24:MI:SS') || '#' || to_char( :old.hor_desde, 'DD/MM/YYYY HH24:MI:SS');
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;

  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'HOR_HASTA', :old.hor_hasta, :new.hor_hasta, 'F' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_CEN_COSTO', :old.cod_cen_costo, :new.cod_cen_costo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'IND_PROCESADO', :old.ind_procesado, :new.ind_procesado );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_PER_AUTORIZADOR', :old.cod_per_autorizador, :new.cod_per_autorizador );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'OBSERVACION', :old.observacion, :new.observacion );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'HOR_TRABAJADA', :old.hor_trabajada, :new.hor_trabajada, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'POR_SUELDO', :old.por_sueldo, :new.por_sueldo, 'N' );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
