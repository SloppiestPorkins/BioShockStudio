class DoorModel extends DoorAttachment
	native
	config(ShockGame)
	hidecategories(DrawScale3D,DisplayAdvanced,Force,LightColor,Lighting,Object,Sound);

var ShockDoor Door;

function BeginPlay()
{
	log('Doors', 4, __NFUN_112__(string(self), "---DoorModel::BeginPlay()."));
	super(Actor).BeginPlay();
	return;
	@NULL
}

// Export UDoorModel::execDestroyAttachments(FFrame&, void* const)
native function DestroyAttachments();

function Attach(Actor Other)
{
	Door.OnActorAttached(self, Other);
	return;
	@NULL
	Item
}

defaultproperties
{
	bOccludesSound=true
	bUpdateAudioOcclusionWhenMoving=true
	bCollideActors=true
	bBlockActors=true
	bBlockPlayers=true
	bBlockHavok=true
	ActorSpecificTextureWeight=7.0000000
}