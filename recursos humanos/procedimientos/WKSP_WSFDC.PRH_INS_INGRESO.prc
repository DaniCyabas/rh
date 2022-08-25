CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_INS_INGRESO
 (RP_ING IN RH_INGRESOS%ROWTYPE
 )
 IS
v_numero rh_ingresos.numero%type;
BEGIN
   v_numero := rp_ing.numero;
   if rp_ing.numero IS NULL then
      BEGIN
         select nvl(max(numero),0) + 1
         into v_numero
         from rh_ingresos
         where cod_persona = rp_ing.cod_persona;
      END;
   end if;
   
   --actualizar el anterior
   update rh_ingresos
   set    fecha   = sysdate - 1
   where  cod_persona = rp_ing.cod_persona
   and    fecha is null;
   
   ---insertar el nuevo
   insert into rh_ingresos
   (cod_persona, numero, fecha, cod_tip_ingreso,
    monto, cod_moneda,
    ind_procesado, cod_per_autorizador, observacion)
    values
   (rp_ing.cod_persona, v_numero, rp_ing.fecha, rp_ing.cod_tip_ingreso,
    rp_ing.monto, rp_ing.cod_moneda,
    rp_ing.ind_procesado, rp_ing.cod_per_autorizador, rp_ing.observacion);
END;
/
