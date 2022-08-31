CREATE OR REPLACE TRIGGER WKSP_WSFDC.TA_RH_EMPLEADOS
 AFTER DELETE OR INSERT OR UPDATE
 ON RH_EMPLEADOS
 FOR EACH ROW
DECLARE
   r_pst  rh_puestos%rowtype;
   v_fec_inicio rh_puestos.fec_desde%type;
   v_cantidad number;
   v_existe varchar2(1) := 'S';
BEGIN
   if inserting then
      --- Insertar el nuevo
      r_pst.cod_persona       := :new.cod_persona;
      r_pst.fec_desde         := :new.fec_ingreso;
      r_pst.cod_cat_empleado  := :new.cod_cat_empleado;
      r_pst.cod_cen_costo     := :new.cod_cen_costo;
      r_pst.cargo             := :new.cargo;
      r_pst.salario           := :new.sal_base;
      r_pst.cod_moneda        := :new.cod_moneda;
      r_pst.cod_oficina       := :new.cod_oficina;
      prh_ins_puesto(r_pst);
   end if;
   ---
   if updating then
     if :new.cod_cat_empleado <> nvl(:old.cod_cat_empleado,0)
     or :new.cod_cen_costo <> nvl(:old.cod_cen_costo,0)
     or :new.cargo <> nvl(:old.cargo,' ')
     or :new.cod_moneda <> nvl(:old.cod_moneda,' ')
     or :new.sal_base <> nvl(:old.sal_base,0)
     or :new.cod_oficina <> nvl(:old.cod_oficina,0) then
        --- Actualizar el anterior

        begin
           select 'S' into v_existe
             from rh_puestos
            where cod_persona = :new.cod_persona
              and trunc(fec_desde) = trunc(sysdate)
              and fec_hasta is null;
        exception
           when no_data_found then
              v_existe := 'N';
           when others then
              v_existe := 'S';
        end;

        if v_existe = 'S' then
           update rh_puestos
           set     cod_cat_empleado  = :new.cod_cat_empleado,
                   cod_cen_costo     = :new.cod_cen_costo,
                   cargo             = :new.cargo,
                   salario           = :new.sal_base,
                   cod_moneda        = :new.cod_moneda,
                   cod_oficina       = :new.cod_oficina
           where  cod_persona = :new.cod_persona
           and    trunc(fec_desde) = trunc(sysdate)
           and    fec_hasta is null;
        else
          update rh_puestos
          set    fec_hasta   = sysdate - 1
          where  cod_persona = :new.cod_persona
          and    fec_hasta is null;
          --- Verificar si se esta migrando
          select count(cod_persona)
          into   v_cantidad
          from   rh_puestos
          where  cod_persona = :new.cod_persona;

          if nvl(v_cantidad,0) = 0 then
             v_fec_inicio := :new.fec_ingreso;
          else
             v_fec_inicio := sysdate;
          end if;
          --- Insertar el nuevo
          r_pst.cod_persona       := :new.cod_persona;
          r_pst.fec_desde         :=  v_fec_inicio;
          r_pst.cod_cat_empleado  := :new.cod_cat_empleado;
          r_pst.cod_cen_costo     := :new.cod_cen_costo;
          r_pst.cargo             := :new.cargo;
          r_pst.salario           := :new.sal_base;
          r_pst.cod_moneda        := :new.cod_moneda;
          r_pst.cod_oficina       := :new.cod_oficina;
          prh_ins_puesto(r_pst);
        end if;
     end if;
   end if;
   --- Por ELIMINAR
   --- Dejar por FK
END;
/
