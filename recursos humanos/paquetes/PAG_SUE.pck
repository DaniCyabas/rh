CREATE OR REPLACE PACKAGE WKSP_WSFDC.PAG_SUE IS

/* Verifica si no existe algo a reprocesar o sin procesar */
PROCEDURE PR_VER_WKSP_WSFDC.PAG_SUELDO
 (
 P_DATOS IN OUT VARCHAR2,
 P_REPROCESA IN OUT VARCHAR2,
 P_FECHA IN OUT DATE,
 P_COD_ENTE IN NUMBER,
 P_LUGAR IN OUT VARCHAR2
 );
/* Procesa los movimientos */
PROCEDURE PR_ACT_CRED_EMPLEADO
 (
   P_REPROCESO       IN OUT VARCHAR2,
   P_COD_ENTE        IN NUMBER,
   P_NRO_SECUENCIA   IN OUT NUMBER,
   P_CDOFICI         IN NUMBER,
   P_FEC_HOY         IN GE_WKSP_WSFDC.PAG_SUELDOS.FEC_PROCESO%TYPE,
   P_USUARIO         IN VARCHAR2,
   P_LUGAR           IN OUT VARCHAR2,
   P_HUBO_ERROR      OUT VARCHAR2,
   P_TIPO_TRA_PADRE IN VARCHAR2
 );
/* Inserta los movimientos */
PROCEDURE LP_INS_MOV_SUELDO
 (
   P_HUBO_ERROR     IN OUT VARCHAR2,
   P_HORAMOV        IN OUT VARCHAR2,
   P_REPROCESO      IN VARCHAR2,
   P_COD_ENTE       IN NUMBER,
   P_NRO_SECUENCIA  IN OUT NUMBER,
   P_LUGAR          IN OUT VARCHAR2,
   P_CDOFICI        IN NUMBER,
   P_FEC_HOY        IN GE_WKSP_WSFDC.PAG_SUELDOS.FEC_PROCESO%TYPE,
   P_USUARIO        IN VARCHAR2,
   P_TIPO_TRA_PADRE IN VARCHAR2 
 );
/* Borra los datos procesados del temporal */
PROCEDURE LP_DEL_DATOS_TEMPORA
 (
 P_COD_ENTE IN NUMBER,
 P_FEC_HOY IN DATE,
 P_LUGAR IN OUT VARCHAR2
 );
/* Inserta en el GE_WKSP_WSFDC.PAG_SUELDOS_TMP los registros con error */
PROCEDURE LP_INS_ERROR_PROCESO
 
 (
   P_COD_ENTE IN NUMBER,
   P_FEC_HOY IN DATE,
   P_LUGAR IN OUT VARCHAR2
 );
/* Verifica creditos y debitos procesados */
PROCEDURE PR_ACT_DATOS_PAGADOS
 (
   P_COD_ENTE IN NUMBER,
   P_FEC_HOY IN DATE,
   P_LUGAR IN OUT VARCHAR2
 );
/* Proceso principal de inserción y generación */
PROCEDURE PR_INS_GE_WKSP_WSFDC.PAG_SUELDO
 (
   P_VERIFICA_OK IN OUT VARCHAR2,
   P_COD_ENTE IN NUMBER,
   P_CTADBSU IN VARCHAR2,
   P_TRANPDB IN NUMBER,
   P_FEC_HOY IN GE_WKSP_WSFDC.PAG_SUELDOS.FEC_PROCESO%TYPE,
   P_LUGAR IN OUT VARCHAR2,
   P_CANT_ERROR OUT NUMBER,
   P_TCRECAB OUT NUMBER,
   P_TCREDET OUT NUMBER,
   P_TDEBDET OUT NUMBER,
   P_CCREDET OUT NUMBER
 );
/* Obtener los datos de la cuenta */
PROCEDURE LP_OBT_DATOS_CUENTA
 (
 P_NRO_CUENTA IN VARCHAR2,
 P_TAS_PERSONALIZADA IN OUT VARCHAR2,
 P_COD_MONEDA IN OUT VARCHAR2,
 P_LUGAR OUT VARCHAR2
 );
/* Verifica que ya no se hayan insertado los mov. de sueldos de la fecha */
PROCEDURE LP_VER_DUP_MOV_DIARI
 (
   P_CUENTA IN VARCHAR2,
   P_SUELDO IN NUMBER,
   P_COD_ENTE IN NUMBER
 );
/* Obtener la max hora para todos los movimientos */
PROCEDURE LP_OBT_HORA_MOVIM
 (
   P_HORA IN OUT VARCHAR2,
   P_FEC_HOY IN GE_WKSP_WSFDC.PAG_SUELDOS.FEC_PROCESO%TYPE,
   P_COD_TRA_PADRE IN VARCHAR2,
   P_LUGAR OUT VARCHAR2
 );
/* Obtener cant.y monto total de pago de sueldo */
PROCEDURE LP_OBT_MONTO_PROC
 (
 P_SECUENCIA IN NUMBER,
 P_COD_ENTE IN NUMBER,
 P_CANTCRED IN OUT NUMBER,
 P_MONTCRED IN OUT NUMBER,
 P_LUGAR OUT VARCHAR2,
 P_FEC_HOY IN DATE
 );
/* Obtener datos de la empresa */
PROCEDURE PR_OBT_DATOS_EMPRESA
 (
   P_EMPRESA         IN NUMBER,
   P_DESCRIP         IN OUT VARCHAR2,
   P_CTADBSU         IN OUT VARCHAR2,
   P_TRANPDB         IN OUT NUMBER,
   P_TRANCOM         IN OUT NUMBER,
   P_TRANEXC         IN OUT NUMBER,
   P_TRANPAGUI       IN OUT NUMBER,
   P_TRANPCOM        IN OUT NUMBER,
   P_TRANPCRE        IN OUT NUMBER,
   P_DEB_EXCESO      IN OUT VARCHAR2,
   P_FEC_INICIO      IN OUT DATE,
   P_FEC_VENCIMIENTO IN OUT DATE,
   P_SER_ACTIVO      IN OUT VARCHAR2,
   P_CAN_MAX_TRANS   IN OUT NUMBER,
   P_NRO_CTA_CONTABLE IN OUT VARCHAR2,
   P_REFERENCIA_TXT  IN OUT VARCHAR2,
   P_LUGAR OUT VARCHAR2
 );
/* Inserta en la tabla GE_WKSP_WSFDC.PAG_SUELDOS */
PROCEDURE LP_INS_TABLA
 (
   P_COD_ENTE      IN NUMBER,
   P_LUGAR         OUT VARCHAR2,
   P_NRO_SECUENCIA OUT NUMBER,
   P_ERROR         OUT VARCHAR2
 );
END;
/
CREATE OR REPLACE PACKAGE BODY PAG_SUE IS
p_fec_hoy date;

/* Verifica si no existe algo a reprocesar o sin procesar */
PROCEDURE PR_VER_PAG_SUELDO
 (P_DATOS IN OUT VARCHAR2
 ,P_REPROCESA IN OUT VARCHAR2
 ,P_FECHA IN OUT DATE
 ,P_COD_ENTE IN NUMBER
 ,P_LUGAR IN OUT VARCHAR2
 )
 IS

 v_ente    GE_PAG_SUELDOS_TMP.cod_ente%type;
begin
   p_lugar := 'VERIFICA DATOS EN GE_PAG_SUELDOS ';
 -- Se busca si existe algún debito no procesado para la empresa, lo que significa que no es
 -- un reproceso
 p_datos     := 'S';
 p_reprocesa := 'N';

 ---- voy a verificar si va a procesar la empresa verificada
   begin
     select min(cod_ente) into v_ente 
       from ge_pag_sueldos_tmp
      where ((cod_ente is null)
             or cod_ente = p_cod_ente);
     if v_ente <> p_cod_ente then
       RAISE_APPLICATION_ERROR(-20811,'El Ente : '||to_char(v_ente)||'aún no fue procesado. Verifique !!!'||sqlerrm);
     end if;
   exception
     when no_data_found then null;
     when others then null;
    end;
 ----
 SELECT FEC_PROCESO
   INTO p_fecha
   FROM GE_PAG_SUELDOS
  WHERE cod_ente = p_cod_ente
    AND tipo = 'D'
    AND COD_PROCESO   <> 0;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     -- Se busca que exista algún credito sin procesar de la Empresa
     BEGIN
      SELECT DISTINCT FEC_PROCESO
        INTO p_fecha
        FROM GE_PAG_SUELDOS
       WHERE cod_ente = p_cod_ente
         AND COD_PROCESO   <> 0;
      p_reprocesa := 'S';
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
          p_datos := 'N';
       WHEN TOO_MANY_ROWS THEN
          p_reprocesa := 'S';
         SELECT MIN(FEC_PROCESO)
           INTO p_fecha
           FROM GE_PAG_SUELDOS
          WHERE cod_ente = p_cod_ente
            AND COD_PROCESO <> 0;
     END;
  WHEN TOO_MANY_ROWS THEN
     -- Existe varios dias sin procesarse
     SELECT MIN(FEC_PROCESO)
       INTO p_fecha
       FROM GE_PAG_SUELDOS
      WHERE cod_ente = p_cod_ente
        AND COD_PROCESO   <> 0;
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20830,'En PR_VER_PAG_SUELDO . Verifique !!!'||sqlerrm);
end pr_ver_pag_sueldo;
/* Procesa los movimientos */
PROCEDURE PR_ACT_CRED_EMPLEADO
 (P_REPROCESO IN OUT VARCHAR2
 ,P_COD_ENTE IN NUMBER
 ,P_NRO_SECUENCIA IN OUT NUMBER
 ,P_CDOFICI IN NUMBER
 ,P_FEC_HOY IN GE_PAG_SUELDOS.FEC_PROCESO%TYPE
 ,P_USUARIO IN VARCHAR2
 ,P_LUGAR IN OUT VARCHAR2
 ,P_HUBO_ERROR OUT VARCHAR2
 ,P_TIPO_TRA_PADRE IN VARCHAR2
 )
 IS
