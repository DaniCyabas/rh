CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_GEN_DESCUENTOS
 (
 P_COD_EPR_DESDE IN RH_EMPLEADOS.COD_PER_EMPRESA%TYPE,
 P_COD_EPR_HASTA IN RH_EMPLEADOS.COD_PER_EMPRESA%TYPE,
 P_COD_EMP_DESDE IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_COD_EMP_HASTA IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_FEC_PROCESO IN DATE
 )
 IS

/* Insertar registros de descuentos */
PROCEDURE LP_INS_DESCUENTOS
 (RP_DESC IN RH_DESCUENTOS%ROWTYPE
 );
r_des  rh_descuentos%rowtype;
   --- Recuperar cuotas de créditos vencidas
   /*
   CURSOR c_cuotas IS
   select c.cod_persona, c.nro_prestamo, 
          c.numero, c.monto,
          c.fec_vto, p.cod_tip_descuento
   from  rh_cuotas c, rh_empleados e, rh_prestamos p
   where c.cod_empleado = e.cod_empleado
   and   c.cod_empleado = p.cod_empleado
   and   c.nro_prestamo = p.nro_prestamo
   and   e.cod_empresa >= p_cod_epr_desde
   and   e.cod_empresa <= p_cod_epr_hasta
   and   c.cod_empleado >= p_cod_emp_desde
   and   c.cod_empleado <= p_cod_emp_hasta
   and   c.fec_pago is null
   and   e.fec_egreso is null
   and   c.fec_vto <= p_fec_proceso;
   */
   --- Recuperar descuentos automaticos a procesar vigentes
   CURSOR c_automatico IS
   select d.cod_persona, d.cod_tip_descuento, d.monto, d.cod_moneda, d.porcentaje
   from rh_des_automaticos d, rh_empleados e
   where d.cod_persona = e.cod_persona
   and   e.fec_egreso is null
   and   e.cod_per_empresa >= p_cod_epr_desde
   and   e.cod_per_empresa <= p_cod_epr_hasta
   and   e.cod_persona >= p_cod_emp_desde
   and   e.cod_persona <= p_cod_emp_hasta
   and   d.fec_hasta >= p_fec_proceso;
/* Insertar registros de descuentos */
PROCEDURE LP_INS_DESCUENTOS
 (RP_DESC IN RH_DESCUENTOS%ROWTYPE
 )
 IS
v_numero  rh_descuentos.numero%type;
BEGIN
   select nvl(max(numero),0) + 1
   into v_numero
   from rh_descuentos
   where cod_persona = rp_desc.cod_persona;
   insert into rh_descuentos
      (cod_persona, numero, fecha,
       cod_tip_descuento, ind_procesado, monto,
       cod_moneda, porcentaje, ind_automatico)
   values
      (rp_desc.cod_persona, v_numero, rp_desc.fecha,
       rp_desc.cod_tip_descuento, rp_desc.ind_procesado, rp_desc.monto,
       rp_desc.cod_moneda, rp_desc.porcentaje, rp_desc.ind_automatico);
exception
   when others then
      raise_application_error(-20000,
      'Ins.Desc.Emp. '||rp_desc.cod_persona||' '||sqlerrm);
END;
BEGIN
   --- Recorrer créditos
   --- no se implementará en Regional
   /*
   FOR r_cuo IN c_cuotas LOOP
      --- Eliminar descuento si existe y aun no fue procesado
      BEGIN
         Delete rh_descuentos
          where cod_empleado      = r_cuo.cod_empleado
            and fec_descuento     = p_fec_proceso
            and cod_tip_descuento = r_cuo.cod_tip_descuento
            and ind_procesado     = 'N'
            and mto_descuento     = r_cuo.monto
            and ind_automatico    = 'S'
            and nro_prestamo      = r_cuo.nro_prestamo
            and cuo_numero        = r_cuo.numero;
      END;
      r_des.cod_empleado      := r_cuo.cod_empleado;
      r_des.fec_descuento     := p_fec_proceso;
      r_des.cod_tip_descuento := r_cuo.cod_tip_descuento;
      r_des.ind_procesado     := 'N';
      r_des.mto_descuento     := r_cuo.monto;
      r_des.ind_automatico    := 'S';
      r_des.nro_prestamo      := r_cuo.nro_prestamo;
      r_des.cuo_numero        := r_cuo.numero;
      lp_ins_descuentos(r_des);
   END LOOP;
   */
   --- Recorrer descuentos automáticos
   FOR r_aut IN c_automatico LOOP
      BEGIN
         Delete rh_descuentos
          where cod_persona           = r_aut.cod_persona
            and fecha                 = p_fec_proceso
            and cod_tip_descuento     = r_aut.cod_tip_descuento
            and ind_procesado         = 'N'
            and nvl(monto,-1)         = nvl(r_aut.monto,-1)
            and nvl(porcentaje,-1)    = nvl(r_aut.porcentaje,-1)
            and ind_automatico        = 'S';
      END;
      r_des.cod_persona       := r_aut.cod_persona;
      r_des.fecha             := p_fec_proceso;
      r_des.cod_tip_descuento := r_aut.cod_tip_descuento;
      r_des.ind_procesado     := 'N';
      r_des.monto             := r_aut.monto;
      r_des.cod_moneda        := r_aut.cod_moneda;
      r_des.porcentaje        := r_aut.porcentaje;
      r_des.ind_automatico    := 'S';
      lp_ins_descuentos(r_des);
   END LOOP;
END;
/
