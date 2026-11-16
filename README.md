# Tienda de turrones

Aplicación web estática conectada a Supabase.

## Antes de publicar
1. Abre Supabase > SQL Editor.
2. Copia y ejecuta el contenido completo de `setup.sql`.
3. Sube `index.html`, `styles.css` y `app.js` a GitHub.
4. En Cloudflare Pages conecta el repositorio. Al ser una web estática, no necesita comando de build; el directorio es `/`.

## Seguridad
La aplicación usa únicamente la Publishable Key. Los precios finales se recalculan dentro de la función SQL `crear_pedido_seguro`. Nunca añadas una secret key o service_role al repositorio.
