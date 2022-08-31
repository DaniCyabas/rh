CREATE OR REPLACE TRIGGER WKSP_WSFDC.AA_RH_PAR_EMPRESAS
 AFTER DELETE OR UPDATE
 ON RH_PAR_EMPRESAS
 FOR EACH ROW
DECLARE
  v_registro RH_AUDITORIAS%ROWTYPE; -- Registro de la tabla RH_AUDITORIAS
BEGIN
  v_registro.tabla := 'RH_PAR_EMPRESAS';
  v_registro.clave := :old.cod_empresa;
  v_registro.fec_calendario := pae_cnf.fu_obt_fec_actual( pae_cnf.g_cod_modulo );
  IF updating THEN
    v_registro.tip_novedad := 'M';
  ELSIF deleting THEN
    v_registro.tip_novedad := 'E';
  END IF;

  -- Registrar Detalle
  v_registro.detalle := pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'PAT_IPS_01', :old.pat_ips_01, :new.pat_ips_01, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'PAT_IPS_02', :old.pat_ips_02, :new.pat_ips_02, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'POR_IPS_EMP', :old.por_ips_emp, :new.por_ips_emp, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'POR_IPS_PAT', :old.por_ips_pat, :new.por_ips_pat, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'ANO_ACTUAL', :old.ano_actual, :new.ano_actual, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'MES_ACTUAL', :old.mes_actual, :new.mes_actual, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'QUI_ACTUAL', :old.qui_actual, :new.qui_actual, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'POR_DESCUENTOS', :old.por_descuentos, :new.por_descuentos, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'POR_BONIFICACION', :old.por_bonificacion, :new.por_bonificacion, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'FEC_ULT_CIERRE', :old.fec_ult_cierre, :new.fec_ult_cierre, 'F' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'MIN_TOLERANCIA', :old.min_tolerancia, :new.min_tolerancia, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_DES_IPS', :old.cod_tip_des_ips, :new.cod_tip_des_ips, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_VACACION', :old.cod_tip_ing_vacacion, :new.cod_tip_ing_vacacion, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_SUELDO', :old.cod_tip_ing_sueldo, :new.cod_tip_ing_sueldo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_BONIFICACION', :old.cod_tip_ing_bonificacion, :new.cod_tip_ing_bonificacion, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_PREAVISO', :old.cod_tip_ing_preaviso, :new.cod_tip_ing_preaviso, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_INDEMNIZACION', :old.cod_tip_ing_indemnizacion, :new.cod_tip_ing_indemnizacion, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_EXTRAS', :old.cod_tip_ing_extras, :new.cod_tip_ing_extras, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_30', :old.cod_tip_ing_30, :new.cod_tip_ing_30, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_50', :old.cod_tip_ing_50, :new.cod_tip_ing_50, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_100', :old.cod_tip_ing_100, :new.cod_tip_ing_100, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_130', :old.cod_tip_ing_130, :new.cod_tip_ing_130, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_AGUINALDO', :old.cod_tip_ing_aguinaldo, :new.cod_tip_ing_aguinaldo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_PROV_VACACION', :old.cod_tip_prov_vacacion, :new.cod_tip_prov_vacacion );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_VAC_PROPORCIONAL', :old.cod_tip_ing_vac_proporcional, :new.cod_tip_ing_vac_proporcional, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TUR_ADMINISTRATIVO', :old.cod_tur_administrativo, :new.cod_tur_administrativo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_COMISION', :old.cod_tip_ing_comision, :new.cod_tip_ing_comision, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_DESTAJO', :old.cod_tip_ing_destajo, :new.cod_tip_ing_destajo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_NORMAL', :old.cod_tip_ing_normal, :new.cod_tip_ing_normal, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_PER_RESPONSABLE', :old.cod_per_responsable, :new.cod_per_responsable );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'NRO_MJT', :old.nro_mjt, :new.nro_mjt, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_BAN_CAJA', :old.cod_ban_caja, :new.cod_ban_caja );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'IND_APO_IPS_CAJA', :old.ind_apo_ips_caja, :new.ind_apo_ips_caja );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'POR_CAJ_EMP', :old.por_caj_emp, :new.por_caj_emp, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'POR_CAJ_PAT', :old.por_caj_pat, :new.por_caj_pat, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'POR_CAJ_EMP_ACT', :old.por_caj_emp_act, :new.por_caj_emp_act, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'POR_CAJ_PAT_ACT', :old.por_caj_pat_act, :new.por_caj_pat_act, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'POR_CAJ_RET_SNPP', :old.por_caj_ret_snpp, :new.por_caj_ret_snpp, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_CARGO', :old.cod_tip_ing_cargo, :new.cod_tip_ing_cargo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_ANTIGUEDAD', :old.cod_tip_ing_antiguedad, :new.cod_tip_ing_antiguedad, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_TITULO', :old.cod_tip_ing_titulo, :new.cod_tip_ing_titulo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_DES_PRI_SUELDO', :old.cod_tip_des_pri_sueldo, :new.cod_tip_des_pri_sueldo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_REPRESENTACION', :old.cod_tip_ing_representacion, :new.cod_tip_ing_representacion, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_DES_CAJA', :old.cod_tip_des_caja, :new.cod_tip_des_caja, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_DES_FONDO', :old.cod_tip_des_fondo, :new.cod_tip_des_fondo, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_DES_AUMENTO', :old.cod_tip_des_aumento, :new.cod_tip_des_aumento, 'N' );
  v_registro.detalle := v_registro.detalle || pae_cnf.fu_reg_auditoria( v_registro.tip_novedad, 'COD_TIP_ING_GRATIFICACION', :old.cod_tip_ing_gratificacion, :new.cod_tip_ing_gratificacion, 'N' );

  -- Insertar tabla de auditoria
  prh_ins_rh_auditoria( v_registro );
EXCEPTION
  when others then
    prh_ins_rh_auditoria( v_registro );
END;
/
