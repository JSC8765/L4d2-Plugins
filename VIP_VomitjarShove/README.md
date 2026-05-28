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