begin
declare
 v_fechamax   DATE;
 v_hrmovim    VARCHAR2(08);
 v_estpres  ba_modulos.estado%type;
BEGIN
   pae_cnf.PR_CTR_MODULO(3);
   --
   p_lugar := 'proc: PR_ACT_CRED_EMPLEADO :llama a LP_INS_MOV_SUELDO Procesar movimiento';
   PAG_SUE.LP_INS_MOV_SUELDO(p_hubo_error,v_hrmovim,p_reproceso,p_cod_ente,p_nro_secuencia,p_lugar,p_cdofici, p_fec_hoy, p_usuario,P_TIPO_TRA_PADRE);

   IF p_hubo_error = 'S' THEN
      p_lugar := 'proc: PR_ACT_CRED_EMPLEADO : llama a LP_DEL_DATOS_TEMPORALES - Borra Datos Temporales ';
      PAG_SUE.LP_DEL_DATOS_TEMPORA(p_cod_ente,p_Fec_hoy,p_lugar);

      p_lugar := 'proc: PR_ACT_CRED_EMPLEADO : llama a LP_INS_ERROR_PROCESO - cod error de proceso ';
      PAG_SUE.LP_INS_ERROR_PROCESO(p_cod_ente,p_Fec_hoy,p_lugar);

   ELSIF p_hubo_error = 'N' THEN
     PAG_SUE.LP_DEL_DATOS_TEMPORA(p_cod_ente,p_Fec_hoy,p_lugar);
     p_lugar := 'proc: PR_ACT_CRED_EMPLEADO : Proceso Terminado sin Errores ....';
   ELSIF p_hubo_error = 'X' THEN --- quiso procesar otro ente distinto al verificado
     p_lugar := 'Trato de procesar otro Ente '; --- en el programa despliega el mensaje de error para no borrar datos del tmp
   END IF;
   -- seteo las variables de hora y secuencia para el debito automatico
   pae_cnf.PR_SET_VARIABLES(v_hrmovim,p_nro_secuencia);

END;

end pr_act_cred_empleado;
/* Inserta los movimientos */
PROCEDURE LP_INS_MOV_SUELDO
 (P_HUBO_ERROR IN OUT VARCHAR2
 ,P_HORAMOV IN OUT VARCHAR2
 ,P_REPROCESO IN VARCHAR2
 ,P_COD_ENTE IN NUMBER
 ,P_NRO_SECUENCIA IN OUT NUMBER
 ,P_LUGAR IN OUT VARCHAR2
 ,P_CDOFICI IN NUMBER
 ,P_FEC_HOY IN GE_PAG_SUELDOS.FEC_PROCESO%TYPE
 ,P_USUARIO IN VARCHAR2
 ,P_TIPO_TRA_PADRE IN VARCHAR2
 )
 IS
begin

declare
CURSOR Sdo IS
   SELECT p.rowid,
          nro_secuencia,
          p.nro_cuenta, tipo, DECODE(tipo,'D',503,'C',602,null),
          monto, r.cod_modalidad, r.cod_modulo, fec_proceso
     FROM GE_CTA_CLIENTES R, GE_PAG_SUELDOS P
    WHERE r.nro_cuenta = p.nro_cuenta
      and cod_ente = p_cod_ente
      and p.nro_secuencia = p_nro_secuencia
      and relacion = 'P'
      and cod_proceso = 0
      and fec_proceso = p_fec_hoy
      and not exists (select 0 from ge_movimientos b
                       where b.nro_cuenta = p.nro_cuenta
                         and b.monto = p.monto
                         and b.cod_transaccion = DECODE(p.tipo,'D',503,'C',602,null)
                         and b.estado = 'N'
                         and b.reversado = 'N'
                         and b.nro_documento = p_cod_ente)
    ORDER BY tipo DESC;

v_cuenta              ge_cuentas.nro_cuenta%type;
v_cuenta_db           ge_cuentas.nro_cuenta%type;
v_tpmovim             VARCHAR2(01);
v_cnmovim             ge_movimientos.concepto%type;
v_mensaje_error       VARCHAR2(200);
v_proceso_ok          VARCHAR2(01);
v_fila                VARCHAR2(18);
v_mov_error           VARCHAR2(01);
v_cdmoned             VARCHAR2(03);
v_estado_nuevo        VARCHAR2(01);
v_puede_procesar      VARCHAR2(01);
v_tiene_tp            VARCHAR2(01);
v_tpvlpor_com         VARCHAR2(01);
v_tpvlpor_iva         VARCHAR2(01);
v_fcproce             DATE;
v_max_sec_use_fgdiari NUMBER(07) := -999;
v_codigo_error        NUMBER(03);
v_cdmodal             NUMBER(03);
v_cdmodul             NUMBER(03);
v_cdmodap             NUMBER(03);
v_cdmodup             NUMBER(03);
v_cdofici             NUMBER(03);
v_cdofior             NUMBER(03);
v_tranh               NUMBER(03);
v_secuencia           NUMBER(03);
v_Sldisp              NUMBER(18,2);
v_valor_com           NUMBER(18,2);
v_valor_iva           NUMBER(18,2);
v_Cantcred            NUMBER(05);
v_Total_Credito       NUMBER(18,2);
v_Comision            NUMBER(18,2);
v_Iva                 NUMBER(18,2);
v_imtrans             NUMBER(18,2);
v_contador            NUMBER(10):=0;
rg_movs               ge_movimientos%rowtype;
v_cod_mon_local       ba_monedas.cod_moneda%type;
---* estas variables son para obtener los datos de empresa
v_descrip varchar2(60);
v_ctadbsu               ge_cuentas.nro_cuenta%type;
v_tranpdb               ge_transacciones.cod_transaccion%type;
v_cdtasas               ge_par_entes.val_parametro%type;
v_cdtasas_iva           ge_par_entes.val_parametro%type;
v_cdtriva               ge_transacciones.cod_transaccion%type;
v_cdtrcom               ge_transacciones.cod_transaccion%type;
---*
v_trancom               ge_transacciones.cod_transaccion%type;
v_tranexc               ge_transacciones.cod_transaccion%type;
v_tranpagui             ge_transacciones.cod_transaccion%type;
v_tranpcom              ge_transacciones.cod_transaccion%type;
v_tranpcre              ge_transacciones.cod_transaccion%type;
v_deb_exceso            ge_par_entes.val_parametro%type;
v_fec_inicio            ge_pag_sueldos.fec_proceso%type;
v_fec_vencimiento       ge_pag_sueldos.fec_proceso%type;
v_nro_cta_contable_txt  ge_par_entes.val_parametro%type;
v_ser_activo            ge_par_entes.val_parametro%type;
v_can_max_trans         ge_par_entes.val_parametro%type;

---* para package de tasas
v_g_cod_transaccion   ge_transacciones.cod_transaccion%type;
v_g_tpvlpor           GE_TASAS.TIP_VALOR%TYPE;
v_g_vltasa            GE_TAS_FECHAS.VAL_TASA%TYPE;
v_g_fecha             GE_TAS_FECHAS.FEC_VIGENCIA%TYPE;
v_g_tipo              GE_TASAS.TIPO%TYPE;
v_g_cdmoned           VARCHAR2(03);
v_ente                ge_entes.cod_ente%type;
v_referencia_txt      varchar2(100);
---* para obtener ley 125
v_val_impuesto     number(18,2);
v_tra_impuesto     ge_transacciones.cod_transaccion%type;
v_cod_tas_impuesto ge_movimientos.cod_tasa%type;
---v_impuesto         number(18,2);

