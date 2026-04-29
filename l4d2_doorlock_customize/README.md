# [L4d2] Doorlock [Personalizable] (v. 2.4)

Basado en el trabajo de alasfourom: [L4D2 Saferoom Locker](https://forums.alliedmods.net/showpost.php?p=2788193&postcount=38)

---

## DESCRIPCIÓN:
Bloquea todos los refugios iniciales durante un periodo de tiempo.

PROPIEDADES:
- Otorga Inmunidad al daño y Munición infinita durante el conteo.
- Muestra un Brillo para las puertas antes y después de abrirlas.
- Soporte para agregar bloqueos, músicas y efectos de sonido, para todas las campañas y capítulos oficiales  y no oficiales (Workshop) del juego.
- Fácil de configurar.
- etc...

---

## COMANDOS:

```c
 •sm_lock -> Bloquea el refugio de manera forzada (Bandera Requerida: z)
 •sm_unlock -> Desbloquea el refugio de manera forzada (Bandera Requerida: z)
```

---

## VISTA PREVIA:
<img width="1366" height="768" alt="left4dead2_V5JYEK04LC" src="https://github.com/user-attachments/assets/218563e8-bf2c-4a21-bd55-167b3303083e" />
<img width="1366" height="768" alt="left4dead2_ovAyZrd1vQ" src="https://github.com/user-attachments/assets/5fbc6397-ff93-4119-837f-396573a1ae1b" />
<img width="1366" height="768" alt="left4dead2_LjDEB6c19F" src="https://github.com/user-attachments/assets/5886f630-b56d-4043-86ff-a39814d14f3b" />
<img width="1366" height="768" alt="left4dead2_d12U2CHKNL" src="https://github.com/user-attachments/assets/19685c75-4f1d-48b9-aefe-29958900850f" />

---

## REQUISITOS:
Para que el plugin funcione correctamente, necesitas tener instalado el siguiente archivo:
* **[[L4D & L4D2] Left 4 DHooks Direct](https://forums.alliedmods.net/showthread.php?t=321696)**

---

## CONVARS:
El archivo de configuración se genera automáticamente en `cfg/sourcemod/l4d2_doorlock.cfg`.

<details>
<summary>Ver la lista de ConVars y configuración</summary>

```c
// ConVars for plugin "l4d2_doorlock_customize.smx"


// 0 = No Cheats, 1 = No Damage, 2 = Infinite Ammo, 3 = All
// -
// Default: "3"
// Minimum: "0.000000"
// Maximum: "3.000000"
l4d2_doorlock_cheats_enable "3"

// How Long You Want To Lock The Safe Area (In Seconds)
// -
// Default: "45"
l4d2_doorlock_countdown "45"

// 0 = No Custom Music, 1 = Only Custom Music
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d2_doorlock_custom_music_enable "0"

// At what second do you want the music to start?
// -
// Default: "40"
l4d2_doorlock_custom_music_started "40"

// Set First Chapters Mode (0=Disable First Scenario Mode, 1 = Freeze Survivors)
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d2_doorlock_first_scenario_mode "0"

// Add The Modes You Want To Enable This Plugin In It
// -
// Default: "versus,coop"
l4d2_doorlock_game_mode "versus,coop"

// 0 = No Glow, 1 = Glow Saferoom Doors Only, 2 = Glow Barricades Only, 3 = Glow All Locks
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "3.000000"
l4d2_doorlock_glow_enable "1"

// Set The Glow Range For Saferoom Doors
// -
// Default: "1500"
l4d2_doorlock_glow_range "1500"

// Display Hint Texts To Connected Players Notiying Them That Loaders Are Connecting (0 = Disable, 1 = Enable)
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d2_doorlock_loaders_message "1"

// How Long Plugin Waits For Loaders Before Giving Up On Them (In Seconds)
// -
// Default: "60"
l4d2_doorlock_loaders_time "60"

// Set Saferoom Lock Glow Color, (0-255) Separated By Spaces.
// -
// Default: "255 0 0"
l4d2_doorlock_lock_glow_color "255 0 0"

// 0 = No Locks, 1 = Lock Saferooms
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d2_doorlock_plugin_enable "1"

// Set Saferoom Unlock Glow Color, (0-255) Separated By Spaces.
// -
// Default: "0 255 0"
l4d2_doorlock_unlock_glow_color "0 255 0"

```
</details>

---

## REGISTRO DE CAMBIOS:

<details>
<summary>Ver el registro de cambios</summary>

* ### v2.4 (22-ABRIL-2026)
    * Se corrigió el bug de curación durante el bloqueo, informado por cumball_007 (Apoyado con IA).
    * Se creó un nuevo CFG para agregar Modelos, con sus Orígenes y Ángulos (Apoyado con IA, gracias a [L4D / L4D2] Anti-Rush System (Reloaded) de cravenge).
    * El nuevo CFG incluye a los antiguos CFG.
    * Se agregaron nuevos ConVars de la versión Ready UP.

* ### v2.2 & v2.3 (18-ABRIL-2026)
    * Se intentó agregar la función de teletransportación exclusivamente en las primeras campañas, sin éxito.
    * Cambios menores.

* ### v2.1 (15-MARZO-2026)
    * Se corrigió un problema en la traducción, informado por cumball_007.

* ### v2.0 (12-MARZO-2026)
    * Se corrigió el problema en el que las rutas dentro del archivo 'l4d2_doorlock_countdown.cfg' no funcionaban (Hecho con IA).
  
* ### v1.9 (17-ENERO-2026)
    * Se corrigió el timer "Timer_StartCountdownToUnlock".

* ### v1.8 (17-ENERO-2026)
    * Se corrigió el ConVar 'l4d2_doorlock_loaders_time' (Gracias a alasfourom por Door Lock Ready Up Mode).
    * Se agregaron nuevos ConVars de la versión Ready UP.
    * Se incluyó el soporte a música y efectos de sonido (Gracias a Silver por Lift Music).
    * Se editó el método de agrupación para más sonidos de Lift Music (Hecho con IA)
    * Se cambió la emisión de sonido de 'EmitSoundToClient' por 'playgamesound'.
    * Se corrigió el problema de vulnerabilidad con armas.
    * Se corrigió el problema de invencibilidad.
    * Se corrigió el problema de las barricadas invisibles.
</details>

---

## REFERENCIAS:
* [[L4D2] Door Lock With Ready Up Mode - v2.8 | Sep 11, 2024](https://forums.alliedmods.net/showthread.php?t=341045)
* [[L4D & L4D2] Lift Music (1.5) [10-May-2020]](https://forums.alliedmods.net/showthread.php?t=157267)
* [[L4D / L4D2] Anti-Rush System (Reloaded) | 1.82 [Final] : Jan. 30, 2019 |](https://forums.alliedmods.net/showthread.php?p=2409563)

---

## RECOMENDADOS:
* [[L4D & L4D2] Survivor Shove (1.17) [04-Jan-2025]](https://forums.alliedmods.net/showthread.php?t=318694)
