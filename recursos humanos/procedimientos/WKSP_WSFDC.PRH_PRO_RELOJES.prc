CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_PRO_RELOJES
 (
 P_COD_EPR_DESDE IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
 P_COD_EPR_HASTA IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
 P_COD_EMP_DESDE IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_COD_EMP_HASTA IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_FEC_DESDE IN DATE,
 P_FEC_HASTA IN DATE
 )
 IS
/* Insertar registros de asistencia. */
PROCEDURE LP_INS_ASISTENCIA
 (R_ASI IN RH_ASISTENCIAS%ROWTYPE
 );
/* Procesar hora extra */ /*
PROCEDURE LP_PRO_HOR_EXTRA
 (P_COD_PERSONA IN RH_HOR_EXTRAS.COD_PERSONA%TYPE
 ,P_FEC_HOR_EXTRA IN RH_HOR_EXTRAS.FECHA%TYPE
 ,P_HORA_DESDE IN RH_TURNOS.HOR_DESDE%TYPE
 ,P_HORA_HASTA IN RH_TURNOS.HOR_HASTA%TYPE
 );*/
   v_fecha         rh_relojes.fecha%type;
   v_vez           number(1);
   v_vez_tur       number(1);
   r_asi           rh_asistencias%rowtype;
   r_epr           rh_par_empresas%rowtype;
   v_cod_persona  rh_empleados.cod_persona%type;
   v_cod_empresa   rh_empleados.cod_per_empresa%type;
   v_cod_turno     rh_turnos.cod_turno%type;
   v_tipo_ant      rh_relojes.tipo%type;
   v_turno         BOOLEAN;
   v_procesado     BOOLEAN;
   v_hor_desde    rh_turnos.hor_desde%type;
   v_hor_hasta    rh_turnos.hor_hasta%type;
   v_hor_des_tur  rh_turnos.hor_desde%type;
   v_hor_has_tur  rh_turnos.hor_hasta%type;
   v_hor_des_det  rh_turnos.hor_desde%type;
   v_hor_has_det  rh_turnos.hor_hasta%type;
   v_hor_des_prc  rh_turnos.hor_desde%type;
   v_hor_has_prc  rh_turnos.hor_hasta%type;
   v_hor_trab    rh_asistencias.hor_normal%type;
   v_hor_normal    rh_asistencias.hor_normal%type;
   v_hor_30por     rh_asistencias.hor_30por%type;
   v_hor_50por     rh_asistencias.hor_50por%type;
   v_hor_100por    rh_asistencias.hor_100por%type;
   v_hor_130por    rh_asistencias.hor_130por%type;
   v_hor_normal_rot rh_asistencias.hor_normal%type;
   v_hor_30por_rot  rh_asistencias.hor_30por%type;
   v_hor_50por_rot  rh_asistencias.hor_50por%type;
   v_hor_100por_rot rh_asistencias.hor_100por%type;
   v_hor_130por_rot rh_asistencias.hor_130por%type;
   v_tolerancia    rh_par_empresas.min_tolerancia%type;
   v_prioridad     number; --rh_emp_horarios.prioridad%type;
   v_hor_des_ori   rh_turnos.hor_desde%type;
   v_hor_has_ori   rh_turnos.hor_hasta%type;
   v_dia_des_ori   rh_turnos.dia_desde%type;
   v_dia_has_ori   rh_turnos.dia_hasta%type;
   v_ult_dia_pro   rh_turnos.dia_hasta%type;
   v_feriado       varchar2(01);
   --v_sig_turno     number; --rh_emp_horarios.cod_turno%type;
   v_exi_reloj     number(03);
   v_exi_inicio    varchar2(01);
   --- parametrizacion de turno administrativo
   v_cod_tur_administrativo rh_turnos.cod_turno%type;
   --- Recuperar lineas del reloj
   cursor c_relojes is
   select r.cod_persona, r.fecha, r.hora, r.tipo,
          to_char(r.fecha,'d') dia,
          e.cod_per_empresa, e.cod_turno
   from rh_relojes r, rh_empleados e
   where e.cod_persona = r.cod_persona
   and e.cod_per_empresa >= p_cod_epr_desde
   and e.cod_per_empresa <= p_cod_epr_hasta
   and trunc(r.fecha) >= p_fec_desde
   and trunc(r.fecha) <= p_fec_hasta
   and e.cod_persona >= p_cod_emp_desde
   and e.cod_persona <= p_cod_emp_hasta
   and r.ind_procesado = 'N'
   and e.cod_turno is not null
   and r.tipo in ('E','S')
   order by r.cod_persona, r.fecha, r.hora, r.tipo;
   --- Recuperar turnos del turno
   cursor c_turnos is
   select to_date(to_char(v_fecha,'ddmmyyyy')||to_char(hor_desde,'hh24mi'),'ddmmyyyyhh24mi') hor_desde,
          to_date(to_char(v_fecha,'ddmmyyyy')||to_char(hor_hasta,'hh24mi'),'ddmmyyyyhh24mi') hor_hasta,
          0 por_sueldo
   from   rh_turnos
   where  cod_turno   = v_cod_turno
   order by hor_desde;

