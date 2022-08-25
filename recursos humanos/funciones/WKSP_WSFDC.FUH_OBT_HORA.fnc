CREATE OR REPLACE FUNCTION WKSP_WSFDC.FUH_OBT_HORA
 (
 P_HORA IN date,
 P_MINUTOS IN number
 )
 RETURN DATE
 IS
   v_hora date;
   v_hora_desde    number;
   v_minuto_desde  number;
   v_segundo_desde number;
   v_tot_seg_desde number;
   v_minutos       number;
   v_hor_final number;
   v_min_final number;
   v_seg_final number;
begin
    V_HORA_desde    := to_number(SUBSTR(to_char(P_HORA,'HH24:MI:SS'),1,2))*3600;
    V_MINUTO_desde  := to_number(SUBSTR(to_char(P_HORA,'HH24:MI:SS'),4,2))*60;
    V_SEGUNDO_desde := to_number(SUBSTR(to_char(P_HORA,'HH24:MI:SS'),7,2));
    v_tot_seg_desde := v_hora_desde + v_minuto_desde + v_segundo_desde;
    V_MINUTOS  := p_minutos * 60;
    v_tot_seg_desde := v_tot_seg_desde + v_minutos;
    v_hor_final := trunc(v_tot_seg_desde/3600);
    v_min_final := trunc((v_tot_seg_desde-(v_hor_final*3600))/60);
    v_seg_final := ((v_tot_seg_desde-(v_hor_final*3600)-(v_min_final*60)));
    v_hora := to_date(lpad(to_char(v_hor_final),2,'0')||
                      lpad(to_char(v_min_final),2,'0')||
                      lpad(to_char(v_seg_final),2,'0'), 'HH24MISS');
    v_hora := to_date(to_char(p_hora,'ddmmyyyy')||' '||to_char(v_hora,'hh24miss'),'ddmmyyyy hh24miss');
    return v_hora;
end;
/
