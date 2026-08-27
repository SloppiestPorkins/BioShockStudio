class PseudoGatherer extends Actor
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

function PreBeginPlay()
{
	local SkeletalMesh GathererMesh;

	super.PreBeginPlay();
	GathererMesh = SkeletalMesh(DynamicLoadObject("GathererGirl.GathererGirl", Class'Engine.SkeletalMesh'));
	LinkMesh(GathererMesh);
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
	ShouldSerializeSkeletonInstance=true
}