/* Insertar registros de asistencia. */
PROCEDURE LP_INS_ASISTENCIA
(R_ASI IN RH_ASISTENCIAS%ROWTYPE
)
 IS
BEGIN
   Insert into rh_asistencias
     (cod_persona, fecha,
      hor_normal, hor_30por, hor_50por, hor_100por, hor_130por)
   values
     (r_asi.cod_persona, r_asi.fecha,
      r_asi.hor_normal, r_asi.hor_30por, r_asi.hor_50por, r_asi.hor_100por, r_asi.hor_130por);
   exception
      when dup_val_on_index then
         update rh_asistencias
            set hor_normal = nvl(hor_normal,0) + r_asi.hor_normal,
                hor_30por = nvl(hor_30por,0) + r_asi.hor_30por,
                hor_50por = nvl(hor_50por,0) + r_asi.hor_50por,
                hor_100por = nvl(hor_100por,0) + r_asi.hor_100por,
                hor_130por = nvl(hor_130por,0) + r_asi.hor_130por
          where cod_persona = r_asi.cod_persona
            and fecha = r_asi.fecha;
END;
/* Procesar hora extra */
PROCEDURE LP_PRO_HOR_EXTRA
 (P_COD_PERSONA IN RH_HOR_EXTRAS.COD_PERSONA%TYPE
 ,P_FECHA IN RH_HOR_EXTRAS.FECHA%TYPE
 ,P_HOR_DESDE IN RH_TURNOS.HOR_DESDE%TYPE
 ,P_HOR_HASTA IN RH_TURNOS.HOR_HASTA%TYPE
 )
 IS
/* Obtener horas extras */
PROCEDURE LP_OBT_HOR_EXTRA
 (P_COD_PERSONA IN RH_HOR_EXTRAS.COD_PERSONA%TYPE
 ,P_FECHA IN RH_HOR_EXTRAS.FECHA%TYPE
 ,P_HOR_DESDE IN RH_TURNOS.HOR_DESDE%TYPE
 ,P_HOR_HASTA IN RH_TURNOS.HOR_HASTA%TYPE
 ,P_EXISTE IN OUT BOOLEAN
 ,RP_EXT IN OUT RH_HOR_EXTRAS%ROWTYPE
 );
/* Actualizar hora extra */
PROCEDURE LP_ACT_HOR_EXTRA
 (P_COD_PERSONA IN RH_HOR_EXTRAS.COD_PERSONA%TYPE
 ,P_FECHA IN RH_HOR_EXTRAS.FECHA%TYPE
 ,P_HOR_TRABAJADA IN RH_HOR_EXTRAS.HOR_TRABAJADA%TYPE
 );
   r_ext           rh_hor_extras%rowtype;
   v_hor_extra    BOOLEAN;
   v_hor_des_ext  rh_turnos.hor_desde%type;
   v_hor_has_ext  rh_turnos.hor_hasta%type;
