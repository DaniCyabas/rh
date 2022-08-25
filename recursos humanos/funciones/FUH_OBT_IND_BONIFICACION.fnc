CREATE OR REPLACE FUNCTION FUH_OBT_IND_BONIFICACION
 (P_COD_PERSOMA IN ba_personas.cod_persona%type
 )
 RETURN VARCHAR2
 IS
  v_bonificacion varchar2(1);
  v_fec_nacimiento date;
begin
  begin
    select f.fec_nacimiento
    into   v_fec_nacimiento
    from   ba_per_fisicas f
    where  f.cod_persona = p_cod_persoma;
  exception
    when no_data_found then
      v_bonificacion := 'N';
  end;

  if v_fec_nacimiento is not null then
    if months_between(sysdate,v_fec_nacimiento) < 216 then
       v_bonificacion := 'S';
    else
       v_bonificacion := 'N';
    end if;
  end if;
  return(v_bonificacion);
end;
/
