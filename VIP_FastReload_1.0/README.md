# [VIP] Fast Reload (v. 1.0)

Publicación Original y Actual: Pizza baiana - [[l4d/l4d2] fast/rapid/sleight of hand guns (including shotguns)](https://forums.alliedmods.net/showthread.php?p=2805605))

---

## DESCRIPCIÓN:
Aumenta la velocidad de recarga de todas las armas del juego.

---

## REQUISITOS:
Para que el plugin funcione correctamente, necesitas tener instalado el siguiente archivo:
* **[VIP-Core](https://github.com/R1KO/VIP-Core)**

---

## INSTALACIÓN:
**PARA QUE FUNCIONE CORRECTAMENTE, ES NECESARIO HACER ESTOS CAMBIOS:**

### PREPARACIÓN:

Modificamos el archivo 'addons/sourcemod/data/vip/cfg/**groups.ini**' de la siguiente manera:

**groups.ini**
```C
"VIP_GROUPS"
{
    "EJEMPLO_DE_GRUPO" // <- Elegimos el grupo VIP en el que pondrás el beneficio
    {
        "L4d2_FastReload" "1" // <- Ponemos el nombre del módulo y 1 para activarlo, todo entre comillas.
    }
}
```

### TRADUCCIÓN:

**vip_modules.phrases**
```c
"Phrases"
{
    "L4d2_FastReload"
    {
        "es"        "Recarga Rápida"
    }
}
```

Guardamos...

Reiniciamos nuestro servidor.

Y listo, eso es todo.

---

## SIMILARES:
* [[L4D2] Melee Swing Speed (v1.3, 2023-7-27)](https://forums.alliedmods.net/showthread.php?p=2748248#post2748248) por HarryPotter.
