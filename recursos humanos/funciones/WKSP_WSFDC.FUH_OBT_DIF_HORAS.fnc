CREATE OR REPLACE FUNCTION WKSP_WSFDC.FUH_OBT_DIF_HORAS
 (
 P_HOR_DESDE IN VARCHAR2,
 P_HOR_HASTA IN VARCHAR2
 )
 RETURN NUMBER
 IS
v_diferencia    number(10,2) := 0;
v_tot_seg_desde number(10,2);
v_tot_seg_hasta number(10,2);
V_HORA_desde    number(10,2);
V_MINUTO_desde  number(10,2);
V_SEGUNDO_desde number(10,2);
V_HORA_hasta    number(10,2);
V_MINUTO_hasta  number(10,2);
V_SEGUNDO_hasta number(10,2);
v_hor_final number(5);
v_min_final number(5);
v_seg_final number(5);
v_dif_final number(10,2);
BEGIN
   if p_hor_hasta >= p_hor_desde then
      V_HORA_desde    := to_number(SUBSTR(P_HOR_desde,1,2))*3600;
      V_MINUTO_desde  := to_number(SUBSTR(P_HOR_desde,4,2))*60;
      V_SEGUNDO_desde := to_number(SUBSTR(P_HOR_desde,7,2));
      v_tot_seg_desde := v_hora_desde + v_minuto_desde + v_segundo_desde;
      V_HORA_hasta    := to_number(SUBSTR(P_HOR_hasta,1,2))*3600;
      V_MINUTO_hasta  := to_number(SUBSTR(P_HOR_hasta,4,2))*60;
      V_SEGUNDO_hasta := to_number(SUBSTR(P_HOR_hasta,7,2));
      v_tot_seg_hasta := v_hora_hasta + v_minuto_hasta + v_segundo_hasta;
      v_diferencia := v_tot_seg_hasta - v_tot_seg_desde;
      v_hor_final := trunc(v_diferencia/3600);
      v_min_final := trunc((v_diferencia-(v_hor_final*3600))/60);
      v_seg_final := ((v_diferencia-(v_hor_final*3600)-(v_min_final*60)));
      v_dif_final := ((v_hor_final*3600)+(v_min_final*60)+(v_seg_final))/3600;
   else
      raise_application_error(-20000,'Error: Hora Hasta debe ser mayor a Hora Desde');
   end if;
   return v_dif_final;
END;
/
