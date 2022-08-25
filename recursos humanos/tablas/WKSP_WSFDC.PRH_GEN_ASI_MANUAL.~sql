CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_GEN_ASI_MANUAL
 (
 P_COD_EPR_DESDE IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
 P_COD_EPR_HASTA IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
 P_COD_EMP_DESDE IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_COD_EMP_HASTA IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_FEC_DESDE IN DATE,
 P_FEC_HASTA IN DATE,
 P_TIP_EMPLEADO IN RH_EMPLEADOS.TIPO%TYPE,
 P_HOR_NORMAL IN RH_ASISTENCIAS.HOR_NORMAL%TYPE,
 P_HOR_30POR IN RH_ASISTENCIAS.HOR_30POR%TYPE,
 P_HOR_50POR IN RH_ASISTENCIAS.HOR_50POR%TYPE,
 P_HOR_100POR IN RH_ASISTENCIAS.HOR_100POR%TYPE,
 P_HOR_130POR IN RH_ASISTENCIAS.HOR_130POR%TYPE
 )
 IS

--- Solo debe tomar los empleados que no poseen turnos definidos
   --- Cursor de empleados a procesarse
   cursor c_empleados is
   select cod_persona
     from rh_empleados
    where /*cod_turno is null
      and */fec_egreso is null
      and (tipo = p_tip_empleado or p_tip_empleado = 'A')
      and cod_per_empresa  >= p_cod_epr_desde
      and cod_per_empresa  <= p_cod_epr_hasta
      and cod_persona >= p_cod_emp_desde
      and cod_persona <= p_cod_emp_hasta
    order by cod_persona;
   v_fec_desde   date;
   v_fec_hasta   date;
   v_hor_normal  rh_asistencias.hor_normal%type;
   v_hor_30por   rh_asistencias.hor_30por%type;
   v_hor_50por   rh_asistencias.hor_50por%type;
   v_hor_100por  rh_asistencias.hor_100por%type;
   v_hor_130por  rh_asistencias.hor_130por%type;
BEGIN
   for reg in c_empleados loop
      v_fec_desde  := p_fec_desde;
      v_hor_normal := 0;
      v_hor_30por  := 0;
      v_hor_50por  := 0;
      v_hor_100por := 0;
      v_hor_130por := 0;
      loop
         if v_fec_desde = p_fec_hasta then
            v_hor_normal := p_hor_normal;
            v_hor_30por  := p_hor_30por;
            v_hor_50por  := p_hor_50por;
            v_hor_100por := p_hor_100por;
            v_hor_130por := p_hor_130por;
         end if;
         delete rh_asistencias
          where cod_persona = reg.cod_persona
            and fecha = v_fec_desde;
         insert into rh_asistencias
           (cod_persona, fecha,
            hor_normal, hor_30por, hor_50por, hor_100por, hor_130por)
         values
           (reg.cod_persona, v_fec_desde,
            v_hor_normal, v_hor_30por, v_hor_50por, v_hor_100por, v_hor_130por);
         exit when v_fec_desde = p_fec_hasta;
         v_fec_desde  := v_fec_desde + 1;
         v_hor_normal := 0;
         v_hor_30por  := 0;
         v_hor_50por  := 0;
         v_hor_100por := 0;
         v_hor_130por := 0;
      end loop;
   end loop;
END;
/
