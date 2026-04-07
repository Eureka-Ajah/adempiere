# Plan completo para actualizar ZK en ADempiere

Este documento describe **todo lo necesario** para migrar el stack ZK actual del repositorio a una versión moderna y soportada, minimizando riesgos.

## 1) Estado actual (baseline)

- La UI `zkwebui` se construye con Ant y empaca `WEB-INF/lib/*.jar` dentro del `webui.war`.
- Los jars de ZK en `zkwebui/WEB-INF/lib` están en versión **3.6.3** (`zk.jar`, `zul.jar`, `zkmax.jar`), extremadamente antigua.
- El proyecto depende de componentes históricos de ZK que suelen romper en upgrades grandes:
  - `org.zkoss.zkex.*`
  - `org.zkforge.keylistener.*`
  - `org.zkforge.fckez.*`
  - `timelinez`, `gmapsz`, `zml`
- Existe acoplamiento directo por `fileTree` hacia `zkwebui/WEB-INF/lib` en módulos Gradle (ej. POS y Manufacturing), por lo que el cambio impacta más que solo `zkwebui`.

## 2) Estrategia recomendada (muy importante)

No intentar salto directo `3.6.3 -> última versión` en una sola PR.

### Estrategia por etapas

1. **Definir versión objetivo** (idealmente LTS soportada por su stack de Java/Tomcat).
2. **POC técnico** en rama aislada con una ventana crítica (login + abrir ventana + guardar registro + reporte).
3. **Eliminar dependencias obsoletas** (`zkex`, `zkforge`, addons legacy) antes de cambiar todo el framework.
4. **Migrar API y ZUL** con cambios masivos controlados.
5. **Cerrar brechas visuales/tema**.
6. **Endurecer pruebas funcionales y regresión**.
7. **Rollout por feature flags / canary**.

## 3) Inventario obligatorio antes de tocar código

### 3.1 Inventario de jars actuales

- Listar jars ZK y addons en `zkwebui/WEB-INF/lib`.
- Registrar versión de cada jar desde `META-INF/MANIFEST.MF`.
- Resultado esperado: matriz `jar -> versión -> reemplazo objetivo`.

### 3.2 Inventario de uso en código

- Buscar imports `org.zkoss.*` en `zkwebui/WEB-INF/src`.
- Separar por categorías:
  - Core (`zk.ui`, `zul`)
  - Legacy (`zkex`, `zhtml`)
  - Addons (`zkforge`, `timelinez`, `gmapsz`, `fckez`)
- Cuantificar clases impactadas y priorizar por criticidad funcional.

### 3.3 Inventario de uso en vistas/config

- Auditar `*.zul`, `*.zhtml`, `*.dsp` y configuración:
  - `zkwebui/WEB-INF/web.xml`
  - `zkwebui/WEB-INF/zk.xml`
  - `zkwebui/theme.zs`
- Identificar tags/componentes descontinuados y propiedades de tema obsoletas.

## 4) Diseño técnico de la migración

### 4.1 Gestión de dependencias (recomendado)

Mover ZK desde jars versionados manualmente en `WEB-INF/lib` a dependencias gestionadas (Maven/Gradle), y dejar `WEB-INF/lib` solo para casos excepcionales.

Opciones:

- **A corto plazo**: seguir con Ant, pero reemplazar jars en bloque + script de verificación de versiones.
- **A medio plazo (ideal)**: declarar dependencias explícitas para `zkwebui` y dejar de acoplar módulos por `fileTree('../zkwebui/WEB-INF/lib')`.

### 4.2 Compatibilidad de Java y servlet container

Validar que la versión objetivo de ZK sea compatible con:

- Java usado por build/runtime (en este repo se compila con target 11 para `zkwebui`).
- Servlet API declarada/servidor de aplicaciones.

### 4.3 Reemplazo de APIs legacy

- `org.zkoss.zkex.*`: migrar a alternativas modernas del propio ZK (`zul/layout` y equivalentes actuales).
- `org.zkforge.keylistener`: evaluar reemplazo por listeners nativos de teclado (`onOK`, `onCtrlKey`, eventos cliente).
- `fckez`: evaluar migración a editor soportado en la versión objetivo.
- `timelinez/gmapsz/zml`: confirmar si siguen disponibles; si no, reemplazar funcionalidades.

## 5) Plan de implementación detallado

## Fase A — Preparación

1. Crear branch de migración ZK.
2. Congelar cambios de UI paralelos durante la migración.
3. Añadir checklist y matriz de compatibilidad en `docs/`.

## Fase B — Dependencias y arranque

1. Sustituir jars ZK base por versión objetivo en entorno de prueba.
2. Alinear `web.xml` y `zk.xml` según requerimientos de esa versión.
3. Arrancar `webui` y corregir errores de classloading iniciales.

## Fase C — Refactor de código Java

