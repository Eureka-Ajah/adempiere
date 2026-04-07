# ZK Rollout Checklist (PR-8)

## 1) Pre-deploy
- [ ] Ejecutar `./scripts/zk/run_guard_suite.sh` y guardar evidencia.
- [ ] Confirmar smoke funcional mínimo (login, abrir ventana, CRUD, reporte).
- [ ] Validar métricas base de performance (tiempo de login y primera ventana).

## 2) Canary
- [ ] Desplegar primero en entorno piloto con usuarios internos.
- [ ] Monitorear logs de servidor y errores JS por 24h.
- [ ] Registrar incidencias por flujo crítico.

## 3) Go/No-Go
- [ ] Go si no hay errores bloqueantes y degradación severa.
- [ ] No-Go si aparecen errores de autenticación/sesión/rendering masivos.

## 4) Rollback
- [ ] Mantener artefacto previo listo para redeploy inmediato.
- [ ] Documentar timestamp y versión exacta revertida.
- [ ] Comunicar rollback y estado al equipo funcional.

## 5) Post-deploy
- [ ] Ejecutar nuevamente `./scripts/zk/run_guard_suite.sh` en rama de release.
- [ ] Cerrar incidencias abiertas del canary.
- [ ] Actualizar inventario y checklist con lecciones aprendidas.