/* Obtener horas extras */
PROCEDURE LP_OBT_HOR_EXTRA
 (P_COD_PERSONA IN RH_HOR_EXTRAS.COD_PERSONA%TYPE
 ,P_FECHA IN RH_HOR_EXTRAS.FECHA%TYPE
 ,P_HOR_DESDE IN RH_TURNOS.HOR_DESDE%TYPE
 ,P_HOR_HASTA IN RH_TURNOS.HOR_HASTA%TYPE
 ,P_EXISTE IN OUT BOOLEAN
 ,RP_EXT IN OUT RH_HOR_EXTRAS%ROWTYPE
 )
 IS
BEGIN
   select *
   into rp_ext
   from rh_hor_extras
   where cod_persona = p_cod_persona
   and fecha = p_fecha
   and to_date(to_char(fecha,'DDMMYYYY')||to_char(hor_desde,'HH24MI'),'DDMMYYYYHH24MI') >= p_hor_desde
   and to_date(to_char(fecha,'DDMMYYYY')||to_char(hor_hasta,'HH24MI'),'DDMMYYYYHH24MI') <= p_hor_hasta;
   rp_ext.hor_desde := to_date(to_char(p_fecha,'DDMMYYYY')||to_char(rp_ext.hor_desde,'HH24MI'),'DDMMYYYYHH24MI');
   rp_ext.hor_hasta := to_date(to_char(p_fecha,'DDMMYYYY')||to_char(rp_ext.hor_hasta,'HH24MI'),'DDMMYYYYHH24MI');
   p_existe := TRUE;
exception
   when no_data_found then
      p_existe := FALSE;
   when too_many_rows then
      p_existe := FALSE;
END;
/* Actualizar hora extra */
PROCEDURE LP_ACT_HOR_EXTRA
 (P_COD_PERSONA IN RH_HOR_EXTRAS.COD_PERSONA%TYPE
 ,P_FECHA IN RH_HOR_EXTRAS.FECHA%TYPE
 ,P_HOR_TRABAJADA IN RH_HOR_EXTRAS.HOR_TRABAJADA%TYPE
 )
 IS
BEGIN
   Update rh_hor_extras
   set hor_trabajada = p_hor_trabajada
   where cod_persona = P_COD_PERSONA
   and fecha = p_fecha;
END;

BEGIN
   LP_OBT_HOR_EXTRA( p_cod_persona, p_fecha, p_hor_desde, p_hor_hasta, v_hor_extra, r_ext);
   if v_hor_extra then
      -- Computar hora extra
      if r_ext.hor_desde > p_hor_desde then
         v_hor_des_ext := r_ext.hor_desde;
      else
         v_hor_des_ext := p_hor_desde;
      end if;
      if r_ext.hor_hasta < p_hor_hasta then
         v_hor_has_ext := r_ext.hor_hasta;
      else
         v_hor_has_ext := p_hor_hasta ;
      end if;
      v_hor_trab := FUH_OBT_DIF_HORAS(to_char(v_hor_des_ext,'hh24:mi:ss'),to_char(v_hor_has_ext,'hh24:mi:ss'));
   end if;
END;

BEGIN

   ------------ INICIALIZACION DE TURNOS PARA REPROCESOS -------
   --- OBS: Para que la restauracion funcione el rango de fechas debe ser exactamente el ultimo procesado
   --- Verificar si hay que restaurar el codigo de turno para el rango a procesar.
   --------------------------------------------------------------------------------------------
   v_vez          := 0;
   v_tipo_ant     := 'S';
   v_hor_desde   := null;
   v_hor_hasta   := null;
   v_hor_normal   := 0;
   v_hor_30por    := 0;
   v_hor_50por    := 0;
   v_hor_100por   := 0;
   v_hor_130por   := 0;
   v_ult_dia_pro  := null;
   FOR r_rel IN c_relojes LOOP
