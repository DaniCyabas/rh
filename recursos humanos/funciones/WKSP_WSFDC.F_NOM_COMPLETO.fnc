CREATE OR REPLACE FUNCTION WKSP_WSFDC.F_NOM_COMPLETO
 (
   P_COD_EMPLEADO IN RH_EMPLEADOS.COD_PERSONA%TYPE
 )
 RETURN VARCHAR2
 IS
V_NOM_COMPLETO VARCHAR2(240);
Begin
    select nom_completo
    into v_nom_completo
    from ba_personas
    where cod_persona = p_cod_empleado;
    return v_nom_completo;
    exception
    when no_data_found then
        raise_application_error(-20000,
        'No existe el empleado: '|| p_cod_empleado);
End;
/
