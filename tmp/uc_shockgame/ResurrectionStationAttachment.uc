class ResurrectionStationAttachment extends StaticMeshActor
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Force,LightColor,Lighting,Object,Sound);

var BaseResurrectionStation OwnerStation;

defaultproperties
{
	bStatic=false
	bDisableTick=true
	bStasis=true
	bWorldGeometry=false
	bOccludesSound=false
	bHardAttach=true
	bUseLightingFromBaseWhenAttached=false
	bCollideActors=false
	bBlockActors=false
	bBlockPlayers=false
	bBlockHavok=false
	HelpTag="Resurrection"
}