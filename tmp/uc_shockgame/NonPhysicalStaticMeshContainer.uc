class NonPhysicalStaticMeshContainer extends StaticMeshContainer
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Movement,Collision);

defaultproperties
{
	bForceStaticLighting=true
	bCastStaticShadow=true
	bCastSimpleShadow=false
	HavokInteractionSet=1
	bCastShadowMapShadow=false
}