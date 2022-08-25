CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_INS_LIQ_SUELDO
 (RP_LIQ_SUELDO IN OUT RH_LIQ_SUELDOS%ROWTYPE
 )
 IS

   v_emp_cod_moneda ba_monedas.cod_moneda%type;
   v_monto NUMBER;
   V_COT_MON_ORIGINAL NUMBER;
   V_COT_MON_DESTINO NUMBER;
BEGIN
   v_monto := 0;
   V_COT_MON_ORIGINAL := 0;
   V_COT_MON_DESTINO := 0;
   --- obtener moneda del empleado
   select cod_moneda
   into   v_emp_cod_moneda
   from   rh_empleados
   where  cod_persona = RP_LIQ_SUELDO.COD_PERSONA;
   if v_emp_cod_moneda = RP_LIQ_SUELDO.COD_MONEDA then
      v_monto := RP_LIQ_SUELDO.MONTO;
      V_COT_MON_ORIGINAL := 1;
   else
     prg_con_mon_a_moneda(RP_LIQ_SUELDO.COD_MONEDA,v_emp_cod_moneda,
                          RP_LIQ_SUELDO.MONTO, v_monto,
                          V_COT_MON_ORIGINAL, V_COT_MON_DESTINO);
   end if;
   --- insertar en liquidacion      
   INSERT INTO rh_liq_sueldos
      (COD_PERSONA,       NRO_SOBRE,     COD_TRANSACCION,
       COD_MODULO,        COD_MODALIDAD, COD_CEN_COSTO,
       MONTO, COD_MONEDA, COTIZACION,    COMPUTABLE,
       COD_TIP_INGRESO,   COD_TIP_DESCUENTO,
       VAC_FEC_DESDE,     ING_NUMERO,
       HEX_FEC_HOR_EXTRA, DES_NUMERO,
       HOR_COMPUTABLE)
   VALUES
      (RP_LIQ_SUELDO.COD_PERSONA, RP_LIQ_SUELDO.NRO_SOBRE,     RP_LIQ_SUELDO.COD_TRANSACCION,
       RP_LIQ_SUELDO.COD_MODULO,  RP_LIQ_SUELDO.COD_MODALIDAD, RP_LIQ_SUELDO.COD_CEN_COSTO,
       v_monto, v_emp_cod_moneda, V_COT_MON_ORIGINAL,          RP_LIQ_SUELDO.COMPUTABLE,
       RP_LIQ_SUELDO.COD_TIP_INGRESO,   RP_LIQ_SUELDO.COD_TIP_DESCUENTO,
       RP_LIQ_SUELDO.VAC_FEC_DESDE,     RP_LIQ_SUELDO.ING_NUMERO,
       RP_LIQ_SUELDO.HEX_FEC_HOR_EXTRA, RP_LIQ_SUELDO.DES_NUMERO,
       RP_LIQ_SUELDO.HOR_COMPUTABLE);
EXCEPTION
   WHEN OTHERS THEN
      raise_application_error(-20000,
      'Ins.Liq.Sueldo '||RP_LIQ_SUELDO.COD_PERSONA||' '||sqlerrm);
END;
/
