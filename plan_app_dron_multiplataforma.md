# Plan para lanzar una app movil de pronostico operativo para drones

## 1. Lectura de la competencia

Las capturas de `competencia/` muestran una app tipo **UAV Forecast**, orientada a responder una pregunta central para el piloto: **"puedo volar ahora o en esta ventana horaria?"**. La aplicacion no se presenta como un clima generalista, sino como una herramienta de decision operacional para vuelos con drones.

### Funcionalidades visibles

1. **Estado rapido de vuelo**
   - Indicador principal tipo semaforo: `Good To Fly`.
   - Criterio visual por colores: verde cuando las condiciones cumplen, rojo/marron cuando hay restricciones.
   - Resumen actual con tarjetas de clima, sol, temperatura, viento, rafagas, direccion del viento, precipitacion, nubosidad, visibilidad, satelites y Kp.

2. **Pronostico por hora**
   - Tabla horaria agrupada por dia.
   - Columnas de rafagas, temperatura, probabilidad de precipitacion, precipitacion, cobertura de nubes, visibilidad, satelites visibles, Kp, satelites estimados bloqueados y decision final `Good To Fly?`.
   - Selector inferior por dias y barra temporal para revisar ventanas futuras.

3. **Perfil vertical del viento**
   - Viento, rafagas y temperatura por altitud AGL: suelo, 25 m, 50 m, 75 m, 100 m, 120 m, 150 m, 200 m, 300 m, 500 m, 1000 m, 1500 m, 2000 m, 3000 m, 5000 m.
   - Datos complementarios: base de nubes, altitud donde se excede el viento maximo, elevacion, altitud de densidad, QNH y QFE.

4. **Graficos**
   - Rangos de 1, 3, 7 y 15 dias.
   - Graficos de sol/luna, aptitud para volar, viento y rafagas, temperatura y punto de rocio, probabilidad de lluvia, precipitacion y nubosidad.
   - Lineas de umbral para interpretar rapidamente si una variable se acerca al limite.

5. **Mapa operativo**
   - Buscador de ubicacion.
   - Ubicacion actual y ubicaciones favoritas.
   - Modos de mapa: ruta, satelite, hibrido y terreno.
   - Capas de zonas restringidas/no-fly, NOTAM/TFR, parques o areas especiales.
   - Guia de rango alrededor del punto de vuelo.

6. **Configuracion**
   - Ajustes de pronostico.
   - Umbrales personalizados.
   - Ajustes de zonas no-fly.
   - Notificaciones.
   - Unidades.
   - Idioma.
   - Tema claro, oscuro, automatico o sistema.
   - Paleta para daltonismo.
   - Reset de configuracion.
   - Cuenta y suscripcion.

7. **Ayuda y educacion**
   - FAQ integrada.
   - Explica por que una condicion puede marcarse como no apta.
   - Indica que los umbrales pueden adaptarse al equipo, estilo de vuelo y preferencias.
   - Aclara diferencias entre ubicacion actual, ubicacion fija y tiempo de pronostico.

8. **Modelo freemium**
   - Edicion gratuita limitada.
   - Suscripciones por nivel: hobby, profesional y elite.
   - Diferenciacion por dias de pronostico horario, altitud maxima del perfil de viento, cantidad de ubicaciones favoritas, graficos, base de nubes y altitud de viento maximo.
   - Prueba gratis de 7 dias.
   - Uso en mas de un dispositivo y web.

## 2. Oportunidad de producto

La oportunidad no esta en copiar una app de clima, sino en crear una **cabina de planificacion de vuelo para drones** que combine clima, restricciones, checklist y recomendacion automatica de ventanas seguras.

### Posicionamiento propuesto

**Una app en espanol para pilotos de drones que recomienda cuando, donde y con que riesgo volar, usando clima hiperlocal, mapas operativos, perfiles por dron y alertas inteligentes.**

### Usuario objetivo

- Pilotos recreativos que necesitan una respuesta rapida antes de despegar.
- Pilotos profesionales que hacen fotografia, video, inspecciones, agricultura, seguridad, obras o relevamientos.
- Empresas con varios pilotos que necesitan criterios homogeneos de seguridad.
- Instructores o escuelas que quieren ensenar decision operacional con datos claros.

## 3. Valor agregado propio

La competencia resuelve bien el "good to fly" climatico. El diferencial recomendado es avanzar hacia **planificacion de mision**.

### Diferencial central: Asistente de ventana de vuelo

