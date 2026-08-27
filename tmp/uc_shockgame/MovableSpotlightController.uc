class MovableSpotlightController extends Actor implements IEffectObserver
	native
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

struct native atomic AttachedEffectActorEntry
{
	var Actor AttachedActor;
	var name AttachmentBoneName;
};

var private MovableSpotlight ParentLight;
var private Actor ActorToTrack;
var private bool StartsOn;
var private Rotator ControllerRotationOffset;
var array<AttachedEffectActorEntry> AttachedEffectActors;

function OnEffectStarted(Actor inStartedEffect)
{
	local AttachedEffectActorEntry Entry;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xC2
	/*@Error*/
	Entry.AttachedActor = inStartedEffect;
	Entry.AttachmentBoneName = inStartedEffect.AttachmentBone;
	AttachedEffectActors[AttachedEffectActors.Length] = Entry;
	DetachFromBone(inStartedEffect);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ClearAttachedEffectActorsArray()
{
	AttachedEffectActors.Remove(0, AttachedEffectActors.Length);
	return;
	@NULL
	Item
}

function OnEffectStopped(Actor inStoppedEffect, bool Completed)
{
	return;
}

function OnEffectInitialized(Actor inInitializedEffect)
{
	return;
}

function OnScreenEffectStarted(ReferenceCountedObject inStartedEffect)
{
	return;
}

function OnScreenEffectStopped(ReferenceCountedObject inStoppedEffect)
{
	return;
}

function Initialize(MovableSpotlight inParentLight, bool inStartsOn, Rotator inRotationOffset)
{
	ParentLight = inParentLight;
	IgnoreLight = inParentLight;
	StartsOn = inStartsOn;
	ControllerRotationOffset = inRotationOffset;
	__NFUN_299__(__NFUN_316__(inParentLight.Rotation, ControllerRotationOffset));
	__NFUN_113__('SetSpotlightState');
	return;
	@NULL
	Item
	Item
	@NULL
}

function SetActorTracking(Actor newActorToTrack)
{
	log(,, __NFUN_112__("Setting actor tracking to ", string(newActorToTrack)));
	ActorToTrack = newActorToTrack;
	__NFUN_113__('TrackActor');
	return;
	@NULL
	Item
	Item
}

// Export UMovableSpotlightController::execRotateLight(FFrame&, void* const)
native function RotateLight();

state SetSpotlightState
{Begin:

	__NFUN_256__(0.0000000);
	ParentLight.SetSpotlightState(StartsOn);
	__NFUN_113__('None');
	stop;			
	@NULL
	@NULL
}

state TrackActor
{Begin:

	log(,, "Tracking Actor");
	J0x17:

	// End:0x3B [Loop If]
	if(__NFUN_119__(ActorToTrack, none))
	{
		RotateLight();
		__NFUN_256__(0.0000000);
		// [Loop Continue]
		goto J0x17;
		log(,, "Done tracking actor");
	}
	__NFUN_113__('None');
	stop;	
	@NULL
}

defaultproperties
{
	bInGameRenderable=true
}