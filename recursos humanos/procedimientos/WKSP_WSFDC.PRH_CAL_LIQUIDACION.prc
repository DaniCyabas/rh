CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_CAL_LIQUIDACION
 (
    P_COD_EPR_DESDE IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
    P_COD_EPR_HASTA IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
  /*,P_ANO_PROCESO IN RH_PAR_EMPRESAS.ANO_ACTUAL%TYPE
   ,P_MES_PROCESO IN RH_PAR_EMPRESAS.MES_ACTUAL%TYPE
   ,P_QUINCENA_PROCESO IN RH_PAR_EMPRESAS.QUI_ACTUAL%TYPE*/
   P_FEC_PROCESO IN RH_SOBRES.FEC_CALCULO%TYPE,
   P_COD_EMP_DESDE IN RH_EMPLEADOS.COD_PERSONA%TYPE,
   P_COD_EMP_HASTA IN RH_EMPLEADOS.COD_PERSONA%TYPE,
   --,P_CHEQUE_DESDE IN RH_CHEQUES.CHEQUE%TYPE
   P_ACTUALIZA_EMPRESA IN VARCHAR2,
   P_NRO_SOBRE IN RH_SOBRES.NRO_SOBRE%TYPE,
   P_TIP_EMPLEADO IN VARCHAR2 := 'A'
 )
 IS
/* Recuperar fecha maxima de liquidacion --- Solo destajistas */
FUNCTION LF_OBT_MAX_FEC_LIQ
 (P_COD_EMPLEADO IN RH_SOBRES.COD_PERSONA%TYPE
 )
 RETURN DATE;
/* Suma de salarios del mes */
FUNCTION LF_SUM_SAL_MES
 (
 P_COD_EMPLEADO IN RH_SOBRES.COD_PERSONA%TYPE,
 P_FEC_DESDE IN RH_SOBRES.FEC_CALCULO%TYPE,
 P_FEC_HASTA IN RH_SOBRES.FEC_CALCULO%TYPE
 )
 RETURN NUMBER;
FUNCTION LF_REC_PER_VACACION
 (P_TRABAJADOS IN RH_PER_VACACIONES.ANO_DESDE%TYPE
 )
 RETURN NUMBER;
   r_emr                 rh_par_empresas%rowtype;
   r_liq                 rh_liq_sueldos%rowtype;
   r_tip_ing             rh_tip_ingresos%rowtype;
   r_tip_des             rh_tip_descuentos%rowtype;
   r_prov                rh_provisiones%rowtype;
 --r_che                 rh_cheques%rowtype;
   r_sob                 rh_sobres%rowtype;
   v_fecha_proceso       rh_par_empresas.fec_ult_cierre%type;
   v_fecha_ult_proceso   rh_par_empresas.fec_ult_cierre%type;
   v_dias_mes            NUMBER(02);
   v_dias_trabajados     NUMBER(02);
   v_hora_trabajadas     rh_liq_sueldos.hor_computable%type;
   v_h30_trabajadas      rh_liq_sueldos.hor_computable%type;
   v_h50_trabajadas      rh_liq_sueldos.hor_computable%type;
   v_h100_trabajadas     rh_liq_sueldos.hor_computable%type;
   v_h130_trabajadas     rh_liq_sueldos.hor_computable%type;
   v_dias_ausencias      NUMBER(02);
   v_dias_aus_injus      NUMBER(02);
--   v_fec_inicio          rh_ausencias.fec_inicio%type;
--   v_fec_final           rh_ausencias.fec_final%type;
   v_salario_empleado    rh_empleados.sal_base%type;
   v_salario_30porc      rh_empleados.sal_base%type;
   v_salario_50porc      rh_empleados.sal_base%type;
   v_salario_100porc     rh_empleados.sal_base%type;
   v_salario_130porc     rh_empleados.sal_base%type;
   v_salario_bonificacion rh_empleados.sal_base%type;
   v_sal_bonificacion_dis rh_empleados.sal_base%type;
   v_can_hijos_dis        number;
   v_salario_vacacion    rh_empleados.sal_base%type;
   v_salario_extra       rh_empleados.sal_base%type;
   v_cod_empleado        rh_empleados.cod_persona%type;
   v_monto_aporte        rh_liq_sueldos.monto%type;
   v_monto_fondo         rh_liq_sueldos.monto%type;
   v_monto_aguinaldo     rh_liq_sueldos.monto%type;
   v_monto_descuento     rh_liq_sueldos.monto%type;
   v_monto_judicial      rh_liq_sueldos.monto%type;
