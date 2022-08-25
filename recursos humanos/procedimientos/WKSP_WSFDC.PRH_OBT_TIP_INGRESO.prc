CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_OBT_TIP_INGRESO
 (
 P_COD_TIP_INGRESO IN RH_TIP_INGRESOS.COD_TIP_INGRESO%TYPE,
 RP_TIP_INGRESO IN OUT RH_TIP_INGRESOS%ROWTYPE
 )
 IS
BEGIN
   SELECT *
   INTO rp_tip_ingreso
   FROM rh_tip_ingresos
   WHERE cod_tip_ingreso = p_cod_tip_ingreso;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      raise_application_error(-20000,
      'No existe tipo ingreso '||to_char(p_cod_tip_ingreso));
   WHEN OTHERS THEN
      raise_application_error(-20000,
      'Rec.Tip.Ing '||to_char(p_cod_tip_ingreso)||' '||sqlerrm);
END;
/
