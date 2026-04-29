# [L4D.1&2] SelfHelp [Editado] (v. 1.6)

Basado en el trabajo de Pan Xiaohai: [[L4D & L4D2] Self Help](https://forums.alliedmods.net/showthread.php?t=129444) - 1.0.1

---

## DESCRIPCIÓN:
Mantén presionado Ctrl para Auto-Ayudarte.

PROPIEDADES:
- Informa  el N° de incapacitaciones y alerta el estado Blanco y Negro por chat.
- Corrige la salud Permanente y Temporal.
- Es compatible  con plugins que otorgan más de 100 de HP.
- Nuevo efecto de adrenalina al usarse.
- etc...

---

## REQUISITOS:
Para que el plugin funcione correctamente, necesitas tener instalado el siguiente archivo:
* **[l4d_heartbeat](https://github.com/fbef0102/L4D1_2-Plugins/tree/master)** (Corrige el latido del corazón y el efecto Blanco y Negro)

---

## CONVARS:
El archivo de configuración se genera automáticamente en `cfg/sourcemod/l4d_selfhelp.cfg`.

<details>
<summary>Ver la lista de ConVars y configuración</summary>

```c
// ConVars for plugin "l4d_selfhelp.smx"


// ¿Cuánto de vida obtendrás al usar tu Adrenalina?
// -
// Default: "30"
// Minimum: "30.000000"
// Maximum: "100.000000"
l4d_selfhelp_adreHP "30"

// ¿Deseas agregar el efecto de la adrenalina al usarse?
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d_selfhelp_adreeffect "0"

// ¿Cuántos segundos quieres que dure el efecto de la adrenalina?
// -
// Default: "10"
// Minimum: "3.000000"
// Maximum: "15.000000"
l4d_selfhelp_adreeffectduration "10"

// ¿En cuánto tiempo deseas mostrar el aviso de la Auto-Ayuda?(Chat)
// NO ES POSIBLE DESACTIVAR ESTO
// -
// Default: "1.0"
// Minimum: "1.000000"
// Maximum: "5.000000"
l4d_selfhelp_delay "1.0"

// ¿Cuánto tiempo debe durar la Auto-Ayuda al usarse?
// NO ES POSIBLE DESACTIVAR ESTO
// -
// Default: "2.5"
// Minimum: "1.000000"
// Maximum: "5.000000"
l4d_selfhelp_duration "2.5"

// ¿Quieres levantar a tus compañeros incapacitados, estando tú también incapacitado?
// 0 - No, 1 - Si
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d_selfhelp_eachother "1"

// ¿Qué usaras para Auto-Ayudarte estando colgado de una cornisa?
// 0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)
// -
// Default: "3"
// Minimum: "0.000000"
// Maximum: "3.000000"
l4d_selfhelp_edgegrab "3"

// ¿Activar Auto-Ayuda?
// 0 - No, 1 - Si
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d_selfhelp_enabled "1"

// ¿Qué usaras para Auto-Ayudarte si te ataca el SMOKER?
// 0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)
// -
// Default: "3"
// Minimum: "0.000000"
// Maximum: "3.000000"
l4d_selfhelp_grab "3"

// ¿En cuánto tiempo deseas mostrar el informe de la Auto-Ayuda?(Hint)
// NO ES POSIBLE DESACTIVAR ESTO
// -
// Default: "3.0"
// Minimum: "1.000000"
// Maximum: "5.000000"
l4d_selfhelp_hintdelay "3.0"

// ¿Qué usaras para Auto-Ayudarte estando incapacitado?
// 0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)
// -
// Default: "3"
// Minimum: "0.000000"
// Maximum: "3.000000"
l4d_selfhelp_incap "3"

// ¿Deseas matar a tu atacante al usar la Auto-Ayuda?
// 0 - No, 1 - Si
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d_selfhelp_kill "1"

// ¿Cuánto de vida obtendrás al usar tu Botiquín?
// -
// Default: "100"
// Minimum: "80.000000"
// Maximum: "100.000000"
l4d_selfhelp_kitHP "100"

// ¿Cuánto de vida obtendrá la persona que levantes? (Estando ambos incapacitados)
// -
// Default: "30"
// Minimum: "30.000000"
// Maximum: "100.000000"
l4d_selfhelp_otherHP "30"

// ¿En cuánto tiempo deseas mostrar el aviso de la Auto-Ayuda
// para ayudar a otros supervivientes incapacitados?(Hint)
// 0.0 - Desactivado
// -
// Default: "7.0"
// Minimum: "0.000000"
// Maximum: "15.000000"
l4d_selfhelp_otherdelay "7.0"

// ¿Quieres agarrar del suelo Botiquines, Píldoras o Adrenalinas estando incapacitado?
// 0 - No, 1 - Si
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d_selfhelp_pickup "1"

// ¿Cuánto de vida obtendrás al usar tus Píldoras?
// -
// Default: "30"
// Minimum: "30.000000"
// Maximum: "100.000000"
l4d_selfhelp_pillsHP "30"

// ¿Qué usaras para Auto-Ayudarte si te ataca el HUNTER?
// 0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)
// -
// Default: "3"
// Minimum: "0.000000"
// Maximum: "3.000000"
l4d_selfhelp_pounce "3"

// ¿Qué usaras para Auto-Ayudarte si te ataca el CHARGER?
// 0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)
// -
// Default: "3"
// Minimum: "0.000000"
// Maximum: "3.000000"
l4d_selfhelp_pummel "3"

// ¿Qué usaras para Auto-Ayudarte si te ataca el JOCKEY?
// 0 - Nada, 1 - Píldoras y Adrenalinas, 2 - Botiquín, 3 - Ambos(1 y 2)
// -
// Default: "3"
// Minimum: "0.000000"
// Maximum: "3.000000"
l4d_selfhelp_ride "3"

// ¿Deseas que al usar tus Adrenalina, tu vida sea temporal?
// 0 - No, 1 - Si
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d_selfhelp_tempadre "1"

// ¿Deseas que al usar tu Botiquín, tu vida sea temporal?
// 0 - No, 1 - Si
// -
// Default: "0"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d_selfhelp_tempkit "0"

// ¿Deseas que al levantar a una persona, estando ambos incapacitados, su vida sea temporal?
// 0 - No, 1 - Si
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d_selfhelp_tempother "1"

// ¿Deseas que al usar tus Píldoras, tu vida sea temporal?
// 0 - No, 1 - Si
// -
// Default: "1"
// Minimum: "0.000000"
// Maximum: "1.000000"
l4d_selfhelp_temppills "1"

```
</details>

---

## REGISTRO DE CAMBIOS:

<details>
<summary>Ver el registro de cambios</summary>

* ### v1.6
    * Testeos múltiples, encontrando un error sobre el latido del corazón. (Solución: "l4d_heartbeat" por HarryPotter)

* ### v1.5
    * Se incluyeron nuevos ConVars para una mejor configuración, todos lo Convars cambiados al español!

* ### v1.4
    * Se cambió el código de la vieja a la nueva sintaxys.

* ### v1.3
    * Se agregó el efecto de la adrenalina al ser usada, Gracias Lux por "adrenaline_effect"!

* ### v1.2
    * Se agregaron los mensajes sobre el número de incapacitaciones(caidas) y la alerta al estado Blanco y Negro,
      Gracias cravenge por "[L4D/L4D2] Self-Help (Reloaded)"!

* ### v1.1
    * Se agregaron opciones de salud permanente y temporal, Gracias valedar por "l4d_selfhelp_en4v"!
</details>

---

## REFERENCIAS:
* [l4d_selfhelp_en4v](https://forums.alliedmods.net/showthread.php?p=2784803#post2784803)
* [[L4D/L4D2] Self-Help (Reloaded) | 0.3 : October 11, 2019 |](https://forums.alliedmods.net/showthread.php?t=281620)
* [adrenaline_effect](https://forums.alliedmods.net/showthread.php?t=327928)

---

## SIMILARES:
* [[L4D2] Scuffle - Get Up! (Ready for Testing 12-18-17)](https://forums.alliedmods.net/showthread.php?p=2566424)
