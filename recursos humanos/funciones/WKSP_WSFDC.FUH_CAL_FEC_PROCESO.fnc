CREATE OR REPLACE FUNCTION WKSP_WSFDC.FUH_CAL_FEC_PROCESO
 (
  P_ANO_PROCESO IN RH_SOBRES.ANO%TYPE,
  P_MES_PROCESO IN RH_SOBRES.MES%TYPE,
  P_QUI_PROCESO IN RH_SOBRES.QUINCENA%TYPE
 )
 RETURN DATE
 IS
v_fecha_proceso DATE;
BEGIN
   IF p_qui_proceso = 1 THEN
      v_fecha_proceso := to_date(to_char(p_ano_proceso,'9999')||to_char(p_mes_proceso,'99')||'15','YYYYMMDD');
   ELSE
      v_fecha_proceso := last_day(to_date(to_char(p_ano_proceso,'9999')||to_char(p_mes_proceso,'99'),'YYYYMM'));
   END IF;
   RETURN v_fecha_proceso;
END;
/