BEGIN
   ----- trata de procesar otro ente , inserto datos de otro ente a verificar desde diskete ---
 begin
  select cod_ente into v_ente from ge_pag_sueldos where
     cod_ente = p_cod_ente and rownum=1;
 exception
    when no_data_found then
    p_hubo_error := 'X';
 end;
 if nvl(v_ente,0) <> p_cod_ente then
    p_hubo_error:= 'X';
    v_mov_error := 'S';
 else
   v_cnmovim := 'Pago de Sueldo ';
   p_horamov := NULL;
   v_mov_error := 'N';

      PAG_SUE.PR_OBT_DATOS_EMPRESA(p_cod_ente,
                                   v_descrip,
                                   v_ctadbsu,
                                   v_tranpdb ,
                                   v_trancom,   ---v_cdtasas,
                                   v_tranexc,   ---v_cdtriva,
                                   v_tranpagui, ---v_cdtrcom,
                                   v_tranpcom,
                                   v_tranpcre,  --- Para RRHH se carga aqui el debito al Rubro
                                   v_deb_exceso,
                                   v_fec_inicio,
                                   v_fec_vencimiento,
                                   v_ser_activo,
                                   v_can_max_trans,
                                   v_nro_cta_contable_txt, ---Agregado para RRHH
                                   v_referencia_txt,
                                   p_lugar);

   --- POR DEFECTO LA TRANS. PADRE ES SUELDO (S) SINO UNO DE LOS SGTES.
   IF P_TIPO_TRA_PADRE = 'A' then --- AGUINALDO
      v_tranpdb := v_tranpagui;
   ELSIF P_TIPO_TRA_PADRE = 'C' then  ---- COMISION
      v_tranpdb := v_tranpcom;
   ELSIF P_TIPO_TRA_PADRE = 'T' then  --- CREDITO
      v_tranpdb := v_tranpcre;
   END IF;

   IF p_Reproceso = 'S' THEN
      PAG_SUE.LP_OBT_HORA_MOVIM(p_horamov,p_fec_hoy,v_tranpdb,p_lugar );
   END IF;
   -- obtiene una hora unica para todos los movimientos a ser insertados
   IF p_horamov IS NULL THEN
      p_horamov := TO_CHAR(SYSDATE,'HH24:MI:SS');
   END IF;
   --
   IF Sdo%ISOPEN THEN
      CLOSE Sdo;
   END IF;
   OPEN Sdo;
   LOOP
       FETCH Sdo INTO v_fila, v_secuencia, v_cuenta, v_tpmovim, v_tranh, v_imtrans,
       v_cdmodal, v_cdmodul,v_fcproce;
        EXIT WHEN Sdo%NOTFOUND OR p_hubo_error = 'S';
          p_lugar := 'Procesando Pago Sueldo Cuenta :'||v_cuenta;
          ---
          v_mov_error := 'N';
          ---
          IF v_cdmodup IS NULL THEN
          ---
            if v_nro_cta_contable_txt is null then --- agregado para modulo de RRHH
              begin
                SELECT A.nro_cuenta,B.cod_moneda,B.cod_oficina
                  INTO v_cuenta_db,v_cdmoned,v_cdofici
                  FROM ge_pag_sueldos A,ge_cuentas B
                 WHERE A.nro_cuenta = B.nro_cuenta
                   AND A.cod_modulo = B.cod_modulo
                   AND A.cod_modalidad = B.cod_modalidad
                   AND A.cod_ente = p_cod_ente
                   AND A.tipo = 'D'
                   AND A.nro_cuenta    = v_ctadbsu
                   AND A.nro_secuencia = v_secuencia
                   AND A.fec_proceso   = v_fcproce;
              exception
                 when no_data_found then
                   p_hubo_error:= 'S';
                   v_mov_error := 'S';
                    UPDATE ge_pag_sueldos
                      SET cod_proceso = 12 WHERE nro_cuenta=v_ctadbsu;
                 when too_many_rows then
                   RAISE_APPLICATION_ERROR(-20909,'Error: Ya se proceso el Ente' );
              end;
              ---
              begin
                SELECT cod_modulo, cod_modalidad, p_cdofici
                  INTO v_cdmodup, v_cdmodap, v_cdofior
                  FROM ge_cta_clientes
                 WHERE nro_cuenta = v_cuenta_db
                   AND relacion = 'P';
              exception
                when others then
                p_hubo_error:= 'S';
                  v_mov_error := 'S';
                 UPDATE ge_pag_sueldos
                  SET cod_proceso = 12 WHERE nro_cuenta=v_ctadbsu;
               end;
            ---
            else
            --- agregado para RRHH
              begin
                SELECT B.cod_moneda,B.cod_oficina
                  INTO v_cdmoned,v_cdofici
                  FROM ge_cuentas B
                 WHERE B.nro_cuenta = v_cuenta;
              exception
                 when others then
                 p_hubo_error:= 'S';
                   v_mov_error := 'S';
                  UPDATE ge_pag_sueldos
                   SET cod_proceso = 12 WHERE nro_cuenta=v_cuenta;
              end;
              --- 
              begin
                SELECT cod_modulo, cod_modalidad, p_cdofici
                  INTO v_cdmodup, v_cdmodap, v_cdofior
                  FROM ge_cta_clientes
                 WHERE nro_cuenta = v_cuenta
                   AND relacion = 'P';
              exception
                when others then
                p_hubo_error:= 'S';
                  v_mov_error := 'S';
                 UPDATE ge_pag_sueldos
                  SET cod_proceso = 12 WHERE nro_cuenta=v_cuenta;
               end;
            end if;
          END IF;
          ---
          if v_mov_error = 'N' then
            p_lugar := 'LP_INS_MOV_SUELDO llama al pack: PAG_CTA.PR_ACT_OPERACION ';
            ---
            if v_nro_cta_contable_txt is not null then
            --- Agregado para modulo de RRHH
            --- Para grabar por cada registro procesado y sus movimientos la misma hora
              v_fcproce := pag_cal.FU_OBT_FEC_ACTUAL(pag_cta.g_ctas.cod_modulo);
              p_horamov  := pag_gen.fu_obt_sig_segundo(p_horamov);
            end if;

            PAG_CTA.PR_ACT_OPERACION(v_cuenta,
                        p_horamov,
                        v_tpmovim,
                        v_cdmoned,
                        v_imtrans,
                        v_tranpdb,
                        v_tranh,
                        p_cod_ente,
                        NULL,
                        v_cdofior,
                        v_cdmodup,
                        v_cdmodap,
                        NULL,
                        NULL,
                        v_cnmovim,
                        'S',
                         v_max_sec_use_fgdiari,
                         v_fcproce);
            --
            v_proceso_ok    := pag_cta.fu_obt_ok_procesar;
            v_mensaje_error := pag_cta.fu_obt_msj_error;
            v_codigo_error  := pag_cta.fu_obt_cod_error;

            UPDATE ge_pag_sueldos
              SET cod_proceso = v_codigo_error
             WHERE ROWID = v_fila;

            IF v_proceso_ok = 'N' AND v_tpmovim = 'D' THEN
            p_hubo_error:= 'S';
              v_mov_error := 'S';
            ELSE
              UPDATE GE_PAG_SUELDOS
               SET FEC_PROCESO = p_fec_hoy
             WHERE ROWID = v_fila;

            END IF;
          end if;
   END LOOP;
   IF Sdo%ISOPEN THEN
     CLOSE Sdo;
   END IF;
   p_hubo_error    := v_mov_error;
   v_cod_mon_local := pag_gen.fu_obt_mon_local;

   IF v_mov_error = 'N' THEN
      ---
      --- agregado para modulo de RRHH
      ---
      if v_nro_cta_contable_txt is null then 
         p_lugar := 'LP_INS_MOV_SUELDO llama al pack. PAG_CTA.PR_VER_OPERACION)';
         PAG_CTA.PR_VER_OPERACION(v_ctadbsu,
                                  v_tranpdb,
                                  v_cdmodul,
                                  v_cdmodal,
                                  'D',
                                  v_cdmoned,
                                  1,
                                  v_cdofici,
                                  v_cdmodup,
                                  v_cdmodap,
                                  v_estado_nuevo,
                                  v_sldisp,
                                  v_puede_procesar);
         v_mensaje_error := pag_cta.fu_obt_msj_error;
         v_codigo_error := pag_cta.fu_obt_cod_error;
         --
         p_lugar := 'EN Proc : LP_INS_MOV_SUELDO llama al proc. lp_obt_datos_cuenta ';
         PAG_SUE.LP_OBT_DATOS_CUENTA(v_ctadbsu, v_tiene_tp, v_cdmoned, p_lugar);
         
         p_lugar := 'EN Proc : LP_INS_MOV_SUELDO llama al proc. lp_obt_monto_proc ';
         PAG_SUE.LP_OBT_MONTO_PROC(v_Secuencia, p_cod_ente, v_CantCred, v_Total_Credito,P_lugar,p_fec_hoy);
  
         -- A PARTIR DE AQUI DEBE HACER EL PRG_OBT_CARGOS
         ----------------------------------------------
         -----Calcula Comision e Iva para La Empresa --
         ----------------------------------------------
          PRG_OBT_CARGOS
          (v_cdofici            --P_COD_OFI_ORIGEN     IN GE_CUENTAS.COD_OFICINA%TYPE
          ,v_ctadbsu            --P_NRO_CUENTA         IN GE_CUENTAS.NRO_CUENTA%TYPE
          ,v_cdmoned            --P_COD_MONEDA         IN GE_CUENTAS.COD_MONEDA%TYPE
          ,v_Total_Credito      --P_MONTO              IN GE_MOVIMIENTOS.MONTO%TYPE
          ,v_cdmodup            --P_COD_MODULO         IN GE_CUENTAS.COD_MODULO%TYPE
          ,v_cdmodap            --P_COD_MODALIDAD      IN GE_CUENTAS.COD_MODALIDAD%TYPE
          ,v_trancom            --P_COD_TRA_CARGO      IN GE_MOVIMIENTOS.COD_TRANSACCION%TYPE
          ,v_cdtasas            --P_COD_TAS_CARGO      OUT GE_MOVIMIENTOS.COD_TASA%TYPE
          ,v_valor_com          --P_VAL_TAS_CARGO      OUT GE_MOVIMIENTOS.VAL_TASA%TYPE
          ,v_comision           --P_VAL_CARGO          OUT GE_MOVIMIENTOS.VAL_TASA%TYPE
          ,v_cdtriva            --P_COD_TRA_IMPUESTO   OUT GE_MOVIMIENTOS.COD_TRANSACCION%TYPE
          ,v_cdtasas_iva        --P_COD_TAS_IMPUESTO   OUT GE_MOVIMIENTOS.COD_TASA%TYPE
          ,v_valor_iva          --P_VAL_TAS_IMPUESTO   OUT GE_MOVIMIENTOS.VAL_TASA%TYPE
          ,v_iva );             -- P_VAL_IMPUESTO      OUT GE_MOVIMIENTOS.VAL_TASA%TYPE
  
          --- si es valor debe multiplicar por la cant. de creditos ---
          if v_valor_com = nvl(v_comision,0) + nvl(v_iva,0) then
             v_comision := v_comision * v_CantCred;
             v_iva := v_iva * v_cantcred;
          end if;
  
  /*        --- BUSCO IMPUESTO LEY 125 ---
          PAG_PRV.pr_obt_impuesto
        (v_cdofici              ---   IN GE_CUENTAS.COD_OFICINA%TYPE
        ,v_cuenta               ---   IN GE_CUENTAS.NRO_CUENTA%TYPE
        ,v_cdmoned              ---   IN GE_CUENTAS.COD_MONEDA%TYPE
        ,v_total_credito        ---   IN GE_MOVIMIENTOS.MONTO%TYPE
        ,v_cdmodup              ---   IN GE_CUENTAS.COD_MODULO%TYPE
        ,v_cdmodap              ---   IN GE_CUENTAS.COD_MODALIDAD%TYPE
        ,v_tra_impuesto         ---  OUT GE_MOVIMIENTOS.COD_TRANSACCION%TYPE
        ,v_cod_tas_impuesto     ---  OUT GE_MOVIMIENTOS.COD_TASA%TYPE
        ,v_val_impuesto         ---  OUT GE_MOVIMIENTOS.VAL_TASA%TYPE
        ,v_impuesto );          ---   OUT GE_MOVIMIENTOS.VAL_TASA%TYPE
  
  */
        p_lugar := 'EN Proc : LP_INS_MOV_SUELDO - Procesar_Movim.Sueldo - Busca Tasa Comision-Empresa';
       ---* aqui verifico si no supera monto+iva lo disponible antes de generar mov 16/02/05
        IF  NVL(v_SlDisp,0)+nvl(pag_cta.FU_OBT_LIN_SOBREGIRO(v_ctadbsu),0) <  NVL(v_comision,0) + NVL(v_iva,0)  then
           p_hubo_error:= 'S';
  
           UPDATE ge_pag_sueldos
              SET cod_proceso = 25 WHERE nro_cuenta=v_ctadbsu;
        ELSE
  
       ---*
          IF  NVL(v_SlDisp,0) >= NVL(v_comision,0) + NVL(v_iva,0) AND
              NVL(v_comision,0) + NVL(v_iva,0) > 0 THEN
              --
              v_cnmovim := 'Comision pago de Sueldo';
              --
              p_lugar := 'EN Proc : LP_INS_MOV_SUELDO llama al pack: PAG_CTA.PR_ACT_OPERACION : pago sueldo';
              PAG_CTA.PR_ACT_OPERACION(v_ctadbsu,
                                       p_horamov,
                                       'D',
                                       v_cdmoned,
                                       v_comision,
                                       v_tranpdb,
                                       v_trancom,  ---v_cdtrcom,
                                       p_cod_ente,
                                       NULL,
                                       p_cdofici,
                                       v_cdmodup,
                                       v_cdmodap,
                                       NULL,
                                       NULL,
                                       v_cnmovim,
                                       'S',
                                       v_max_sec_use_fgdiari,
                                       v_fcproce);
  
              v_mensaje_error:=pag_cta.fu_obt_msj_error;
              v_proceso_ok:=pag_cta.fu_obt_ok_procesar;
              v_codigo_error:=pag_cta.fu_obt_cod_error;
  
              if v_proceso_ok!='S' then
                 RAISE_APPLICATION_ERROR(-20500,'Error en pr_act_operacion: '||v_codigo_error||v_mensaje_error);
              end if;
              --
              v_cnmovim := 'Iva s/Imp.pago de Sueldo';
              --
              p_lugar := 'EN Proc : LP_INS_MOV_SUELDO llama al pack: PAG_CTA.PR_ACT_OPERACION : DB Iva';
              PAG_CTA.PR_ACT_OPERACION(v_ctadbsu,
                                       p_horamov,
                                       'D',
                                       v_cdmoned,
                                       v_iva,
                                       v_tranpdb,
                                       v_cdtriva,
                                       p_cod_ente,
                                       NULL,
                                       p_cdofici,
                                       v_cdmodup,
                                       v_cdmodap,
                                       NULL,
                                       NULL,
                                       v_cnmovim,
                                       'S',
                                       v_max_sec_use_fgdiari,
                                       v_fcproce);
  
              v_mensaje_error := pag_cta.fu_obt_msj_error;
              v_proceso_ok    := pag_cta.fu_obt_ok_procesar;
              v_codigo_error  := pag_cta.fu_obt_cod_error;
  
              if v_proceso_ok!='S' then
              RAISE_APPLICATION_ERROR(-20600,'Error en pr_act_operacion : IVA '||v_codigo_error||v_mensaje_error);
              end if;
             --
          ELSIF  NVL(v_SlDisp,0) < NVL(v_comision,0) + NVL(v_iva,0) AND
               NVL(v_comision,0) + NVL(v_iva,0) > 0  THEN
           --
           p_lugar                 := ' Carga registro rg_movs ';
           rg_movs.COD_USUARIO     := p_usuario;
           rg_movs.hora            := p_horamov;
           rg_movs.nro_secuencia   := v_max_sec_use_fgdiari + 1;
           rg_movs.cod_modulo      := v_cdmodul;
           rg_movs.cod_modalidad   := v_cdmodal;
           rg_movs.cod_oficina     := v_cdofici;
           rg_movs.nro_cuenta      := v_ctadbsu;
           rg_movs.cod_moneda      := v_cdmoned;
           rg_movs.cod_tra_padre   := v_tranpdb;
           rg_movs.cod_transaccion := v_cdtrcom;
           rg_movs.fecha           := p_fec_hoy ;
           rg_movs.fec_valor       := p_fec_hoy ;
           rg_movs.nro_documento   := p_cod_ente;
           rg_movs.monto           := v_comision;
           rg_movs.est_cuenta      := 'N';
           rg_movs.estado          := 'E';
           rg_movs.cod_ofi_origen  := p_cdofici;
           rg_movs.concepto        := v_cnmovim;
           rg_movs.reversado       := 'N';
           rg_movs.emi_aviso       := 'N';
           rg_movs.cod_mod_padre   := v_cdmodup;
           rg_movs.cod_mad_padre   := v_cdmodap;
  
           p_lugar := 'EN Proc : LP_INS_MOV_SUELDO llama al pack :PAG_GEN.PR_INS_GE_MOVIMIENTO , inserta mov E ';
           PAG_GEN.PR_INS_GE_MOVIMIENTO(rg_movs,'N');
          END IF;
        END IF;
        ---
      else
         --- agregado para RRHH
         --------------------------------------
         --- si no se debita de cuenta de ahorro
         --- se debe debitar del rubro contable
         p_lugar := 'EN Proc : LP_INS_MOV_SUELDO llama al proc. lp_obt_monto_proc ';
         PAG_SUE.LP_OBT_MONTO_PROC(v_Secuencia, p_cod_ente, v_CantCred, v_Total_Credito,P_lugar,p_fec_hoy);
         
         begin
           select c.cod_moneda
           into   v_cdmoned
           from   cb_rubros c 
           where  c.cod_rubro = v_nro_cta_contable_txt;
         exception
           when no_data_found then
              RAISE_APPLICATION_ERROR(-20600,'Rubro contable no posee moneda: '|| v_nro_cta_contable_txt);
         end;
         
         p_lugar                 := ' Carga registro rg_movs ';
         rg_movs.cod_transaccion := 1400;
         rg_movs.cod_modulo      := 14;
         rg_movs.cod_modalidad   := 141;
         rg_movs.cod_tra_padre   := 1400;
         rg_movs.cod_mod_padre   := 14;
         rg_movs.cod_mad_padre   := 141;
         rg_movs.monto           := v_Total_Credito;
         rg_movs.cod_moneda      := v_cdmoned;
         --
         rg_movs.nro_cuenta      := null; --v_ctadbsu;
         rg_movs.cod_oficina     := v_cdofici;
         rg_movs.COD_USUARIO     := p_usuario;
         rg_movs.hora            := p_horamov;
         rg_movs.fecha           := p_fec_hoy ;
         rg_movs.nro_secuencia   := v_max_sec_use_fgdiari + 1;
         rg_movs.fec_valor       := p_fec_hoy ;
         rg_movs.nro_documento   := p_cod_ente;
         rg_movs.cod_tasa        := null;
         rg_movs.val_tasa        := null;
         rg_movs.cotizacion      := null;
         rg_movs.emi_aviso       := 'N';
         rg_movs.cod_ofi_origen  := p_cdofici;
         rg_movs.concepto        := v_cnmovim;
         rg_movs.estado          := 'N';
         rg_movs.est_cuenta      := 'N';
         rg_movs.reversado       := 'N';
         rg_movs.emi_aviso       := 'N';
         --
         rg_movs.nro_caja        := null;--to_number(p_nro_caja);
         rg_movs.cod_rubro       := v_nro_cta_contable_txt;
         rg_movs.tip_mov_rubro   := 'D'; -- débito
         --
         p_lugar := 'EN Proc : LP_INS_MOV_SUELDO llama al pack :PAG_GEN.PR_INS_GE_MOVIMIENTO , inserta mov E ';
         PAG_GEN.PR_INS_GE_MOVIMIENTO(rg_movs,'N');
          
      END IF; --- filtro agregado para RRHH
   END IF;
 end if;
