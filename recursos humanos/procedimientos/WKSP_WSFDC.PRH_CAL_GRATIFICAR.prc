CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_CAL_GRATIFICAR
 (
   P_COD_EPR_DESDE IN RH_AUMENTOS.COD_EMPRESA%TYPE,
   P_COD_EPR_HASTA IN RH_AUMENTOS.COD_EMPRESA%TYPE,
   P_COD_CEN_COSTO IN RH_AUMENTOS.COD_CEN_COSTO%TYPE,
   P_COD_EMP_DESDE IN RH_AUMENTOS.COD_PER_DESDE%TYPE,
   P_COD_EMP_HASTA IN RH_AUMENTOS.COD_PER_HASTA%TYPE,
   P_FEC_AUMENTO IN RH_AUMENTOS.FECHA%TYPE
 )
 IS
/* Recupera el salario mínimo. */
PROCEDURE LP_OBT_SAL_MINIMO
 (P_COD_SAL_MINIMO IN RH_SAL_MINIMOS.COD_SAL_MINIMO%TYPE
 ,RP_SALMIN IN OUT RH_SAL_MINIMOS%ROWTYPE
 );
   r_aum          rh_aumentos%rowtype;
   r_ing          rh_ingresos%rowtype;
   r_salmin       rh_sal_minimos%rowtype;
   v_aumento      rh_empleados.sal_base%type;
   v_cod_empresa  rh_empleados.cod_per_empresa%type;
   v_existe       BOOLEAN;
   --- Cursor de aumentos
   CURSOR c_aumentos IS
      select *
      from rh_aumentos
      where cod_empresa >= p_cod_epr_desde
      and  cod_empresa  <= p_cod_epr_hasta
      and cod_per_desde = p_cod_emp_desde
      and cod_per_hasta = p_cod_emp_hasta
      and fecha         = p_fec_aumento
      and ind_procesado = 'N'
      and ind_afectacion = 'G'
      and cod_per_autorizador IS NOT NULL;
   --- Cursor de empleados
   CURSOR c_empleados IS
      select cod_per_empresa, cod_sal_minimo, cod_persona, sal_base, cod_moneda
      from rh_empleados
      where cod_per_empresa = v_cod_empresa
      and  cod_persona >= p_cod_emp_desde
      and  cod_persona <= p_cod_emp_hasta
      and  fec_egreso is null
      and  cod_cen_costo = nvl(p_cod_cen_costo,cod_cen_costo);
/* Recupera el salario mínimo. */
PROCEDURE LP_OBT_SAL_MINIMO
 (P_COD_SAL_MINIMO IN RH_SAL_MINIMOS.COD_SAL_MINIMO%TYPE
 ,RP_SALMIN IN OUT RH_SAL_MINIMOS%ROWTYPE
 )
 IS
BEGIN
   select *
   into rp_salmin
   from rh_sal_minimos
   where cod_sal_minimo = p_cod_sal_minimo;
exception
    when no_data_found then
       raise_application_error(-20000,
       'Salario minimo '||to_char(p_cod_sal_minimo)||' no registrado');
END;
BEGIN
   v_existe := FALSE;
   FOR r_aum IN c_aumentos LOOP
      v_existe := TRUE;
      v_cod_empresa := r_aum.cod_empresa;
      FOR r_emp IN c_empleados LOOP
         if r_aum.monto is not null then
            v_aumento := r_aum.monto;
         else
          --lp_obt_sal_minimo(r_emp.cod_sal_minimo, r_salmin);
          --v_aumento := round((r_salmin.monto * r_aum.porcentaje)/100);
          --En Bco. Regional las Gratificaciones son en base al Salario Basico
            v_aumento := round((r_emp.sal_base * r_aum.porcentaje)/100);
         end if;
         --- Insertar ingreso
         r_ing.cod_persona      := r_emp.cod_persona;
         r_ing.fecha            := sysdate;
         r_ing.cod_tip_ingreso  := r_aum.cod_tip_ingreso;
         r_ing.monto            := v_aumento;
         r_ing.ind_procesado    := 'N';
         r_ing.cod_per_autorizador := r_aum.cod_per_autorizador;
         --- se agrego codigo de la moneda
         r_ing.cod_moneda          := r_emp.cod_moneda;
         prh_ins_ingreso(r_ing);
      END LOOP;
      update rh_aumentos
      set ind_procesado = 'S'
      where cod_empresa = r_aum.cod_empresa
      and cod_cen_costo = r_aum.cod_cen_costo
      and cod_per_desde = r_aum.cod_per_desde
      and cod_per_hasta = r_aum.cod_per_hasta
      and fecha         = r_aum.fecha;
      IF sql%notfound then
         raise_application_error(-20000,
         'Gratificación no registrada');
      END IF;
   END LOOP;
   IF not v_existe THEN
      raise_application_error(-20000,
     'Gratificación no registrada o no autorizada');
   END IF;
END;
/
