CREATE OR REPLACE FUNCTION WKSP_WSFDC.FUH_REC_ULT_LIQ
 (
    P_COD_EMPRESA IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE
 )
 RETURN DATE
 IS
v_fecha rh_sobres.fec_calculo%type;
BEGIN
   select max(s.fec_calculo)
     into v_fecha
     from rh_sobres s, rh_empleados e
    where s.cod_persona = e.cod_persona
      and e.cod_per_empresa >= p_cod_empresa;
   return v_fecha;
END;
/
