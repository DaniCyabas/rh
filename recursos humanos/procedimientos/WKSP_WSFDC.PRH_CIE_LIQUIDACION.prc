CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_CIE_LIQUIDACION
 (
   P_COD_EPR_DESDE IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
   P_COD_EPR_HASTA IN RH_PAR_EMPRESAS.COD_EMPRESA%TYPE,
   P_FEC_CIERRE IN DATE
 )
 IS
   r_emr   rh_par_empresas%rowtype;
   v_ano   rh_par_empresas.ano_actual%type;
   v_mes   rh_par_empresas.mes_actual%type;
   v_qui   rh_par_empresas.qui_actual%type;
   -- modificado para obtener la transaccion
   -- defino por defecto el modulo y modalidad a utilizar
   v_cod_modulo        number(3)    := 14;          -- RRHH
   v_cod_modalidad     number(3)    := 141;         -- RRHH
   v_cod_usuario       varchar2(10) := upper(user); -- usuario
   v_cod_transaccion   ge_movimientos.cod_transaccion%type;
   v_mto_transaccion   ge_movimientos.monto%type;
   -- Datos para generar el movimiento
   v_fec_actual        date         := pag_cal.fu_obt_fec_actual(v_cod_modulo); -- fecha de hoy
   v_hor_actual        varchar2(08) := to_char(sysdate,'HH24:MI:SS');           -- Hora actual
   v_cod_moneda        varchar2(3)  := pag_gen.fu_obt_mon_local;                -- moneda de la cuenta
   v_cod_persona       rh_liq_sueldos.cod_persona%type;
   v_nro_sobre         rh_liq_sueldos.nro_sobre%type;
   v_nro_secuencia     number(3) := 0;  -- secuencia del mov.
   r_gmovi             ge_movimientos%rowtype;
   v_cod_tip_movto     char(1);
   r_tip_ing           rh_tip_ingresos%rowtype;
   r_tip_des           rh_tip_descuentos%rowtype;
   v_concepto          ge_movimientos.concepto%type;
 --fin modificaciones
   v_cod_tip_descuento   rh_liq_sueldos.cod_tip_descuento%type;
 --v_mig_caja            BOOLEAN;
   v_cod_empresa rh_par_empresas.cod_empresa%type;
   v_actividad varchar2(02);
   --- variables para calculo de aporte a la caja
   v_monto_titulo         rh_liq_sueldos.monto%type;
   v_monto_antiguedad     rh_liq_sueldos.monto%type;
   v_monto_cargo          rh_liq_sueldos.monto%type;
   v_monto_representacion rh_liq_sueldos.monto%type;
   v_monto_hor_extras     rh_liq_sueldos.monto%type;
   v_monto_caja           rh_liq_sueldos.monto%type;
   v_monto_fondo          rh_liq_sueldos.monto%type;
   v_monto_pri_sueldo     rh_liq_sueldos.monto%type;
   v_monto_otros_ing      rh_liq_sueldos.monto%type;
   v_monto_gratificacion  rh_liq_sueldos.monto%type;
   v_monto_aumento        rh_liq_sueldos.monto%type;
   v_monto_imponible      rh_liq_sueldos.monto%type;
   v_can_dias             number(10);
   v_aporte_caja_pat      rh_liq_sueldos.monto%type;
   v_aporte_caja_fondo    rh_liq_sueldos.monto%type;
   v_aporte_caja_snpp     rh_liq_sueldos.monto%type;
   --- Cursor de Empresas a cerrar
   cursor c_empresa is
   select *
   from rh_par_empresas
   where cod_empresa >= p_cod_epr_desde
   and   cod_empresa <= p_cod_epr_hasta
   order by cod_empresa;
   --- Cursor de IPS a informa
   CURSOR c_empleados IS
   select e.nro_ips, s.nro_patronal, e.nro_caja,
          l.cod_persona, l.nro_sobre,
          p.nro_documento nro_cedula,
          rtrim(f.pri_apellido || ' ' || nvl(f.seg_apellido,' ')) apellido,
          rtrim(f.pri_nombre || ' ' || nvl(f.seg_nombre,' ')) nombre,
          decode(e.cod_cat_empleado,2,'E',3,'O','E') categoria,
          '00' actividad, e.fec_ingreso, e.fec_egreso,
          e.sal_base, e.cod_oficina,
          sum(l.computable) computable, sum(l.monto) mto_movto
   from rh_liq_sueldos l, rh_empleados e, rh_sobres s,
        ba_personas p, ba_per_fisicas f
   where e.cod_persona     = l.cod_persona
   and   p.cod_persona     = e.cod_persona
   and   p.cod_persona     = f.cod_persona --(+)
   and   s.nro_sobre       = l.nro_sobre
   and   s.cod_persona     = l.cod_persona
   and   s.ano             = v_ano
   and   s.mes             = v_mes
 --and   s.quincena        = v_qui
   and   e.cod_per_empresa = v_cod_empresa
 --and   l.cod_tip_descuento = v_cod_tip_descuento --Se informan los salarios
   and  (e.nro_ips is not null or e.nro_caja is not null)
   group by e.nro_ips, s.nro_patronal, e.nro_caja,
            l.cod_persona, l.nro_sobre,
            p.nro_documento, rtrim(f.pri_apellido || ' ' || nvl(f.seg_apellido,' ')),
            rtrim(f.pri_nombre || ' ' || nvl(f.seg_nombre,' ')),
            decode(e.cod_cat_empleado,2,'E',3,'O','E'), '00',
            e.fec_ingreso, e.fec_egreso, e.sal_base, e.cod_oficina;
 --cursor movimientos de empleados
   cursor c_mov is
   select *
   from   rh_liq_sueldos l
   where  l.cod_persona = v_cod_persona
   and    l.nro_sobre   = v_nro_sobre;
   ---
   v_archivo           utl_file.file_type;
   v_patronal_ant      rh_sobres.nro_patronal%type;
   v_linea             varchar2(400);
   v_cantidad          number(10);
   v_can_vacaciones    number(10);
   v_can_reposo        number(10);
