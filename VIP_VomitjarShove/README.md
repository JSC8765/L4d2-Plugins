# [VIP] Vomitjar Shove (v. 1.9.1)

Publicación Original y Actual: Silvers - [[L4D2] Vomitjar Shove (1.9) [01-Nov-2022]](https://forums.alliedmods.net/showthread.php?t=188045)

---

## DESCRIPCIÓN:
Cubre de vómito a cualquier infectado si  empuñas y empujas con el frasco de bilis.

---

## REQUISITOS:
Necesarios:
* **[VIP-Core](https://github.com/R1KO/VIP-Core)**

---

## CONVARS:
El archivo de configuración se genera automáticamente en `cfg/vip/l4d2_vomitjar_shove.cfg`.

<details>
<summary>Ver la lista de ConVars y configuración</summary>

```c
// ConVars for plugin "vip\VIP_VomitjarShove.smx"


// 0=Plugin off, 1=Plugin on.
// -
// Default: "1"
l4d2_vomitjar_shove_allow "1"

// Which infected to affect: 1=Common, 2=Witch, 4=Smoker, 8=Boomer, 16=Hunter, 32=Spitter, 64=Jockey, 128=Charger, 256=Tank, 511=All.
// -
// Default: "511"
l4d2_vomitjar_shove_infected "511"

// Which key combination to use when shoving: 1=Shove key. 2=Reload + Shove keys.
// -
// Default: "1"
l4d2_vomitjar_shove_keys "1"

// Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).
// -
// Default: ""
l4d2_vomitjar_shove_modes ""

// Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).
// -
// Default: ""
l4d2_vomitjar_shove_modes_off ""

// Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.
// -
// Default: "0"
l4d2_vomitjar_shove_modes_tog "0"

// 0=Unlimited. How many times can a player hit zombies with the vomitjar before it breaks.
// -
// Default: "5"
l4d2_vomitjar_shove_punch "0"

// 0=Only the player holding the vomitjar. Distance to splash nearby survivors when the vomitjar breaks.
// -
// Default: "50"
l4d2_vomitjar_shove_radius "50"

// Chance out of 100 to splash self and nearby players when the vomitjar breaks.
// -
// Default: "10"
l4d2_vomitjar_shove_splash "10"

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
        "L4d2_VomitjarShove" "1" // <- Ponemos el nombre del módulo y 1 para activarlo, todo entre comillas.
    }
}
```

### TRADUCCIÓN:

Traducimos el beneficio:
'addons/sourcemod/translations/**vip_modules.phrases**'

**vip_modules.phrases**
```c
"Phrases"
{
    "L4d2_VomitjarShove"
    {
        "es"        "Empuje Cegador"
    }
}
```

Guardamos...

Reiniciamos nuestro servidor.

Y listo, eso es todo.

---

## SIMILARES:
* [[L4D & L4D2] Molotov Shove (1.10) [01-Nov-2022]](https://forums.alliedmods.net/showthread.php?p=1732252) por Silvers.
* [[L4D & L4D2] Pipebomb Shove (1.17) [21-Mar-2025]](https://forums.alliedmods.net/showthread.php?p=1733534) por Silvers.
