class TelekinesisAbility extends Ability implements IInterestedActorDestroyed, IEffectObserver
	native
	config(Abilities);

enum ETelekinesisState
{
	kIDLE,                          // 0
	kPULLING,                       // 1
	kHOLDING,                       // 2
	kTHROWING,                      // 3
	kDROPPING                       // 4
};

var transient bool bInitialized;
var private bool bLastUseSuccessful;
var native transient pointer CurrentState;
var native transient pointer DamageListener;
var private TelekinesisAbility.ETelekinesisState State;
var float ConeAngle;
var int TargetHkCollisionLayer;
var float AcquisitionDistance;
var float BreakageDistance;
var float Range;
var /*0x00000000-0x01000000*/ private transient Actor Target;
var ShockPlayer Player;
var config float MaximumHoldingDistance;
var config name InterruptFireWithEveAnimationName;
var config name InterruptFireWithoutEveAnimationName;
var const config float TargetAssistanceCosine;
var const config float TargetAssistanceRange;
var const config float ExplosiveProjectilePreferenceFactor;
var private transient float TelekinesesStartTime;
var private transient SoundInstance SoundInstance;
var private native transient pointer Controller;
var private native transient pointer ActionListener;

function Actor GetTarget()
{
	return Target;
	return;
	@NULL
}

function name GetFinishFireWithEveAnimationName()
{
	// End:0x1A
	if(bLastUseSuccessful)
	{
		return FinishFireWithEveAnimationName;
		goto J0x24;
		return InterruptFireWithEveAnimationName;
		return;
	}
	@NULL
	Item
	J0x24:

	Item
}

function name GetFinishFireWithoutEveAnimationName()
{
	// End:0x1A
	if(bLastUseSuccessful)
	{
		return FinishFireWithoutEveAnimationName;
		goto J0x24;
		return InterruptFireWithoutEveAnimationName;
		return;
	}
	@NULL
	Item
	J0x24:

	Item
}

function bool HasBeenInterrupted(ShockPlayer Instigator)
{
	return __NFUN_129__(bLastUseSuccessful);
	return;
	@NULL
}

function UseAbility(ShockPlayer Instigator)
{
	return;
}

function StartedUsingAbility(ShockPlayer Instigator)
{
	//native.Instigator;	
	@NULL
}

function UseAbilityRelease(ShockPlayer Instigator)
{
	//native.Instigator;	
	@NULL
}

// Export UTelekinesisAbility::execGetState(FFrame&, void* const)
native function TelekinesisAbility.ETelekinesisState GetState();

function bool CanUseAbilityOnRelease(ShockPlayer Instigator)
{
	return true;
	return;
}

function bool ShouldUseAbilityOnRelease()
{
	return true;
	return;
}

function bool CanUseAbility(ShockPlayer Instigator)
{
	return __NFUN_132__(__NFUN_155__(int(GetState()), int(0)), super.CanUseAbility(Instigator));
	return;
	@NULL
	Item
}

// Export UTelekinesisAbility::execDropObject(FFrame&, void* const)
native function bool DropObject();

function name GetCurrentUseName()
{
	// End:0x22
	if(__NFUN_154__(int(GetState()), int(0)))
	{
		return 'TelekinesisGrab';		
	}
	else
	{
		return 'TelekinesisThrow';
	}
	return;
}

function ChangeHoldingPitch(float Pitch)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x2F
	/*@Error*/
	SoundInstance.SetDynamicPitchInput(Pitch);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnStartedPullingActor()
{
	Player.dispatchMessage(Class'ShockGame.MessageTelekinesisStartedPullingActor'.static.Allocate(self)., construct_Actor(Target));
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	//native.ActorBeingDestroyed;	
	@NULL
}

function OnEffectStarted(Actor inStartedEffect)
{
	local SoundInstance ThisInstance;

	ThisInstance = SoundInstance(inStartedEffect);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5C
	/*@Error*/
	SoundInstance = ThisInstance;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnEffectStopped(Actor inStoppedEffect, bool Completed)
{
	// End:0x22
	if(__NFUN_114__(inStoppedEffect, SoundInstance))
	{
		SoundInstance = none;
		return;
		@NULL
		Item
	}
	Item
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

defaultproperties
{
	ConeAngle=0.8600000
	AcquisitionDistance=1.0000000
	BreakageDistance=4.0000000
	Range=5000.0000000
	MaximumHoldingDistance=2.5000000
	InterruptFireWithEveAnimationName="TK_FireInterruptEve"
	TargetAssistanceCosine=0.9659000
	TargetAssistanceRange=2000.0000000
	ExplosiveProjectilePreferenceFactor=0.8000000
	ModGroupName="Telekinesis_Exists"
	BioAmmoCost=2.5000000
	FriendlyName="Telekinesis"
	FireAnimationName="TK_Fire"
	FireLoopAnimationName="TK_FireLoop"
	FinishFireWithEveAnimationName="TK_FireEve"
	FinishFireWithoutEveAnimationName="TK_FireNoEve"
}