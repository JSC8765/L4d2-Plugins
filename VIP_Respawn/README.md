# [VIP] Respawn CMD (v. 1.6.1)

Publicación Original y Actual: R1KO - [[VIP] Respawn 1.6](https://hlmod.net/resources/vip-respawn.221/)

---

## DESCRIPCIÓN:
Si moriste, escribe !respawn para volver a jugar.

PROPIEDADES:
- Soporte para músicas y efectos de sonido (hasta 32 rutas)
- Eliges el número de reapariciones
- Configuración Avanzada
- Corrección de gamedata y translations
- etc...

IMPORTANTE:
- El siguiente mod además soporta:
CS:S, CS:GO, TF2, DOD:S (es necesario el gamedata de todos)

---

## COMANDOS:
GLOBALES:
```c
sm_respawn
```

---

## REQUISITOS:
Necesarios:
* **[VIP-Core](https://github.com/R1KO/VIP-Core)**

---

## CONVARS:
El archivo de configuración se genera automáticamente en `cfg/vip/VIP_Respawn.cfg`.

<details>
<summary>Ver la lista de ConVars y configuración</summary>

```c
// ConVars for plugin "vip\VIP_Respawn_1.6.smx"


// Enable/Disable AddFileToDownloadsTable. 
// 0 = Disable, 1 = Enable.
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "1.000000"
vip_respawn_addfiletodownloads_enable "0"

// Enable/Disable the respawn custom music. 
// 0 = Disable, 1 = Enable.
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "1.000000"
vip_respawn_custom_music_enable "0"

// Enable/Disable the plugin. 
// 0 = Disable, 1 = Enable.
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
vip_respawn_enable "1"

// Respawn limit per round/map. 
// -1 = No Limit, 0 = Prohibited.
// -
// Default: "-1"
// Minimum: "-1.000000"
vip_respawn_map_limit "-1"

// What is the minimum number of living players a team must have for a player to be able to respawn. 
// 0 = Disabled.
// -
// Default: "0"
// Minimum: "0.000000"
vip_respawn_min_alive "0"

```

---

## INSTALACIÓN:
**PARA QUE FUNCIONE CORRECTAMENTE, ES NECESARIO HACER ESTOS CAMBIOS:**

### PREPARACIÓN:

Modificamos el archivo 'addons/sourcemod/data/vip/cfg/**groups.ini**' de la siguiente manera:

**groups.ini**
```c
"VIP_GROUPS"
{
    "EJEMPLO_DE_GRUPO" // <- Elegimos el grupo VIP en el que pondrás el beneficio
    {
        "Respawn" "3" // <- Ponemos el nombre del módulo y un 'valor' para activarlo, todo entre comillas.
    }
}
```
El 'valor' que pongas, será el número de veces que el jugador podrá reaparecer, en este caso serían 3 veces.

### TRADUCCIÓN:

Traducimos el beneficio:
'addons/sourcemod/translations/**vip_modules.phrases**'

**vip_modules.phrases**
```c
"Phrases"
{
    "Respawn"
    {
        "es"        "Reaparición"
    }
}
```

Guardamos...

Reiniciamos nuestro servidor.

Y listo, eso es todo.