1. Corregir imports/paquetes renombrados.
2. Ajustar firmas/API rotas (renderers, events, desktop/session handling).
3. Refactorizar componentes custom que extienden clases legacy.

## Fase D — Refactor de vistas ZUL/tema

1. Corregir namespaces, tags y atributos deprecados.
2. Revisar comportamiento de databinding/eventos.
3. Adaptar CSS/tema (impacto visual es esperado).

## Fase E — Addons y módulos satélite

1. Validar módulos que toman jars desde `zkwebui/WEB-INF/lib`.
2. Probar funcionalidad por módulo (POS, Manufacturing, etc.).
3. Corregir empaquetado en builds Ant/Gradle relacionados.

## Fase F — Testing y hardening

1. Smoke tests críticos:
   - Login/logout
   - Abrir ventana estándar
   - CRUD básico
   - Búsqueda/filtros
   - Adjuntos
   - Reporte/impresión
2. Pruebas de regresión funcional por rol.
3. Revisar performance (tiempo de carga inicial, eventos AU).
4. Revisar logs y memory footprint.

## Fase G — Despliegue controlado

1. Deploy canary con usuarios internos.
2. Monitorear errores JS, errores de servidor, métricas de uso.
3. Plan de rollback documentado (artefacto anterior + DB sin cambios destructivos).

## 6) Riesgos reales que debes asumir

- **Riesgo alto**: uso intensivo de `zkex` y addons legacy.
- **Riesgo medio/alto**: cambios visuales por tema/CSS.
- **Riesgo medio**: módulos externos que asumen jars concretos en `WEB-INF/lib`.
- **Riesgo medio**: dependencia en componentes custom de `org.zkoss.zkmax.*`.

## 7) Definición de “hecho” (DoD)

Se considera completada la migración cuando:

1. No quedan referencias a paquetes descontinuados en código crítico.
2. El WAR arranca sin errores de clase/configuración.
3. Flujos funcionales críticos pasan QA.
4. No hay degradación severa de rendimiento.
5. Está documentado rollback y procedimiento operativo.

## 8) Checklist ejecutable (resumen corto)

- [ ] Definir versión objetivo y matriz Java/Tomcat.
- [ ] Inventario de jars y APIs usadas.
- [ ] Migrar dependencias ZK base.
- [ ] Corregir `web.xml` / `zk.xml`.
- [ ] Refactor Java (imports/APIs).
- [ ] Refactor ZUL/tema.
- [ ] Sustituir addons legacy.
- [ ] Validar módulos satélite.
- [ ] Ejecutar smoke + regresión + performance.
- [ ] Despliegue canary + rollback validado.

## 9) Comandos útiles para ejecutar durante la migración

```bash
# 1) Ver jars ZK actuales
find zkwebui/WEB-INF/lib -maxdepth 1 -type f -name '*.jar' | sort

# 2) Ver versión de un jar
unzip -p zkwebui/WEB-INF/lib/zk.jar META-INF/MANIFEST.MF | egrep 'Implementation-Version|Specification-Version'

# 3) Ver uso de APIs ZK en Java
rg -n "import org\.zkoss|import org\.zkforge" zkwebui/WEB-INF/src

# 4) Ver referencias legacy de alto riesgo
rg -n "org\.zkoss\.zkex|org\.zkforge|timelinez|gmapsz|fckez|zml" zkwebui/WEB-INF/src zkwebui

# 5) Build de zkwebui
ant -f zkwebui/build.xml war
```

---

Si deseas, en el siguiente paso te preparo una **ruta de migración concreta con versión objetivo propuesta**, lista de reemplazos API por API, y una **PR inicial mínima** para arrancar la Fase A/B.

## 10) Plan de ejecución propuesto (PRs concretas)

> Objetivo: dividir el upgrade en PRs pequeñas, auditables y con rollback simple.

### PR-1 — Inventario + observabilidad base (sin cambio funcional)

**Alcance**
- Agregar scripts/reportes para inventario automático de:
  - jars en `zkwebui/WEB-INF/lib`
  - imports `org.zkoss.*` / `org.zkforge.*`
  - uso de `zkex`, `zhtml`, addons (`timelinez`, `gmapsz`, `fckez`, `zml`, `keylistener`)
- Publicar reporte en `docs/zk-inventory.md`.
- Documentar baseline de tiempos de arranque y errores en logs.

**Criterio de aceptación**
- Existe reporte versionado con conteos por categoría.
- No cambia comportamiento del `webui`.

---

### PR-2 — Normalización de dependencias ZK (preparación de plataforma)

**Alcance**
- Definir mecanismo único de dependencias ZK (ideal: Gradle/Maven para `zkwebui`; temporal: catálogo de jars validado).
- Eliminar duplicidades/variantes no usadas en `WEB-INF/lib`.
- Agregar validación de versiones en CI (script que falla si hay mezcla de versiones ZK).

**Criterio de aceptación**
- Build de `zkwebui` reproducible con set de dependencias explícito.
- CI detecta desalineación de versión automáticamente.

