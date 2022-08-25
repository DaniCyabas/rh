CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_LIQ_FINAL_EMP
 (
    P_COD_EMPLEADO IN RH_EMPLEADOS.COD_PERSONA%TYPE,
    P_FEC_EGRESO IN RH_EMPLEADOS.FEC_EGRESO%TYPE,
   --,P_CHEQUE IN RH_CHEQUES.CHEQUE%TYPE
   P_FEC_AVISO IN DATE,
   P_PAG_INDEMNIZACION IN VARCHAR2,
   P_MOT_SALIDA IN VARCHAR2
 )
 IS
/* Recuperar dias correspondiente a pre-aviso segun anos trabajados. */
FUNCTION LF_REC_PER_AVISO
 (P_TRABAJADOS IN RH_PER_VACACIONES.ANO_DESDE%TYPE
 )
 RETURN NUMBER;
/* Recuperar dias correspondiente a indenmización segun anos trabajados. */
FUNCTION LF_REC_PER_INDENMIZACIONES
 (P_TRABAJADOS IN RH_PER_INDEMNIZACIONES.ANO_DESDE%TYPE
 )
 RETURN NUMBER;
/* Obtener promedio del salario de los ultimos 6 meses. */
FUNCTION LF_OBT_PROMEDIO
 (
  P_COD_EMPLEADO IN RH_EMPLEADOS.COD_PERSONA%TYPE,
  P_COD_TIP_INGRESO IN RH_TIP_INGRESOS.COD_TIP_INGRESO%TYPE,
  P_FEC_DESDE IN DATE
 )
 RETURN NUMBER;
   r_liq            rh_liq_sueldos%rowtype;
   r_tip_ing        rh_tip_ingresos%rowtype;
   r_tip_des        rh_tip_descuentos%rowtype;
   r_emr            rh_par_empresas%rowtype;
   r_sob            rh_sobres%rowtype;
   v_trabajados     number(05,2);
   v_dias_aviso     rh_per_preaviso.dias_preaviso%type;
   v_dias_cursados  rh_per_preaviso.dias_preaviso%type;
   v_mto_preaviso   rh_liq_sueldos.monto%type;
   v_monto_ips      rh_liq_sueldos.monto%type;
   v_promedio       rh_liq_sueldos.monto%type;
   v_indemnizacion  rh_liq_sueldos.monto%type;
   v_años           number(10,2);
   v_sal_vacaciones varchar2(01);
   ---parametrizar empresa principal
   v_emp_principal     ge_par_generales.cod_persona%type;
   v_dias_indenmizar   rh_per_indemnizaciones.dias_indemnizacion%type;

   --- Cursor de datos del empleado
   CURSOR c_empleado IS
   select cod_persona, cod_per_empresa, fec_ingreso, cod_cen_costo,
          tipo, sal_base, ind_jub_ips, cod_moneda
   from rh_empleados
   where cod_persona = p_cod_empleado;
/* Recuperar dias correspondiente a pre-aviso segun anos trabajados. */
FUNCTION LF_REC_PER_AVISO
 (P_TRABAJADOS IN RH_PER_VACACIONES.ANO_DESDE%TYPE
 )
 RETURN NUMBER
 IS
v_dias_aviso rh_per_preaviso.dias_preaviso%type;
BEGIN
   Select min(nvl(dias_preaviso,0))
   into v_dias_aviso
   from rh_per_preaviso
   where ano_desde <= p_trabajados
   and ano_hasta   >= p_trabajados;
   return v_dias_aviso;
exception
   when no_data_found then
      return 0;
END;
/* Recuperar dias correspondiente a indenmización segun anos trabajados. */
FUNCTION LF_REC_PER_INDENMIZACIONES
 (P_TRABAJADOS IN RH_PER_INDEMNIZACIONES.ANO_DESDE%TYPE
 )
 RETURN NUMBER
 IS
