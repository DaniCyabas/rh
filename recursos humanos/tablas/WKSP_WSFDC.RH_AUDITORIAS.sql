CREATE TABLE WKSP_WSFDC.RH_AUDITORIAS
 (
  TABLA VARCHAR2(40) NOT NULL,
  CLAVE VARCHAR2(100) NOT NULL,
  USUARIO VARCHAR2(30) DEFAULT USER NOT NULL,
  FEC_SISTEMA DATE NOT NULL,
  FEC_CALENDARIO DATE NOT NULL,
  TIP_NOVEDAD VARCHAR2(1) NOT NULL,
  TERMINAL VARCHAR2(40),
  DETALLE VARCHAR2(2000) NOT NULL,
  ORIGEN VARCHAR2(40)
 );
COMMENT ON TABLE WKSP_WSFDC.RH_AUDITORIAS IS 'Registra la auditoría de operaciones o novedades sobre los registros.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUDITORIAS.TABLA IS 'Nombre de la tabla auditada.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUDITORIAS.CLAVE IS 'Clave primaria correspondiente al registro auditado a ser identificado.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUDITORIAS.USUARIO IS 'Usuario responsable por la novedad ocurrida sobre los datos.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUDITORIAS.FEC_SISTEMA IS 'Fecha del sistema en que se realizó la operación.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUDITORIAS.FEC_CALENDARIO IS 'Fecha calendario del módulo en el momento de realizarse la operación.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUDITORIAS.TIP_NOVEDAD IS 'Tipo de novedad u operación realizada con el dato.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUDITORIAS.TERMINAL IS 'Nombre de la terminal en la que se ejecutó la operación';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUDITORIAS.DETALLE IS 'Detalle de modificaciones realizadas.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUDITORIAS.ORIGEN IS 'Nombre del programa o aplicación desde el cual se ejecuto la operación.';
-- Grant/Revoke object privileges 
grant select, insert, update, delete on WKSP_WSFDC.RH_AUDITORIAS to PUBLIC;
