CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_INS_PUESTO
 (RP_PST IN RH_PUESTOS%ROWTYPE)
 IS
BEGIN
   insert into rh_puestos
    (cod_persona, fec_desde, fec_hasta,
     cod_cat_empleado, cod_cen_costo, cargo,
     ind_interino, salario, cod_moneda, cod_oficina)
    values
    (rp_pst.cod_persona, rp_pst.fec_desde, rp_pst.fec_hasta,
     rp_pst.cod_cat_empleado, rp_pst.cod_cen_costo, rp_pst.cargo,
     rp_pst.ind_interino, rp_pst.salario, rp_pst.cod_moneda, rp_pst.cod_oficina);
END;
/
