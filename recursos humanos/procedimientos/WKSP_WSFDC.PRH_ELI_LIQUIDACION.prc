CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_ELI_LIQUIDACION
 (
 P_COD_EPR_DESDE IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
 P_COD_EPR_HASTA IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
 P_COD_EMP_DESDE IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_COD_EMP_HASTA IN RH_EMPLEADOS.COD_PERSONA%TYPE,
 P_ACTUALIZA_EMPRESA IN VARCHAR2,
 P_FEC_PROCESO IN DATE
 )
 IS
--- Cursor de registros de liquidación a eliminar
   CURSOR c_liq_sueldos IS
      Select l.nro_sobre, l.cod_persona,
             l.vac_fec_desde, l.ing_numero, l.hex_fec_hor_extra, l.des_numero,
             e.fec_egreso
      from rh_liq_sueldos l, rh_empleados e, rh_sobres s
      WHERE s.fec_calculo = p_fec_proceso
      and s.cod_persona   = l.cod_persona
      and s.nro_sobre     = l.nro_sobre
      and l.cod_persona   = e.cod_persona
      and e.cod_per_empresa  >= p_cod_epr_desde
      and e.cod_per_empresa  <= p_cod_epr_hasta
      and l.cod_persona >= p_cod_emp_desde
      and l.cod_persona <= p_cod_emp_hasta
      and s.ind_pagado   = 'N';
BEGIN
   FOR r_liq IN c_liq_sueldos LOOP
      --- Recuperar datos de la empresa
      --- Eliminar registros de cheques
      /*
      DELETE rh_cheques
      WHERE nro_sobre  = r_liq.nro_sobre
      and cod_empleado = r_liq.cod_empleado;
      */
      --- Actualizar ingresos procesados
      IF r_liq.ing_numero IS NOT NULL THEN
         update rh_ingresos
         set ind_procesado  = 'N'
         where cod_persona  = r_liq.cod_persona
         and numero         = r_liq.ing_numero;
      END IF;
      --- Actualizar descuentos procesados
      IF r_liq.des_numero IS NOT NULL THEN
         update rh_descuentos
         set ind_procesado       = 'N'
         where cod_persona       = r_liq.cod_persona
         and numero              = r_liq.des_numero;
      END IF;
      --- Actualizar vacaciones procesadas
      IF r_liq.vac_fec_desde IS NOT NULL THEN
         update rh_vacaciones
         set ind_procesado  = 'N'
         where cod_persona = r_liq.cod_persona
         and fec_desde      = r_liq.vac_fec_desde;
      END IF;
      --- Actualizar horas extras procesadas
      IF r_liq.hex_fec_hor_extra IS NOT NULL THEN
         update rh_hor_extras
         set ind_procesado  = 'N'
         where cod_persona = r_liq.cod_persona
         and fecha  = r_liq.hex_fec_hor_extra;
      END IF;
      --- Eliminar provisiones
      -- actualizo aguinaldos cobrados
      update rh_provisiones
      set sal_actual = nvl(sal_actual,0) + nvl(mto_debe,0),
          mto_debe = 0
      where cod_persona = r_liq.cod_persona
      and to_char(fecha,'YYYY') = to_char(p_fec_proceso,'YYYY')
      and cod_tip_provision = 21; -- Aguinaldo
      -- elimino provision del sobre de despido
      delete rh_provisiones
      where cod_tip_provision = 21
      and cod_persona = r_liq.cod_persona
      and fecha = p_fec_proceso;
      --- Eliminar registros de liquidacion
      DELETE rh_liq_sueldos
      WHERE nro_sobre  = r_liq.nro_sobre
      and cod_persona = r_liq.cod_persona;
      IF r_liq.vac_fec_desde IS NOT NULL THEN
         if r_liq.fec_egreso is not null then
            --- Reversion de una liquidacion final
            delete rh_vacaciones
             where cod_persona = r_liq.cod_persona
               and fec_desde    = r_liq.vac_fec_desde;
            delete rh_provisiones
             where cod_persona  = r_liq.cod_persona
               and fecha = p_fec_proceso;
         end if;
      END IF;
      --- Eliminar SOBRES
      DELETE rh_sobres
      WHERE nro_sobre  = r_liq.nro_sobre
      and cod_persona = r_liq.cod_persona;
      --- Actualizar fecha de egreso si el empleado esta saliendo
      UPDATE rh_empleados
      set fec_egreso = null
      where cod_persona = r_liq.cod_persona;
      --- Actualizar ausencias
      update rh_ausencias
         set ind_procesado = 'N'
       where cod_persona = r_liq.cod_persona
         and ind_procesado = 'S'
         and fec_inicio >
             (select nvl(max(fec_calculo),last_day(add_months(p_fec_proceso,-1)))
                from rh_sobres
               where cod_persona = r_liq.cod_persona
                 and fec_calculo < p_fec_proceso)
         and fec_fin <= p_fec_proceso;
   END LOOP;
   IF p_actualiza_empresa = 'S' THEN
      UPDATE rh_par_empresas
      set qui_actual = decode(qui_actual,2,1,1,2),
          mes_actual = decode(qui_actual,2,mes_actual, mes_actual - 1),
          ano_actual = decode(mes_actual,1,ano_actual-1,ano_actual)
      where cod_empresa >= p_cod_epr_desde
      and cod_empresa   <= p_cod_epr_hasta;
   END IF;
END;
/
