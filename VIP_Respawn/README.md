# [VIP] Fast Reload (v. 1.0)

Publicación Original y Actual: Pizza baiana - [[l4d/l4d2] fast/rapid/sleight of hand guns (including shotguns)](https://forums.alliedmods.net/showthread.php?p=2805605))

---

## DESCRIPCIÓN:
Si moriste, escribe !respawn para volver a jugar.

---

## REQUISITOS:
Necesarios:
* **[VIP-Core](https://github.com/R1KO/VIP-Core)**

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
