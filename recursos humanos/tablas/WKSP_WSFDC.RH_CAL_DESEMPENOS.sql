CREATE TABLE WKSP_WSFDC.RH_CAL_DESEMPENOS
 (
   COD_PERSONA VARCHAR2(10) NOT NULL,
   FEC_CALIFICACION DATE NOT NULL,
   COD_TIP_DESEMPENO NUMBER(3,0) NOT NULL,
   CALIFICACION NUMBER(3),
   OBSERVACION VARCHAR2(1000),
   USU_INSERCION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
   FEC_INSERCION DATE DEFAULT SYSDATE NOT NULL,
   USU_MODIFICACION VARCHAR2(10) DEFAULT SUBSTR(USER,1,10) NOT NULL,
   FEC_MODIFICACION DATE DEFAULT SYSDATE NOT NULL
 );

COMMENT ON TABLE WKSP_WSFDC.RH_CAL_DESEMPENOS IS 'Calificaciones de Desempe�o de Empleados';
COMMENT ON COLUMN WKSP_WSFDC.RH_CAL_DESEMPENOS.COD_PERSONA IS 'Codigo de la persona';
COMMENT ON COLUMN WKSP_WSFDC.RH_CAL_DESEMPENOS.FEC_CALIFICACION IS 'Fecha de Calificaci�n';
COMMENT ON COLUMN WKSP_WSFDC.RH_CAL_DESEMPENOS.COD_TIP_DESEMPENO IS 'Tipo de Calidad del Desempe�o';
COMMENT ON COLUMN WKSP_WSFDC.RH_CAL_DESEMPENOS.OBSERVACION IS 'Observaci�n';
-- Grant/Revoke object privileges
grant select, insert, update, delete on WKSP_WSFDC.RH_CAL_DESEMPENOS to PUBLIC;