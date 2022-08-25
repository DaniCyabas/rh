CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_CAL_AGUINALDO
 (
   P_COD_EPR_DESDE IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
   P_COD_EPR_HASTA IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
   P_COD_EMP_DESDE IN RH_EMPLEADOS.COD_PERSONA%TYPE,
   P_COD_EMP_HASTA IN RH_EMPLEADOS.COD_PERSONA%TYPE,
   P_ANO_MES_HASTA IN DATE,
   P_FEC_PROCESO IN DATE,
   P_NRO_SOBRE IN RH_SOBRES.NRO_SOBRE%TYPE
 )
 IS
   r_emr            rh_par_empresas%rowtype;
   r_liq            rh_liq_sueldos%rowtype;
   r_prov           rh_provisiones%rowtype;
   r_sob            rh_sobres%rowtype;
   r_tip_ing        rh_tip_ingresos%rowtype;
   v_cod_empleado   rh_empleados.cod_persona%type;
   v_fec_aguinaldo  rh_provisiones.fecha%type;
   v_mto_aguinaldo  rh_provisiones.sal_actual%type;
   v_ingresos       rh_ingresos.monto%type;
   v_nro_sobre      rh_sobres.nro_sobre%type;
   v_meses          number(03);
   v_tip_prov_aguinaldo rh_par_empresas.cod_tip_prov_aguinaldo%type; --agregado para parametrizar

   --- Cursor de empleados a procesar
   CURSOR c_empleados IS
      select cod_per_empresa, cod_persona, tipo, sal_base, cod_cen_costo, cod_moneda
      from rh_empleados
      where cod_per_empresa >= p_cod_epr_desde
      and cod_per_empresa  <= p_cod_epr_hasta
      and cod_persona >= p_cod_emp_desde
      and cod_persona <= p_cod_emp_hasta
      and fec_egreso IS NULL;
   --- Cursor de aguinaldos provisionados para el empleado
   CURSOR c_aguinaldos IS
      select fecha, sal_actual
      from rh_provisiones
      where cod_persona = v_cod_empleado
      and cod_tip_provision = v_tip_prov_aguinaldo --21 --- Aguinaldo
      and sal_actual > 0
      and fecha <= last_day(P_FEC_PROCESO)
      order by fecha;
