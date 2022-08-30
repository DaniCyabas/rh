CREATE OR REPLACE TRIGGER WKSP_WSFDC.TB_RH_PAR_EMPRESAS
 BEFORE DELETE OR INSERT OR UPDATE
 ON RH_PAR_EMPRESAS
 FOR EACH ROW
DECLARE
   v_empresa    ba_per_juridicas.cod_persona%type;
BEGIN
   if inserting or updating then
      begin
         --if FUH_OBT_COD_EMPRESA(v_cod_per_empresa) <> v_cod_per_empresa then
         select cod_persona
         into   v_empresa
         from   ba_per_juridicas
         where  cod_persona = :new.cod_empresa;
      exception
         when no_data_found then
            raise_application_error(-20000,'Empresa no existe');
      end;

   end if;
END;
/
