CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_OBT_TIP_DESCUENT
 (
  P_COD_TIP_DESCUENTO IN RH_TIP_DESCUENTOS.COD_TIP_DESCUENTO%TYPE,
  RP_TIP_DESCUENTO IN OUT RH_TIP_DESCUENTOS%ROWTYPE
 )
 IS
BEGIN
   select *
   into rp_tip_descuento
   from rh_tip_descuentos
   where cod_tip_descuento = p_cod_tip_descuento;
exception
   when no_data_found then
      raise_application_error(-20000,
      'El tipo de descuento '||to_char(p_cod_tip_descuento)||' no registrado');
END;
/