-- v_cheque              rh_cheques.cheque%type;
   v_saldo_salario       rh_empleados.sal_base%type;
   v_cod_empresa         rh_par_empresas.cod_empresa%type;
   v_max_fec_sob_emp     rh_sobres.fec_calculo%type;
   v_fec_ult_liq         date;
   v_dias_vaca           number(03);
   v_vac_dia_habil       number(03);
   v_sal_vacacion        rh_liq_sueldos.monto%type;
   ----------------------------------
   --- parametrizar empresa principal
   v_emp_principal        ge_par_generales.cod_persona%type;
   --- verificar hijos en vínculos
   v_ind_hijos            varchar2(1);
   --- variables de periodos
   V_ANO_PROCESO          RH_PAR_EMPRESAS.ANO_ACTUAL%TYPE;
   V_MES_PROCESO          RH_PAR_EMPRESAS.MES_ACTUAL%TYPE;
   V_QUINCENA_PROCESO     RH_PAR_EMPRESAS.QUI_ACTUAL%TYPE;
   V_DIA_PROCESO          NUMBER(02);
   ----------------------------------
   --- Cursor de empleados en base a parámetros
   CURSOR c_emp IS
      Select e.cod_per_empresa, e.cod_persona, e.fre_liquidacion, e.ind_jub_ips,
             e.sal_base, e.cod_moneda, e.tipo, --e.ind_hijos,
             e.fec_ingreso, --e.ind_pago,
             pag_gen.fu_con_mon_a_moneda(m.cod_moneda, e.cod_moneda, nvl(m.monto,0)) monto,
             e.cod_cen_costo, e.cod_oficina, e.nro_ips, e.nro_caja
      from rh_empleados e, rh_sal_minimos m
      where e.cod_sal_minimo = m.cod_sal_minimo
      and e.cod_per_empresa >= p_cod_epr_desde
      and e.cod_per_empresa <= p_cod_epr_hasta
      and e.cod_persona >= p_cod_emp_desde
      and e.cod_persona <= p_cod_emp_hasta
   /* and (e.tip_empleado <> 'Z'
           or (e.tip_empleado = 'Z'
               and nvl(e.fec_fin_zafra,v_fecha_proceso) >= v_fecha_proceso))*/
      and (e.fre_liquidacion = decode(v_quincena_proceso,1,'Q',2,'Q') or
           e.fre_liquidacion = decode(v_quincena_proceso,2,'M') or
           e.fre_liquidacion = decode(v_quincena_proceso,1,'S',2,'S'))
      and (e.tipo = p_tip_empleado or p_tip_empleado = 'A')
      and e.fec_egreso IS NULL; --- Que no procese los dados de baja
   --- Cursor de ausencias del empleado para el periodo
   CURSOR c_ausencias IS
      select a.fec_inicio, a.fec_fin,
         --trunc(a.fec_fin-a.fec_inicio+1) dias,
         --En Bco. Regional se tiene en cuenta los días hábiles
           trunc(fuh_obt_dif_dias(a.fec_inicio,a.fec_fin+1)) dias,
           t.por_sueldo, a.cod_tip_ausencia
      from rh_ausencias a, rh_tip_ausencias t
      where a.cod_persona = v_cod_empleado
      and a.cod_tip_ausencia = t.cod_tip_ausencia
      and t.ind_goc_sueldo = 'S'
      and trunc(a.fec_inicio) > v_fecha_ult_proceso
      and trunc(a.fec_fin) <= v_fecha_proceso;
   --- Cursor de Ingresos adicionales del empleado
   CURSOR c_ingresos IS
      select i.numero, i.cod_tip_ingreso,
       pag_gen.fu_con_mon_a_moneda(i.cod_moneda, e.cod_moneda, nvl(i.monto,0)) monto,
       e.cod_moneda, i.fecha
      from rh_ingresos i, rh_tip_ingresos t, rh_par_empresas p, rh_empleados e
      where i.cod_tip_ingreso = t.cod_tip_ingreso
      and e.cod_persona  = i.cod_persona
      and i.fecha        > v_fecha_ult_proceso
      and i.fecha        <= v_fecha_proceso
      and i.cod_persona  = v_cod_empleado
      and p.cod_empresa  = v_cod_empresa
      and i.cod_per_autorizador IS NOT NULL
      and i.ind_procesado = 'N'
      and i.cod_tip_ingreso <> p.cod_tip_ing_sueldo
      and i.cod_tip_ingreso <> p.cod_tip_ing_vacacion
      and i.cod_tip_ingreso <> p.cod_tip_ing_bonificacion
      and i.cod_tip_ingreso <> p.cod_tip_ing_extras;
   --- Cursor de Descuentos adicionales del empleado
   CURSOR c_descuentos IS
      select d.numero, d.cod_tip_descuento, t.tipo,
       pag_gen.fu_con_mon_a_moneda(d.cod_moneda, e.cod_moneda, nvl(d.monto,0)) monto,
       e.cod_moneda, d.porcentaje, d.fecha
      from rh_descuentos d, rh_tip_descuentos t, rh_par_empresas p, rh_empleados e
      where d.cod_tip_descuento = t.cod_tip_descuento
      and e.cod_persona  = d.cod_persona
      --- and d.fecha      >= v_fecha_proceso
      --- COMENTADO por si existen descuentos
      --- De meses anteriores que no se procesaron
      and d.cod_persona = v_cod_empleado
      and p.cod_empresa  = v_cod_empresa
      and p.cod_tip_des_ips <> t.cod_tip_descuento
      and d.ind_procesado = 'N'
      order by t.prioridad;
   --- Cursor de horas extras del empleado
   CURSOR c_extras IS
      select HOR_TRABAJADA cant_horas,
             fecha, por_sueldo
      from rh_hor_extras
      where cod_persona = v_cod_empleado
      and ind_procesado = 'N'
      and cod_per_autorizador IS NOT NULL
      and fecha > v_fecha_ult_proceso
      and fecha <= v_fecha_proceso;
   --- Cursor de vacaciones
   CURSOR c_vacaciones IS
      select nvl(monto,0) monto, cod_moneda, nvl(can_dias,0) can_dia_habil, fec_desde
      from rh_vacaciones
      where cod_persona = v_cod_empleado
      and fec_desde > v_fecha_ult_proceso
      and fec_desde <= v_fecha_proceso
      and cod_per_autorizador IS NOT NULL;
/* Recuperar fecha maxima de liquidacion --- Solo destajistas */
FUNCTION LF_OBT_MAX_FEC_LIQ
 (P_COD_EMPLEADO IN RH_SOBRES.COD_PERSONA%TYPE
 )
 RETURN DATE
 IS
v_fec_liquidacion rh_sobres.fec_calculo%type;
BEGIN
   select max(fec_calculo)
     into v_fec_liquidacion
     from rh_sobres
    where cod_persona = p_cod_empleado
      and fec_calculo < p_fec_proceso; --- por si es una liquidacion ya existe sobre
   return v_fec_liquidacion;
exception
   when no_data_found then
      return v_fec_liquidacion;
END;
/* Suma de salarios del mes */
FUNCTION LF_SUM_SAL_MES
 (P_COD_EMPLEADO IN RH_SOBRES.COD_PERSONA%TYPE
 ,P_FEC_DESDE IN RH_SOBRES.FEC_CALCULO%TYPE
 ,P_FEC_HASTA IN RH_SOBRES.FEC_CALCULO%TYPE
 )
 RETURN NUMBER
 IS
v_mto_salario rh_liq_sueldos.monto%type;
BEGIN
   select nvl(sum(nvl(pag_gen.fu_con_mon_a_moneda(l.cod_moneda, e.cod_moneda, nvl(l.monto,0)),0)),0)
     into v_mto_salario
     from rh_sobres s, rh_liq_sueldos l, rh_tip_ingresos i, rh_empleados e
    where s.cod_persona = p_cod_empleado
      and s.cod_persona = e.cod_persona
      and s.fec_calculo > p_fec_desde
      and s.fec_calculo <= p_fec_hasta
      and s.cod_persona  = l.cod_persona
      and s.nro_sobre = l.nro_sobre
      and l.cod_tip_ingreso = i.cod_tip_ingreso
      and i.ind_imponible = 'S';
   return v_mto_salario;
END;
FUNCTION LF_REC_PER_VACACION
 (P_TRABAJADOS IN RH_PER_VACACIONES.ANO_DESDE%TYPE
 )
 RETURN NUMBER
 IS
v_dias_vaca rh_per_vacaciones.dias_vacaciones%type;
BEGIN
   Select nvl(dias_vacaciones,0)
   into v_dias_vaca
   from rh_per_vacaciones
   where ano_desde <= p_trabajados
   and ano_hasta >= p_trabajados;
   return v_dias_vaca;
exception
   when no_data_found then
      return 0;
END;
BEGIN
   v_fecha_proceso     := p_fec_proceso;
 --v_cheque            := p_cheque_desde;
   select to_number(to_char(v_fecha_proceso,'yyyy')) ano,
          to_number(to_char(v_fecha_proceso,'mm'))   mes,
          to_number(to_char(v_fecha_proceso,'dd'))   dia
   into   v_ano_proceso, v_mes_proceso, V_DIA_PROCESO
   from dual;
   if V_DIA_PROCESO > 15 then
      v_quincena_proceso := 2;
   else
      v_quincena_proceso := 1;
   end if;
   --- Recorrer empleados a liquidar
   FOR r_emp IN c_emp LOOP
      prh_obt_empresa(r_emp.cod_per_empresa, r_emr);
      v_cod_empresa       := r_emp.cod_per_empresa;
      --- Verificar que se halla cerrado la liquidacion
      v_fec_ult_liq := fuh_rec_ult_liq(r_emp.cod_per_empresa);
    /*if v_fec_ult_liq < p_fec_proceso and nvl(p_actualiza_empresa,'N') = 'S' then
         raise_application_error(-20000,
         'No se ha cerrado aun la liquidacion de la empresa '||r_emp.cod_empresa);
      end if;*/
      v_fecha_ult_proceso := nvl(r_emr.fec_ult_cierre,to_date('01/01/2000','DD/MM/YYYY'));
      v_max_fec_sob_emp   := lf_obt_max_fec_liq(r_emp.cod_persona);
      if nvl(v_max_fec_sob_emp,v_fecha_ult_proceso) > v_fecha_ult_proceso then
         --- Para casos de destajistas cobran semanalmente
         v_fecha_ult_proceso := v_max_fec_sob_emp;
      end if;