END;
end lp_ins_mov_sueldo;
/* Borra los datos procesados del temporal */
PROCEDURE LP_DEL_DATOS_TEMPORA
 (P_COD_ENTE IN NUMBER
 ,P_FEC_HOY IN DATE
 ,P_LUGAR IN OUT VARCHAR2
 )
 IS
begin
  p_lugar := 'Borra Cuentas de Empresas Procesadas ';
    DELETE GE_PAG_SUELDOS_TMP
      WHERE COD_ENTE    = p_cod_ente
        AND FEC_PROCESO = p_fec_hoy;
exception
 When others then
  RAISE_APPLICATION_ERROR(-20010,'Al Borrar GE_PAG_SUELDOS_TMP ');
end lp_del_datos_tempora;
/* Inserta en el GE_PAG_SUELDOS_TMP los registros con error */
PROCEDURE LP_INS_ERROR_PROCESO
 (P_COD_ENTE IN NUMBER
 ,P_FEC_HOY IN DATE
 ,P_LUGAR IN OUT VARCHAR2
 )
 IS
begin
    p_lugar := 'Inserta error Cuentas de Empresas Procesadas ';
    INSERT INTO GE_PAG_SUELDOS_TMP
          (cod_ente, fec_proceso, nro_secuencia,
           nro_cuenta, cod_moneda, fec_envio, tipo, monto,
           estado, cod_proceso)
         SELECT
                p_cod_ente, p_fec_hoy,
                nro_secuencia,  nro_cuenta, cod_moneda, fec_envio,
                tipo, monto, estado, cod_proceso
           FROM GE_PAG_SUELDOS
          WHERE cod_ente  = p_cod_ente
           and fec_proceso = p_fec_hoy
           and COD_proceso <> 0;
          ---  AND COD_PROCESO = 0;
