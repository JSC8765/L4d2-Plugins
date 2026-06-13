#if defined _Hats_included
#endinput
#endif
#define _Hats_included


#define Hats_version "xd"

/**
*   @param  iClient     Client Index.
*   @return             Entity Index, -1 on invalid.
*/
native int Hats_GetClientOverlayModel(int iClient);

/**
*	@Note This function is called when the Hat model is Changed.
*
*   @param  iClient         Client Index.
*   @param  iEntity         Entity Index, of OverlayModel
*   @param  sModel          Model Path Of Entity.
*   @no return
*/
forward void Hats_OnClientModelApplied(int iClient, int iEntity, const char sModel[PLATFORM_MAX_PATH]);

/**
*	@Note This function is called when the Hat model is Removed.
*
*   @param  iClient     Client Index who had the model.
*   @param  iEntity     Entity Index of OverlayModel
*   @no return
*/
forward void Hats_OnClientModelDestroyed(int iClient, int iEntity);

public SharedPlugin __pl_Hats = 
{
	name = "l4d_hats",
	file = "l4d_hats.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_Hats_SetNTVOptional()
{
	MarkNativeAsOptional("Hats_GetClientOverlayModel");
}
#endif
