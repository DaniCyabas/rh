CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_CAL_VACACIONES
 (
   P_COD_EPR_DESDE IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
   P_COD_EPR_HASTA IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
   P_COD_EMP_DESDE IN RH_EMPLEADOS.COD_PERSONA%TYPE,
   P_COD_EMP_HASTA IN RH_EMPLEADOS.COD_PERSONA%TYPE,
   P_FEC_PROCESO IN DATE,
   P_LIQ_FINAL IN VARCHAR2
 )
 IS
/* Recuperar dias correspondiente a vacaciones segun anos trabajados. */
FUNCTION LF_REC_PER_VACACION
 (P_TRABAJADOS IN RH_PER_VACACIONES.ANO_DESDE%TYPE
 )
 RETURN NUMBER;
/* Obtener promedio del salario de los ultimos 6 meses. */
FUNCTION LF_OBT_PROMEDIO
 (P_COD_EMPLEADO IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_COD_TIP_INGRESO IN RH_TIP_INGRESOS.COD_TIP_INGRESO%TYPE,
 P_FEC_DESDE IN DATE
 )
 RETURN NUMBER;
/* Obtener promedio de ingresos de los ultimos 6 meses. */
FUNCTION LF_OBT_PROM_ING
 (P_COD_EMPLEADO IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_COD_TIP_INGRESO IN RH_TIP_INGRESOS.COD_TIP_INGRESO%TYPE,
 P_FEC_DESDE IN DATE
 )
 RETURN NUMBER;
   r_emr            rh_par_empresas%rowtype;
   r_prov           rh_provisiones%rowtype;
   v_per_desde      rh_provisiones.per_desde%type;
   v_per_hasta      rh_provisiones.per_hasta%type;
   v_trans          rh_per_vacaciones.ano_desde%type;
   v_trabajados     rh_per_vacaciones.ano_desde%type;
   v_dias_vaca      rh_per_vacaciones.dias_vacaciones%type;
   v_mto_vacacion   rh_provisiones.mto_haber%type;
   v_promedio       rh_liq_sueldos.monto%type;
   v_meses          number(06);
   v_cod_emp_autoriza rh_empleados.cod_persona%type;
   v_tip_ing_vacacion rh_par_empresas.cod_tip_ing_vacacion%type;
   --- Cursor de empleados a procesar
   CURSOR c_empleados IS
      Select cod_per_empresa, cod_persona, fec_ingreso, tipo, sal_base, cod_moneda
      from rh_empleados
      where cod_per_empresa >= p_cod_epr_desde
      and cod_per_empresa <= p_cod_epr_hasta
      and cod_persona >= p_cod_emp_desde
      and cod_persona <= p_cod_emp_hasta
      and fec_egreso IS NULL;