**Entregables sugeridos**
- `scripts/zk/check_zk_versions.sh` para validar que jars core de ZK estén alineados a una única versión.
- `.github/workflows/zk-version-guard.yml` para ejecutar validación en PR/push.

---

### PR-3 — Migración de configuración web/zk (bootstrap)

**Alcance**
- Actualizar `zkwebui/WEB-INF/web.xml` y `zkwebui/WEB-INF/zk.xml` a configuración compatible con versión objetivo.
- Corregir listeners/servlets/params deprecados.

**Criterio de aceptación**
- `webui` arranca y carga login sin errores de classloading/configuración.
- Smoke mínimo de navegación inicial pasa.

**Entregables sugeridos**
- `scripts/zk/check_zk_bootstrap_config.sh` para validar estructura mínima de `web.xml` y `zk.xml`.
- Actualización de descriptor `web.xml` a Servlet 3.1 y saneamiento de `automatic-timeout` en `zk.xml`.

---

### PR-4 — Eliminación progresiva de `zkex` (layout/components)

**Alcance**
- Reemplazar imports y usos `org.zkoss.zkex.*` por componentes modernos equivalentes.
- Atacar primero componentes compartidos (wrappers/layout base), luego paneles más usados.

**Criterio de aceptación**
- Reducción medible del uso de `zkex` (objetivo por PR: >=30% de referencias).
- Pantallas críticas mantienen funcionalidad y layout aceptable.

**Entregables sugeridos**
- Wrappers de transición en `org.adempiere.webui.component` para `Center/North/South/East/West`.
- Reemplazo masivo de imports `org.zkoss.zkex.zul.*` por wrappers de ADempiere en `org/adempiere/webui/**`.

---

### PR-5 — Reemplazo de addons legacy (`keylistener`, `fckez`, etc.)

**Alcance**
- Sustituir `org.zkforge.keylistener` por eventos nativos/estrategia soportada.
- Evaluar y migrar editor legacy (`fckez`) a componente vigente.
- Definir destino de `timelinez`, `gmapsz`, `zml` (migrar o retirar si no tienen uso real).

**Criterio de aceptación**
- No quedan dependencias bloqueantes de addons obsoletos para versión objetivo.
- Casos de uso de teclado/editor siguen operativos.

**Entregables sugeridos**
- Wrappers de transición para `Keylistener` y `FCKeditor` en `org.adempiere.webui.component`.
- Reemplazo de imports `org.zkforge.*` por wrappers de ADempiere en `org/adempiere/webui/**`.

---

### PR-6 — Refactor ZUL + tema/CSS

**Alcance**
- Corregir namespaces/atributos/tags ZUL deprecados.
- Ajustar `theme.zs` y css/img asociados por cambios de rendering.
- Limpiar warnings JS/CSS visibles en consola.

**Criterio de aceptación**
- Smoke visual de ventanas principales aprobado por QA.
- Sin errores JS críticos en flujos core.

**Entregables sugeridos**
- `scripts/zk/check_zul_theme_refs.sh` para auditar referencias de assets y uso de ZUL.
- Baseline de auditoría en `docs/zk-theme-audit.md` para controlar drift en PRs.

---

### PR-7 — Módulos satélite y empaquetado final

**Alcance**
- Alinear módulos que dependen de `../zkwebui/WEB-INF/lib` (ej. POS/Manufacturing y otros).
- Ajustar tareas Ant/Gradle de empaquetado y publicación de artefactos ZK relacionados.

**Criterio de aceptación**
- Build completo del repo y empaquetado de módulos satélite exitoso.
- No hay referencias rotas a jars legacy.

**Entregables sugeridos**
- Catálogo compartido `gradle/zk-legacy-libs.gradle` para módulos satélite.
- Validación automatizada con `scripts/zk/check_satellite_modules.sh` y CI.

---

### PR-8 — Hardening, regresión y rollout

**Alcance**
- Suite de smoke/regresión formalizada (checklist automatizable).
- Medición comparativa de performance vs baseline.
- Procedimiento de canary + rollback documentado y ensayado.

**Criterio de aceptación**
- QA funcional aprobado para flujos críticos.
- Plan de despliegue productivo firmado por equipo funcional/técnico.

**Entregables sugeridos**
- `scripts/zk/run_guard_suite.sh` para ejecutar suite integral de validación pre/post deploy.
- `docs/zk-rollout-checklist.md` con pasos operativos de canary y rollback.

---

## 11) Orden recomendado y duración estimada

- **Semana 1:** PR-1, PR-2
- **Semana 2:** PR-3, PR-4 (primera ola)
- **Semana 3:** PR-4 (segunda ola), PR-5
- **Semana 4:** PR-6
- **Semana 5:** PR-7
- **Semana 6:** PR-8 + salida canary

> Nota: si aparece bloqueo fuerte en addons legacy, dividir PR-5 en sub-PRs por addon.
