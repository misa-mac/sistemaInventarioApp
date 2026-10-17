/**
 * Validador de Seguridad Deny-By-Default (Regla 2)
 * Recorre todas las rutas registradas en Express.
 * Si alguna ruta (salvo POST /api/auth/login) no tiene el middleware authorize(),
 * lanza un error impidiendo el arranque de la aplicación o haciendo fallar las pruebas.
 */
function validateAppSecurity(app) {
  if (!app || !app._router || !app._router.stack) {
    return;
  }

  const unsecuredRoutes = [];

  function scanStack(stack, basePath = '') {
    for (const layer of stack) {
      if (layer.route) {
        const routePath = `${basePath}${layer.route.path}`.replace(/\/+/g, '/');
        const methods = Object.keys(layer.route.methods || {});

        for (const method of methods) {
          // Excepción explícita: POST /api/auth/login es público y GET / es healthcheck
          if (
            (method.toLowerCase() === 'post' && routePath === '/api/auth/login') ||
            (method.toLowerCase() === 'get' && (routePath === '/' || routePath === ''))
          ) {
            continue;
          }

          // Verificar si algún middleware de la ruta es authorize
          const hasAuthorize = (layer.route.stack || []).some(
            (handlerLayer) => handlerLayer.handle && (handlerLayer.handle._isAuthorize === true || handlerLayer.handle._action)
          );

          if (!hasAuthorize) {
            unsecuredRoutes.push(`${method.toUpperCase()} ${routePath}`);
          }
        }
      } else if (layer.name === 'router' && layer.handle && layer.handle.stack) {
        // Sub-router montado con app.use(...)
        let routerPath = '';
        if (layer.regexp) {
          const match = layer.regexp.source
            .replace('\\/?(?=\\/|$)', '')
            .replace('^', '')
            .replace('\\/?$', '')
            .replace(/\\\//g, '/');
          routerPath = match.replace(/\\/g, '');
        }
        scanStack(layer.handle.stack, `${basePath}/${routerPath}`.replace(/\/+/g, '/'));
      }
    }
  }

  scanStack(app._router.stack);

  if (unsecuredRoutes.length > 0) {
    const errorMsg = `[SEGURIDAD CRÍTICA - DENEGAR POR DEFECTO] Se encontraron rutas sin middleware authorize:\n` +
      unsecuredRoutes.map(r => `  - ${r}`).join('\n') +
      `\nTodas las rutas (salvo POST /api/auth/login) deben invocar authorize('accion').`;
    console.error(errorMsg);
    throw new Error(errorMsg);
  }

  console.log('🛡️ [SEGURIDAD]: Validación Deny-By-Default completada: Todas las rutas tienen RBAC estricto.');
}

module.exports = { validateAppSecurity };
