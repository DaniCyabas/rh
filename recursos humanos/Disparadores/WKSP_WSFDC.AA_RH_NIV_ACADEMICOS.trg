CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_NIV_ACADEMICOS
 AFTER DELETE OR UPDATE
 ON RH_NIV_ACADEMICOS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_NIV_ACADEMICOS';
  v_registro.clave := :old.cod_persona || '#' || to_char( :old.cod_niv_estudio);
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;
  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'CUR_ALCANZADO', :old.cur_alcanzado, :new.cur_alcanzado, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'CARRERA', :old.carrera, :new.carrera );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'UNIVERSIDAD', :old.universidad, :new.universidad );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'TITULO', :old.titulo, :new.titulo );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'MOT_ABANDONO', :old.mot_abandono, :new.mot_abandono );
  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