--dbms_output.put_line('Emp '||r_rel.cod_persona||' fecha '||to_char(r_rel.fecha,'dd/mm/yyyy')||' Hora '||to_char(r_rel.hora,'hh24:mi')||' Tipo '||r_rel.tipo||' Ant '||v_tipo_ant||' Dia '||r_rel.dia);
      if v_vez = 0 then
         --- Solo para la primera vez
         v_fecha         := r_rel.fecha;
         v_cod_persona   := r_rel.cod_persona;
         v_cod_empresa   := r_rel.cod_per_empresa;
         v_vez           := 1;
         v_ult_dia_pro   := r_rel.dia;
         v_cod_turno     := r_rel.cod_turno;
         --- Recuperar la prioridad del turno actual
         v_prioridad := 1;
         --- Recuperar datos de la empresa
         prh_obt_empresa(r_rel.cod_per_empresa, r_epr);
      end if;
      if v_fecha        <> r_rel.fecha
      or v_cod_persona <> r_rel.cod_persona then
--dbms_output.put_line('Corte control '||to_char(r_rel.fecha,'dd/mm/yyyy'));
         if (v_hor_normal > 0 OR v_hor_30por > 0 or v_hor_50por > 0
         or v_hor_100por > 0 or v_hor_130por > 0)THEN
            --- Insertar asistencia
            r_asi.cod_persona    := v_cod_persona;
            r_asi.fecha          := v_fecha;
            r_asi.hor_normal     := v_hor_normal;
            r_asi.hor_30por      := v_hor_30por;
            r_asi.hor_50por      := v_hor_50por;
            r_asi.hor_100por     := v_hor_100por;
            r_asi.hor_130por     := v_hor_130por;
            lp_ins_asistencia(r_asi);
            --------------------------------------------
--dbms_output.put_line('Inserto asistencia '||to_char(r_rel.fecha,'dd/mm/yyyy'));
         else
            --- Si no calculo horas de asistencia es porque no tenia turnos
            --- Actualizar el reloj a no procesado
            update rh_relojes
            set ind_procesado = 'N'
            where cod_persona = v_cod_persona
            and fecha = v_fecha;
--dbms_output.put_line('No inserto asistencia '||to_char(r_rel.fecha,'dd/mm/yyyy'));
         end if;
         if v_cod_persona <> r_rel.cod_persona then
            v_cod_turno   := r_rel.cod_turno;
            v_prioridad   := null;
            v_hor_des_ori := null;
            v_hor_has_ori := null;
            v_dia_des_ori := null;
            v_dia_has_ori := null;
         end if;
         --
         v_cod_persona  := r_rel.cod_persona;
         v_cod_empresa  := r_rel.cod_per_empresa;
         v_fecha        := r_rel.fecha;
         v_tipo_ant     := 'S';
         v_hor_desde   := null;
         v_hor_hasta   := null;
         v_hor_normal   := 0;
         v_hor_30por    := 0;
         v_hor_50por    := 0;
         v_hor_100por   := 0;
         v_hor_130por   := 0;
         v_ult_dia_pro  := r_rel.dia;
         --- Recuperar datos de la empresa
         prh_obt_empresa(r_rel.cod_per_empresa, r_epr);
      END IF;
      v_procesado := FALSE;
      --- Verificar si existe otra marcacion para el dia
      BEGIN
         v_exi_reloj := 0;
         select count(*) into v_exi_reloj
           from rh_relojes
          where cod_persona = r_rel.cod_persona
            and fecha = r_rel.fecha
            and hora  > r_rel.hora;
      END;
      --- Verificar que la correlatividad del registro sea correcta
      IF ( ( (r_rel.tipo = 'E' and v_tipo_ant = 'S')
          OR (r_rel.tipo = 'S' and v_tipo_ant = 'E') )
         AND (v_exi_reloj > 0 or r_rel.tipo = 'S'  ) ) THEN
         if v_hor_desde is not null and v_hor_hasta is null then
            v_hor_hasta := r_rel.hora;
         end if;
         if v_hor_desde is null then
            v_hor_desde := r_rel.hora;
         end if;
         v_tipo_ant := r_rel.tipo;
      ELSE
         --- v_hor_desde := null;
         --- v_hor_hasta := null;
         --- Tratar excepcion con solo salida para turnos que empiezan el dia anterior
         --- o solo Entrada que finalizan el dia siguiente
         if  v_cod_turno is not null
         and to_char(v_hor_des_ori,'HH24:MI') = '00:00'
         and r_rel.tipo = 'S' then
            v_hor_desde := v_hor_des_ori;
            v_hor_hasta := r_rel.hora;
            v_tipo_ant   := r_rel.tipo;
         end if;
         if  v_cod_turno is not null
         and to_char(v_hor_has_ori,'HH24:MI') = '23:59'
         and r_rel.tipo = 'E' then
            v_hor_hasta := v_hor_has_ori;
            v_hor_desde := r_rel.hora;
            v_tipo_ant   := 'S';
         end if;
      END IF;
      --- Se tiene un turno completo
      if v_hor_desde is not null and v_hor_hasta is not null THEN
         v_turno   := FALSE;
         --- Recuperar turno del dia
         BEGIN
            select to_date(to_char(v_fecha,'ddmmyyyy')||to_char(t.hor_desde,'hh24mi'),'ddmmyyyyhh24mi'),
                   to_date(to_char(v_fecha,'ddmmyyyy')||to_char(t.hor_hasta,'hh24mi'),'ddmmyyyyhh24mi')
            into   v_hor_des_tur, v_hor_has_tur
            from   rh_turnos t, rh_empleados e
            where  e.cod_persona = r_rel.cod_persona
            and    e.cod_turno = t.cod_turno
            and    t.dia_desde <= r_rel.dia
            and    t.dia_hasta >= r_rel.dia
            and    t.cod_turno = v_cod_turno;