dbms_output.put_line('entro liquidacion '||v_fecha_ult_proceso||' '||v_fecha_proceso);
      v_cod_empleado      := r_emp.cod_persona;
      r_sob.nro_sobre     := p_nro_sobre;
      r_sob.cod_persona   := r_emp.cod_persona;
      r_sob.ano           := v_ano_proceso;
      r_sob.mes           := v_mes_proceso;
      r_sob.quincena      := v_quincena_proceso;
      r_sob.fec_calculo   := p_fec_proceso;
      -------------------------------------
      --- obtener empresa principal
      select p.cod_persona
      into   v_emp_principal
      from   ge_par_generales p;
      -------------------------------------
      if (r_emr.ind_apo_ips_caja = 'I' or 
         (r_emr.ind_apo_ips_caja = 'A' and r_emp.nro_ips is not null)) then
        if r_emp.tipo = 'A' and r_emr.cod_empresa <> v_emp_principal then ---'01'
           r_sob.nro_patronal := r_emr.pat_ips_02;
        else
           r_sob.nro_patronal := r_emr.pat_ips_01;
        end if;
      elsif (r_emr.ind_apo_ips_caja = 'C' or 
            (r_emr.ind_apo_ips_caja = 'A' and r_emp.nro_caja is not null)) then
           --r_sob.nro_patronal := nvl(fug_obt_pardinamico('NRO_PAT_MJT',null,null,null,r_emp.cod_oficina),fug_obt_pardinamico('NRO_PAT_MJT',null,null,null,11));
             r_sob.nro_patronal := r_emr.cod_ban_caja;
      end if;
      
      r_liq.cod_persona       := r_emp.cod_persona;
      r_liq.nro_sobre         := p_nro_sobre;
      r_liq.cod_cen_costo     := r_emp.cod_cen_costo;
      r_liq.cod_moneda        := r_emp.cod_moneda;
      r_liq.vac_fec_desde     := null;
      r_liq.ing_numero        := null;
      r_liq.cod_tip_ingreso   := null;
      r_liq.cod_tip_descuento := null;
      r_liq.hex_fec_hor_extra := null;
      r_liq.des_numero        := null;
      --- Inicializar variables del calculo
      v_dias_ausencias       := 0;
      v_dias_trabajados      := 0;
      v_monto_aporte         := 0;
      v_monto_fondo          := 0;
      v_monto_aguinaldo      := 0;
      v_monto_descuento      := 0;
      v_monto_judicial       := 0;
      v_salario_empleado     := 0;
      v_saldo_salario        := 0;
      v_salario_extra        := 0;
      v_salario_vacacion     := 0;
      v_salario_bonificacion := 0;
      IF r_emp.tipo = 'M' THEN -- CALCULAR SALARIO PARA MENSUALEROS
         v_dias_mes := to_number(to_char(v_fecha_proceso,'DD'));
         --- Recuperar dias trabajados por el empleado
         --- select count(*) into v_dias_trabajados --- Modificado porque se carga el total de horas
         --- Mientras no se implementa el tema del reloj.
         select nvl(sum(nvl(hor_normal,0)),0),
                nvl(sum(nvl(HOR_30POR,0)),0),
                nvl(sum(nvl(hor_50por,0)),0),
                nvl(sum(nvl(HOR_100POR,0)),0),
                nvl(sum(nvl(hor_130por,0)),0)
           into v_hora_trabajadas, v_h30_trabajadas,
                v_h50_trabajadas, v_h100_trabajadas, v_h130_trabajadas
           from rh_asistencias a
          where cod_persona = r_emp.cod_persona
            and fecha > v_fecha_ult_proceso
            and fecha <= v_fecha_proceso;
         --- Calcular ausencias totales para descontar de los dias trabajados
         begin
          --select nvl(sum(round(nvl(a.fec_fin-a.fec_inicio+1,0),0)),0)
          --En Bco. Regional se tiene en cuenta los días hábiles
            select nvl(sum(round(nvl(fuh_obt_dif_dias(a.fec_inicio,a.fec_fin+1),0),0)),0)
              into v_dias_aus_injus
              from rh_ausencias a, rh_tip_ausencias t
             where a.cod_persona = v_cod_empleado
               and a.cod_tip_ausencia = t.cod_tip_ausencia
               ---and t.ind_goc_sueldo = 'N'
               and trunc(a.fec_fin) > v_fecha_ult_proceso
               and trunc(a.fec_fin) <= v_fecha_proceso;
         end;
         --- Actualizar ausencias injustificadas
         update rh_ausencias
            set ind_procesado = 'S'
          where cod_persona = v_cod_empleado
            and exists (select 1 from rh_tip_ausencias t
                         where rh_ausencias.cod_tip_ausencia = t.cod_tip_ausencia
                           and t.ind_goc_sueldo = 'N')
            and trunc(fec_fin) > v_fecha_ult_proceso
            and trunc(fec_fin) <= v_fecha_proceso;
         --- Calcular dias trabajados del mensualero sin ausencias
         v_dias_trabajados  := v_dias_mes - v_dias_aus_injus;
         if to_char(r_emp.fec_ingreso,'YYYYMM') = to_char(v_fecha_proceso,'YYYYMM') then
            --- Colocar como ausencias los dias que no trabajo por ingresar a mediados del mes
            v_dias_aus_injus := v_dias_aus_injus + (r_emp.fec_ingreso - to_date('01'||to_char(r_emp.fec_ingreso,'MMYYYY'),'DDMMYYYY'));
         end if;
         v_salario_empleado := nvl(r_emp.sal_base,0) - round((r_emp.sal_base/30)*v_dias_aus_injus,0);
         if v_salario_empleado < 0 then
            v_salario_empleado := 0;
         end if;
         --- Salario normal extra
         v_salario_30porc  := round(nvl(r_emp.sal_base,0)/240 * 0.30 * v_h30_trabajadas,0);
         v_salario_50porc  := round(nvl(r_emp.sal_base,0)/240 * 1.50 * v_h50_trabajadas,0);
         v_salario_100porc := round(nvl(r_emp.sal_base,0)/240 * 2    * v_h100_trabajadas,0);
         v_salario_130porc := round(nvl(r_emp.sal_base,0)/240 * 2.3  * v_h130_trabajadas,0);
         --- Ajustar dias trabajados para los listados
         if  v_dias_mes < to_number(to_char(last_day(v_fecha_proceso),'DD'))
         and v_fecha_proceso <> last_day(v_fecha_proceso) then
            --- Solo cuando es por liquidacion final del empleado
            --v_dias_trabajados  := v_dias_mes - v_dias_aus_injus;
            v_salario_empleado := round((r_emp.sal_base/30)*v_dias_trabajados,0);
       /*else
            --- Cierre normal de liquidacion
            v_dias_trabajados := 30 - v_dias_aus_injus;*/
            --- se comenta en Regional porque en los listados deben salir todos los dias del mes
         end if;
      ELSIF r_emp.tipo IN ('Z', 'D', 'J') THEN --- CALCULAR SALARIO PARA JORNALEROS
         select count(*),
                nvl(sum(nvl(hor_normal,0)),0),
                nvl(sum(nvl(HOR_30POR,0)),0),
                nvl(sum(nvl(hor_50por,0)),0),
                nvl(sum(nvl(HOR_100POR,0)),0),
                nvl(sum(nvl(hor_130por,0)),0),
                round(nvl(sum(((nvl(hor_normal,0)/8)*r_emp.sal_base)),0),0),
                round(nvl(sum((nvl(hor_30por,0)/8*(r_emp.sal_base+(r_emp.sal_base*30/100)))),0),0),
                round(nvl(sum((nvl(hor_50por,0)/8*(r_emp.sal_base+(r_emp.sal_base*50/100)))),0),0),
                round(nvl(sum((nvl(hor_100por,0)/8*(r_emp.sal_base+r_emp.sal_base))),0),0),
                round(nvl(sum((nvl(hor_130por,0)/8*(r_emp.sal_base+(r_emp.sal_base*130/100)))),0),0)
           into v_dias_trabajados, v_hora_trabajadas, v_h30_trabajadas,
                v_h50_trabajadas, v_h100_trabajadas, v_h130_trabajadas,
                v_salario_empleado, v_salario_30porc, v_salario_50porc,
                v_salario_100porc, v_salario_130porc
         from rh_asistencias
         where cod_persona = v_cod_empleado
         and fecha > v_fecha_ult_proceso
         and fecha <= v_fecha_proceso;
      ELSIF r_emp.tipo = 'X' THEN --- CALCULO PARA ZAFRISTAS
         --- Es directo por horas trabajadas ver si es igual al anterior
         NULL;
      END IF;
      --- Procesar ausencias justificadas
      for aus in c_ausencias loop
         IF r_emp.tipo = 'M' THEN
            v_salario_empleado := v_salario_empleado + round((nvl(r_emp.sal_base,0)/30 * aus.dias) * (aus.por_sueldo/100),0);
            v_dias_trabajados  := v_dias_trabajados + aus.dias;
            v_hora_trabajadas  := v_hora_trabajadas + (aus.dias * 8);
         ELSIF r_emp.tipo IN ('Z', 'D', 'J') THEN
            v_salario_empleado := v_salario_empleado + round((nvl(r_emp.sal_base,0) * aus.dias) * (aus.por_sueldo/100),0);
            v_dias_trabajados  := v_dias_trabajados + aus.dias;
            v_hora_trabajadas  := v_hora_trabajadas + (aus.dias * 8);
         END IF;
         --- Actualizar a procesado
         update rh_ausencias
            set ind_procesado = 'S'
          where cod_persona = v_cod_empleado
            and fec_inicio = aus.fec_inicio
            and ind_procesado = 'N';
      end loop;
      if nvl(v_salario_empleado,0) > 0 or nvl(v_dias_trabajados,0) > 0 then
          r_liq.computable := v_dias_trabajados;
          r_liq.hor_computable := v_hora_trabajadas;
          --- Generar cabeceras de la liquidación (SOBRE)
          --- Recuperar tipo de mvto del ingreso
          prh_obt_tip_ingreso(r_emr.cod_tip_ing_sueldo, r_tip_ing);
          --- Insertar registro de liquidación del empleado por SALARIO
          r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_sueldo;
          r_liq.cod_moneda      := r_emp.cod_moneda;
        --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
        --modificado para obtener la transaccion
          r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
          r_liq.cod_modulo      := r_tip_ing.cod_modulo;
          r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
        --fin modificaciones
          r_liq.monto           := v_salario_empleado;
          IF nvl(r_liq.monto,0) > 0 or nvl(r_liq.computable,0) > 0 THEN
             --- Debe igual salir la linea si tiene asistencia
             if r_liq.nro_sobre is null then
                prh_ins_sobre(r_sob, r_liq.nro_sobre);
             end if;
    dbms_output.put_line('salario');
             v_saldo_salario := nvl(v_saldo_salario,0) + nvl(r_liq.monto,0);
             prh_ins_liq_sueldo(r_liq);
          END IF;
          --- Acumular Aporte---
          IF r_tip_ing.ind_imponible = 'S' and nvl(v_salario_empleado,0) > 0 THEN
             if r_emr.ind_apo_ips_caja = 'I' then --- acumula aporte para IPS
                v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
             elsif r_emr.ind_apo_ips_caja = 'C' then --- acumula aporte para la Caja
                v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp, nvl(r_emr.por_caj_emp,0)),0);
                v_monto_fondo  := nvl(v_monto_fondo,0)  + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp_act, nvl(r_emr.por_caj_emp_act,0)),0);
             else
                v_monto_aporte := 0;
             end if;
          END IF;
          --- Acumular Aguinaldo a provisionar
          IF r_tip_ing.ind_acu_aguinaldo = 'S' and nvl(v_salario_empleado,0) > 0 THEN
             v_monto_aguinaldo := nvl(v_monto_aguinaldo,0) + round(nvl(v_salario_empleado,0) / 12,0);
          END IF;
      END IF;
      IF nvl(v_salario_30porc,0) > 0 then
          r_liq.computable     := v_dias_trabajados;
          r_liq.hor_computable := v_h30_trabajadas;
          --- Generar cabeceras de la liquidación (SOBRE)
          --- Recuperar tipo de mvto del ingreso
          prh_obt_tip_ingreso(r_emr.cod_tip_ing_30, r_tip_ing);
          --- Insertar registro de liquidación del empleado por SALARIO
          r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_30;
          r_liq.cod_moneda      := r_emp.cod_moneda;
        --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
        --modificado para obtener la transaccion
          r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
          r_liq.cod_modulo      := r_tip_ing.cod_modulo;
          r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
        --fin modificaciones
          r_liq.monto           := v_salario_30porc;
          IF nvl(r_liq.monto,0) > 0 THEN
             if r_liq.nro_sobre is null then
                prh_ins_sobre(r_sob, r_liq.nro_sobre);
             end if;
    dbms_output.put_line('salario');
             v_saldo_salario := nvl(v_saldo_salario,0) + nvl(r_liq.monto,0);
             prh_ins_liq_sueldo(r_liq);
          END IF;
          --- Acumular Aporte---
          IF r_tip_ing.ind_imponible = 'S' and nvl(v_salario_30porc,0) > 0 THEN
             if r_emr.ind_apo_ips_caja = 'I' then --- acumula aporte para IPS
                v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_30porc,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
             elsif r_emr.ind_apo_ips_caja = 'C' then --- acumula aporte para la Caja
                v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_30porc,0) * nvl(r_emr.por_caj_emp, nvl(r_emr.por_caj_emp,0)),0);
                v_monto_fondo  := nvl(v_monto_fondo,0)  + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp_act, nvl(r_emr.por_caj_emp_act,0)),0);
             else
                v_monto_aporte := 0;
             end if;
          END IF;
          --- Acumular Aguinaldo a provisionar
          IF r_tip_ing.ind_acu_aguinaldo = 'S' and nvl(v_salario_30porc,0) > 0 THEN
             v_monto_aguinaldo := nvl(v_monto_aguinaldo,0) + round(nvl(v_salario_30porc,0) / 12,0);
          END IF;
      END IF;
      IF nvl(v_salario_50porc,0) > 0 then
          r_liq.computable := v_dias_trabajados;
          r_liq.hor_computable := v_h50_trabajadas;
          --- Generar cabeceras de la liquidación (SOBRE)
          --- Recuperar tipo de mvto del ingreso
          prh_obt_tip_ingreso(r_emr.cod_tip_ing_50, r_tip_ing);
          --- Insertar registro de liquidación del empleado por SALARIO
          r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_50;
          r_liq.cod_moneda      := r_emp.cod_moneda;
        --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
        --modificado para obtener la transaccion
          r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
          r_liq.cod_modulo      := r_tip_ing.cod_modulo;
          r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
        --fin modificaciones
          r_liq.monto           := v_salario_50porc;
          IF nvl(r_liq.monto,0) > 0 THEN
             if r_liq.nro_sobre is null then
                prh_ins_sobre(r_sob, r_liq.nro_sobre);
             end if;
    dbms_output.put_line('salario');
             v_saldo_salario := nvl(v_saldo_salario,0) + nvl(r_liq.monto,0);
             prh_ins_liq_sueldo(r_liq);
          END IF;
          --- Acumular Aporte---
          IF r_tip_ing.ind_imponible = 'S' and nvl(v_salario_50porc,0) > 0 THEN
             if r_emr.ind_apo_ips_caja = 'I' then --- acumula aporte para IPS
                v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_50porc,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
             elsif r_emr.ind_apo_ips_caja = 'C' then --- acumula aporte para la Caja
                v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_50porc,0) * nvl(r_emr.por_caj_emp, nvl(r_emr.por_caj_emp,0)),0);
                v_monto_fondo  := nvl(v_monto_fondo,0)  + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp_act, nvl(r_emr.por_caj_emp_act,0)),0);
             else
                v_monto_aporte := 0;
             end if;
          END IF;
          --- Acumular Aguinaldo a provisionar
          IF r_tip_ing.ind_acu_aguinaldo = 'S' and nvl(v_salario_50porc,0) > 0 THEN
             v_monto_aguinaldo := nvl(v_monto_aguinaldo,0) + round(nvl(v_salario_50porc,0) / 12,0);
          END IF;
      END IF;
      IF nvl(v_salario_100porc,0) > 0 then
          r_liq.computable := v_dias_trabajados;
          r_liq.hor_computable := v_h100_trabajadas;
          --- Generar cabeceras de la liquidación (SOBRE)
          --- Recuperar tipo de mvto del ingreso
          prh_obt_tip_ingreso(r_emr.cod_tip_ing_100, r_tip_ing);
          --- Insertar registro de liquidación del empleado por SALARIO
          r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_100;
          r_liq.cod_moneda      := r_emp.cod_moneda;
        --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
        --modificado para obtener la transaccion
          r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
          r_liq.cod_modulo      := r_tip_ing.cod_modulo;
          r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
        --fin modificaciones
          r_liq.monto           := v_salario_100porc;
          IF nvl(r_liq.monto,0) > 0 THEN
             if r_liq.nro_sobre is null then
                prh_ins_sobre(r_sob, r_liq.nro_sobre);
             end if;
    dbms_output.put_line('salario');
             v_saldo_salario := nvl(v_saldo_salario,0) + nvl(r_liq.monto,0);
             prh_ins_liq_sueldo(r_liq);
          END IF;
          --- Acumular Aporte---
          IF r_tip_ing.ind_imponible = 'S' and nvl(v_salario_100porc,0) > 0 THEN
             if r_emr.ind_apo_ips_caja = 'I' then --- acumula aporte para IPS
                v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_100porc,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
             elsif r_emr.ind_apo_ips_caja = 'C' then --- acumula aporte para la Caja
                v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_100porc,0) * nvl(r_emr.por_caj_emp, nvl(r_emr.por_caj_emp,0)),0);
                v_monto_fondo  := nvl(v_monto_fondo,0)  + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp_act, nvl(r_emr.por_caj_emp_act,0)),0);
             else
                v_monto_aporte := 0;
             end if;
          END IF;
          --- Acumular Aguinaldo a provisionar
          IF r_tip_ing.ind_acu_aguinaldo = 'S' and nvl(v_salario_100porc,0) > 0 THEN
             v_monto_aguinaldo := nvl(v_monto_aguinaldo,0) + round(nvl(v_salario_100porc,0) / 12,0);
          END IF;
      END IF;
      IF nvl(v_salario_130porc,0) > 0 then
          r_liq.computable := v_dias_trabajados;
          r_liq.hor_computable := v_h130_trabajadas;
          --- Generar cabeceras de la liquidación (SOBRE)
          --- Recuperar tipo de mvto del ingreso
          prh_obt_tip_ingreso(r_emr.cod_tip_ing_130, r_tip_ing);
          --- Insertar registro de liquidación del empleado por SALARIO
          r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_130;
          r_liq.cod_moneda      := r_emp.cod_moneda;
        --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
        --modificado para obtener la transaccion
          r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
          r_liq.cod_modulo      := r_tip_ing.cod_modulo;
          r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
        --fin modificaciones
          r_liq.monto           := v_salario_130porc;
          IF nvl(r_liq.monto,0) > 0 THEN
             if r_liq.nro_sobre is null then
                prh_ins_sobre(r_sob, r_liq.nro_sobre);
             end if;
    dbms_output.put_line('salario');
             v_saldo_salario := nvl(v_saldo_salario,0) + nvl(r_liq.monto,0);
             prh_ins_liq_sueldo(r_liq);
          END IF;
          --- Acumular Aporte---
          IF r_tip_ing.ind_imponible = 'S' and nvl(v_salario_130porc,0) > 0 THEN
             if r_emr.ind_apo_ips_caja = 'I' then --- acumula aporte para IPS
                v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_130porc,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
             elsif r_emr.ind_apo_ips_caja = 'C' then --- acumula aporte para la Caja
                v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_130porc,0) * nvl(r_emr.por_caj_emp, nvl(r_emr.por_caj_emp,0)),0);
                v_monto_fondo  := nvl(v_monto_fondo,0)  + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp_act, nvl(r_emr.por_caj_emp_act,0)),0);
             else
                v_monto_aporte := 0;
             end if;
          END IF;
          --- Acumular Aguinaldo a provisionar
          IF r_tip_ing.ind_acu_aguinaldo = 'S' and nvl(v_salario_130porc,0) > 0 THEN
             v_monto_aguinaldo := nvl(v_monto_aguinaldo,0) + round(nvl(v_salario_130porc,0) / 12,0);
          END IF;
      END IF;
      r_liq.computable := null;
      r_liq.hor_computable := null;
      --- Calcular HORAS EXTRAS
      FOR r_ext IN c_extras LOOP
         IF r_emp.tipo = 'M' then
            v_salario_extra := round(((r_emp.sal_base/240)+((r_emp.sal_base/240)*(r_ext.por_sueldo/100)))*r_ext.cant_horas,0);
         ELSE --- Destajistas y zafreros
            v_salario_extra := round(((r_emp.sal_base/8)+((r_emp.sal_base/8)*(r_ext.por_sueldo/100)))*r_ext.cant_horas,0);
         END IF;
         r_liq.hor_computable := r_ext.cant_horas;
         --- Recuperar tipo de mvto del ingreso
         prh_obt_tip_ingreso(r_emr.cod_tip_ing_extras, r_tip_ing);
         --- Insertar registro de liquidación del empleado por HORAS EXTRAS
         r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_extras;
         r_liq.cod_moneda      := r_emp.cod_moneda;
       --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
       --modificado para obtener la transaccion
         r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
         r_liq.cod_modulo      := r_tip_ing.cod_modulo;
         r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
       --fin modificaciones
         r_liq.monto           := v_salario_extra;
         r_liq.vac_fec_desde   := null;
         r_liq.ing_numero      := null;
         r_liq.des_numero      := null;
         r_liq.hex_fec_hor_extra := r_ext.fecha;
         IF r_liq.monto > 0 THEN
            if r_liq.nro_sobre is null then
               prh_ins_sobre(r_sob, r_liq.nro_sobre);
            end if;
            v_saldo_salario := nvl(v_saldo_salario,0) + nvl(r_liq.monto,0);
            prh_ins_liq_sueldo(r_liq);
         END IF;
         --- Acumular Aporte---
         if r_emr.ind_apo_ips_caja = 'I' then --- acumula aporte para IPS
            v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_extra,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
         elsif r_emr.ind_apo_ips_caja = 'C' then --- acumula aporte para la Caja
            v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_extra,0) * nvl(r_emr.por_caj_emp, nvl(r_emr.por_caj_emp,0)),0);
            v_monto_fondo  := nvl(v_monto_fondo,0)  + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp_act, nvl(r_emr.por_caj_emp_act,0)),0);
         else
            v_monto_aporte := 0;
         end if;
         --- Acumular Aguinaldo a provisionar
         v_monto_aguinaldo := nvl(v_monto_aguinaldo,0) + round(nvl(v_salario_extra,0) / 12,0);
         --- Actualizar indicador de proceso
         UPDATE rh_hor_extras
         set ind_procesado = 'S'
         where cod_persona = r_emp.cod_persona
         and fecha = r_ext.fecha;
      END LOOP;
      r_liq.computable := null;
      r_liq.hor_computable := null;
      r_liq.hex_fec_hor_extra := null;
      --- CALCULAR VACACIONES
      FOR r_vac IN c_vacaciones LOOP
