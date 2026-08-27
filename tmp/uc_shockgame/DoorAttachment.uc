class DoorAttachment extends StaticMeshActor
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Force,LightColor,Lighting,Object,Sound);

defaultproperties
{
	bLightingVisibility=false
	bStatic=false
	bDisableTick=true
	bWorldGeometry=false
	bOccludesSound=false
	bHardAttach=true
	bUseLightingFromBaseWhenAttached=false
	bCollideActors=false
	bBlockActors=false
	bBlockPlayers=false
	bBlockHavok=false
}