/* Recuperar dias correspondiente a vacaciones segun anos trabajados. */
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
/* Obtener promedio del salario de los ultimos 6 meses. */
FUNCTION LF_OBT_PROMEDIO
 (P_COD_EMPLEADO IN RH_EMPLEADOS.COD_PERSONA%TYPE,
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
   where l.cod_persona   = p_cod_empleado
   and l.cod_tip_ingreso = i.cod_tip_ingreso
   ---and i.cod_tip_ingreso = p_cod_tip_ingreso --- todos los ingresos imponibles
   and i.ind_imponible   = 'S'
   and s.cod_persona     = l.cod_persona
   and s.nro_sobre       = l.nro_sobre
   and s.fec_calculo     >  p_fec_desde;  --- Incluyo lo de ese mes
dbms_output.put_line('Total '||v_total||' can '||v_can_sueldos||' fecha '||p_fec_desde);
   if v_total > 0 then
      v_promedio := round(v_total/v_can_sueldos,0);
   else
      v_promedio := 0;
   end if;
   RETURN v_promedio;
END;
/* Obtener promedio de ingresos de los ultimos 6 meses. */
FUNCTION LF_OBT_PROM_ING
 (P_COD_EMPLEADO IN RH_EMPLEADOS.COD_PERSONA%TYPE,
  P_COD_TIP_INGRESO IN RH_TIP_INGRESOS.COD_TIP_INGRESO%TYPE,
  P_FEC_DESDE IN DATE
 )
 RETURN NUMBER
 IS
   v_total        rh_liq_sueldos.monto%type;
   v_promedio     rh_liq_sueldos.monto%type;
   v_can_sueldos  number(06);
BEGIN
   select nvl(sum(l.monto),0)
   into v_total
   from rh_liq_sueldos l, rh_tip_ingresos i, rh_sobres s
   where l.cod_persona   = p_cod_empleado
   and l.cod_tip_ingreso = i.cod_tip_ingreso
   and i.cod_tip_ingreso <> p_cod_tip_ingreso
   and s.cod_persona     = l.cod_persona
   and s.nro_sobre       = l.nro_sobre
   and s.fec_calculo     > p_fec_desde
   and i.ind_imponible   = 'S';
dbms_output.put_line('Total ing '||v_total);
   if v_total > 0 then
      v_promedio := round(v_total/180,0);
   else
      v_promedio := 0;
   end if;
   RETURN v_promedio;
END;
BEGIN
dbms_output.put_line('Liq fin '||p_liq_final);
   FOR r_emp IN c_empleados LOOP
      --- Recuperar datos de la empresa
      PRH_OBT_EMPRESA(r_emp.cod_per_empresa, r_emr);
      v_trans       := 0;
      v_dias_vaca   := 0;
      v_trabajados  := 0;
      -----------------------------------------------------
      --- Obtener parametro tipo de ingreso para vacaciones
      select cod_tip_prov_vacacion
      into   v_tip_ing_vacacion
      from   rh_par_empresas
      where  cod_empresa = r_emr.cod_empresa;
      ------------------------------------------------------
      IF r_emp.tipo NOT IN ('Z','D') THEN -- PARA TODOS ES IGUAL EL CALCULO
         --- Recuperar maximo periodo computado para el empleado
         BEGIN
            Select p1.per_desde, p1.per_hasta
            into v_per_desde, v_per_hasta
            from rh_provisiones p1
            where p1.cod_persona = r_emp.cod_persona
            and p1.cod_tip_provision = v_tip_ing_vacacion  ---20 Vacaciones
            and p1.per_hasta = (select max(p2.per_hasta)
                                from rh_provisiones p2
                                where p2.cod_persona = p1.cod_persona
                                  and p2.cod_tip_provision = v_tip_ing_vacacion ); ---20 Vacaciones
         exception
            when no_data_found then
               v_per_hasta := to_char(r_emp.fec_ingreso,'YYYY');
          END;
         --- Verificar si le corresponde computar otro periodo
         If to_number(to_char(p_fec_proceso,'yyyy')) > v_per_hasta THEN
            v_trans := trunc(months_between(p_fec_proceso,
                       to_date(to_char(r_emp.fec_ingreso,'dd/mm/')||to_char(v_per_hasta,'9999'),'dd/mm/yyyy'))/12,0);
         end if;
         if p_liq_final IN ('S','D') then
            v_trans := 1;
         end if;
         if v_trans >= 1 then --- Transcurre un año mas o es egreso
            FOR i in 1..v_trans LOOP --- Por si son mas de un año, no deberia de darse porq va a saltar el PK de provisiones
               v_trabajados := round(months_between(p_fec_proceso,r_emp.fec_ingreso)/12,0);
               --- Recuperar dias correspondientes de vacaciones segun antiguedad
               if p_liq_final = 'D' and v_trabajados < 1 then
                  v_dias_vaca := lf_rec_per_vacacion(1);
               else
                  v_dias_vaca := lf_rec_per_vacacion(v_trabajados);
               end if;
               if p_liq_final = 'D' then
                  --- Hallar dias correspondientes a meses transcurridos
                  v_meses := round(months_between(p_fec_proceso,
                             to_date(to_char(r_emp.fec_ingreso,'dd/mm/')||
                             to_char(v_per_hasta,'9999'),'dd/mm/yyyy')),0);
                  v_dias_vaca := round((v_dias_vaca/12)*v_meses,0);
               end if;
               If v_dias_vaca > 0 then
                  IF p_liq_final in ('S','D') then
                     --- La liquidacion del empleado corresponde al promedio de los ultimos seis meses
                     ----v_promedio := lf_obt_promedio(r_emp.cod_empleado, r_emr.cod_tip_ing_sueldo, add_months(p_fec_proceso,-6));
                     v_promedio     := lf_obt_prom_ing(r_emp.cod_persona, r_emr.cod_tip_ing_sueldo, add_months(to_date('01'||to_char(p_fec_proceso,'MMYYYY'),'DDMMYYYY'),-6));
dbms_output.put_line('Promedio '||v_promedio||' dias '||v_dias_vaca||' salbase '||r_emp.sal_base);
                     IF r_emp.tipo = 'M' THEN
                        ---v_mto_vacacion := round(((r_emp.salario_base/30)+nvl(v_promedio,0))*v_dias_vaca,0);
                        v_mto_vacacion := round(((r_emp.sal_base/30))*v_dias_vaca,0);
                     ELSE
                        ---v_mto_vacacion := round((r_emp.salario_base+nvl(v_promedio,0))*v_dias_vaca,0);
                        --- Modificado a Pedido de Ramon Alvarez 14/02/05
                        v_mto_vacacion := round((r_emp.sal_base)*v_dias_vaca,0);
                     END IF;
                     ----v_mto_vacacion := round((v_promedio/30)*v_dias_vaca,0);
                  ELSE
dbms_output.put_line('PromedioN '||v_promedio||' dias '||v_dias_vaca||' salbase '||r_emp.sal_base);
                     -- Modificación realizada a Pedido de Ramon Alvarez 30/12/04
                     -- Debe realizarse en base al salario base actual + el promedio de ingresos que no son salario
                     -- de los ultimos 6 meses dividido 180. Se asume que siempre el empleado saldra todos los dias de vacaciones
                     v_promedio     := lf_obt_prom_ing(r_emp.cod_persona, r_emr.cod_tip_ing_sueldo, add_months(to_date('01'||to_char(p_fec_proceso,'MMYYYY'),'DDMMYYYY'),-6));
                     IF r_emp.tipo = 'M' THEN
                        ---v_mto_vacacion := round(((r_emp.salario_base/30)+nvl(v_promedio,0))*v_dias_vaca,0);
                        v_mto_vacacion := round(((r_emp.sal_base/30))*v_dias_vaca,0);
                     ELSE
                        ---v_mto_vacacion := round((r_emp.salario_base+nvl(v_promedio,0))*v_dias_vaca,0);
                        --- Modificado a Pedido de Ramon Alvarez 14/02/05
                        v_mto_vacacion := round((r_emp.sal_base)*v_dias_vaca,0);
                     END IF;
                  END IF;
                  --- Insertar provision vacaciones (computadas)
                  r_prov.cod_persona       := r_emp.cod_persona;
                  r_prov.cod_tip_provision := v_tip_ing_vacacion; ---20 Vacaciones
                  r_prov.fecha             := p_fec_proceso;
                  r_prov.mto_haber         := v_mto_vacacion;
                  r_prov.cod_moneda        := r_emp.cod_moneda;
                  r_prov.dia_haber         := v_dias_vaca;
                  r_prov.per_desde         := v_per_hasta;
                  r_prov.per_hasta         := v_per_hasta + 1;
                  v_per_hasta              := r_prov.per_hasta;
dbms_output.put_line('Provision '||v_mto_vacacion||' PerDes '||r_prov.per_desde||' Hast '||r_prov.per_hasta);
                  prh_ins_provision(r_prov);
                  IF p_liq_final in('S','D') THEN
                     --- Si es el calculo de su vacaciones por liquidacion de egreso
                     --- Generar automáticamente la vacacion
                     BEGIN
                        select cod_persona into v_cod_emp_autoriza
                          from ba_usuarios
                         where cod_usuario = user;
                     exception
                        when no_data_found then
                        ---v_cod_emp_autoriza := '86926';
                           raise_application_error(-20000,
                           'Empleado no puede autorizar operacion');
                     END;
                     BEGIN
                        insert into rh_vacaciones
                          (cod_persona, fec_desde, can_dias, cod_per_autorizador, cod_moneda)
                        values
                          (r_emp.cod_persona, p_fec_proceso, v_dias_vaca,
                           v_cod_emp_autoriza, r_emp.cod_moneda);
                     exception
                        when dup_val_on_index then
                           --- Si ya se proceso manualmente la vacación del ultimo año
                           --- no debe tratar de reprocesar
                           null;
                        when others then
                           raise_application_error(-20000,
                           'Ins.Vacaciones Empl:'||r_emp.cod_persona||' '||sqlerrm);
                     END;
                  END IF;
               end if;
            END LOOP;
         end if;
      ELSE
         --- Aclarar ART. 219
         NULL;
      END IF;
   END LOOP;
END;
/
