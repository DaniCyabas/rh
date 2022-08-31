CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_PUESTOS
 AFTER DELETE OR UPDATE
 ON RH_PUESTOS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_PUESTOS';
  v_registro.clave := :old.cod_persona || '#' || to_char( :old.fec_desde, 'DD/MM/YYYY HH24:MI:SS');
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;

  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'FEC_HASTA', :old.fec_hasta, :new.fec_hasta, 'F' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_CAT_EMPLEADO', :old.cod_cat_empleado, :new.cod_cat_empleado, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_CEN_COSTO', :old.cod_cen_costo, :new.cod_cen_costo );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'CARGO', :old.cargo, :new.cargo );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'IND_INTERINO', :old.ind_interino, :new.ind_interino );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'SALARIO', :old.salario, :new.salario, 'M' );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
