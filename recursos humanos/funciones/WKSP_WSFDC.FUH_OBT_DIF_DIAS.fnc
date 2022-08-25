create or replace function WKSP_WSFDC.FUH_OBT_DIF_DIAS 
   (
    p_fec_ini date,
    p_fec_fin date
   )
   return number
is
  v_fec_fin number;  -- diferencias bruta desde dia de ingreso hasta aprobacion
  v_cant number;   -- cantidad de registros
  i date;          -- auxiliar para el loop
begin
  v_fec_fin := p_fec_fin - p_fec_ini;
  -- ver si hubo feriados entre esas fechas , y restar
  select count(*)
  into   v_cant
  from   ba_feriados c
  where  c.fecha between p_fec_ini and p_fec_fin
  and    to_char(c.fecha,'D') not in ('6','7'); -- sabado o domingo;
  v_fec_fin := v_fec_fin - v_cant;
  -- ver si hubo fines de semanas entre fechas y restar
  i := p_fec_ini;
  while i <> p_fec_fin loop
    if to_char(i,'D') = '6' or to_char(i,'D') = '7' then -- sabado o domingo
      v_fec_fin := v_fec_fin - 1;
    end if;
    i := i + 1;
  end loop;
  return v_fec_fin;
end;
/
