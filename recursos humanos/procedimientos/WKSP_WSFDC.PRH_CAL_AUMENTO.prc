CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_CAL_AUMENTO
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
PROCEDURE LP_INS_DESCUENTOS
 (RP_DESC IN RH_DESCUENTOS%ROWTYPE
 );
   r_aum                rh_aumentos%rowtype;
   r_salmin             rh_sal_minimos%rowtype;
   v_aumento            rh_empleados.sal_base%type;
   v_cod_empresa        rh_empleados.cod_per_empresa%type;
   v_existe             BOOLEAN;
   r_des                rh_descuentos%rowtype;
   v_cod_des_aumento    rh_tip_descuentos.cod_tip_descuento%type;
   v_ind_apo_caja       rh_par_empresas.ind_apo_ips_caja%type;
   --- Cursor de aumentos
   CURSOR c_aumentos IS
      select *
      from rh_aumentos
      where cod_empresa >= p_cod_epr_desde
      and  cod_empresa  <= p_cod_epr_hasta
      and cod_per_desde = p_cod_emp_desde
      and cod_per_hasta = p_cod_emp_hasta
      and fecha   = p_fec_aumento
      and ind_procesado = 'N'
      and ind_afectacion = 'A'
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
   v_existe := FALSE;
   FOR r_aum IN c_aumentos LOOP
      v_existe := TRUE;
      v_cod_empresa := r_aum.cod_empresa;
      FOR r_emp IN c_empleados LOOP
         if r_aum.monto is not null then
            v_aumento := r_emp.sal_base + r_aum.monto;
         else
            lp_obt_sal_minimo(r_emp.cod_sal_minimo, r_salmin);
            v_aumento := round((r_salmin.monto * r_aum.porcentaje)/100);
            --- agregado el 12/abr/07
            --- no sumaba el aumento
            v_aumento := r_emp.sal_base + v_aumento;
            --- fin actualizacion
         end if;
         update rh_empleados
         set sal_base = v_aumento
         where cod_persona = r_emp.cod_persona;
         --- Insertar descuento del empleado para la Caja
         select p.cod_tip_des_aumento, p.ind_apo_ips_caja
         into   v_cod_des_aumento, v_ind_apo_caja
         from   rh_par_empresas p
         where  p.cod_empresa = r_emp.cod_per_empresa;
         If v_ind_apo_caja = 'C' then
            r_des.cod_persona       := r_emp.cod_persona;
            r_des.fecha             := P_FEC_AUMENTO;
            r_des.cod_tip_descuento := v_cod_des_aumento;
            r_des.ind_procesado     := 'N';
            r_des.monto             := v_aumento;
            r_des.cod_moneda        := r_emp.cod_moneda;
            r_des.porcentaje        := null;
            r_des.ind_automatico    := 'S';
            lp_ins_descuentos(r_des);
         end if;
      END LOOP;
      update rh_aumentos
      set ind_procesado = 'S'
      where cod_empresa = r_aum.cod_empresa
      and cod_cen_costo = r_aum.cod_cen_costo
      and cod_per_desde = r_aum.cod_per_desde
      and cod_per_hasta = r_aum.cod_per_hasta
      and fecha   = r_aum.fecha;
      IF sql%notfound then
         raise_application_error(-20000,
         'Aumento no registrado');
      END IF;
   END LOOP;
   IF not v_existe THEN
      raise_application_error(-20000,
     'Aumento no registrado o no autorizado');
   END IF;
END;
/
