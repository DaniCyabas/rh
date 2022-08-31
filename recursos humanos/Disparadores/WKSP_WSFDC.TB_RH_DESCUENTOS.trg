CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_DESCUENTOS
 BEFORE DELETE OR INSERT OR UPDATE
 ON RH_DESCUENTOS
 REFERENCING OLD AS OLD NEW AS NEW
 FOR EACH ROW
BEGIN
   IF deleting THEN
      IF :old.ind_procesado = 'S' THEN
         raise_application_error(-20000,
         'No puede eliminar descuento procesado '||to_char(:old.fecha,'DD/MM/YYYY')||' del empleado '||:old.cod_persona);
      END IF;
   END IF;
END;
/
