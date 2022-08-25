CREATE TABLE WKSP_WSFDC.RH_HOR_EXTRAS
 (
   COD_PERSONA VARCHAR2(10) NOT NULL,
   FECHA DATE NOT NULL,
   HOR_DESDE DATE NOT NULL,
   HOR_HASTA DATE NOT NULL,
   COD_CEN_COSTO NUMBER(3) NOT NULL,
   IND_PROCESADO VARCHAR2(1) DEFAULT 'N' NOT NULL,
   COD_PER_AUTORIZADOR VARCHAR2(10),
   OBSERVACION VARCHAR2(1000),
   HOR_TRABAJADA NUMBER(8,2),
   POR_SUELDO NUMBER(5,2) DEFAULT 0 ,
   USU_INSERCION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
   FEC_INSERCION DATE DEFAULT SYSDATE NOT NULL,
   USU_MODIFICACION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
   FEC_MODIFICACION DATE DEFAULT SYSDATE NOT NULL
 );
COMMENT ON TABLE WKSP_WSFDC.RH_HOR_EXTRAS IS 'Horas Extras del Empleado';
COMMENT ON COLUMN WKSP_WSFDC.RH_HOR_EXTRAS.FECHA IS 'Fecha';
COMMENT ON COLUMN WKSP_WSFDC.RH_HOR_EXTRAS.HOR_DESDE IS 'Hora desde la cual realizar� la hora extra.';
COMMENT ON COLUMN WKSP_WSFDC.RH_HOR_EXTRAS.HOR_HASTA IS 'Hora hasta la cual realizar� sus labores extraordinarias.';
COMMENT ON COLUMN WKSP_WSFDC.RH_HOR_EXTRAS.IND_PROCESADO IS 'Procesado?';
COMMENT ON COLUMN WKSP_WSFDC.RH_HOR_EXTRAS.OBSERVACION IS 'Observaci�n';
COMMENT ON COLUMN WKSP_WSFDC.RH_HOR_EXTRAS.HOR_TRABAJADA IS 'Cantidad de horas trabajadas efectivamente por el empleado.';
-- Grant/Revoke object privileges
grant select, insert, update, delete on WKSP_WSFDC.RH_HOR_EXTRAS to PUBLIC;