CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_ERR_RELOJES
 AFTER DELETE OR UPDATE
 ON RH_ERR_RELOJES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_ERR_RELOJES';
  v_registro.clave := :old.nro_tarjeta || '#' || to_char( :old.fecha, 'DD/MM/YYYY HH24:MI:SS') || '#' || :old.archivo;
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;

  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'ERROR', :old.error, :new.error );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