exception
 When others then
  RAISE_APPLICATION_ERROR(-20020,'En insertar error GE_PAG_SUELDOS_TMP ');
end lp_ins_error_proceso;
/* Verifica creditos y debitos procesados */
PROCEDURE PR_ACT_DATOS_PAGADOS
 (P_COD_ENTE IN NUMBER
 ,P_FEC_HOY IN DATE
 ,P_LUGAR IN OUT VARCHAR2
 )
 IS
begin
DECLARE
  v_nrsecue     NUMBER;
  v_TCRSINPROCE NUMBER(18,2);
  v_TDBSINPROCE NUMBER(18,2);
BEGIN
  p_lugar := 'Obtiener Maxima Secuencia sin Procesar en el dia';
  BEGIN
    SELECT MAX(NRO_SECUENCIA)
      INTO v_nrsecue
      FROM GE_PAG_SUELDOS
     WHERE COD_ENTE = p_cod_ente
       AND FEC_PROCESO = p_fec_hoy
       AND COD_PROCESO <> 0;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       v_nrsecue := NULL;
    WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20100,'Al obtener secuencia sin procesar '||sqlerrm);
  END;
  --
  IF v_nrsecue IS NOT NULL THEN
    p_lugar := 'Suma Total de Creditos sin procesar ';
    SELECT SUM(NVL(MONTO,0))
      INTO v_tcrsinproce
      FROM GE_PAG_SUELDOS
     WHERE COD_ENTE = p_cod_ente
       AND FEC_PROCESO = p_fec_hoy
       AND COD_PROCESO <> 0
       AND tipo = 'C'
       AND nro_secuencia = v_nrsecue;
    --
    p_lugar := 'Suma Total de Débitos sin procesar ';
    SELECT SUM(NVL(MONTO,0))
      INTO v_tdbsinproce
      FROM GE_PAG_SUELDOS
     WHERE COD_ENTE = p_cod_ente
       AND FEC_PROCESO = p_fec_hoy
       AND COD_PROCESO <> 0
       AND TIPO = 'D'
       AND nro_secuencia = v_nrsecue;
  END IF;
  --
  IF v_nrsecue IS NULL THEN
   RAISE_APPLICATION_ERROR(-20150,'No Existen Datos Cargados el día '||TO_CHAR(p_fec_hoy,'DD/MM/YYYY')||sqlerrm);
  ELSIF v_TCRSINPROCE < v_TDBSINPROCE THEN
   RAISE_APPLICATION_ERROR(-20200,'Existen Sueldos ya acreditados para la Empresa '
   ||TO_CHAR(p_cod_ente)||'. Imposible actualizar datos !!!' ||sqlerrm);
  ELSIF v_TDBSINPROCE = 0 THEN
   RAISE_APPLICATION_ERROR(-20250,'El Débito a la Empresa '
   ||TO_CHAR(p_cod_ente)||' fue realizado. Imposible actualizar datos !!!'||sqlerrm);
  END IF;
  --
  -- Borra los datos...
  --
      DELETE GE_PAG_SUELDOS
       WHERE COD_ENTE = p_cod_ente
         AND FEC_PROCESO = p_fec_hoy
         AND nro_secuencia = v_nrsecue;
END;

