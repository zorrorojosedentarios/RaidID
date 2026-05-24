# RaidID Tracker v1.0

**RaidID Tracker** es un addon ligero de rastreo de IDs de estancias y bloqueos de banda para **World of Warcraft 3.3.5a (WotLK)**, optimizado para el servidor **NaerZone**. Permite comprobar en tiempo real, desde cualquier personaje, qué personajes de tu cuenta tienen IDs de banda activas, con detalles del tiempo de reinicio, tamaño, dificultad y la ID específica.

---

## 🚀 Funcionalidades y Módulos

| Característica / Módulo | Descripción |
|---|---|
| **Rastreo Multi-Personaje** | Guarda el historial de IDs de todos los personajes de tu cuenta en una base de datos global unificada. |
| **Detección de Dificultad** | Muestra el tamaño de la banda (10/25) y un indicador visual de la dificultad: Normal `[N]` (en verde) o Heroico `[H]` (en rojo). |
| **Tiempo Dinámico** | Calcula y formatea en tiempo real el tiempo restante para el reinicio (ej: `5d 12h` o `45m`). |
| **Limpieza Inteligente** | Elimina automáticamente del historial los registros de bloqueos expirados para mantener la base de datos optimizada y limpia. |
| **Interfaz Integrada** | Ventana compacta, movible y con barra de desplazamiento para ver todos tus personajes cómodamente de un vistazo. |
| **Base de Datos Sincronizada** | Sincroniza la información en variables persistentes (`SavedVariables: RaidIDLibDB`) para no perder datos al cerrar el juego. |

> **Actualización Automática**: El addon actualiza la información de tus IDs al iniciar sesión, matar a un jefe, entrar al mundo o al presionar el botón manual de refresco.

---

## 🛠️ Instalación

1. Copia la carpeta `RaidId` en `World of Warcraft\Interface\Addons\`
2. Asegúrate de que la carpeta se llame exactamente `RaidId`
3. Actívalo en el menú de Addons al iniciar el juego o recarga la interfaz con `/reload`

---

## 📖 Uso Rápido

- **Comando `/raidid`**: Abre o cierra la ventana principal del rastreador.
- **Comando `/raidid reset`**: Borra todos los datos de personajes y IDs guardados en la cuenta.
- **Botón Actualizar**: Refresca manualmente la información y las IDs del personaje actual de forma instantánea.
- **Ventana Movible**: Arrastra desde el título superior para posicionar la ventana libremente en tu pantalla.

---

## 💻 Desarrollo

Desarrollado por **Zorrorojo/Miabuelita** hermandad **<Sedentarios>** para el servidor NaerZone.