-- dbms_output.put_line('Turno desde '||to_char(v_hor_des_tur,'HH24:MI')||' Hsta '||to_char(v_hor_has_tur,'HH24:MI'));
            --- Recuperar detalles del turno si existe
            v_vez_tur := 0;
            v_hor_des_det := v_hor_desde;
            v_hor_has_det := v_hor_hasta;
            FOR r_dtu in c_turnos LOOP
               if v_vez_tur = 0 then
                  v_exi_inicio := 'N';
               end if;
--dbms_output.put_line('Turno detalle desde '||to_char(r_dtu.hor_desde,'HH24:MI')||' Hsta '||to_char(r_dtu.hor_hasta,'HH24:MI'));
               v_turno := TRUE;
               if to_char(v_hor_des_det,'HH24:MI') < to_char(r_dtu.hor_hasta,'HH24:MI') then
                  if to_char(v_hor_des_det,'HH24:MI') < to_char(r_dtu.hor_desde,'HH24:MI') then
                     if v_vez_tur = 0 then
                        -- Verificar si existe hora extra entre la hora desde y la hora del turno
                        LP_PRO_HOR_EXTRA(v_cod_persona, v_fecha, v_hor_des_det, v_hor_has_det);
                        v_vez_tur := 1;
                     end if;
                     v_hor_des_prc := r_dtu.hor_desde;
                  else
                     --- Verificar tolerancia de entrada
                     v_tolerancia   := to_number(to_char(v_hor_des_det,'hh24mi')) -
                                       to_number(to_char(r_dtu.hor_desde,'hh24mi'));
                     if nvl(v_tolerancia,0) > nvl(r_epr.min_tolerancia,0) then
                        --- Llega tarde pero se le dan los minutos de tolerancia
--  dbms_output.put_line('Hora desde '||v_hor_des_det||' Tolerancia '||r_epr.min_tolerancia);
                        v_hor_des_det := fuh_obt_hora(v_hor_des_det, nvl(r_epr.min_tolerancia,0)*-1);
                     elsif nvl(v_tolerancia,0) > 0 then
                        --- Llega tarde pero no supera los minutos de tolerancia
                          v_hor_des_det := r_dtu.hor_desde;
                     end if;
                     v_hor_des_prc := v_hor_des_det;
                     --- Si las horas son menores a la de entrada colocar la de entrada
                     if v_hor_des_prc < r_dtu.hor_desde then
                        v_hor_des_prc := r_dtu.hor_desde;
                     end if;
                  end if;
                  if v_hor_has_det > r_dtu.hor_hasta then
                     v_hor_has_prc := r_dtu.hor_hasta;
                  else
                     v_hor_has_prc := v_hor_has_det;
                  end if;
                  --- Computar
                  if v_hor_has_prc >= v_hor_des_prc then
