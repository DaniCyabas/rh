CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_INS_RH_AUDITORIA
 (RP_GAUDI IN GE_AUDITORIAS%ROWTYPE
 )
 IS
/* Obtener datos de parametros */
PROCEDURE PRG_OBT_GE_PARAMETRO
 (P_PARAMETRO IN GE_PARAMETROS.PARAMETRO%TYPE,
  RP_GPARAM IN OUT GE_PARAMETROS%ROWTYPE
 );

/* Obtener datos de parametros */
PROCEDURE PRG_OBT_GE_PARAMETRO
 (P_PARAMETRO IN GE_PARAMETROS.PARAMETRO%TYPE,
  RP_GPARAM IN OUT GE_PARAMETROS%ROWTYPE
 )
 IS
BEGIN
   select *
   into rp_gparam
   from ge_parametros
   where parametro = p_parametro;
exception
   when no_data_found then
      raise_application_error(-20000,
      'Parametro '||p_parametro||' no registrado');
END;
BEGIN
   if rp_gaudi.detalle is not null then
      insert into rh_auditorias
      (tabla, clave, usuario,
       fec_sistema,  fec_calendario,
       tip_novedad,  origen,
       terminal, detalle)
      values
      (rp_gaudi.tabla, rp_gaudi.clave, USER,
       SYSDATE, rp_gaudi.fec_calendario, rp_gaudi.tip_novedad,
       PAE_CNF.G_PROGRAMA, PAE_CNF.FU_OBT_TERMINAL, rp_gaudi.detalle);
   end if;
END;
/
