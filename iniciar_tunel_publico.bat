@echo off
title Tunel Publico Cloudflare - ITBM Inventario
echo ========================================================
echo   Exponiendo Backend a Internet (Datos Moviles / Wi-Fi)
echo ========================================================
echo.
echo Conectando tu backend local (http://localhost:3000) a Internet...
echo.
echo --------------------------------------------------------
echo Copia la direccion HTTPS (ej: https://xxxx.trycloudflare.com)
echo que aparecera abajo y pegala en la app movil tocando el
echo icono de Wi-Fi en la pantalla de inicio de sesion.
echo --------------------------------------------------------
echo.
npx --yes cloudflared tunnel --url http://localhost:3000
pause