end pr_act_datos_pagados;
/* Proceso principal de inserción y generación */
PROCEDURE PR_INS_GE_PAG_SUELDO
 (P_VERIFICA_OK IN OUT VARCHAR2
 ,P_COD_ENTE IN NUMBER
 ,P_CTADBSU IN VARCHAR2
 ,P_TRANPDB IN NUMBER
 ,P_FEC_HOY IN GE_PAG_SUELDOS.FEC_PROCESO%TYPE
 ,P_LUGAR IN OUT VARCHAR2
 ,P_CANT_ERROR OUT NUMBER
 ,P_TCRECAB OUT NUMBER
 ,P_TCREDET OUT NUMBER
 ,P_TDEBDET OUT NUMBER
 ,P_CCREDET OUT NUMBER
 )
 IS
begin
declare
  /* Definición de Variables */
  v_Tot_Debito  number(18,2) := 0;
  v_Tot_Credito number(18,2) := 0;
  v_min_fec     date;
  v_max_fec     date;
  v_cantreg     number(5) := 0;
  -------------------
  v_fech_env          date;
  v_linea             varchar2(1000);
  v_linea_cab         varchar2(1000);
  v_cuenta            varchar2(15);
  v_tip_movimiento    varchar2(01);
  v_mensaje_error     varchar2(200);
  v_cod_moneda        varchar2(03);
  v_cod_mon_debito    varchar2(03);
  v_est_movimiento    varchar2(01);
  v_estado_nuevo      varchar2(01);
  v_puede_procesar    varchar2(01);
  IdCta               varchar2(02);
  v_tas_personalizada varchar2(01);
  v_cod_modulo        number(03);
  v_cod_modalidad     number(03);
  v_cod_oficina       number(03);
  v_empresa           number(03);
  v_Sueldo            number(18,2);
  v_sldisponible      number(18,2);
  v_cCreCab           number(06);
  v_Secuencia         number(03);
  v_Codigo_Error      number(03);
  v_Long_Cabecera     number(04);
  v_boton             number(02);
  v_cant_linea        number(05);
--* para verificar si cta de txt es la del ente seleccionado
  v_descripcion_txt   ge_entes.descripcion%type;
  v_cta_debito_txt    ge_pag_sueldos.nro_cuenta%type;
  v_tranpdb_txt       ge_transacciones.cod_transaccion%type;
  v_tasa_txt          ge_tasas.cod_tasa%type;
  v_traniva_txt       ge_transacciones.cod_transaccion%type;
  v_lugar_txt         varchar2(200);

v_trancom_txt               ge_par_entes.val_parametro%type;
v_tranexc_txt               ge_par_entes.val_parametro%type;
v_tranpagui_txt             ge_par_entes.val_parametro%type;
v_tranpcom_txt              ge_par_entes.val_parametro%type;
v_tranpcre_txt              ge_par_entes.val_parametro%type;
v_deb_exceso_txt            ge_par_entes.val_parametro%type;
v_fec_inicio_txt            ge_par_entes.val_parametro%type;
v_fec_vencimiento_txt       ge_par_entes.val_parametro%type;
v_ser_activo_txt            ge_par_entes.val_parametro%type;
v_nro_cta_contable_txt      ge_par_entes.val_parametro%type; --agregado para RRHH
v_can_max_trans_txt         ge_par_entes.val_parametro%type;
v_referencia_txt_txt        ge_par_entes.val_parametro%type;

  v_cta_ok            varchar2(1) := 'N';
  v_cta_deb_txt       varchar2(15);

  cursor c1 is Select *
                 from GE_PAG_SUELDOS_TMP
                where ((cod_ente is null)
                        or cod_ente = p_cod_ente)
                Order by decode(TIPO, 'D', 1, 99)
                  for update of estado;
