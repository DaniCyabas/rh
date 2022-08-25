CREATE OR REPLACE FUNCTION WKSP_WSFDC.FUH_OBT_IND_DISCAPACIDAD
 (
 P_COD_PERSOMA IN ba_personas.cod_persona%type
 )
 RETURN VARCHAR2
 IS
  v_dicapacitado varchar2(1);
begin
  begin
    select 'S'
    into   v_dicapacitado
    from   ba_afecciones a, ba_per_afecciones p, ba_vinculos b
    where  a.cod_afeccion = p.cod_afeccion
    and    b.cod_per_vinculo = p.cod_persona
    and    b.cod_per_vinculo = p_cod_persoma
    and    a.ind_discapacitado = 'S'
    and    b.tipo = 'H';
  exception
    when no_data_found then
      v_dicapacitado := 'N';
    when too_many_rows then
      v_dicapacitado := 'S';
  end;
  return(v_dicapacitado);
end;
/