La app no solo muestra datos: propone las mejores ventanas para volar.

Ejemplo:

> "Mejor ventana: Sabado 08:20 a 10:10. Viento bajo a 120 m, buena visibilidad, baja precipitacion, Kp normal. Riesgo medio por cercania a zona controlada."

### Funciones diferenciales

1. **Perfiles por dron y tipo de mision**
   - DJI Mini / Air / Mavic / Matrice u otros perfiles manuales.
   - Misiones: fotografia, video, inspeccion, mapeo, vuelo nocturno, costa/montana/campo.
   - Umbrales distintos por perfil: viento maximo, rafagas, visibilidad minima, lluvia, nubosidad, altura objetivo.

2. **Checklist pre-vuelo integrado**
   - Bateria, helices, firmware, sensores, permisos, RTH, zona de despegue, clima, viento, restricciones.
   - Resultado exportable como registro operativo.

3. **Reporte compartible**
   - PDF o imagen con ubicacion, hora, condiciones, mapa, riesgos y checklist.
   - Util para clientes, seguros, equipos internos o auditoria.

4. **Alertas inteligentes**
   - "Avisame cuando esta ubicacion tenga una ventana apta de al menos 45 minutos".
   - "Avisame si manana entre 08:00 y 12:00 baja el viento".
   - "Avisame si aparece una restriccion nueva cerca de mi zona favorita".

5. **Enfoque regional**
   - Espanol primero.
   - Unidades metricas por defecto.
   - Capas y textos pensados para Argentina y LATAM, con fuentes oficiales a validar por pais.

## 4. Recomendacion tecnica

### Enfoque recomendado

Usar **Flutter** para Android e iOS con una sola base de codigo.

Flutter encaja bien porque:

- Permite UI consistente y de alto rendimiento en ambas plataformas.
- Tiene buen soporte para mapas, graficos, notificaciones, compras in-app y ubicacion.
- Reduce duplicacion frente a mantener Swift/iOS y Kotlin/Android por separado.
- Facilita lanzar una version web/PWA mas adelante si el modelo comercial lo justifica.

### Como evitar reescribir para cada plataforma

La regla de arquitectura debe ser: **la logica importante vive una sola vez**.

Separacion recomendada:

- **Compartido en Flutter**
  - Pantallas.
  - Componentes visuales.
  - Navegacion.
  - Estado de la app.
  - Validacion de umbrales.
  - Calculo de `Apto / Precaucion / No apto`.
  - Perfiles de dron.
  - Perfiles de mision.
  - Favoritos.
  - Checklist.
  - Graficos.

- **Compartido en backend**
  - Agregacion de datos de clima.
  - Cache.
  - Normalizacion de proveedores.
  - Reglas de alertas.
  - Jobs programados.
  - Datos de zonas geograficas.
  - Webhooks de suscripcion.

- **Nativo solo donde haga falta**
  - Compras in-app.
  - Permisos de ubicacion.
  - Push notifications.
  - Integracion fina con mapas si el SDK lo exige.
  - Configuraciones especificas de App Store y Google Play.

Estructura sugerida dentro de Flutter:

```text
lib/
  app/
  core/
  design_system/
  features/
    conditions/
    forecast/
    wind_profile/
    charts/
    map/
    alerts/
    checklist/
    settings/
    subscription/
  domain/
    entities/
    services/
    rules/
  data/
    repositories/
    dto/
    api/
```

Con esta organizacion, Android e iOS consumen el mismo codigo de producto. Las diferencias se resuelven en configuracion, permisos, builds y SDKs puntuales, no duplicando pantallas ni reglas.

### Arquitectura propuesta

```text
Flutter App
  - Features
    - Conditions
    - Forecast
    - Wind Profile
    - Charts
    - Map
    - Alerts
    - Checklist
    - Settings
    - Subscription
  - Domain
    - FlightReadinessScore
    - WeatherThresholds
    - DroneProfile
    - MissionProfile
    - FlightWindowRecommendation
  - Data
    - WeatherRepository
    - GeoZoneRepository
    - SubscriptionRepository
    - UserRepository

Backend API
  - Auth
  - Weather aggregation
  - Forecast caching
  - Geo/no-fly layers
  - Favorite locations
  - Alert jobs
  - Subscription webhooks

External providers
  - Weather forecast
  - Wind by altitude
  - Sunrise/sunset
  - Geomagnetic/Kp
  - Maps/tiles
  - NOTAM/no-fly sources
  - Push notifications
  - In-app purchases
```

