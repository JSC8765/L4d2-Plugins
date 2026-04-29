# [VIP] Chat (scp) (v. 3.1.3)

R1KO - [[VIP] Chat 3.3](https://hlmod.net/resources/vip-chat.215/)

---

## DESCRIPCIÓN:
Gestiona y personaliza el color de tu nombre y mensajes que envíes para l4d2.

PROPIEDADES:
- Soporte para agregar colores y prefijos.
- Hasta 3 métodos diferentes para agregar colores y prefijos (Elegido por el Administrador, Elección por menú, Elección al escribirse por el chat)
- Cookies.
- Configuración Avanzada
- Se corrigió y agregó el color verde.
- etc...

IMPORTANTE:
- Colores permitidos {verde, naranja, blanco, (azul o rojo)}
- Colores no permitidos {verde claro}

---

## COMANDOS:
GLOBALES:
```c
 •sm_charla -> Abre el Chat Menu (2do Método)
```

---

## REQUISITOS:
Para que el plugin funcione correctamente, necesitas tener instalado el siguiente archivo:
* **[VIP-Core](https://github.com/R1KO/VIP-Core)**

---

## INSTALACIÓN:
**PARA QUE FUNCIONE CORRECTAMENTE, ES NECESARIO HACER ESTOS CAMBIOS:**
El siguiente módulo agrega el color verde para l4d2, sin embargo es necesario recompilar VIP-Core, modificando el siguiente archivo:
* /sourcemod/scripting/vip/Colors.sp

Nuestro trabajo es reemplazar "Colors_Print".
Para ello copien y peguen el siguiente enunciado:
```C
void Colors_Print(int iClient, const char[] szFormat)
{
    char szMessage[512];
    FormatEx(SZF(szMessage), g_EngineVersion == Engine_CSGO ? " \x01%t %s":"\x01%t %s", "VIP_CHAT_PREFIX", szFormat);

    ReplaceString(SZF(szMessage), "\\n", "\n");
    ReplaceString(SZF(szMessage), "{DEFAULT}", "\x01");
    ReplaceString(SZF(szMessage), "{GREEN}", "\x04");
  // Color Verde
    ReplaceString(SZF(szMessage), "{OLIVE}", "\x05");
    
    switch (g_EngineVersion)
    {
        case Engine_SourceSDK2006, Engine_Left4Dead, Engine_Left4Dead2:
    {
      ReplaceString(SZF(szMessage), "{LIGHTGREEN}", "\x03");
      int iColor = Colors_ReplaceColors(SZF(szMessage));
      switch (iColor)
      {
      case -1:    Colors_SayText2(iClient, 0, szMessage);
      case 0:        Colors_SayText2(iClient, iClient, szMessage);
      default:
        {
          Colors_SayText2(iClient, Colors_FindPlayerByTeam(iColor), szMessage);
        }
      }
    }
    }
}
```
Una vez reemplazado, guarden el archivo, compilen Vip-Core y reemplacen, con esto el color verde ya estará disponible.

Si no sabe como instalar módulos, pueden ir a mi Discord, en la publicación "VIP-Core Tutorial de Instalación"

---

## SIMILARES:
* [[ANY] HexTags [Tags/Chat Colors & Score Tags]](https://forums.alliedmods.net/showthread.php?p=2566623)
* [l4d2_tags_public_no_info](https://discord.gg/dgpKr9etsZ) (Hecho por ¹⁹𝙹ẳʳԑԃ, Disponible en el Discord de Haku.cfg)
