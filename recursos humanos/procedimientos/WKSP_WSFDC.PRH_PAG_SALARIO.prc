CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_PAG_SALARIO
 (
 P_COD_ENTE IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
 P_COD_EMP_DESDE IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_COD_EMP_HASTA IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_FEC_PROCESO IN DATE,
 P_LUGAR OUT VARCHAR2,
 P_HUBO_ERROR OUT VARCHAR2
 )
 IS


   v_fecha          ge_calendarios.fec_actual%type;
   v_hora           ge_movimientos.hora%type;
   v_nro_secuencia  ge_movimientos.nro_secuencia%type;
   v_mto_pago       ge_cuentas.sal_contable%type;
   v_ente           ge_entes.cod_ente%type;
   v_empresa        rh_par_empresas.cod_empresa%type;
   --- Cursor de empleados a acreditar
   cursor c_empleados is
   select e.nro_cta_asociada nro_cuenta, s.nro_sobre,
          e.cod_oficina, e.cod_persona nro_documento, e.cod_moneda
     from rh_empleados e, rh_sobres s
    where e.cod_persona = s.cod_persona
      and s.ind_pagado  = 'N'
      and s.fec_calculo = p_fec_proceso
      and e.cod_per_empresa  = v_empresa
      and e.nro_cta_asociada is not null
      and e.cod_persona >= p_cod_emp_desde
      and e.cod_persona <= p_cod_emp_hasta;
BEGIN
   --- Recuperar datos de fecha calendario
   v_fecha          := to_char(sysdate,'DD/MM/YYYY');
   v_hora           := to_char(sysdate,'HH24:MI:SS');
   v_nro_secuencia  := 0;
   -----------------------------
    begin
      select cod_persona
      into   v_empresa
      from   ge_entes
      where  cod_ente = P_COD_ENTE
      and    tipo = 'SU';
   exception
      when no_data_found then
         p_lugar := 'La empresa no está definida como ente';
         p_hubo_error := 'S';
         raise_application_error(-20000,p_lugar);
      when others then
         p_lugar := 'PRH_PAGO_SALARIO' || ' - ' ||sqlerrm;
         p_hubo_error := 'S';
         raise_application_error(-20000,p_lugar);
   end;
   -----------------------------
   --- Inicializar secuencia
   v_nro_secuencia  := 0;
   for r_emp in c_empleados loop
      --- Recuperar datos de la cuenta de ahorro
      pag_cta.pr_obt_cuenta(r_emp.nro_cuenta);
      if pag_cta.g_cod_error <> 0 then
         p_lugar := 'Error al recuperar datos de la cuenta de ahorro para el empleado '
                 || to_char( r_emp.nro_documento) || ' - ' ||sqlerrm;
         p_hubo_error := 'S';
         raise_application_error(-20000,p_lugar);
      end if;
      --- Obtener monto total a acreditar
      select sum(nvl(pag_gen.fu_con_mon_a_moneda(l.cod_moneda, e.cod_moneda,
             nvl(decode(nvl(cod_tip_ingreso,0),0,l.monto * -1,l.monto),0)),0))
      into   v_mto_pago
      from   rh_liq_sueldos l, rh_empleados e
      where  l.cod_persona = e.cod_persona
      and    l.cod_persona = r_emp.nro_documento
      and    l.nro_sobre   = r_emp.nro_sobre;
      --- Verificar monedas ----
      v_mto_pago := pag_gen.fu_con_mon_a_moneda(r_emp.cod_moneda, pag_cta.g_ctas.cod_moneda,v_mto_pago);
      --- Para grabar por cada registro procesado y sus movimientos la misma hora
      v_fecha         := pag_cal.FU_OBT_FEC_ACTUAL(pag_cta.g_ctas.cod_modulo);
      v_hora          := pag_gen.fu_obt_sig_segundo(v_hora);
      v_nro_secuencia := v_nro_secuencia + 1;
      --- insertar en temporal en moneda de la cta
      begin
        insert into ge_pag_sueldos_tmp (
                    COD_ENTE,
                    FEC_PROCESO,
                    NRO_SECUENCIA,
                    COD_MODULO,
                    COD_MODALIDAD,
                    NRO_CUENTA,
                    COD_MONEDA,
                    FEC_ENVIO,
                    TIPO,
                    MONTO,
                    ESTADO,
                    COD_PROCESO)
        values (    v_ente,
                    v_fecha,
                    v_nro_secuencia,
                    pag_cta.g_ctas.cod_modulo,
                    pag_cta.g_ctas.cod_modalidad,
                    r_emp.nro_cuenta,
                    r_emp.cod_moneda,
                    P_FEC_PROCESO,
                    'C',
                    v_mto_pago,
                    'N',
                    0);
      exception
         when others then
         -- GOTO siguiente_registro;
            p_lugar := 'Error al insertar ge_pag_sueldos_tmp' || ' - ' ||sqlerrm;
            p_hubo_error := 'S';
            raise_application_error(-20000,p_lugar);
      end;

      --- Siguiente registro
      <<siguiente_registro>>
      null;
   end loop;
END;
/