v_dias_indenmizar rh_per_indemnizaciones.dias_indemnizacion%type;
BEGIN
   Select min(nvl(dias_indemnizacion,0))
   into v_dias_indenmizar
   from rh_per_indemnizaciones
   where ano_desde <= p_trabajados
   and   ano_hasta   >= p_trabajados;
   return v_dias_indenmizar;
exception
   when no_data_found then
      return 15;
END;
/* Obtener promedio del salario de los ultimos 6 meses. */
FUNCTION LF_OBT_PROMEDIO
 (
  P_COD_EMPLEADO IN RH_EMPLEADOS.COD_PERSONA%TYPE,
  P_COD_TIP_INGRESO IN RH_TIP_INGRESOS.COD_TIP_INGRESO%TYPE,
  P_FEC_DESDE IN DATE
 )
 RETURN NUMBER
 IS
   v_total        rh_liq_sueldos.monto%type;
   v_promedio     rh_liq_sueldos.monto%type;
   v_can_sueldos  number(06);
BEGIN
   select nvl(sum(l.monto),0), count(distinct to_char(s.fec_calculo,'YYYYMM'))
   into v_total, v_can_sueldos
   from rh_liq_sueldos l, rh_tip_ingresos i, rh_sobres s
   where l.cod_persona  = p_cod_empleado
   and l.cod_tip_ingreso = i.cod_tip_ingreso
   ---and i.cod_tip_ingreso = p_cod_tip_ingreso --- todos los ingresos imponibles
   and i.ind_imponible   = 'S'
   and s.cod_persona    = l.cod_persona
   and s.nro_sobre       = l.nro_sobre
   and s.fec_calculo    >  p_fec_desde  --- Incluyo lo de ese mes
   and s.fec_calculo    < p_fec_egreso; --- No incluyo lo ganado en el mes del egreso
dbms_output.put_line('Total '||v_total||' can '||v_can_sueldos||' fecha '||p_fec_desde);
   if v_total > 0 then
      v_promedio := round(v_total/v_can_sueldos,0);
   else
      v_promedio := 0;
   end if;
   RETURN v_promedio;
END;
BEGIN
   FOR r_emp IN c_empleado LOOP
      --- Calcular vacaciones a la fecha de egreso
dbms_output.put_line('vac');
      if p_fec_aviso is not null then
         v_sal_vacaciones := 'D'; --- Calcula vacaciones proporcionales.
      else
         v_sal_vacaciones := 'S'; --- Solo vacaciones causadas
      end if;
      prh_cal_vacaciones(r_emp.cod_per_empresa, r_emp.cod_per_empresa,
                         r_emp.cod_persona, r_emp.cod_persona, p_fec_egreso, v_sal_vacaciones);
      --- Calcular salario a la fecha de egreso
dbms_output.put_line('liq');
      prh_cal_liquidacion(r_emp.cod_per_empresa, r_emp.cod_per_empresa,
                        /*to_number(to_char(p_fec_egreso,'yyyy')),
                          to_number(to_char(p_fec_egreso,'mm')), 2,*/
                          p_fec_egreso, r_emp.cod_persona, r_emp.cod_persona, --p_cheque,
                          'N', r_liq.nro_sobre, r_emp.tipo);
      --- Recuperar datos de la Empresa del Empleado
      prh_obt_empresa(r_emp.cod_per_empresa, r_emr);
      IF p_fec_aviso is not null then --- Es un DESPIDO
         --- Calcular pre-aviso a la fecha de egreso
         v_trabajados := round(months_between(p_fec_egreso, r_emp.fec_ingreso)/12,2);
