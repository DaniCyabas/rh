CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_OBT_EMPRESA
 (
  P_COD_EMPRESA IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
  RP_EMPRESA IN OUT RH_PAR_EMPRESAS%ROWTYPE
 )
 IS
BEGIN
   select *
   into rp_empresa
   from rh_par_empresas
   where cod_empresa = p_cod_empresa;
exception
   when no_data_found then
      raise_application_error(-20000,
      'La Empresa '||p_cod_empresa||' no existe.');
   when others then
      raise_application_error(-20000,
      'Obt. Empresa '||p_cod_empresa||' '||sqlerrm);
END;
/
