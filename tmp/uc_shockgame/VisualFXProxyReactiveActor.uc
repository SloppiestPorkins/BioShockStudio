class VisualFXProxyReactiveActor extends NonPhysicalReactiveActor
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Collision,Havok);

function PostBeginPlay()
{
	super.PostBeginPlay();
	SetHidden(true);
	return;
	@NULL
	Item
}

defaultproperties
{
	MaxLightsStatic=0
	MaxLightsDynamic=0
	bUnlit=true
	bCastStaticShadow=false
	bBlockActors=false
	bBlockPlayers=false
	bBlockZeroExtentTraces=false
	bBlockNonZeroExtentTraces=false
	HavokInteractionSet=4
	bPathColliding=false
}