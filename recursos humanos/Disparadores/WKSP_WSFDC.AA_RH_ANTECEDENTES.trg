CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_ANTECEDENTES
 AFTER DELETE OR UPDATE
 ON RH_ANTECEDENTES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_ANTECEDENTES';
  v_registro.clave := :old.cod_persona || '#' || to_char(:old.cod_ente) || '#' || to_char( :old.fecha, 'DD/MM/YYYY HH24:MI:SS');
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;

  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'MTO_DEUDA', :old.mto_deuda, :new.mto_deuda, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_MONEDA', :old.cod_moneda, :new.cod_moneda );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'SAL_DEUDA', :old.sal_deuda, :new.sal_deuda, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'OBSERVACION', :old.observacion, :new.observacion );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