BEGIN
   FOR r_emp IN c_empleados LOOP
      --- Recuperar datos de la empresa
      prh_obt_empresa(r_emp.cod_per_empresa, r_emr);
      v_fec_aguinaldo := null;
      v_mto_aguinaldo := 0;
      v_cod_empleado  := r_emp.cod_persona;
      --- Recuperar parametro de tipo de ingreso de aguinaldo para la empresa
      --- reemplazar el tipo de ingreso 21 por uno parametrizado
      BEGIN
         select cod_tip_prov_aguinaldo
         into   v_tip_prov_aguinaldo
         from   rh_par_empresas
         where  cod_empresa = r_emp.cod_per_empresa;
      END;
      --- Recuperar maximo aguinaldo provisionado
      BEGIN
         select max(fecha)
         into   v_fec_aguinaldo
         from   rh_provisiones
         where  cod_persona = r_emp.cod_persona
         and    fecha <= last_day(P_FEC_PROCESO)
         and    cod_tip_provision = v_tip_prov_aguinaldo; --21; --- Aguinaldo
      END;
      if to_char(v_fec_aguinaldo,'YYYYMM') < to_char(p_ano_mes_hasta,'YYYYMM') THEN
         --- Calcular aguinaldo correspondiente por los meses faltantes (Solo mensualeros)
         --- Destajistas se paga hasta donde se cobro
         if r_emp.tipo = 'M' then
            --- Calcular aguinaldo por salario base
            v_meses         := months_between(p_fec_proceso, v_fec_aguinaldo);
            --- No se calcula aguinaldo sobre el salario porque esto depende de lo que cobra
            --- Solo sobre los ingresos extraordinarios
            ---v_mto_aguinaldo := round((v_meses*r_emp.salario_base/12),0);
            --- Calcular aguinaldo por ingresos extraordinarios imputables
            begin
               select nvl(sum(i.monto),0) into v_ingresos
                 from rh_ingresos i, rh_tip_ingresos t
                where i.cod_tip_ingreso = t.cod_tip_ingreso
                  and i.fecha > nvl(r_emr.FEC_ULT_CIERRE,to_date('01/01/2000','DD/MM/YYYY'))
                  and i.fecha <= p_fec_proceso
                  and i.cod_persona = r_emp.cod_persona
                  and i.cod_per_autorizador IS NOT NULL
                  and i.ind_procesado = 'N'
                  and t.ind_acu_aguinaldo = 'S';
            end;
            v_mto_aguinaldo := nvl(v_mto_aguinaldo,0) + round((nvl(v_ingresos,0)/12),0);
            r_prov.cod_persona      := r_emp.cod_persona;
            r_prov.fecha     := p_fec_proceso;
            r_prov.mto_haber         := v_mto_aguinaldo;
            r_prov.cod_tip_provision := v_tip_prov_aguinaldo; --21; -- Aguinaldo
            prh_ins_provision(r_prov);
         end if;
      end if;
      --- Procesar aguinaldos provisionados
      v_mto_aguinaldo := 0;
      FOR r_agu IN c_aguinaldos LOOP
         v_mto_aguinaldo := v_mto_aguinaldo + r_agu.sal_actual;
         update rh_provisiones
         set mto_debe = mto_debe + r_agu.sal_actual
         where cod_persona = r_emp.cod_persona
         and cod_tip_provision = v_tip_prov_aguinaldo --21 -- Aguinaldo
         and fecha = r_agu.fecha;
      END LOOP;
      if v_mto_aguinaldo > 0 then
         --- Insertar liquidacion de aguinaldo
         r_liq.cod_persona  := r_emp.cod_persona;
         r_liq.cod_cen_costo := r_emp.cod_cen_costo;
         r_liq.vac_fec_desde := null;
         r_liq.ing_numero    := null;
         r_liq.hex_fec_hor_extra := null;
         r_liq.des_numero    := null;
         --- Recuperar tipo de mvto del ingreso
         prh_obt_tip_ingreso(r_emr.cod_tip_ing_aguinaldo, r_tip_ing);
         r_liq.cod_tip_ingreso := r_emr.cod_tip_ing_aguinaldo;
       --r_liq.cod_tip_movto   := r_tip_ing.cod_tip_movto;
       --reemplazado por ge_transacciones
         r_liq.cod_transaccion := r_tip_ing.cod_transaccion;
         r_liq.cod_modulo      := r_tip_ing.cod_modulo;
         r_liq.cod_modalidad   := r_tip_ing.cod_modalidad;
       --fin modificación
         r_liq.monto           := nvl(v_mto_aguinaldo,0);
         r_liq.computable      := null;
       --SE AGREGA CODIGO DE LA MONEDA
         r_liq.cod_moneda      := r_emp.cod_moneda;
         IF r_liq.monto > 0 THEN
            r_sob.cod_persona  := r_emp.cod_persona;
            r_sob.ano          := r_emr.ano_actual;
            r_sob.mes          := r_emr.mes_actual;
            r_sob.quincena     := r_emr.qui_actual;
            if r_emp.tipo = 'Z' and r_emr.cod_empresa <> '01' then
               r_sob.nro_patronal := r_emr.pat_ips_02;
            else
               r_sob.nro_patronal := r_emr.pat_ips_01;
            end if;
            r_sob.fec_calculo  := p_fec_proceso;
            if p_nro_sobre is null then
               prh_ins_sobre(r_sob, v_nro_sobre);
            else
               v_nro_sobre := p_nro_sobre;
            end if;
            r_liq.nro_sobre := v_nro_sobre;
            prh_ins_liq_sueldo(r_liq);
         END IF;
      end if;
   END LOOP;
END;
/