dbms_output.put_line('pre-aviso '||v_trabajados);
         v_dias_aviso := lf_rec_per_aviso(v_trabajados);
         v_trabajados := round(v_trabajados,0);
         --- Se descuentan los dias cursados de pre-aviso
         if p_fec_aviso is null then
            v_dias_cursados := 0;
         else
            v_dias_cursados := p_fec_aviso - p_fec_egreso;
         end if;
         v_dias_aviso := v_dias_aviso - v_dias_cursados;
         --- Calcular promedio de los ultimos seis meses de ingresos imponibles
         v_promedio := lf_obt_promedio(r_emp.cod_persona, r_emr.cod_tip_ing_sueldo,
                       add_months(to_date('01'||to_char(p_fec_egreso,'MMYYYY'),'DDMMYYYY'),-6));
dbms_output.put_line('Prome '||v_promedio||' dias '||v_dias_aviso);
         v_mto_preaviso := round((v_promedio/30)*v_dias_aviso,0);
       /*if r_emp.tip_empleado = 'M' then
            v_mto_preaviso := round((r_emp.salario_base /30)*v_dias_aviso,0);
         else
            v_mto_preaviso := round(r_emp.salario_base * v_dias_aviso,0);
         end if;*/
         --- Insertar liquidación
         r_liq.computable    := v_dias_aviso;
         r_liq.cod_persona   := r_emp.cod_persona;
         r_sob.cod_persona   := r_emp.cod_persona;
         r_sob.ano           := to_number(to_char(p_fec_egreso,'yyyy'));
         r_sob.mes           := to_number(to_char(p_fec_egreso,'mm'));
         r_sob.quincena      := 2;
         r_sob.fec_calculo   := p_fec_egreso;
         ---obtener la empresa principal
         select cod_persona
         into   v_emp_principal
         from   ge_par_generales;
         if r_emp.tipo = 'Z' and r_emr.cod_empresa <> v_emp_principal then--'01' 
            r_sob.nro_patronal := r_emr.pat_ips_02;
         else
            r_sob.nro_patronal := r_emr.pat_ips_01;
         end if;
         r_liq.cod_cen_costo := r_emp.cod_cen_costo;
         --- Recuperar tipo de mvto del ingreso
         prh_obt_tip_ingreso(r_emr.cod_tip_ing_preaviso, r_tip_ing);
         r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_preaviso;
       --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
       --modificado para obtener la transaccion
         r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
         r_liq.cod_modulo      := r_tip_ing.cod_modulo;
         r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
       --fin modificaciones
         r_liq.monto           := v_mto_preaviso;
         r_liq.cod_moneda      := r_emp.cod_moneda;
         IF r_liq.monto > 0 THEN
            if r_liq.nro_sobre is null then
               prh_ins_sobre(r_sob, r_liq.nro_sobre);
            end if;
            prh_ins_liq_sueldo(r_liq);
         END IF;
         --- Acumular IPS
         IF r_tip_ing.ind_imponible = 'S' and nvl(v_mto_preaviso,0) > 0 THEN
            v_monto_ips := nvl(v_monto_ips,0) + round(nvl(v_mto_preaviso,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
         END IF;
      END IF;
      IF p_pag_indemnizacion = 'S' THEN
dbms_output.put_line('indem');
         --- Calcular indemnizacion
         --- Calcular promedio de los ultimos seis meses
         v_promedio := lf_obt_promedio(r_emp.cod_persona, r_emr.cod_tip_ing_sueldo,
                       add_months(to_date('01'||to_char(p_fec_egreso,'MMYYYY'),'DDMMYYYY'),-6));
         v_años     := ROUND(months_between(p_fec_egreso, r_emp.fec_ingreso)/12,0);
dbms_output.put_line('anos '||v_años||' prom '||v_promedio||' rod '||round(v_años,0));
         --v_indemnizacion     := v_promedio * v_años;
         --- 15 dias por cada año trabajado por el promedio de los ultimos 6 meses
         if v_años < 1 then
            --- Igual se indemniza como si fuera un año completo
            v_años := 1;
         end if;
         v_dias_indenmizar   := LF_REC_PER_INDENMIZACIONES(v_trabajados);
         v_indemnizacion     := ((v_promedio/30)*v_dias_indenmizar) * v_años;
         --r_liq.computable    := v_años;
         r_liq.computable    := v_años*v_dias_indenmizar; --- Pasar en dias y son 15 por cada año
         r_liq.cod_persona   := r_emp.cod_persona;
         r_sob.cod_persona   := r_emp.cod_persona;
         r_sob.ano           := to_number(to_char(p_fec_egreso,'yyyy'));
         r_sob.mes           := to_number(to_char(p_fec_egreso,'mm'));
         r_sob.quincena      := 2;
         r_sob.fec_calculo   := p_fec_egreso;
         if r_emp.tipo = 'Z' and r_emr.cod_empresa <> v_emp_principal then--'01' 
            r_sob.nro_patronal := r_emr.pat_ips_02;
         else
            r_sob.nro_patronal := r_emr.pat_ips_01;
         end if;
         r_liq.cod_cen_costo := r_emp.cod_cen_costo;
         --- Recuperar tipo de mvto del ingreso
         prh_obt_tip_ingreso(r_emr.cod_tip_ing_indemnizacion, r_tip_ing);
         r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_indemnizacion;
       --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
       --modificado para obtener la transaccion
         r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
         r_liq.cod_modulo      := r_tip_ing.cod_modulo;
         r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
       --fin modificaciones
         r_liq.monto       := v_indemnizacion;
         r_liq.cod_moneda  := r_emp.cod_moneda;
         IF r_liq.monto > 0 THEN
            if r_liq.nro_sobre is null then
               prh_ins_sobre(r_sob, r_liq.nro_sobre);
            end if;
            prh_ins_liq_sueldo(r_liq);
         END IF;
         --- Acumular IPS
         IF r_tip_ing.ind_imponible = 'S' and nvl(v_indemnizacion,0) > 0 THEN
            v_monto_ips := nvl(v_monto_ips,0) + round(nvl(v_indemnizacion,0) * nvl(r_emr.por_ips_emp, nvl(r_emr.por_ips_emp,0)),0);
         END IF;
      END IF;
      --- Insertar registro de IPS
      IF v_monto_ips > 0 and r_emp.ind_jub_ips = 'N' THEN
         --- Recuperar tipo de mvto del ingreso
         prh_obt_tip_descuent(r_emr.cod_tip_des_ips, r_tip_des);
         --- Insertar registro de liquidación del empleado por IPS
         r_liq.cod_tip_ingreso   := null;
         r_liq.cod_tip_descuento := r_emr.cod_tip_des_ips;
       --r_liq.cod_tip_movto     := r_tip_des.cod_tip_movto;
       --modificado para obtener la transaccion
         r_liq.cod_transaccion := r_tip_des.cod_transaccion;
         r_liq.cod_modulo      := r_tip_des.cod_modulo;
         r_liq.cod_modalidad   := r_tip_des.cod_modalidad;
       --fin modificaciones
         r_liq.monto         := round(nvl(v_monto_ips,0)/100,0);
         r_liq.cod_moneda    := r_emp.cod_moneda;
         r_liq.computable    := NULL;
         IF r_liq.monto > 0 THEN
            prh_ins_liq_sueldo(r_liq);
         END IF;
      END IF;
      --- Calcular aguinaldo a la fecha de egreso
dbms_output.put_line('agui');
      prh_cal_aguinaldo(r_emp.cod_per_empresa, r_emp.cod_per_empresa,
                        r_emp.cod_persona, r_emp.cod_persona,
                        p_fec_egreso, p_fec_egreso, r_liq.nro_sobre);
   END LOOP;
   --- Actualizar fecha de egreso del empleado
   update rh_empleados
   set fec_egreso = p_fec_egreso,
     --mot_salida
       observacion = rtrim(observacion || ' ' || nvl(p_mot_salida,' '))
   where cod_persona = p_cod_empleado;
END;
/