### Stack sugerido

- **App movil:** Flutter.
- **Estado:** Riverpod o Bloc.
- **Graficos:** `fl_chart` o libreria equivalente.
- **Mapas:** Google Maps, Mapbox o MapLibre segun costos/licencias.
- **Compras in-app:** RevenueCat o implementacion directa de StoreKit + Google Play Billing.
- **Auth:** Firebase Auth, Supabase Auth o backend propio.
- **Push notifications:** Firebase Cloud Messaging.
- **Backend:** Laravel, NestJS o FastAPI. Elegir segun el equipo existente.
- **Base de datos:** PostgreSQL con PostGIS para zonas geograficas.
- **Cache:** Redis para pronosticos y capas consultadas con frecuencia.
- **Jobs:** colas para alertas, refresco de pronosticos y notificaciones.

## 5. Modulos de la app

### 5.1 Home / Conditions

Pantalla principal con decision inmediata:

- Estado `Apto para volar`, `Precaucion` o `No apto`.
- Tarjetas de:
  - Clima.
  - Temperatura y punto de rocio.
  - Viento.
  - Rafagas.
  - Direccion del viento.
  - Probabilidad de lluvia.
  - Nubosidad.
  - Base de nubes.
  - Visibilidad.
  - Kp.
  - Satelites/GNSS si se consigue una fuente confiable.
- Explicacion breve de que variable esta bloqueando el vuelo.

### 5.2 Forecast

- Pronostico horario.
- Agrupacion por dia.
- Columna final de decision operacional.
- Filtro por altura objetivo: 50 m, 100 m, 120 m, 150 m o personalizada.
- Tap en una hora para ver detalle y checklist sugerido.

### 5.3 Wind Profile

- Tabla de viento/rafagas/temperatura por altura.
- Alturas frecuentes para drones: suelo, 25 m, 50 m, 75 m, 100 m, 120 m, 150 m.
- Alturas extendidas para planes pagos o profesionales.
- Deteccion de altura donde se supera el limite del dron/perfil.

### 5.4 Charts

- Graficos por 24 h, 3 dias, 7 dias y 15 dias.
- Lineas de umbral personalizadas.
- Capas minimas:
  - Viento y rafagas.
  - Temperatura/punto de rocio.
  - Lluvia.
  - Nubosidad.
  - Visibilidad.
  - Score de aptitud.

### 5.5 Map

- Busqueda de ubicacion.
- Punto actual y favoritos.
- Radio de vuelo configurable.
- Capas:
  - Zonas restringidas.
  - Aeropuertos/aerodromos.
  - Helipuertos.
  - Areas sensibles.
  - NOTAM o equivalentes, si la fuente oficial lo permite.
  - Terreno.
- Aviso claro de que la app ayuda a planificar pero el piloto debe validar normativa vigente.

### 5.6 Alerts

- Alertas por ubicacion favorita.
- Alertas por ventana apta.
- Alertas por cambios de viento.
- Alertas por lluvia.
- Alertas por restricciones cercanas.

### 5.7 Checklist

- Checklist configurable por tipo de vuelo.
- Estado pre-vuelo guardable.
- Exportacion de reporte.

### 5.8 Settings

- Umbrales por perfil.
- Unidades.
- Idioma.
- Tema.
- Accesibilidad.
- Notificaciones.
- Cuenta.
- Suscripcion.

## 6. MVP recomendado

### MVP 1: version lanzable

Debe incluir:

- Ubicacion actual y busqueda de ubicaciones.
- Condicion actual `Apto / Precaucion / No apto`.
- Pronostico horario 48 h o 7 dias segun proveedor/costo.
- Viento y rafagas.
- Temperatura, lluvia, nubosidad, visibilidad.
- Perfil de viento basico hasta 120 m o 150 m.
- Umbrales configurables.
- Favoritos.
- Mapa con radio de vuelo.
- Alertas basicas.
- Checklist pre-vuelo simple.
- Cuenta de usuario.
- Suscripcion o paywall preparado, aunque inicialmente se lance con trial.

### Fuera del MVP

- Comunidad de pilotos.
- Integracion con logs DJI.
- Flotas empresariales.
- Web app completa.
- Reportes avanzados.
- Analitica historica.
- Multipais con fuentes oficiales completas.

## 7. Roadmap por fases

### Fase 0 - Validacion y definicion (1 a 2 semanas)