BEGIN
    v_secuencia := nvl(v_secuencia,0) + 1;
    p_TCreDet := 0;
    p_TDebDet := 0;
    p_cCreDet := 0;
    p_verifica_ok := 'S';
    --------------------------------------------------------------------------------
    p_lugar := 'PR_INS_GE_PAG_SUELDO : ';
    BEGIN
        -- Se verifican los datos leidos....
         Select sum(decode(tipo, 'D', monto, 0)) Tot_debito,
                sum(decode(tipo, 'C', monto, 0)) Tot_credito,
                min(fec_envio), max(fec_envio), count(*)
           into v_Tot_debito, v_Tot_credito, v_min_fec, v_max_fec, v_cantreg
           from GE_PAG_SUELDOS_TMP
          where ((cod_ente is null)
                  or cod_ente = p_cod_ente);
         ---
         --- modificado para RRHH
       /*if v_cantreg = 0 then
            RAISE_APPLICATION_ERROR(-20700,'Archivo sin dato ');
         else
            if nvl(v_Tot_Debito,0) != nvl(v_Tot_Credito,0) Then
              RAISE_APPLICATION_ERROR(-20710,'Total de Créditos no coincide con Total de Débitos');
            else
                v_fech_env := v_min_fec;
                p_TCreCab  := v_tot_Credito;
            end if;
         end if;
         ---
      p_lugar := 'proc: PR_INS_GE_PAG_SUELDO : Obt_Datos_cuenta';
      pag_sue.lp_obt_datos_cuenta(p_ctadbsu,v_tas_personalizada,v_cod_mon_debito,p_lugar);
      --*/
      PAG_SUE.PR_OBT_DATOS_EMPRESA(p_cod_ente,
                                   v_descripcion_txt,
                                   v_cta_debito_txt,
                                   v_tranpdb_txt,
                                   v_trancom_txt,   ---v_tasa_txt,
                                   v_tranexc_txt,   ---v_traniva_txt,
                                   v_tranpagui_txt, ---v_trancom_txt,
                                   v_tranpcom_txt,
                                   v_tranpcre_txt,
                                   v_deb_exceso_txt,
                                   v_fec_inicio_txt,
                                   v_fec_vencimiento_txt,
                                   v_ser_activo_txt,
                                   v_can_max_trans_txt,
                                   v_nro_cta_contable_txt, ---Agregado para RRHH
                                   v_referencia_txt_txt,
                                   v_lugar_txt);

         --- agregado para RRHH
         if v_nro_cta_contable_txt is not null then
             v_cod_mon_debito := fuy_obt_mon_base;
         elsif v_cta_debito_txt is not null then
            if nvl(v_Tot_Debito,0) != nvl(v_Tot_Credito,0) Then
              RAISE_APPLICATION_ERROR(-20710,'Total de Creditos no coincide con Total de Debitos');
            else
              p_lugar := 'proc: PR_INS_GE_PAG_SUELDO : Obt_Datos_cuenta';
              pag_sue.lp_obt_datos_cuenta(p_ctadbsu,v_tas_personalizada,v_cod_mon_debito,p_lugar);
            end if;
         else
             RAISE_APPLICATION_ERROR(-20720,'Se debe parametrizar para que el descuento se realice
                                             del Rubro Contable o de la Cta. de Débito');
         end if;
        ------------------------
        v_fech_env := v_min_fec;
        p_TCreCab  := v_tot_Credito;
         -----------------------
        Update ge_pag_sueldos_tmp
           set nro_secuencia = v_secuencia,
               fec_proceso   = p_fec_hoy
         where ((cod_ente is null)
                 or cod_ente = p_cod_ente);

      v_cta_ok := 'S';
      FOR r1 in c1 LOOP
         v_tip_movimiento := r1.tipo;
         IF v_tip_movimiento = 'D' THEN
           v_cta_deb_txt := r1.nro_cuenta;
           if r1.nro_cuenta <> v_cta_debito_txt then
              v_cta_ok := 'N';
           end if;
           v_cuenta := p_ctadbsu;
           v_Sueldo := v_Tot_Debito;
         ELSE
           v_cuenta  := r1.nro_cuenta;
           v_sueldo  := r1.monto;
         END IF;

         if v_cta_ok = 'N' then
            Update ge_pag_sueldos_tmp
               set cod_proceso   = 48 
             where nro_cuenta = v_cta_deb_txt;
         end if;

            --Obtengo el modulo,la modalidad y la oficina de la cuenta
            BEGIN
             SELECT A.COD_MODULO,A.COD_MODALIDAD,A.COD_OFICINA,A.COD_MONEDA
               INTO v_cod_modulo,v_cod_modalidad,v_cod_oficina,v_cod_moneda
               FROM GE_CUENTAS A
              WHERE A.NRO_CUENTA = V_CUENTA;
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
              RAISE_APPLICATION_ERROR(-20800,'Nro.Cuenta '||v_cuenta||' Inexistente... Verifique.'||v_cuenta||sqlerrm);
             WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR(-20801,'Error al Buscar Nro.Cuenta ..Verifique.'||sqlerrm);
            END;

            p_lugar := 'Verifica_Dup_En_Mov_Diario ';
            PAG_SUE.LP_VER_DUP_MOV_DIARI(v_cuenta,v_Sueldo,p_cod_ente);

            p_lugar := 'PAG_CTA.PR_VER_OPERACION : '||v_cuenta;
            PAG_CTA.PR_VER_OPERACION(v_cuenta,
                                  p_tranpdb,
                                  v_cod_modulo,
                                  v_cod_modalidad,
                                  v_tip_movimiento,
                                  v_cod_moneda,
                                  v_Sueldo,
                                  v_cod_oficina,
                                  v_cod_modulo,
                                  v_cod_modalidad,
                                  v_estado_nuevo,
                                  v_sldisponible,
                                  v_puede_procesar);

           v_mensaje_error := PAG_CTA.FU_OBT_MSJ_ERROR;
           v_Codigo_Error := PAG_CTA.FU_OBT_COD_ERROR;

           IF v_puede_procesar = 'S' AND v_cod_mon_debito = v_cod_moneda THEN
              v_est_movimiento := 'N'; -- Movimiento Normal
           ELSIF v_puede_procesar = 'S' AND v_cod_mon_debito <> v_cod_moneda THEN
              v_est_movimiento := 'E'; -- Movimiento Erróneo
              v_Codigo_Error := 43;
           ELSE
              v_est_movimiento := 'E'; -- Movimiento Erróneo
           END IF;
           if v_est_movimiento = 'N' Then
              if v_tip_movimiento = 'C' Then
               p_TCreDet := p_TCreDet + v_Sueldo;
               p_cCreDet := p_cCreDet + 1;
             else
               p_TDebDet := p_TDebDet + v_Sueldo;
             end if;
           End if;
           ---* valido si tiene saldo suficiente - 16/02/05
           if v_sldisponible < v_Tot_debito and v_puede_procesar = 'N' and r1.nro_cuenta = p_ctadbsu then
             v_Codigo_Error  :=25;
           end if;
           ---*
            Update ge_pag_sueldos_tmp
             set estado       = v_est_movimiento,
                cod_ente      = p_cod_ente,
                cod_proceso   = v_codigo_error,
                cod_modalidad = v_cod_modalidad,
                cod_moneda    = v_cod_moneda,
                cod_modulo    = v_cod_modulo
            where current of c1;

            if sql%notfound then
              RAISE_APPLICATION_ERROR(-20725,'ERROR. Al actualiza ge_pag_sueldos_tmp '||sqlerrm);
            end if;
      END LOOP;
    END;
   p_lugar :=  'PR_INS_GE_PAG_SUELDO : Verificando ERRORES';
   BEGIN
     SELECT COUNT(*)
       INTO p_Cant_Error
       FROM ge_pag_sueldos_tmp
      WHERE fec_proceso = p_fec_hoy
        and cod_proceso <> 0
        and ((cod_ente is null)
             or cod_ente = p_cod_ente);
   EXCEPTION
       WHEN OTHERS THEN
         p_Cant_Error := 0;
   END;
END;
end pr_ins_ge_pag_sueldo;
/* Obtener los datos de la cuenta */
PROCEDURE LP_OBT_DATOS_CUENTA
 (P_NRO_CUENTA IN VARCHAR2
 ,P_TAS_PERSONALIZADA IN OUT VARCHAR2
 ,P_COD_MONEDA IN OUT VARCHAR2
 ,P_LUGAR OUT VARCHAR2
 )
 IS
begin
 p_lugar := 'Obteniendo Datos de la Cuenta';
  Select tas_personalizada, cod_moneda
    into p_tas_personalizada, p_cod_moneda
    from GE_CUENTAS
   where nro_cuenta = p_nro_cuenta;
EXCEPTION
 WHEN NO_DATA_FOUND THEN
 RAISE_APPLICATION_ERROR(-20030,'ERROR. Cuenta :'||p_nro_cuenta||' no existe.');
  WHEN OTHERS THEN
 RAISE_APPLICATION_ERROR(-20040,'ERROR. obt. datos cuenta: '||p_nro_cuenta||' '||sqlerrm);
end lp_obt_datos_cuenta;
/* Verifica que ya no se hayan insertado los mov. de sueldos de la fecha */
PROCEDURE LP_VER_DUP_MOV_DIARI
 (P_CUENTA IN VARCHAR2
 ,P_SUELDO IN NUMBER
 ,P_COD_ENTE IN NUMBER
 )
 IS

V_HRMOVIM VARCHAR2(8);
V_DCEMPRESA VARCHAR2(35);
V_EMPRESA NUMBER(3);
BEGIN
  v_HrMovim := NULL;
  v_Empresa := NULL;
  --
  SELECT HORA  INTO v_HrMovim
    FROM GE_MOVIMIENTOS
   WHERE NRO_CUENTA = p_cuenta
     AND NRO_DOCUMENTO = p_cod_ente
     AND MONTO = p_sueldo
     and reversado = 'N';
  IF v_HrMovim IS NOT NULL THEN
    RAISE_APPLICATION_ERROR(-20050,'ERROR. Información Procesada en fecha de hoy a las '||v_hrmovim);
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     NULL;
END;
/* Obtener la max hora para todos los movimientos */
PROCEDURE LP_OBT_HORA_MOVIM
 (P_HORA IN OUT VARCHAR2
 ,P_FEC_HOY IN GE_PAG_SUELDOS.FEC_PROCESO%TYPE
 ,P_COD_TRA_PADRE IN VARCHAR2
 ,P_LUGAR OUT VARCHAR2
 )
 IS
begin
     p_lugar := 'Obtener_Hora_Movimiento';
   SELECT MAX(hora)
     INTO p_hora
     FROM ge_movimientos
    WHERE fecha = p_Fec_hoy
      AND cod_tra_padre = p_cod_tra_padre
      and reversado = 'N' ;
EXCEPTION
  WHEN OTHERS THEN
   RAISE_APPLICATION_ERROR(-20080,'Al obtener hora movimiento '||sqlerrm);
end lp_obt_hora_movim;
/* Obtener cant.y monto total de pago de sueldo */
PROCEDURE LP_OBT_MONTO_PROC
 (P_SECUENCIA IN NUMBER
 ,P_COD_ENTE IN NUMBER
 ,P_CANTCRED IN OUT NUMBER
 ,P_MONTCRED IN OUT NUMBER
 ,P_LUGAR OUT VARCHAR2
 ,P_FEC_HOY IN DATE
 )
 IS
begin
  --Obtener Cantidad y Monto Total del Pago de Sueldos
  p_lugar := 'Obtener_CantMont_Proc_Total';
  SELECT count(*), SUM(NVL(MONTO,0))
    INTO p_CantCred, p_MontCred
    FROM GE_PAG_SUELDOS
   WHERE COD_ENTE = p_cod_ente
     AND TIPO = 'C'
     and trunc(fec_proceso) = trunc(P_FEC_HOY);
EXCEPTION
   WHEN OTHERS THEN
   RAISE_APPLICATION_ERROR(-20090,'Al Buscar monto y cant total proceso '||sqlerrm);
end lp_obt_monto_proc;
/* Obtener datos de la empresa */
PROCEDURE PR_OBT_DATOS_EMPRESA
 (P_EMPRESA IN NUMBER
 ,P_DESCRIP IN OUT VARCHAR2
 ,P_CTADBSU IN OUT VARCHAR2
 ,P_TRANPDB IN OUT NUMBER
 ,P_TRANCOM IN OUT NUMBER
 ,P_TRANEXC IN OUT NUMBER
 ,P_TRANPAGUI IN OUT NUMBER
 ,P_TRANPCOM IN OUT NUMBER
 ,P_TRANPCRE IN OUT NUMBER
 ,P_DEB_EXCESO IN OUT VARCHAR2
 ,P_FEC_INICIO IN OUT DATE
 ,P_FEC_VENCIMIENTO IN OUT DATE
 ,P_SER_ACTIVO IN OUT VARCHAR2
 ,P_CAN_MAX_TRANS IN OUT NUMBER
 ,P_NRO_CTA_CONTABLE IN OUT VARCHAR2
 ,P_REFERENCIA_TXT IN OUT VARCHAR2
 ,P_LUGAR OUT VARCHAR2
 )
 IS
begin

 p_lugar := 'Obt_Datos_Empresa';
  SELECT descripcion
    INTO p_descrip
    FROM GE_ENTES
   WHERE cod_ente = p_empresa;
   ------------------------------------------
 -- Se debe obtener los demás parametros...
   ------------------------------------------
  p_ctadbsu := fug_obt_parentes(p_empresa, 'NRO_CTA_DEBITO');
--  Comentado para funcionalidad de cuenta de ahorro o rubro contable en modulo de RRHH
--  IF p_ctadbsu IS NULL THEN
--   RAISE_APPLICATION_ERROR(-20300,'ATENCION. La empresa no posee Cuenta de Débito. Verifique!!!');
--  END IF;

  p_tranpdb := fug_obt_parentes(p_empresa, 'COD_TRA_PAD_SUELDO');
  if p_tranpdb IS NULL THEN
   RAISE_APPLICATION_ERROR(-20310,'ATENCION. La empresa no posee Transacción Padre de Débito. Verifique!!!');
  end if;

  p_trancom := fug_obt_parentes(p_empresa, 'COD_TRA_COMISION');
  if p_trancom IS NULL then
   RAISE_APPLICATION_ERROR(-20320,'ATENCION. La empresa no posee Trans.COMISION . Verifique!!!');
  end if;

  p_tranexc := fug_obt_parentes(p_empresa, 'COD_TRA_COM_EXCESO');
--  if p_tranexc IS NULL then
--   RAISE_APPLICATION_ERROR(-20330,'ATENCION. La empresa no posee trans.COMIS.X EXCESO . Verifique!!!');
--  end if;

  p_tranpagui := fug_obt_parentes(p_empresa, 'COD_TRA_PAD_AGUINALDO');
--  if p_tranpagui is null then
--   RAISE_APPLICATION_ERROR(-20340,'ATENCION. La empresa no posee trans.PADRE AGUINALDO . Verifique!!!');
--  end if;

  p_tranpcom := fug_obt_parentes(p_empresa, 'COD_TRA_PAD_COMISION');
--  if p_tranpcom is null then
--   RAISE_APPLICATION_ERROR(-20340,'ATENCION. La empresa no posee trans.PADRE COMISION . Verifique!!!');
--  end if;

  p_tranpcre := fug_obt_parentes(p_empresa, 'COD_TRA_PAD_CREDITO');
--  if p_tranpcre is null then
--   RAISE_APPLICATION_ERROR(-20340,'ATENCION. La empresa no posee trans.PADRE CREDITO. Verifique!!!');
--  end if;

  p_deb_exceso := fug_obt_parentes(p_empresa, 'DEB_EXCESO_EMPRESA');
--  if p_deb_exceso is null then
--   RAISE_APPLICATION_ERROR(-20340,'ATENCION. La empresa no posee INDICADOR DEB.X EXCESO. Verifique!!!');
--  end if;

  p_fec_inicio := to_date(fug_obt_parentes(p_empresa, 'FEC_INICIO'), 'DD/MM/YYYY');
  if p_fec_inicio is null then
   RAISE_APPLICATION_ERROR(-20340,'ATENCION. La empresa no posee FECHA INICIO CONTRATO . Verifique!!!');
  end if;

  p_fec_vencimiento := to_date(fug_obt_parentes(p_empresa, 'FEC_VENCIMIENTO'), 'DD/MM/YYYY');
  if p_fec_vencimiento is null then
   RAISE_APPLICATION_ERROR(-20340,'ATENCION. La empresa no posee FECHA VENCIMIENTO CONTRATO . Verifique!!!');
  end if;

  p_ser_activo := fug_obt_parentes(p_empresa, 'SER_ACTIVO');
--  if p_ser_activo is null then
--   RAISE_APPLICATION_ERROR(-20340,'ATENCION. La empresa no posee INDICADOR DE SERVICIO ACTIVO. Verifique!!!');
--  end if;

  p_can_max_trans := fug_obt_parentes(p_empresa, 'CAN_MAX_TRANSACCION');
--  if  p_can_max_trans is null then
--   RAISE_APPLICATION_ERROR(-20340,'ATENCION. La empresa no posee CANTIDAD MAX.DE TRANS. Verifique!!!');
--  end if;

  p_nro_cta_contable := fug_obt_parentes(p_empresa, 'NRO_CTA_CONTABLE');
  if  p_nro_cta_contable is null and p_ctadbsu is null then
   RAISE_APPLICATION_ERROR(-20340,'ATENCION. La empresa no posee NRO. de CTA. CONTABLE para Debitar Salarios. Verifique!!!');
  end if;

  p_referencia_txt := fug_obt_parentes(p_empresa, 'REFERENCIA_TXT_SUELDO');
  if p_referencia_txt is null then
   RAISE_APPLICATION_ERROR(-20341,'ATENCION. La empresa no posee DEFINICION PARA TXT . Verifique!!!');
  end if;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
   RAISE_APPLICATION_ERROR(-20400,'Empresa Inexistente... Verifique.'||sqlerrm);
  WHEN TOO_MANY_ROWS THEN
   RAISE_APPLICATION_ERROR(-20450,'Empresa Duplicada... AVISE AL ADMINISTRADOR.'||sqlerrm);
  WHEN OTHERS THEN
   RAISE_APPLICATION_ERROR(-20460,'Error en pr_obt_datos_empresa '||sqlerrm);
end pr_obt_datos_empresa;
/* Inserta en la tabla GE_PAG_SUELDOS */
PROCEDURE LP_INS_TABLA
 (P_COD_ENTE IN NUMBER
 ,P_LUGAR OUT VARCHAR2
 ,P_NRO_SECUENCIA OUT NUMBER
 ,P_ERROR OUT VARCHAR2
 )
 IS
v_nro_cuenta   ge_pag_sueldos.nro_cuenta%type;
   v_nro_cta_tmp  ge_pag_sueldos.nro_cuenta%type;
   v_existe       char(1) := 'N';
   v_secuencia    ge_pag_sueldos.nro_secuencia%type;

   cursor c_tmp is select a.*, rowid fila 
                     from ge_pag_sueldos_tmp a
                    where ((cod_ente is null)
                            or cod_ente = p_cod_ente);

   cursor c_cta is select nro_cuenta from ge_cuentas where
      nro_cuenta = v_nro_cuenta
      and rownum = 1 ;
begin
   -- primero verifico si todas las cuentas estan en GE_CUENTAS --
    p_lugar := 'Insertando en GE_PAG_SUELDOS';

    for reg in c_tmp loop
      v_nro_cuenta  := reg.nro_cuenta ;

        v_nro_Cta_tmp := null;

        open c_Cta;
        fetch c_cta into v_nro_Cta_tmp;
        close c_Cta;

        if v_nro_cta_tmp is null then
          update ge_pag_sueldos_tmp set cod_proceso=12 --CTA INEXISTENTE --
           where rowid = reg.fila;
        /* where nro_cuenta = reg.nro_cuenta
             and ((cod_ente is null)
                   or cod_ente = p_cod_ente);*/
           P_ERROR :='S';
           exit;
        else
           --- voy a verificar si ya no se insertaron estos datos
           begin
             select 'S', nro_secuencia into v_existe, v_secuencia
             from ge_pag_sueldos where
                nro_cuenta = reg.nro_cuenta and
                fec_envio  = reg.fec_envio and
                cod_ente   = reg.cod_ente and
                monto      = reg.monto and
                tipo       = reg.tipo and
                rownum     = 1;
           exception
             when no_data_found then
                v_existe := 'N';
           end;
           ---
           if v_existe = 'N' then
             insert into ge_pag_sueldos
              (cod_ente, fec_proceso, nro_secuencia, nro_cuenta,
               cod_moneda, fec_envio, tipo, monto, estado,
               cod_proceso, cod_modulo,cod_modalidad)
             select cod_ente, trunc(fec_proceso), nro_secuencia, nro_cuenta,
                    cod_moneda, fec_envio, tipo, monto, estado,
                    cod_proceso, cod_modulo,cod_modalidad
               from ge_pag_sueldos_tmp
              where rowid = reg.fila;
            /*where nro_cuenta = reg.nro_cuenta
                and ((cod_ente is null)
                      or cod_ente = p_cod_ente);*/
           else

             insert into ge_pag_sueldos
              (cod_ente, fec_proceso, nro_secuencia, nro_cuenta,
               cod_moneda, fec_envio, tipo, monto, estado,
               cod_proceso, cod_modulo,cod_modalidad)
             select cod_ente, trunc(fec_proceso), (NVL(v_secuencia,0)+1), nro_cuenta,
                    cod_moneda, fec_envio, tipo, monto, estado,
                    cod_proceso, cod_modulo,cod_modalidad
               from ge_pag_sueldos_tmp
              where rowid = reg.fila;
            /*where nro_cuenta = reg.nro_cuenta
                and ((cod_ente is null)
                      or cod_ente = p_cod_ente);*/
           end if;
        end if;
    P_NRO_SECUENCIA := (NVL(v_secuencia,0)+1);
    end loop;
  exception
     when others then
     P_ERROR :='S';
     RAISE_APPLICATION_ERROR(-20808,'Error al insertar GE_PAG_SUELDOS :'||sqlerrm);
  end lp_ins_tabla;

END PAG_SUE;
/