--dbms_output.put_line('Horas hasta '||to_char(v_hor_has_prc,'hh24mi')||' Desde '||to_char(v_hor_des_prc,'hh24mi'));
                     v_hor_trab := FUH_OBT_DIF_HORAS(to_char(v_hor_des_prc,'hh24:mi:ss'),to_char(v_hor_has_prc,'hh24:mi:ss'));
--dbms_output.put_line('Horas trab '||to_char(v_hor_trab));
                     --- Verificar si corresponde a feriado para calcular % horas
                     BEGIN
                        v_feriado := 'N';
                        select 'S' into v_feriado
                          from ba_feriados f
                         where f.fecha = r_rel.fecha;
                        exception
                          when no_data_found then null;
                     END;
                     -------------------------------------------
                     --- parametrizado para turno adminsitrativo
                     select cod_tur_administrativo
                     into   v_cod_tur_administrativo
                     from   rh_par_empresas
                     where  cod_empresa = r_rel.cod_per_empresa;
                     -------------------------------------------
                     if     v_feriado = 'S'
                     and    v_cod_tur_administrativo = v_cod_turno then
                        --- Administrativos no debe procesar los feriados por mas que marque
                        --- se cargarian como horas extras
                        v_hor_trab := 0;
                     end if;
                     if v_feriado = 'S' and r_rel.dia <> 1 then
                        --- Domingos y feriados tienen el mismo % de sueldo, se deja el del turno
                        --- Los horarios de feriados son:
                        --- de 00:00 a 06:00 130%
                        --- de 06:00 a 20:00 100%
                        r_dtu.por_sueldo := 100;
                        if to_char(v_hor_des_prc,'HH24MI') >= '2000' then
                           r_dtu.por_sueldo := 130;
                        end if;
                        if to_char(v_hor_has_prc,'HH24MI') <= '0600' then
                           r_dtu.por_sueldo := 130;
                        end if;
                     end if;
                      ----------------- INCLUIDO PARA EMPLEADOS CON ROTACION
                      ---- cuyo turno termina al dia siguiente
                      ---if  to_char(v_hora_has_prc,'HH24MI') = '2359' then
                      if v_exi_inicio = 'S' and v_exi_reloj = 0
                      and r_rel.tipo = 'E' then
                          --- Si no existe marcacion para el reloj en ese dia
                          --- y si el turno termina en 23:59
                          --- y si se esta procesando la entrada
                          if r_dtu.por_sueldo = 0 then
                             v_hor_normal_rot := v_hor_trab;
                          elsif r_dtu.por_sueldo = 30 then
                             v_hor_30por_rot  := v_hor_trab;
                          elsif r_dtu.por_sueldo = 50 then
                             v_hor_50por_rot  := v_hor_trab;
                          elsif r_dtu.por_sueldo = 100 then
                             v_hor_100por_rot := v_hor_trab;
                          elsif r_dtu.por_sueldo = 130 then
                             v_hor_130por_rot := v_hor_trab;
                          end if;
                          if v_hor_trab > 0 THEN
                              --- Insertar asistencia en el dia siguiente
                              r_asi.cod_persona    := v_cod_persona;
                              r_asi.fecha           := v_fecha+1;
                              r_asi.hor_normal     := v_hor_normal_rot;
                              r_asi.hor_30por      := v_hor_30por_rot;
                              r_asi.hor_50por      := v_hor_50por_rot;
                              r_asi.hor_100por     := v_hor_100por_rot;
                              r_asi.hor_130por     := v_hor_130por_rot;
                              lp_ins_asistencia(r_asi);
                              v_hor_normal_rot   := 0;
                              v_hor_30por_rot    := 0;
                              v_hor_50por_rot    := 0;
                              v_hor_100por_rot   := 0;
                              v_hor_130por_rot   := 0;
                              v_hor_trab         := 0;
                          end if;
                     end if;
                     ----------------- FIN EMPLEADOS CON ROTACION
                     ---
                     if r_dtu.por_sueldo = 0 then
                        v_hor_normal := v_hor_normal + v_hor_trab;
                     elsif r_dtu.por_sueldo = 30 then
                        v_hor_30por := v_hor_30por + v_hor_trab;
                     elsif r_dtu.por_sueldo = 50 then
                        v_hor_50por := v_hor_50por + v_hor_trab;
                     elsif r_dtu.por_sueldo = 100 then
                        v_hor_100por := v_hor_100por + v_hor_trab;
                     elsif r_dtu.por_sueldo = 130 then
                        v_hor_130por := v_hor_130por + v_hor_trab;
                     end if;
                  end if;
                  --- Corte de Control
                  v_hor_des_det := v_hor_has_prc;