- Definir pais inicial y fuentes de datos.
- Definir 3 perfiles de usuario.
- Definir variables del score de vuelo.
- Disenar wireframes de las 5 pantallas clave.
- Validar costos de APIs de clima/mapas.

### Fase 1 - Prototipo funcional (3 a 4 semanas)

- Flutter app con navegacion base.
- Home con `Apto / Precaucion / No apto`.
- Pronostico horario.
- Umbrales locales.
- Mapa con ubicacion y favoritos.
- Datos mock o un solo proveedor real.

### Fase 2 - MVP beta (6 a 8 semanas)

- Backend con cache de pronosticos.
- Auth.
- Favoritos sincronizados.
- Perfil de dron y mision.
- Perfil de viento por altura.
- Graficos basicos.
- Alertas por ubicacion favorita.
- Checklist.
- Crash reporting y analytics.

### Fase 3 - Monetizacion y release cerrado (3 a 4 semanas)

- Paywall.
- Compras in-app.
- Trial.
- Limites por plan.
- TestFlight y Google Play Internal Testing.
- Revision legal de disclaimers, privacidad y terminos.

### Fase 4 - Lanzamiento publico (2 a 3 semanas)

- App Store y Google Play.
- Landing simple.
- Soporte y FAQ.
- Campana inicial con pilotos beta.
- Seguimiento de conversion, retencion y errores.

## 8. Modelo de suscripcion sugerido

### Free

- Condicion actual.
- Pronostico limitado.
- 1 o 2 favoritos.
- Umbrales basicos.
- Mapa simple.

### Pro

- Pronostico extendido.
- Favoritos multiples.
- Perfil de viento completo para drones.
- Alertas inteligentes.
- Graficos.
- Checklist exportable.

### Team / Empresa

- Multiples pilotos.
- Ubicaciones compartidas.
- Reportes de vuelo/pre-vuelo.
- Politicas de umbrales por empresa.
- Historial de decisiones.
- Soporte prioritario.

## 9. Algoritmo de aptitud para volar

El score debe ser explicable. No alcanza con decir "no apto"; hay que mostrar por que.

Variables iniciales:

- Viento sostenido.
- Rafagas.
- Lluvia.
- Probabilidad de lluvia.
- Visibilidad.
- Nubosidad/base de nubes.
- Temperatura extrema.
- Kp/actividad geomagnetica.
- Cercania a zonas restringidas.
- Restricciones temporales.
- Perfil del dron.
- Tipo de mision.

Salida:

- `Apto`
- `Precaucion`
- `No apto`

Cada salida debe incluir:

- Motivo principal.
- Variables que superan umbral.
- Recomendacion de proxima ventana mejor.

## 10. Datos y fuentes a resolver

Antes de desarrollo completo hay que confirmar:

- Proveedor de clima con buen soporte horario e hiperlocal.
- Proveedor de viento por altitud.
- Fuente de Kp/geomagnetismo.
- Fuente de salida/puesta de sol.
- Fuente de mapas y costos.
- Fuente oficial o confiable de zonas restringidas por pais.
- Terminos de uso de cada proveedor.
- Cache permitido por licencia.

## 11. Riesgos principales

1. **Precision y responsabilidad**
   - La app ayuda a decidir, pero no debe prometer autorizacion legal ni seguridad absoluta.

2. **Costo de APIs**
   - Clima hiperlocal, mapas y geocoding pueden escalar rapido.

3. **Fuentes regulatorias**
   - Las zonas no-fly y NOTAM dependen del pais y pueden requerir integraciones oficiales.

4. **Suscripciones**
   - Apple y Google requieren implementacion correcta de compras, restauracion y cancelacion.

5. **Confianza del usuario**
   - Si el score no explica el motivo, el piloto no lo va a adoptar.

## 12. Metricas de exito

- Usuarios que consultan la app antes de volar.
- Favoritos creados por usuario.
- Alertas configuradas.
- Conversion de trial a pago.
- Retencion a 7 y 30 dias.
- Cantidad de ventanas recomendadas abiertas.
- Reportes/checklists exportados.
- Errores de pronostico o quejas por datos incorrectos.

## 13. Proxima accion recomendada

Arrancar con un **prototipo Flutter** de 5 pantallas:

1. Conditions.
2. Forecast.
3. Wind Profile.
4. Map.
5. Settings.

Y agregar desde el primer prototipo el diferencial:

> **"Mejores ventanas para volar" segun dron, mision y umbrales configurables.**

Ese diferencial permite competir sin depender solo de tener los mismos datos meteorologicos que la app analizada.
