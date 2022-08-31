CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_AUMENTOS
 BEFORE DELETE OR INSERT OR UPDATE
 ON RH_AUMENTOS
 FOR EACH ROW
BEGIN
   IF deleting THEN
      IF :old.ind_procesado = 'S' THEN
         raise_application_error(-20000,
         'No puede eliminar aumentos procesados');
      END IF;
   END IF;
END;
/
