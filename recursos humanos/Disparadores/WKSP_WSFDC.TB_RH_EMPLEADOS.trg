CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_EMPLEADOS
 BEFORE DELETE OR INSERT OR UPDATE
 ON RH_EMPLEADOS
 FOR EACH ROW
DECLARE
   v_cod_per_empresa    ba_per_juridicas.cod_persona%type;
BEGIN
   if inserting or updating then
    --if FUH_OBT_COD_EMPRESA(v_cod_per_empresa) <> v_cod_per_empresa then
      begin
         select cod_persona
         into   v_cod_per_empresa
         from   ba_per_juridicas
         where  cod_persona = :new.cod_per_empresa;
      exception
         when no_data_found then
            raise_application_error(-20000,'Empresa no existe');
      end;
   end if;
END;
/