dbms_output.put_line('en vacaciones');
         --- Recuperar dias correspondientes de vacaciones segun antiguedad
         v_dias_vaca := 0;
         v_dias_vaca := lf_rec_per_vacacion(round(months_between(p_fec_proceso,r_emp.fec_ingreso)/12,0));
         v_vac_dia_habil := r_vac.can_dia_habil;
         v_sal_vacacion  := r_vac.monto;
         if v_vac_dia_habil >= v_dias_vaca then
             --- Vacaciones causadas
            v_salario_vacacion := round((r_vac.monto/r_vac.can_dia_habil)*v_dias_vaca,0);
            r_liq.computable   := v_dias_vaca;
            v_vac_dia_habil    := v_vac_dia_habil - v_dias_vaca;
            v_sal_vacacion     := v_sal_vacacion - v_salario_vacacion;
            --- Recuperar tipo de mvto del ingreso
            prh_obt_tip_ingreso(r_emr.cod_tip_ing_vacacion, r_tip_ing);
            r_liq.cod_moneda      := r_emp.cod_moneda;
            --- Insertar registro de liquidación del empleado por VACACIONES
            r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_vacacion;
          --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
          --modificado para obtener la transaccion
            r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
            r_liq.cod_modulo      := r_tip_ing.cod_modulo;
            r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
          --fin modificaciones
            r_liq.monto           := nvl(v_salario_vacacion,0);
            r_liq.vac_fec_desde   := r_vac.fec_desde;
            r_liq.ing_numero      := null;
            r_liq.des_numero      := null;
            r_liq.hex_fec_hor_extra := null;
            IF r_liq.monto > 0 THEN
               if r_liq.nro_sobre is null then
                  prh_ins_sobre(r_sob, r_liq.nro_sobre);
               end if;
               v_saldo_salario := nvl(v_saldo_salario,0) + nvl(r_liq.monto,0);
               prh_ins_liq_sueldo(r_liq);
            END IF;
            --- Acumular Aporte---
            IF r_tip_ing.ind_imponible = 'S' THEN
               if r_emr.ind_apo_ips_caja = 'I' then --- acumula aporte para IPS
                  v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_vacacion,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
               elsif r_emr.ind_apo_ips_caja = 'C' then --- acumula aporte para la Caja
                  v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_vacacion,0) * nvl(r_emr.por_caj_emp, nvl(r_emr.por_caj_emp,0)),0);
                  v_monto_fondo  := nvl(v_monto_fondo,0)  + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp_act, nvl(r_emr.por_caj_emp_act,0)),0);
               else
                  v_monto_aporte := 0;
               end if;
            END IF;
            --- Acumular Aguinaldo a provisionar
            IF r_tip_ing.ind_acu_aguinaldo = 'S' THEN
               v_monto_aguinaldo := nvl(v_monto_aguinaldo,0) + round(v_salario_vacacion / 12,0);
            END IF;
         end if;
         if v_vac_dia_habil < v_dias_vaca then
             --- Vacaciones proporcionales
            v_salario_vacacion := v_sal_vacacion;
            r_liq.computable := v_vac_dia_habil;
            --- Recuperar tipo de mvto del ingreso
            prh_obt_tip_ingreso(r_emr.cod_tip_ing_vacacion, r_tip_ing);
            --- Insertar registro de liquidación del empleado por VACACIONES
          --r_liq.cod_tip_ingreso := 18; --- Vacaciones PROPORCIONALES
          ------------------------------------------------
          --- parametrización ce Vacaciones PROPORCIONALES
            select p.cod_tip_ing_vac_proporcional
            into   r_liq.cod_tip_ingreso
            from   rh_par_empresas p
            where  p.cod_empresa = r_emr.cod_empresa;
          --------------------------------------------------
          --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
          --modificado para obtener la transaccion
            r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
            r_liq.cod_modulo      := r_tip_ing.cod_modulo;
            r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
          --fin modificaciones
            r_liq.cod_moneda      := r_emp.cod_moneda;
            r_liq.monto           := nvl(v_salario_vacacion,0);
            r_liq.vac_fec_desde   := r_vac.fec_desde;
            r_liq.ing_numero      := null;
            r_liq.des_numero      := null;
            r_liq.hex_fec_hor_extra := null;
            IF r_liq.monto > 0 THEN
               if r_liq.nro_sobre is null then
                  prh_ins_sobre(r_sob, r_liq.nro_sobre);
               end if;
               v_saldo_salario := nvl(v_saldo_salario,0) + nvl(r_liq.monto,0);
               prh_ins_liq_sueldo(r_liq);
            END IF;
            --- Acumular Aporte---
            IF r_tip_ing.ind_imponible = 'S' THEN
               if r_emr.ind_apo_ips_caja = 'I' then --- acumula aporte para IPS
                  v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_vacacion,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
               elsif r_emr.ind_apo_ips_caja = 'C' then --- acumula aporte para la Caja
                  v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_vacacion,0) * nvl(r_emr.por_caj_emp, nvl(r_emr.por_caj_emp,0)),0);
                  v_monto_fondo  := nvl(v_monto_fondo,0)  + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp_act, nvl(r_emr.por_caj_emp_act,0)),0);
               else
                  v_monto_aporte := 0;
               end if;
            END IF;
            --- Acumular Aguinaldo a provisionar
            IF r_tip_ing.ind_acu_aguinaldo = 'S' THEN
               v_monto_aguinaldo := nvl(v_monto_aguinaldo,0) + round(v_salario_vacacion / 12,0);
            END IF;
         end if;
         --- Actualizar indicador de proceso
         UPDATE rh_vacaciones
         SET ind_procesado = 'S'
         where cod_persona = r_emp.cod_persona
         and fec_desde = r_vac.fec_desde;
      END LOOP;
      r_liq.vac_fec_desde := null;
      --- CALCULAR BONIFICACION FAMILIAR  (NO PERMITE DESCUENTOS!!! Artículo 271º)
      ---
      --- busqueda de hijos en vínculos
      begin
         select 'S'
         into   v_ind_hijos
         from   ba_vinculos
         where  cod_persona = r_emp.cod_persona
         and    tipo = 'H';
      exception
         when no_data_found then
            v_ind_hijos := 'N';
         when too_many_rows then
            v_ind_hijos := 'S';
      end;

      IF v_ind_hijos = 'S'
      and (p_fec_proceso = last_day(p_fec_proceso) --- Solo se calcula a fin de mes
        OR NVL(p_actualiza_empresa,'N') = 'N')     --- Por liquidacion final del empleado
       --- Se calcula sobre salario base del empleado
       ---
       --- En Bco. Regional no se tiene en cuenta que el salario sobrepase el doble del sal. minimo   
    /* and (  (nvl(r_emp.sal_base,0) < round(r_emp.monto*2,0)
              and r_emp.tipo = 'M')
          or (round(nvl(r_emp.sal_base,0)*26 ,0) < round((r_emp.monto*26)*2,0)
              and r_emp.tipo <> 'M')
          ) */
      THEN
      -------------------------------------------------------
      --- busqueda de vinculos con afecciones
      ------------------------------------------------------------*/
      /* select count(*) into r_liq.computable
         from   ba_vinculos f, ba_per_fisicas p
         where  p.cod_persona = f.cod_per_vinculo
         and    f.tipo = 'H'
         and  ( ( exists(select 1
                        from   ba_afecciones a, ba_per_afecciones b
                        where  a.cod_afeccion = b.cod_afeccion
                        and    p.cod_persona  = b.cod_persona
                        and    a.ind_discapacitado = 'S')
                 )
               or
                (months_between(sysdate,p.fec_nacimiento) < 216
                )
               )
         and f.cod_persona = r_emp.cod_persona;*/
         
         -- El calculo se separa para Banco Regional
         -- Si es discapacitado tiene un 50% mas de Bonificacion Familiar
         select count(*) into r_liq.computable
         from   ba_vinculos f, ba_per_fisicas p
         where  p.cod_persona = f.cod_per_vinculo
         and    f.tipo = 'H'
         and    months_between(sysdate,p.fec_nacimiento) < 216
         and    f.cod_persona = r_emp.cod_persona
         and    not exists( select 1
                            from   ba_afecciones a, ba_per_afecciones b
                            where  a.cod_afeccion = b.cod_afeccion
                            and    p.cod_persona  = b.cod_persona
                            and    a.ind_discapacitado = 'S');
         
         select count(*) into v_can_hijos_dis
         from   ba_vinculos f, ba_per_fisicas p
               ,ba_afecciones a, ba_per_afecciones b
         where  p.cod_persona = f.cod_per_vinculo
         and    a.cod_afeccion = b.cod_afeccion
         and    p.cod_persona  = b.cod_persona
         and    a.ind_discapacitado = 'S'
         and    f.tipo = 'H'
         and    f.cod_persona = r_emp.cod_persona;
       --------------------------------------------------------------
         if r_emp.tipo = 'M' then
            v_salario_bonificacion := r_liq.computable * round((r_emp.monto*r_emr.por_bonificacion/100),0);
            v_sal_bonificacion_dis := v_can_hijos_dis * round((r_emp.monto*r_emr.por_bonificacion/100),0);
            v_sal_bonificacion_dis := v_sal_bonificacion_dis + round((v_sal_bonificacion_dis * 50 /100),0);
            v_salario_bonificacion := v_salario_bonificacion + v_sal_bonificacion_dis;
         else
            v_salario_bonificacion := r_liq.computable * round(((r_emp.monto*26)*r_emr.por_bonificacion/100),0);
            v_sal_bonificacion_dis := v_can_hijos_dis * round(((r_emp.monto*26)*r_emr.por_bonificacion/100),0);
            v_sal_bonificacion_dis := v_sal_bonificacion_dis + round((v_sal_bonificacion_dis * 50 /100),0);
            v_salario_bonificacion := v_salario_bonificacion + v_sal_bonificacion_dis;
         end if;
         --- Recuperar tipo de mvto del ingreso
         prh_obt_tip_ingreso(r_emr.cod_tip_ing_bonificacion, r_tip_ing);
         --- Insertar registro de liquidación del empleado por BONIFICACION FAMILIAR
         r_liq.cod_moneda      := r_emp.cod_moneda;
         r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_bonificacion;
       --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
       --modificado para obtener la transaccion
         r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
         r_liq.cod_modulo      := r_tip_ing.cod_modulo;
         r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
       --fin modificaciones
         r_liq.monto           := nvl(v_salario_bonificacion,0);
         IF r_liq.monto > 0 THEN
            if r_liq.nro_sobre is null then
               prh_ins_sobre(r_sob, r_liq.nro_sobre);
            end if;
            prh_ins_liq_sueldo(r_liq);
         END IF;
         --- Acumular Aporte --- Se hace la pregunta pero por Ley debe cargarse N en el parametro
         IF r_tip_ing.ind_imponible = 'S' THEN
            if r_emr.ind_apo_ips_caja = 'I' then --- acumula aporte para IPS
               v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_bonificacion,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
            elsif r_emr.ind_apo_ips_caja = 'C' then --- acumula aporte para la Caja
               v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(v_salario_bonificacion,0) * nvl(r_emr.por_caj_emp, nvl(r_emr.por_caj_emp,0)),0);
               v_monto_fondo  := nvl(v_monto_fondo,0)  + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp_act, nvl(r_emr.por_caj_emp_act,0)),0);
            else
               v_monto_aporte := 0;
            end if;
         END IF;
         --- Acumular Aguinaldo a provisionar
         IF r_tip_ing.ind_acu_aguinaldo = 'S' THEN
            v_monto_aguinaldo := v_monto_aguinaldo + round(v_salario_bonificacion / 12,0);
         END IF;
      END IF;
      --- CALCULAR INGRESOS
      FOR r_ing IN c_ingresos LOOP
         --- Recuperar tipo de mvto del ingreso
         prh_obt_tip_ingreso(r_ing.cod_tip_ingreso, r_tip_ing);
         --- Insertar registro de liquidación del empleado por INGRESOS
         r_liq.cod_tip_ingreso := r_ing.cod_tip_ingreso;
         r_liq.cod_moneda      := r_ing.cod_moneda;
       --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
       --modificado para obtener la transaccion
         r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
         r_liq.cod_modulo      := r_tip_ing.cod_modulo;
         r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
       --fin modificaciones
         r_liq.monto           := pag_gen.fu_con_mon_a_moneda(r_ing.cod_moneda, r_emp.cod_moneda, nvl(r_ing.monto,0));
         r_liq.computable      := null;
         r_liq.vac_fec_desde   := null;
         r_liq.ing_numero      := r_ing.numero;
         r_liq.des_numero      := null;
         r_liq.cod_tip_descuento := null;
         r_liq.hex_fec_hor_extra := null;
         IF r_liq.monto > 0 THEN
            if r_liq.nro_sobre is null then
               prh_ins_sobre(r_sob, r_liq.nro_sobre);
            end if;
            v_saldo_salario := v_saldo_salario + r_liq.monto;
            prh_ins_liq_sueldo(r_liq);
         END IF;
         --- Acumular Aporte ---
         IF r_tip_ing.ind_imponible = 'S' THEN
            if r_emr.ind_apo_ips_caja = 'I' then --- acumula aporte para IPS
               v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(r_ing.monto,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
            elsif r_emr.ind_apo_ips_caja = 'C' then --- acumula aporte para la Caja
               v_monto_aporte := nvl(v_monto_aporte,0) + round(nvl(r_ing.monto,0) * nvl(r_emr.por_caj_emp, nvl(r_emr.por_caj_emp,0)),0);
               v_monto_fondo  := nvl(v_monto_fondo,0)  + round(nvl(v_salario_empleado,0) * nvl(r_emr.por_caj_emp_act, nvl(r_emr.por_caj_emp_act,0)),0);
            else
               v_monto_aporte := 0;
            end if;
         END IF;
         --- Acumular Aguinaldo a provisionar
         IF r_tip_ing.ind_acu_aguinaldo = 'S' THEN
            v_monto_aguinaldo := v_monto_aguinaldo + round(r_ing.monto / 12,0);
         END IF;
         --- Actualizar bandera de proceso para Ingresos
         UPDATE rh_ingresos
         SET ind_procesado = 'S'
         where cod_persona = r_emp.cod_persona
         and numero = r_ing.numero;
      END LOOP;
      --- CALCULAR DESCUENTOS
      r_liq.cod_tip_ingreso   := null;
      r_liq.ing_numero        := null;
      FOR r_des IN c_descuentos LOOP
         IF r_des.monto IS NULL THEN
            v_monto_descuento := round(v_saldo_salario*r_des.porcentaje/100,0);
         ELSE
            v_monto_descuento := r_des.monto;
         END IF;
         v_monto_descuento := pag_gen.fu_con_mon_a_moneda(r_des.cod_moneda, r_emp.cod_moneda, nvl(v_monto_descuento,0));
         --- Controlar % Judicial
         IF r_des.tipo = 'J' THEN
            v_monto_judicial := v_monto_judicial + v_monto_descuento;
            IF v_monto_judicial >= round(v_saldo_salario*r_emr.por_descuentos/100,0) then
               v_monto_descuento := 0;
            END IF;
         END IF;
         IF v_monto_descuento <= v_saldo_salario and v_monto_descuento > 0 THEN
            --- Insertar registro de liquidación del empleado por DESCUENTOS
            r_liq.cod_moneda        := r_des.cod_moneda;
            r_liq.cod_tip_descuento := r_des.cod_tip_descuento;
          --r_liq.cod_tip_movto     := r_des.cod_tip_movto;
            prh_obt_tip_descuent(r_des.cod_tip_descuento, r_tip_des);
          --modificado para obtener la transaccion
            r_liq.cod_transaccion   := r_tip_des.cod_transaccion;
            r_liq.cod_modulo        := r_tip_des.cod_modulo;
            r_liq.cod_modalidad     := r_tip_des.cod_modalidad;
          --fin modificaciones
            r_liq.des_numero        := r_des.numero;
            r_liq.monto             := nvl(v_monto_descuento,0);
            r_liq.computable        := NULL;
            r_liq.cod_tip_ingreso   := null;
            r_liq.ing_numero        := null;
            IF r_liq.monto > 0 THEN
               v_saldo_salario := v_saldo_salario - r_liq.monto;
               prh_ins_liq_sueldo(r_liq);
            END IF;
            --- Actualizar bandera de proceso en Descuentos
            UPDATE rh_descuentos
            set ind_procesado = 'S'
            where cod_persona = r_emp.cod_persona
            and fecha         = r_des.fecha
            and ind_procesado = 'N'
            and numero = r_des.numero;
         END IF;
      END LOOP;
      r_liq.des_numero        := null;
      r_liq.cod_tip_descuento := null;
      --- Insertar Liquidación
      IF v_monto_aporte > 0 and r_emp.ind_jub_ips = 'N' THEN
        if r_emr.ind_apo_ips_caja = 'I' or
          (r_emr.ind_apo_ips_caja = 'A' and r_emp.nro_ips is not null) then --- acumula aporte para IPS
             --- Recuperar tipo de mvto del ingreso
             prh_obt_tip_descuent(r_emr.cod_tip_des_ips, r_tip_des);
             --- Insertar registro de liquidación del empleado por IPS
             r_liq.cod_tip_descuento := r_emr.cod_tip_des_ips;
         elsif r_emr.ind_apo_ips_caja = 'C' or
              (r_emr.ind_apo_ips_caja = 'A' and r_emp.nro_caja is not null) then --- acumula aporte para la Caja
             --- Recuperar tipo de mvto del ingreso
             prh_obt_tip_descuent(r_emr.cod_tip_des_caja, r_tip_des);
             --- Insertar registro de liquidación del empleado pora la Caja
             r_liq.cod_tip_descuento := r_emr.cod_tip_des_caja;
         else
             null;
         end if;
       --r_liq.cod_tip_movto     := r_tip_des.cod_tip_movto;
       --modificado para obtener la transaccion
         r_liq.cod_transaccion   := r_tip_des.cod_transaccion;
         r_liq.cod_modulo        := r_tip_des.cod_modulo;
         r_liq.cod_modalidad     := r_tip_des.cod_modalidad;
         r_liq.cod_moneda        := r_emp.cod_moneda;
       --fin modificaciones
         r_liq.monto             := round(nvl(v_monto_aporte,0)/100,0);
         r_liq.computable        := NULL;
         IF r_liq.monto > 0 THEN
            prh_ins_liq_sueldo(r_liq);
         END IF;
         -------------------------------------------------
         --- Insertar el monto acumulado para el fondo ---
         -------------------------------------------------
         If (r_emr.ind_apo_ips_caja = 'C' or
            (r_emr.ind_apo_ips_caja = 'A' and r_emp.nro_caja is not null))
             and v_monto_fondo > 0 then
           --- Recuperar tipo de mvto del ingreso
           prh_obt_tip_descuent(r_emr.cod_tip_des_fondo, r_tip_des);
           --- Insertar registro de liquidación del empleado pora la Caja
           r_liq.cod_tip_descuento := r_emr.cod_tip_des_fondo;
         --r_liq.cod_tip_movto     := r_tip_des.cod_tip_movto;
         --modificado para obtener la transaccion
           r_liq.cod_transaccion   := r_tip_des.cod_transaccion;
           r_liq.cod_modulo        := r_tip_des.cod_modulo;
           r_liq.cod_modalidad     := r_tip_des.cod_modalidad;
           r_liq.cod_moneda        := r_emp.cod_moneda;
         --fin modificaciones
           r_liq.monto             := round(nvl(v_monto_fondo,0)/100,0);
           r_liq.computable        := NULL;
           IF r_liq.monto > 0 THEN
              prh_ins_liq_sueldo(r_liq);
           END IF;
         end if;
      END IF;
      --- Insertar provision de Aguinaldo
      IF v_monto_aguinaldo > 0 THEN
         r_prov.cod_persona       := r_emp.cod_persona;
         r_prov.fecha             := v_fecha_proceso;
         r_prov.mto_haber         := v_monto_aguinaldo;
         r_prov.cod_moneda         := r_emp.cod_moneda;
       --r_prov.cod_tip_provision := 21; -- Aguinaldo
      ------------------------------------------------
      --- parametrización de Ingreso de  Aguinaldo
         select p.cod_tip_prov_vacacion
         into   r_prov.cod_tip_provision
         from   rh_par_empresas p
         where  p.cod_empresa = r_emr.cod_empresa;
      --------------------------------------------------
         prh_ins_provision(r_prov);
      END IF;

   END LOOP;
   --- ACTUALIZAR Empresas, Fechas de proceso
   IF nvl(p_actualiza_empresa,'N') = 'S' THEN
      UPDATE rh_par_empresas
      set    ano_actual = v_ano_proceso,
             mes_actual = v_mes_proceso,
             qui_actual = v_quincena_proceso
      where  cod_empresa >= p_cod_epr_desde
      and    cod_empresa <= p_cod_epr_hasta;
      IF sql%notfound then
         raise_application_error(-20000,
         'No pudo actualizarse datos de procesos de la Empresa ');
      END IF;
   END IF;
END;
/
