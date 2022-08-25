CREATE OR REPLACE FUNCTION WKSP_WSFDC.FUH_REC_CON_VENCER
 (
  P_COD_EMPRESA IN VARCHAR2
 )
 RETURN NUMBER
 IS
   v_cod_emp_desde rh_par_empresas.cod_empresa%type;
   v_cod_emp_hasta rh_par_empresas.cod_empresa%type;
   v_cantidad number;
BEGIN
   if p_cod_empresa = '99' then
      v_cod_emp_desde := '00';
      v_cod_emp_hasta := '99';
   else
      v_cod_emp_desde := p_cod_empresa;
      v_cod_emp_hasta := p_cod_empresa;
   end if;
   select count(*)
     into v_cantidad
     from rh_empleados
    where cod_per_empresa >= v_cod_emp_desde
      and cod_per_empresa <= v_cod_emp_hasta
      and fec_fin_contrato is not null
      and fec_fin_contrato >= sysdate
      and fec_fin_contrato <= sysdate + 3;
   return v_cantidad;
END;
/
