class AIAttachment extends Actor implements IHaveAContainer, IAffectedByTelekinesis, IDamagee
	abstract
	native
	config(AIAttachments)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var name TargetAttachmentBone;
var float ChanceToFallOff;
var bool FallOffWhenKilled;
var bool bUseAsContainer;
var bool TelekinesisCanTearOff;
var bool TelekinesisTearOffShouldBeNoticedByAI;
var bool ShouldDestroyIfBurned;
var float DroppedVelocityModifier;
var Class<HavokObject> StaticMeshAttachmentHavokDataClass;
var name AttachmentCategory;
var private config localized string FriendlyName;
var private config localized string UseVerbText;
var private Container Container;
var name LootSlot0TableName;
var name LootSlot1TableName;
var name LootSlot2TableName;
var private Vector PreviousLocation;

function PreBeginPlay()
{
	super.PreBeginPlay();
	InitializeContainer();
	return;
	@NULL
}

function InitializeContainer()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xC9
	/*@Error*/
	Container = Class'ShockGame.Container'.static.Allocate(self).;
	Construct_Void();
	// End:0x65
	if(__NFUN_119__(Container, none))
	{
		Container.SetOwner(self);
		Container.SetLootSlotTableName(0, LootSlot0TableName);
	}
	Container.SetLootSlotTableName(1, LootSlot1TableName);
	Container.SetLootSlotTableName(2, LootSlot2TableName);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function PostBeginPlay()
{
	super.PostBeginPlay();
	assert(__NFUN_119__(Owner, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x51
	/*@Error*/
	Owner.AttachToBone(self, TargetAttachmentBone);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Destroyed()
{
	super.Destroyed();
	DestroyManagedAIAttachmentObjects();
	return;
	@NULL
}

// Export UAIAttachment::execDestroyManagedAIAttachmentObjects(FFrame&, void* const)
native function DestroyManagedAIAttachmentObjects();

function bool CanBeFocusedNow()
{
	return __NFUN_114__(Base, none);
	return;
	@NULL
}

function string GetFocusDisplayName()
{
	return FriendlyName;
	return;
	@NULL
}

function string GetHUDMessageForFocusAttained()
{
	return GetFocusDisplayName();
	return;
}

function bool ShouldHighlightWhenFocused()
{
	return true;
	return;
}

function bool ShouldShowHelpTagWhenFocused()
{
	return true;
	return;
}

function OnFocusStarted()
{
	TriggerEffectEvent('BecameUseFocus');
	return;
}

function OnFocusStopped()
{
	UnTriggerEffectEvent('BecameUseFocus');
	return;
}

function bool CanBeUsedNow()
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	return __NFUN_130__(__NFUN_130__(bUseAsContainer, thePlayer.CanUseContainer(Container)), CanBeFocusedNow());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetRequiredPlacementForUse(out Vector WorldSpaceLocation, out Rotator WorldSpaceRotation)
{
	return false;
	return;
}

function OnUsed(Pawn Pawn)
{
	AssertWithDescription(Pawn.__NFUN_303__('ShockPlayer'), __NFUN_112__(string(Class.Name), " was used by someone other than a ShockPlayer."));
	ShockPlayer(Pawn).OpenContainer(Container, GetCurrentMaterial());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnUseStopped(Pawn Pawn)
{
	return;
}

function string GetUseVerbText()
{
	return UseVerbText;
	return;
	@NULL
}

function Container GetContainer()
{
	return Container;
	return;
	@NULL
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x13
	if(CanBeUsedNow())
	{
		return 1;		
	}
	else
	{
		return 0;
	}
	return;
}

function float GetUseDistance()
{
	return 0.0000000;
	return;
}

function bool ActionBlockedByPawns()
{
	return true;
	return;
}

function OnTelekinesisStartedPulling(TelekinesisAbility Telekinesis)
{
	LifeSpan = 0.0000000;
	FadeOutDuration = 0.0000000;
	return;
	@NULL
	CommanderAction
}

function OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	LifeSpan = Class'ShockAI.ShockAI'.default.DroppedAttachmentLifeSpan;
	FadeOutDuration = Class'ShockAI.ShockAI'.default.DroppedAttachmentFadeOutDuration;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

event OnTelekinesisStartedHolding(TelekinesisAbility Telekinesis)
{
	return;
}

function OnTelekinesisStartedDroping(TelekinesisAbility Telekinesis)
{
	LifeSpan = Class'ShockAI.ShockAI'.default.DroppedAttachmentLifeSpan;
	FadeOutDuration = Class'ShockAI.ShockAI'.default.DroppedAttachmentFadeOutDuration;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

event Actor GetAffectedActor()
{
	return self;
	return;
}

function PreTelekinesis()
{
	local ShockAI theAI;

	theAI = ShockAI(Base);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5B
	/*@Error*/
	theAI.DropAttachment(self);
	theAI.OnAttachmentWasRemovedByTelekinesis(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsAffectedByTelekinesis()
{
	return __NFUN_130__(__NFUN_129__(bHidden), __NFUN_132__(__NFUN_154__(int(Physics), int(1)), __NFUN_130__(TelekinesisCanTearOff, __NFUN_132__(__NFUN_119__(StaticMeshAttachmentHavokDataClass, none), __NFUN_119__(HavokDataClass, none)))));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function TakeDamage(DamageStimuliSet DamageStimuli, float CritChance, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, float DamageAttenuation, name HitHighBone, name HitLowBone, bool WasMeleeAttack)
{
	//native.DamageStimuli;
	//native.CritChance;
	//native.Damager;
	//native.HitLocation;
	//native.HitNormal;
	//native.HitImpulseDirection;
	//native.EffectEventName;
	//native.DamageAttenuation;
	//native.HitHighBone;
	//native.HitLowBone;
	//native.WasMeleeAttack;	
	@NULL
	@NULL
	return default.@NULL;
}

function TakeScriptedDamage(DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, float DamageChance, optional Actor Damager)
{
	return;
}

defaultproperties
{
	TelekinesisCanTearOff=true
	TelekinesisTearOffShouldBeNoticedByAI=true
	DroppedVelocityModifier=0.5000000
	DrawType=8
	bAcceptsProjectors=true
	bInGameRenderable=true
	bHardAttach=true
	bCastSimpleShadow=true
	bIsHavokPhysicsEventually=true
	bCastShadowMapShadow=true
}