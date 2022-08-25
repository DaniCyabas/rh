CREATE OR REPLACE FUNCTION WKSP_WSFDC.FUH_OBT_COD_EMPRESA
 (P_EMPRESA IN varchar2
 )
 RETURN INTEGER
 IS
v_empresa rh_par_empresas.cod_empresa%type;
BEGIN
    select cod_persona
    into   v_empresa
    from   ba_per_juridicas
    where  cod_persona = p_empresa;
return v_empresa;
exception
    when no_data_found then
    raise_application_error(-20000,'Empresa no existe');
END;
/
