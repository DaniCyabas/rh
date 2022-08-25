CREATE TABLE WKSP_WSFDC.RH_AUMENTOS
 (
 COD_EMPRESA VARCHAR2(10) NOT NULL,
 COD_CEN_COSTO NUMBER(3),
 COD_PER_DESDE VARCHAR2(10) NOT NULL,
 COD_PER_HASTA VARCHAR2(10) NOT NULL,
 FECHA DATE NOT NULL
 MONTO NUMBER(18,2),
 PORCENTAJE NUMBER(5,2),
 IND_PROCESADO VARCHAR2(1) DEFAULT 'N' NOT NULL,
 COD_PER_AUTORIZADOR VARCHAR2(10),
 IND_AFECTACION VARCHAR2(1) NOT NULL,
 COD_TIP_INGRESO NUMBER(3,0),
 USU_INSERCION VARCHAR2(30) NOT NULL,
 FEC_INSERCION DATE NOT NULL,
 USU_MODIFICACION VARCHAR2(30) NOT NULL,
 FEC_MODIFICACION DATE NOT NULL
 );
COMMENT ON TABLE WKSP_WSFDC.RH_AUMENTOS IS 'Aumentos del m�dulo de Recursos Humanos';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.COD_EMPRESA IS 'C�digo de la empresa';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.COD_CEN_COSTO IS 'C�digo del Centro de Costo';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.COD_PER_DESDE IS 'C�digo de empleado desde el cual se procesa.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.COD_PER_HASTA IS 'C�digo de Empleado hasta el cual se aumenta.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.FECHA IS 'Fecha del aumento de salario.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.MONTO IS 'Monto a ser aumentado.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.PORCENTAJE IS 'Porcentaje a aumentar el sueldo.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.IND_PROCESADO IS 'Indica si el aumento fue o no procesado.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.COD_PER_AUTORIZADOR IS 'C�digo del Empleado Autorizador';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.IND_AFECTACION IS 'Indica si el aumento afecta al sueldo o es solo gratificaci�n.';
COMMENT ON COLUMN WKSP_WSFDC.RH_AUMENTOS.COD_TIP_INGRESO IS 'Tipo de Ingreso';

--Grant/Revoke object privileges
grant select, insert, update, delete on WKSP_WSFDC.RH_AUMENTOS to PUBLIC;