CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_GEN_INGRESOS
 (
   P_COD_EPR_DESDE IN RH_EMPLEADOS.COD_PER_EMPRESA%TYPE
   P_COD_EPR_HASTA IN RH_EMPLEADOS.COD_PER_EMPRESA%TYPE
   P_COD_EMP_DESDE IN RH_EMPLEADOS.COD_PERSONA%TYPE
   P_COD_EMP_HASTA IN RH_EMPLEADOS.COD_PERSONA%TYPE
   P_FEC_PROCESO IN DATE
 )
 IS
/* Insertar registros de ingresos */
PROCEDURE LP_INS_INGRESOS
 (RP_ING IN RH_INGRESOS%ROWTYPE
 );
   r_ing  rh_ingresos%rowtype;
   CURSOR c_automatico IS
   select d.cod_persona, d.cod_tip_ingreso, d.monto, d.cod_moneda
   from   rh_ing_automaticos d, rh_empleados e
   where  d.cod_persona = e.cod_persona
   and    e.fec_egreso is null
   and    e.cod_per_empresa >= p_cod_epr_desde
   and    e.cod_per_empresa <= p_cod_epr_hasta
   and    e.cod_persona >= p_cod_emp_desde
   and    e.cod_persona <= p_cod_emp_hasta
   and    d.fec_hasta   >= p_fec_proceso;
/* Insertar registros de ingresos */
PROCEDURE LP_INS_INGRESOS
 (RP_ING IN RH_INGRESOS%ROWTYPE
 )
 IS
v_numero  rh_ingresos.numero%type;
BEGIN
   select nvl(max(numero),0) + 1
   into v_numero
   from rh_ingresos
   where cod_persona = rp_ing.cod_persona;
   insert into rh_ingresos
      (cod_persona, numero, fecha,
       cod_tip_ingreso, ind_procesado, monto,
       cod_moneda, ind_automatico)
   values
      (rp_ing.cod_persona, v_numero, rp_ing.fecha,
       rp_ing.cod_tip_ingreso, rp_ing.ind_procesado, rp_ing.monto,
       rp_ing.cod_moneda, rp_ing.ind_automatico);
exception
   when others then
      raise_application_error(-20000,
      'Ins.Ing.Emp. '||rp_ing.cod_persona||' '||sqlerrm);
END;
BEGIN
   --- Recorrer ingresos automáticos
   FOR r_aut IN c_automatico LOOP
      BEGIN
         Delete rh_ingresos
          where cod_persona           = r_aut.cod_persona
            and fecha                 = p_fec_proceso
            and cod_tip_ingreso       = r_aut.cod_tip_ingreso
            and ind_procesado         = 'N'
            and nvl(monto,-1)         = nvl(r_aut.monto,-1)
            and ind_automatico        = 'S';
      END;
      r_ing.cod_persona       := r_aut.cod_persona;
      r_ing.fecha             := p_fec_proceso;
      r_ing.cod_tip_ingreso   := r_aut.cod_tip_ingreso;
      r_ing.ind_procesado     := 'N';
      r_ing.monto             := r_aut.monto;
      r_ing.cod_moneda        := r_aut.cod_moneda;
      r_ing.ind_automatico    := 'S';
      lp_ins_ingresos(r_ing);
   END LOOP;
END;
/
