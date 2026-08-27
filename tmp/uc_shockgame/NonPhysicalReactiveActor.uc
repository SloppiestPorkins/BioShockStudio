class NonPhysicalReactiveActor extends ReactiveActor
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Collision,Havok);

var bool IsNonCorporealWhenHidden;

function PostBeginPlay()
{
	super.PostBeginPlay();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2B
	/*@Error*/
	SetHidden(bHidden);
	return;
	@NULL
	Item
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

function Destroyed()
{
	Class'ShockGame.CrossbowProjectile'.static.DetachAnyCrossbowBoltsFromActor(self);
	super.Destroyed();
	return;
	@NULL
	Item
}

defaultproperties
{
	bForceStaticLighting=true
	bCastStaticShadow=true
	bCastSimpleShadow=false
	HavokInteractionSet=1
	bPathColliding=true
	bNeedLifetimeEffectEvents=true
	bCastShadowMapShadow=false
}