CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_INS_PROVISION
 (RP_PROVISIONES IN RH_PROVISIONES%ROWTYPE
 )
 IS
BEGIN
   insert into rh_provisiones
   (cod_persona, cod_tip_provision, fecha,
    mto_debe, mto_haber, sal_actual,
    cod_moneda,per_desde, per_hasta,
    dia_haber, dia_debe)
   values
   (rp_provisiones.cod_persona, rp_provisiones.cod_tip_provision, rp_provisiones.fecha,
    rp_provisiones.mto_debe, rp_provisiones.mto_haber, rp_provisiones.sal_actual,
    rp_provisiones.cod_moneda, rp_provisiones.per_desde, rp_provisiones.per_hasta,
    rp_provisiones.dia_haber, rp_provisiones.dia_debe);
exception
   when dup_val_on_index then
      null; --- Si ya se ejecuto calculo de aguinaldo
   when others then
      raise_application_error(-20000,'Ins.Prov '||rp_provisiones.cod_persona||
      ' Debe '||rp_provisiones.mto_debe||' Haber '||rp_provisiones.mto_haber||' '||sqlerrm);
END;
/
