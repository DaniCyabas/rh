CREATE OR REPLACE PROCEDURE WKSP_WSFDC.PRH_INS_SOBRE
 (
   RP_SOB IN RH_SOBRES%ROWTYPE,
   P_NRO_SOBRE IN OUT RH_SOBRES.NRO_SOBRE%TYPE
 )
 IS
BEGIN
   SELECT nvl(max(nro_sobre),0) + 1
   into p_nro_sobre
   FROM rh_sobres
   where cod_persona = rp_sob.cod_persona;
   insert into rh_sobres
   (cod_persona, nro_sobre, ano, mes, quincena,
    nro_patronal, fec_calculo)
   values
   (rp_sob.cod_persona, p_nro_sobre, rp_sob.ano, rp_sob.mes, rp_sob.quincena,
    rp_sob.nro_patronal, rp_sob.fec_calculo);
exception
   when dup_val_on_index then
      select nro_sobre
        into p_nro_sobre
        from rh_sobres
       where cod_persona = rp_sob.cod_persona
         and fec_calculo  = rp_sob.fec_calculo;
END;
/