BEGIN
 --v_mig_caja     := FALSE;
   v_patronal_ant := null;
   --- Realizar archivo de IPS
   --- Recuperar datos de la Empresa
   FOR r_emr IN c_empresa LOOP
      v_ano := to_number(to_char(p_fec_cierre,'YYYY'));
      v_mes := to_number(to_char(p_fec_cierre,'MM'));
      v_qui := r_emr.qui_actual;
      v_cod_tip_descuento := r_emr.cod_tip_des_ips;
      v_cod_empresa := r_emr.cod_empresa;
      FOR r_emp IN c_empleados LOOP
         --- Abrir archivo por cada diferente patronal
         if nvl(v_patronal_ant,0) <> r_emp.nro_patronal then
            if utl_file.is_open(v_archivo) then
               utl_file.fclose(v_archivo);
            end if;
            v_archivo      := utl_file.fopen('/backup',R_EMP.NRO_PATRONAL||'.TXT','w');
          --v_archivo      := utl_file.fopen('c:\rrhh',R_EMP.NRO_PATRONAL||'.TXT','w');
            v_patronal_ant := r_emp.nro_patronal;
         end if;
         --- Calcular actividad a informar ---
         v_actividad := r_emp.actividad;
         -------------------------------------
         if r_emr.ind_apo_ips_caja = 'I' or
           (r_emr.ind_apo_ips_caja = 'A' and r_emp.nro_ips is not null) then --- formato para IPS
            BEGIN
              if to_char(r_emp.fec_ingreso,'YYYYMM') = to_char(p_fec_cierre,'YYYYMM') then
                 v_actividad := '01';
              end if;
              if to_char(r_emp.fec_egreso,'YYYYMM') = to_char(p_fec_cierre,'YYYYMM') then
                 select count(*) into v_cantidad
                   from rh_liq_sueldos l, rh_sobres s
                  where s.cod_persona = r_emp.cod_persona
                    and s.nro_sobre = l.nro_sobre
                    and s.cod_persona = l.cod_persona
                    and s.ano = v_ano
                    and s.mes = v_mes
                    and l.cod_tip_ingreso in --(14,16);
                       ( (select emp1.cod_tip_ing_preaviso
                          from   rh_par_empresas emp1
                          where  emp1.cod_empresa = r_emr.cod_empresa),
                         (select emp2.cod_tip_ing_indemnizacion
                          from   rh_par_empresas emp2
                          where  emp2.cod_empresa = r_emr.cod_empresa));
                 if v_cantidad > 0 then
                    v_actividad := '05';
                 else
                    v_actividad := '02';
                 end if;
              else --- Si no es salida
                 select count(*) into v_can_vacaciones
                   from rh_liq_sueldos l, rh_sobres s
                  where s.cod_persona = r_emp.cod_persona
                    and s.nro_sobre = l.nro_sobre
                    and s.cod_persona = l.cod_persona
                    and s.ano = v_ano
                    and s.mes = v_mes
                    and l.cod_tip_ingreso in --(9,18);
                       ( (select emp3.cod_tip_ing_vacacion
                          from   rh_par_empresas emp3
                          where  emp3.cod_empresa = r_emr.cod_empresa),
                         (select emp4.cod_tip_prov_vacacion
                          from   rh_par_empresas emp4
                          where  emp4.cod_empresa = r_emr.cod_empresa));
                 -------------------------------------
                 begin
                  --select trunc(a.fec_fin-a.fec_inicio+1) dias
                  --En Bco. Regional se tienen en cuenta los días hábiles
                    select trunc(fuh_obt_dif_dias(a.fec_fin,a.fec_inicio+1)) dias
                    into   v_can_reposo
                    from   rh_liq_sueldos l, rh_sobres s,
                           rh_ausencias a, rh_tip_ausencias t
                    where  s.cod_persona = r_emp.cod_persona
                    and    a.cod_persona = s.cod_persona
                    and    s.nro_sobre   = l.nro_sobre
                    and    s.cod_persona = l.cod_persona
                    and    a.cod_tip_ausencia = t.cod_tip_ausencia
                    and    t.ind_goc_sueldo  = 'S'
                    and    a.ind_justificado = 'S'
                    and    a.ind_procesado   = 'S'
                    and    trunc(a.fec_fin) <=   s.fec_calculo
                    and    trunc(a.fec_inicio) > add_months (s.fec_calculo,-1);
                 exception
                    when no_data_found then
                       v_can_reposo := 0;
                    when others then 
                       raise_application_error(-20000,'Error: '||sqlerrm);
                  end;
                 --------------------------------------
                 if v_can_vacaciones <> 0 and v_can_reposo = 0 then
                    v_actividad := '03';
                 elsif v_can_vacaciones = 0 and v_can_reposo > 0 then
                    v_actividad := '04';
                 elsif v_can_vacaciones > 0 and v_can_reposo > 0 then
                    v_actividad := '06';
                 end if;
              end if;

              v_linea := lpad(trim(to_char(r_emp.nro_patronal)),10,' ')||
                         lpad(r_emp.cod_persona,10,' ')||
                         lpad(r_emp.nro_cedula,10,'0')||
                         rpad(r_emp.apellido,30,' ')||
                         rpad(r_emp.nombre,30,' ')||
                         r_emp.categoria||
                         lpad(to_char(r_emp.computable),2,'0')||
                         lpad(to_char(r_emp.mto_movto),10,' ')||
                         lpad(to_char(r_emp.computable),2,'0')||
                         lpad(to_char(r_emp.mto_movto),10,' ')||
                         lpad(to_char(v_mes),2,'0')||
                         to_char(v_ano)||
                         v_actividad;
            END;
         elsif r_emr.ind_apo_ips_caja = 'C' or
              (r_emr.ind_apo_ips_caja = 'A' and r_emp.nro_caja is not null) then --- formato para la Caja
            BEGIN
               v_monto_titulo         :=0;
               v_monto_antiguedad     :=0;
               v_monto_cargo          :=0;
               v_monto_representacion :=0;
               v_monto_hor_extras     :=0;
               v_monto_caja           :=0;
               v_monto_fondo          :=0;
               v_monto_pri_sueldo     :=0;
               v_monto_otros_ing      :=0;
               v_can_dias             :=0;
               --- dias de asistencia
               select count(*)
               into   v_can_dias
               from   rh_asistencias a
               where  a.cod_persona = r_emp.cod_persona
               and    to_char(a.fecha,'MM') = v_mes
               and    to_char(a.fecha,'YYYY') = v_ano;
               --- monto del adicional por titulo universitario
               select sum(l.monto) into v_monto_titulo
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_ingreso = r_emr.cod_tip_ing_titulo;
               --- monto del adicional por antigüedad
               select sum(l.monto) into v_monto_antiguedad
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_ingreso = r_emr.cod_tip_ing_antiguedad;
               --- monto del adicional por cargo
               select sum(l.monto) into v_monto_cargo
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_ingreso = r_emr.cod_tip_ing_cargo;
               --- monto del adicional por gastos de representación
               select sum(l.monto) into v_monto_representacion
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_ingreso = r_emr.cod_tip_ing_representacion;
               --- monto de las horas extras
               select sum(l.monto) into v_monto_hor_extras
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_ingreso in (r_emr.cod_tip_ing_extras, r_emr.cod_tip_ing_30,
                      r_emr.cod_tip_ing_50, r_emr.cod_tip_ing_100,  r_emr.cod_tip_ing_130);
               --- monto del aporte a la caja
               select sum(l.monto) into v_monto_caja
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_descuento = r_emr.cod_tip_des_caja;
               --- monto del aporte al fondo de actualización
               select sum(l.monto) into v_monto_fondo
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_descuento = r_emr.cod_tip_des_fondo;
               --- monto del aporte por el primer sueldo
               select sum(l.monto) into v_monto_pri_sueldo
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_descuento = r_emr.cod_tip_des_pri_sueldo;
               --- monto otros ingresos
               select sum(l.monto) into v_monto_otros_ing
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_ingreso not in ( r_emr.cod_tip_ing_sueldo,
                      r_emr.cod_tip_ing_extras, r_emr.cod_tip_ing_30,
                      r_emr.cod_tip_ing_50, r_emr.cod_tip_ing_100,  r_emr.cod_tip_ing_130,
                      r_emr.cod_tip_ing_titulo, r_emr.cod_tip_ing_antiguedad, r_emr.cod_tip_ing_cargo,
                      r_emr.cod_tip_ing_representacion);
              --- gratificacion
               select sum(l.monto) into v_monto_gratificacion
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_ingreso = r_emr.cod_tip_ing_gratificacion;
              --- aumento
               select sum(l.monto) into v_monto_aumento
                 from rh_liq_sueldos l, rh_sobres s
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_ingreso = r_emr.cod_tip_des_aumento;
               --- Calcular imponible para calculo de aporte patronal
               select sum(l.monto) into v_monto_imponible
                 from rh_liq_sueldos l, rh_sobres s, rh_tip_ingresos t
                where s.cod_persona = r_emp.cod_persona
                  and s.nro_sobre = l.nro_sobre
                  and s.cod_persona = l.cod_persona
                  and s.ano = v_ano
                  and s.mes = v_mes
                  and l.cod_tip_ingreso = t.cod_tip_ingreso
                  and t.ind_imponible = 'S';
               --aporte patronal
               v_aporte_caja_pat   := round(nvl(v_monto_imponible,0) * nvl(r_emr.por_caj_pat, nvl(r_emr.por_caj_pat,0))/100,0);
               --aporte patronal para fondo
               v_aporte_caja_fondo := round(nvl(v_monto_imponible,0) * nvl(r_emr.por_caj_pat_act, nvl(r_emr.por_caj_pat_act,0))/100,0);
               --retención SNPP
               v_aporte_caja_snpp  := round(nvl(v_monto_imponible,0) * nvl(r_emr.por_caj_ret_snpp, nvl(r_emr.por_caj_ret_snpp,0))/100,0);
               ----------------------------------------------
               v_linea := lpad(r_emp.nro_caja,6,'0')||
                          lpad(r_emr.cod_ban_caja,3,'0')||
                          rpad(nvl(r_emp.apellido,0),30,' ')||
                          rpad(nvl(r_emp.nombre,0),30,' ')||
                          lpad(to_char(last_day(to_date('01/'||to_char(v_mes)||'/'||to_char(v_ano),'DD/MM/YYYY')),'YYYYMMDD'),8,'0')||
                          lpad(to_char(nvl(r_emp.sal_base,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_titulo,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_antiguedad,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_cargo,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_hor_extras,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_representacion,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_otros_ing,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_gratificacion,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_imponible,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_aumento,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_pri_sueldo,0)),11,'0')||
                          lpad(to_char(nvl(r_emr.por_caj_emp * 100,0)),5,'0')||
                          lpad(to_char(nvl(v_monto_caja,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_caja,0)),11,'0')||
                          lpad(to_char(nvl(v_monto_fondo,0)),11,'0')||
                          lpad(to_char(nvl(r_emr.por_caj_pat * 100,0)),5,'0')||
                          lpad(to_char(nvl(v_aporte_caja_pat,0)),11,'0')||
                          lpad(to_char(nvl(v_aporte_caja_pat,0)),11,'0')||
                          lpad(to_char(nvl(v_aporte_caja_fondo,0)),11,'0')||
                          lpad(to_char(nvl(v_aporte_caja_snpp,0)),11,'0');
            END;
         end if;
         --------------------------------------
         utl_file.put_line(v_archivo, v_linea);
         --------------------------------------
         ---
         ---------------------------
         --- INSERTAR MOVIMIENTO ---
         ---------------------------
         ---
         v_cod_persona := r_emp.cod_persona;
         v_nro_sobre   := r_emp.nro_sobre;
         for r_liq in c_mov loop
            if nvl(r_liq.cod_tip_ingreso,0) = 0 then
               v_cod_tip_movto := 'D';
               --- Recuperar tipo de mvto del descuento
               prh_obt_tip_descuent(r_liq.cod_tip_descuento, r_tip_des);
               v_concepto := r_tip_des.descripcion;
            else
               v_cod_tip_movto := 'C';
               --- Recuperar tipo de mvto del ingreso
               prh_obt_tip_ingreso(r_liq.cod_tip_ingreso, r_tip_ing);
               v_concepto := r_tip_ing.descripcion;
            end if;
            ---
            v_cod_modulo            := r_liq.cod_modulo;
            v_cod_modalidad         := r_liq.cod_modalidad;
            v_cod_transaccion       := r_liq.cod_transaccion;
            v_mto_transaccion       := r_liq.monto;
            v_hor_actual            := pag_gen.fu_obt_sig_segundo(v_hor_actual);
            -- Aumento la secuencia
            v_nro_secuencia         := nvl(v_nro_secuencia,0) + 1;
            -- Genero el movimiento
            r_gmovi.cod_modulo      := v_cod_modulo;
            r_gmovi.cod_modalidad   := v_cod_modalidad;
            r_gmovi.cod_oficina     := nvl(r_emp.cod_oficina,11);
            r_gmovi.nro_cuenta      := null;
            r_gmovi.cod_moneda      := v_cod_moneda;
            r_gmovi.cod_usuario     := v_cod_usuario;
            r_gmovi.hora            := v_hor_actual;
            r_gmovi.fecha           := v_fec_actual;
            r_gmovi.nro_secuencia   := v_nro_secuencia;
            --
            r_gmovi.fec_valor       := v_fec_actual;
            r_gmovi.cod_tra_padre   := 1303;
            r_gmovi.cod_mod_padre   := v_cod_modulo;
            r_gmovi.cod_mad_padre   := v_cod_modalidad;
            r_gmovi.cod_transaccion := v_cod_transaccion;
            r_gmovi.monto           := v_mto_transaccion;
            r_gmovi.nro_documento   := v_cod_persona;
            r_gmovi.cod_tasa        := null;
            r_gmovi.val_tasa        := null;
            r_gmovi.cotizacion      := null;
            r_gmovi.cod_ofi_origen  := nvl(r_emp.cod_oficina,11);
            r_gmovi.emi_aviso       := 'N';
            r_gmovi.concepto        := v_concepto;
            r_gmovi.estado          := 'N';
            r_gmovi.reversado       := 'N';
            r_gmovi.nro_caja        := null;
            r_gmovi.cod_rubro       := NULL;
            r_gmovi.tip_mov_rubro   := v_cod_tip_movto;
            PAG_GEN.PR_INS_GE_MOVIMIENTO(r_gmovi, 'N'); -- no es nocturno

         end loop;
         ---
      END LOOP;
      ---
      update rh_par_empresas
      set fec_ult_cierre = p_fec_cierre
      where cod_empresa = r_emr.cod_empresa;
      if sql%notfound then
         raise_application_error(-20000,
         'La empresa no fue actualizada');
      end if;
  END LOOP;
   utl_file.fclose(v_archivo);
   EXCEPTION
     when no_data_found then
        --- Fin del archivo
        utl_file.fclose(v_archivo);
     when utl_file.invalid_path  THEN
        utl_file.fclose(v_archivo);
        raise_application_error(-20000,
        'Directorio invalido');
     when utl_file.invalid_mode  THEN
        utl_file.fclose(v_archivo);
        raise_application_error(-20000,
        'Modo invalido');
     when utl_file.invalid_filehandle THEN
        utl_file.fclose(v_archivo);
        raise_application_error(-20000,
        'Invalida Filehandle');
     when utl_file.invalid_operation  THEN
        --- Fin del archivo
        utl_file.fclose(v_archivo);
     when utl_file.read_error         THEN
        utl_file.fclose(v_archivo);
        raise_application_error(-20000,
        'Lectura errada');
     when utl_file.write_error        THEN
        utl_file.fclose(v_archivo);
        raise_application_error(-20000,
        'Escritura errada');
     when utl_file.internal_error     THEN
         utl_file.fclose(v_archivo);
        raise_application_error(-20000,
        'Error interno');
END;
/
