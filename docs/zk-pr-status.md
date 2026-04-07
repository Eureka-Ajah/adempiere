# Estado de ejecución — Plan de migración ZK (PR-1..PR-8)

| PR | Estado | Objetivo | Entregables implementados | Riesgo abierto principal | Siguiente acción sugerida |
|---|---|---|---|---|---|
| PR-1 | ✅ Completado | Inventario + línea base | `scripts/zk/generate_inventory.sh`, `docs/zk-inventory.md` | Cobertura de inventario depende de patrones actuales | Regenerar baseline al cerrar cada ola técnica |
| PR-2 | ✅ Completado | Normalización/guardas de dependencias ZK | `scripts/zk/check_zk_versions.sh`, CI en `zk-version-guard.yml` | Sigue existiendo stack legacy 3.6.3 | Definir versión objetivo final (LTS) |
| PR-3 | ✅ Completado | Bootstrap web/zk validado | Ajustes en `zkwebui/WEB-INF/web.xml` y `zkwebui/WEB-INF/zk.xml`, `scripts/zk/check_zk_bootstrap_config.sh` | Aún hay clases legacy de server push/complementos | Validar compatibilidad exacta contra versión ZK objetivo |
| PR-4 | ✅ Completado (ola 1) | Reducir acoplamiento a `zkex` | Wrappers `Borderlayout/Center/North/South/East/West` + reemplazos de imports en `org/adempiere/webui/**` | Persisten referencias en otros paquetes (`org/eevolution`, `org/spin`) | Ejecutar PR-4 ola 2 fuera de `org/adempiere/webui` |
| PR-5 | ✅ Completado (ola 1) | Reducir acoplamiento a `zkforge` | Wrappers `Keylistener`, `FCKeditor` + reemplazo de imports en `org/adempiere/webui/**` | Quedan referencias puntuales fuera del bloque principal | Completar sustitución en paquetes restantes |
| PR-6 | ✅ Completado (baseline) | Auditoría ZUL/tema/CSS | `scripts/zk/check_zul_theme_refs.sh`, `docs/zk-theme-audit.md`, check en CI | 3 assets faltantes detectados en tema | Corregir assets faltantes y cerrar gap visual |
| PR-7 | ✅ Completado | Alinear módulos satélite | `gradle/zk-legacy-libs.gradle`, módulos POS/Manufacturing alineados, `scripts/zk/check_satellite_modules.sh` | Dependencia temporal a jars legacy aún vigente | Migrar catálogo a coordenadas Maven de versión objetivo |
| PR-8 | ✅ Completado | Hardening + rollout | `scripts/zk/run_guard_suite.sh`, `docs/zk-rollout-checklist.md`, ejecución integral en CI | Falta validación funcional end-to-end en entorno real | Ejecutar canary controlado + checklist operativo |

## KPI de avance sugeridos

- `% imports directos zkex/zkforge` vs wrappers ADempiere.
- `missing_assets_count` de `docs/zk-theme-audit.md`.
- Resultado de `./scripts/zk/run_guard_suite.sh` en ramas release.

## Comando de verificación integral

```bash
./scripts/zk/run_guard_suite.sh
```
