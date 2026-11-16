-- Ejecuta este archivo UNA VEZ en Supabase > SQL Editor.
-- Crea un pedido completo y calcula los precios en la base de datos.
create or replace function public.crear_pedido_seguro(p_pedido jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_pedido_id bigint;
  v_codigo text;
  v_total numeric(10,2) := 0;
  v_linea jsonb;
  v_precio numeric(10,2);
  v_producto_id bigint;
  v_opcion_id bigint;
  v_cantidad integer;
begin
  if coalesce(trim(p_pedido->>'nombre_cliente'),'') = '' or coalesce(trim(p_pedido->>'telefono'),'') = '' then
    raise exception 'Nombre y telefono son obligatorios';
  end if;
  if coalesce((p_pedido->>'consentimiento_datos')::boolean,false) is not true then
    raise exception 'Se requiere consentimiento';
  end if;
  if jsonb_array_length(coalesce(p_pedido->'lineas','[]'::jsonb)) = 0 then
    raise exception 'El pedido no tiene lineas';
  end if;
  v_codigo := 'PED-' || to_char(now(),'YYYYMMDD-HH24MISS') || '-' || lpad((floor(random()*1000))::int::text,3,'0');
  insert into public.pedidos(codigo,nombre_cliente,telefono,email,direccion,poblacion,metodo_entrega,metodo_pago,estado,total,notas_cliente,consentimiento_datos)
  values(v_codigo,left(p_pedido->>'nombre_cliente',100),left(p_pedido->>'telefono',30),nullif(left(p_pedido->>'email',150),''),nullif(left(p_pedido->>'direccion',200),''),nullif(left(p_pedido->>'poblacion',100),''),left(p_pedido->>'metodo_entrega',50),left(p_pedido->>'metodo_pago',50),'Nuevo',0,nullif(left(p_pedido->>'notas_cliente',500),''),true)
  returning id into v_pedido_id;
  for v_linea in select * from jsonb_array_elements(p_pedido->'lineas') loop
    v_producto_id := (v_linea->>'producto_id')::bigint;
    v_opcion_id := (v_linea->>'opcion_id')::bigint;
    v_cantidad := greatest(1,least(99,(v_linea->>'cantidad')::integer));
    select round(p.precio_base * o.factor_precio,2) into v_precio
    from public.productos p join public.opciones_venta o on o.producto_id=p.id
    where p.id=v_producto_id and o.id=v_opcion_id and p.activo=true and o.activa=true;
    if v_precio is null then raise exception 'Producto u opcion no validos'; end if;
    insert into public.lineas_pedido(pedido_id,producto_id,opcion_id,cantidad,precio_unitario,subtotal)
    values(v_pedido_id,v_producto_id,v_opcion_id,v_cantidad,v_precio,round(v_precio*v_cantidad,2));
    v_total := v_total + round(v_precio*v_cantidad,2);
  end loop;
  update public.pedidos set total=v_total where id=v_pedido_id;
  return v_codigo;
end;
$$;
revoke all on function public.crear_pedido_seguro(jsonb) from public;
grant execute on function public.crear_pedido_seguro(jsonb) to anon, authenticated;
