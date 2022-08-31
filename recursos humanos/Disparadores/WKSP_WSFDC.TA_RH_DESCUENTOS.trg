CREATE OR REPLACE TRIGGER WKSP_WSFDC.TA_RH_DESCUENTOS
 AFTER DELETE OR INSERT OR UPDATE
 ON RH_DESCUENTOS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
   if updating then
      if :old.ind_procesado <> :new.ind_procesado then
         --verificar cuotas del prestamo
         null;
      /* if :new.cuo_numero is not null and :new.ind_procesado = 'S' then
            update rh_cuotas
            set fec_pago = :new.fec_descuento,
                cod_tip_pago = 1
            where cod_empleado = :new.cod_empleado
            and nro_prestamo = :new.nro_prestamo
            and numero = :new.cuo_numero;
         elsif :new.cuo_numero is not null and :new.ind_procesado = 'N' then
            --- Reversion
            update rh_cuotas
            set fec_pago = null,
                cod_tip_pago = null
            where cod_empleado = :new.cod_empleado
            and nro_prestamo = :new.nro_prestamo
            and numero = :new.cuo_numero;
         end if; */
      end if;
   end if;
END;
/