--  dbms_output.put_line('Hora desde '||to_char(v_hor_des_det,'DDMMYYYY HH24MISS')||' hora hasta '||TO_CHAR(v_hor_has_det,'DDMMYYYY HH24MISS'));
                  if v_hor_des_det >= v_hor_has_det then
                     --- Salir del ciclo si no hay otros turnos que procesar
                     exit;
                  end if;
               end if;
            END LOOP;
            IF not v_turno THEN
--  dbms_output.put_line('Hora desde '||v_hor_des_tur||' Tolerancia '||r_epr.min_tolerancia);
               -- No existe detalle de turnos
               if v_hor_desde < v_hor_des_tur then
                  -- Verificar si existe hora extra entre la hora desde y la hora del turno
                  LP_PRO_HOR_EXTRA(v_cod_persona, v_fecha, v_hor_des_tur, v_hor_has_tur);
                  v_hor_des_prc := v_hor_des_tur;
               else
                  --- Verificar tolerancia de entrada
                  v_tolerancia   := to_number(to_char(v_hor_desde,'hh24mi')) -
                                    to_number(to_char(v_hor_des_tur,'hh24mi'));
-- dbms_output.put_line('Tolerancia calculada '||v_tolerancia);
                  if nvl(v_tolerancia,0) > nvl(r_epr.min_tolerancia,0) then
                     --- Llega tarde pero se le dan los minutos de tolerancia
                     v_hor_desde := fuh_obt_hora(v_hor_desde, nvl(r_epr.min_tolerancia,0)*-1);
                  elsif nvl(v_tolerancia,0) > 0 then
                     --- Llega tarde pero no supera los minutos de tolerancia
