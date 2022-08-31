CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_RELOJES
 AFTER DELETE OR UPDATE
 ON RH_RELOJES
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_RELOJES';
  v_registro.clave := to_char( :old.fecha, 'DD/MM/YYYY HH24:MI:SS') || '#' || :old.cod_persona || '#' || to_char( :old.hora, 'DD/MM/YYYY HH24:MI:SS') || '#' || :old.tipo;
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;

  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'NRO_TARJETA', :old.nro_tarjeta, :new.nro_tarjeta );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'NRO_RELOJ', :old.nro_reloj, :new.nro_reloj );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'IND_PROCESADO', :old.ind_procesado, :new.ind_procesado );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
