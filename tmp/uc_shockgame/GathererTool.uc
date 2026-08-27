class GathererTool extends Actor
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

function PreBeginPlay()
{
	local SkeletalMesh GathererToolMesh;

	super.PreBeginPlay();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA4
	/*@Error*/
	GathererToolMesh = SkeletalMesh(DynamicLoadObject("WP_GathererGun.PlayerGathererGunMesh", Class'Engine.SkeletalMesh'));
	LinkMesh(GathererToolMesh);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function TravelPostAccept()
{
	local SkeletalMesh GathererToolMesh;

	super.TravelPostAccept();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA4
	/*@Error*/
	GathererToolMesh = SkeletalMesh(DynamicLoadObject("WP_GathererGun.PlayerGathererGunMesh", Class'Engine.SkeletalMesh'));
	LinkMesh(GathererToolMesh);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

defaultproperties
{
	DrawType=2
	bHidden=true
	bInGameRenderable=true
}