--  dbms_output.put_line('1.3.'||to_char(v_hor_desde,'hh24mi')||' Calc '||lpad(to_char(to_number(to_char(v_hor_desde,'hh24mi'))+nvl(v_tolerancia,0)),4,'0'));
                     v_hor_desde := v_hor_des_tur;
                  end if;
                  v_hor_des_prc := v_hor_desde;
                  --- Si las horas son menores a la de entrada colocar la de entrada
                  if v_hor_des_prc < v_hor_des_tur then
                     v_hor_des_prc := v_hor_des_tur;
                  end if;
               end if;
               if v_hor_hasta > v_hor_has_tur then
                  -- Verificar si existe hora extra entre la hora del turno y la hora hasta
                  LP_PRO_HOR_EXTRA(v_cod_persona, v_fecha, v_hor_des_tur, v_hor_has_tur);
                  v_hor_has_prc := v_hor_has_tur;
               else
                  v_hor_has_prc := v_hor_hasta;
               end if;
               v_hor_trab := FUH_OBT_DIF_HORAS(to_char(v_hor_des_prc,'hh24:mi:ss'), to_char(v_hor_has_prc,'hh24:mi:ss'));
               BEGIN
                  v_feriado := 'N';
                  select 'S' into v_feriado
                    from ba_feriados f
                   where f.fecha = r_rel.fecha;
                  exception
                    when no_data_found then null;
               END;
               -------------------------------------------
               --- parametrizado para turno adminsitrativo
               select cod_tur_administrativo
               into   v_cod_tur_administrativo
               from   rh_par_empresas
               where  cod_empresa = r_rel.cod_per_empresa;
               -------------------------------------------
               if     v_feriado = 'S'
               and    v_cod_tur_administrativo = v_cod_turno then
               /*and (  (r_rel.cod_per_empresa = '01' and v_cod_turno = 6)
                   or (r_rel.cod_per_empresa = '02' and v_cod_turno in (10,11))) then*/
                  --- Administrativos no debe procesar los feriados por mas que marque
                  --- se cargarian como horas extras
                  v_hor_trab := 0;
               end if;
               if v_feriado = 'S' and r_rel.dia <> 1 then
                  --- Domingos y feriados tienen el mismo % de sueldo, se deja el del turno
                  --- Los horarios de feriados son:
                  --- de 00:00 a 06:00 130%
                  --- de 06:00 a 20:00 100%
                  v_hor_100por := v_hor_100por + v_hor_trab;
                  if to_char(v_hor_des_prc,'HH24MI') >= '2000' then
                     v_hor_130por := v_hor_130por + v_hor_trab;
                  end if;
                  if to_char(v_hor_has_prc,'HH24MI') <= '0600' then
                     v_hor_130por := v_hor_130por + v_hor_trab;
                  end if;
                  v_hor_trab := 0;
               end if;
               v_hor_normal := v_hor_normal + v_hor_trab;
            ELSE
               if v_hor_hasta > v_hor_has_prc then
                  -- Verificar si existe hora extra entre la hora del turno y la hora hasta
                  LP_PRO_HOR_EXTRA(v_cod_persona, v_fecha, v_hor_des_prc, v_hor_has_prc);
               end if;
            END IF;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               --- No existe turno Verificar si existe hora extra
               --- Computar hora extra
               -- Verificar si existe hora extra entre la hora del turno y la hora hasta
               LP_PRO_HOR_EXTRA(v_cod_persona, v_fecha, v_hor_desde, v_hor_hasta);
            WHEN too_many_rows THEN
               raise_application_error(-20000,
               'Existe más de un turno del dia '||r_rel.dia||' turno '||v_cod_turno||' del Empleado '||r_rel.cod_persona);
         END;
         --- Actualizar reloj
/*dbms_output.put_line('Actualizo '||to_char(r_rel.fecha,'dd/mm/yyyy')
                     ||' Desde '||to_char(v_hor_desde,'hh24:mi')
                     ||' Hasta '||to_char(v_hor_hasta,'hh24:mi')
                     ||' Empleado '||r_rel.cod_persona);*/
         update rh_relojes
         set ind_procesado = 'S'
         where cod_persona = r_rel.cod_persona
         and fecha = r_rel.fecha
         and tipo = r_rel.tipo;
         /*and (to_char(hora,'HH24:MI') = to_char(v_hor_desde,'HH24:MI') 
              or
              to_char(hora,'HH24:MI') = to_char(v_hor_hasta,'HH24:MI'))*/
         IF sql%notfound then
            v_procesado := FALSE;
         else
            v_procesado := TRUE;
         end if;
         --- Corte de control
         v_tipo_ant    := r_rel.tipo;
         v_ult_dia_pro := r_rel.dia;
         v_hor_desde   := null;
         v_hor_hasta   := null;
      END IF;
   END LOOP;
   --- PARA EL ULTIMO REGISTRO DE EMPLEADO
   if (v_hor_normal > 0 OR v_hor_30por > 0 or v_hor_50por > 0
   or v_hor_100por > 0 or v_hor_130por > 0)THEN
      --- Insertar asistencia
      r_asi.cod_persona    := v_cod_persona;
      r_asi.fecha          := v_fecha;
      r_asi.hor_normal     := v_hor_normal;
      r_asi.hor_30por      := v_hor_30por;
      r_asi.hor_50por      := v_hor_50por;
      r_asi.hor_100por     := v_hor_100por;
      r_asi.hor_130por     := v_hor_130por;
      lp_ins_asistencia(r_asi);
      --------------------------------------------
   end if;
   -------------------------------------
   exception
      when others then
        raise_application_error(-20000,
        'Act.Reloj '||v_cod_persona||' Fecha '||v_fecha||' '||sqlerrm);
END;
/
