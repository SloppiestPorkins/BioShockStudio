class Assassin extends Aggressor
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var private Vector TeleportInRunningTranslation;
var private Actor NextTeleportPoint;
var private Actor NextTeleportInRunDestination;
var private Material OriginalSkin;
var private AIRangedWeapon RangedWeapon;
var private AIRangedWeapon BlastWeapon;
var private config Class<AIRangedWeapon> RangedWeaponClass;
var private config Class<AIRangedWeapon> BlastWeaponClass;
var private config name TeleportInRunningAnimation;
var private config name TeleportInStandingAnimation;
var private config float TeleportToAILODOverrideTime;
var private config Class<HavokForceActorPreset> TeleportInExplosionClass;
var private config Class<HavokForceActorPreset> TeleportOutExplosionClass;
var private HavokForceActorPreset TeleportInExplosion;
var private HavokForceActorPreset TeleportOutExplosion;

function PostBeginPlay()
{
	super(ShockAI).PostBeginPlay();
	DetermineTeleportInRunningTranslation();
	// End:0x70
	if(__NFUN_119__(TeleportInExplosionClass, none))
	{
		TeleportInExplosion = __NFUN_278__(TeleportInExplosionClass, self,, Location);
		TeleportInExplosion.__NFUN_298__(self);
		TeleportInExplosion.SetEnabled(false);
		goto J0xD1;
		SLog(__NFUN_168__("TeleportInExplosionClass == None.", "will not create an explosion when teleporting in"));
	}
	// End:0x12D
	if(__NFUN_119__(TeleportOutExplosionClass, none))
	{
		TeleportOutExplosion = __NFUN_278__(TeleportOutExplosionClass, self,, Location);
		TeleportOutExplosion.__NFUN_298__(self);
		TeleportOutExplosion.SetEnabled(false);
		goto J0x190;
		SLog(__NFUN_168__("TeleportOutExplosionClass == None.", "will not create an explosion when teleporting out"));
	}
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function DetermineTeleportInRunningTranslation()
{
	local float TeleportInRunningAnimationLength, TeleportInRunningDeltaRotationYaw;

	TeleportInRunningAnimationLength = GetAnimationLength(TeleportInRunningAnimation);
	GetAnimationAbsoluteMotion(TeleportInRunningAnimation, TeleportInRunningAnimationLength, TeleportInRunningTranslation, TeleportInRunningDeltaRotationYaw);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function OnArchetypeApplied()
{
	super(ShockAI).OnArchetypeApplied();
	OriginalSkin = GetCurrentMaterial(0);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function AddInitialKeywords()
{
	super.AddInitialKeywords();
	AddLocomotionKeyword('Assassin', Class'ShockAI.ShockAI'.0);
	AddLocomotionKeyword('SanderCohen', Class'ShockAI.ShockAI'.-1);
	AddLocomotionKeyword('SanderCohenSpeech', Class'ShockAI.ShockAI'.-1);
	GetRagdoll().AddRequiredRiseFromRagdollKeyword('Assassin');
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.AssassinAttackAction');
	CharacterAI.addAbility_Class(Class'ShockAI.TeleportAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function ResetOriginalSkin()
{
	SetSkin(0, OriginalSkin);
	return;
	@NULL
	CommanderAction
}

function AIRangedWeapon GetRangedWeapon()
{
	return RangedWeapon;
	return;
	@NULL
}

function AIRangedWeapon GetBlastWeapon()
{
	return BlastWeapon;
	return;
	@NULL
}

function CreateWeapons()
{
	assert(__NFUN_119__(RangedWeaponClass, none));
	RangedWeapon = AIRangedWeapon(CreateAIWeapon(RangedWeaponClass));
	AddAvailableHoldable(RangedWeapon);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x90
	/*@Error*/
	BlastWeapon = AIRangedWeapon(CreateAIWeapon(BlastWeaponClass));
	AddAvailableHoldable(BlastWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function SetNextTeleportPoint(Actor inNextTeleportPoint)
{
	assert(__NFUN_119__(inNextTeleportPoint, none));
	log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " SetNextTeleportPoint: "), string(inNextTeleportPoint)), " was: "), string(NextTeleportPoint)));
	NextTeleportPoint = inNextTeleportPoint;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Actor GetNextTeleportPoint()
{
	return NextTeleportPoint;
	return;
	@NULL
}

function ClearNextTeleportPoint()
{
	log('AI', 5, __NFUN_112__(__NFUN_112__(string(Name), " ClearNextTeleportPoint: "), string(NextTeleportPoint)));
	NextTeleportPoint = none;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function SetNextTeleportInRunDestination(Actor inNextTeleportInRunDestination)
{
	assert(__NFUN_119__(inNextTeleportInRunDestination, none));
	log('AI', 5, __NFUN_112__(__NFUN_112__(string(Name), " SetNextTeleportInRunDestination - inNextTeleportInRunDestination: "), string(inNextTeleportInRunDestination)));
	NextTeleportInRunDestination = inNextTeleportInRunDestination;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Actor GetNextTeleportInRunDestination()
{
	return NextTeleportInRunDestination;
	return;
	@NULL
}

function ClearNextTeleportInRunDestination()
{
	log('AI', 5, __NFUN_112__(__NFUN_112__(string(Name), " ClearNextTeleportInRunDestination: "), string(NextTeleportPoint)));
	NextTeleportInRunDestination = none;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function TeleportTo(Actor inTeleportDestination, Actor inTeleportRotationMarker, bool bUseTeleportOutEffects, bool bSkipEtherTime)
{
	local TeleportGoal TeleportNowGoal;
	local Rotator TeleportRotation;

	assert(__NFUN_119__(inTeleportDestination, none));
	SetNormalAILODOverrideTime(TeleportToAILODOverrideTime);
	// End:0x6B
	if(__NFUN_119__(inTeleportRotationMarker, none))
	{
		TeleportRotation = Rotator(__NFUN_216__(inTeleportRotationMarker.Location, inTeleportDestination.Location));
		TeleportNowGoal = Class'ShockAI.TeleportGoal'.static.Allocate(self).;
		construct_AI_ResourceVectorBoolBoolRotatorBool(CharacterAI, inTeleportDestination.Location, __NFUN_129__(bUseTeleportOutEffects), __NFUN_119__(inTeleportRotationMarker, none), TeleportRotation, bSkipEtherTime);
	}
	TeleportNowGoal.postGoal(none);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanDouse()
{
	return __NFUN_130__(__NFUN_129__(IsTeleporting()), super(EcologyAI).CanDouse());
	return;
	@NULL
}

function bool CanPlayFallDownHitReaction()
{
	return __NFUN_130__(__NFUN_129__(IsTeleporting()), super(ShockAI).CanPlayFallDownHitReaction());
	return;
	@NULL
}

function bool CanPlayFullBodyHitReaction()
{
	return __NFUN_130__(__NFUN_129__(IsTeleporting()), super(ShockAI).CanPlayFullBodyHitReaction());
	return;
	@NULL
}

function name GetTeleportInAnimation()
{
	local Vector TeleportInRunningDirection, TeleportInRunningEndLocation, TeleportInRunningEndLocationAdjusted;

	TeleportInRunningDirection = __NFUN_276__(__NFUN_226__(TeleportInRunningTranslation), Rotation);
	TeleportInRunningEndLocation = __NFUN_215__(Location, __NFUN_212__(TeleportInRunningDirection, __NFUN_225__(TeleportInRunningTranslation)));
	TeleportInRunningEndLocationAdjusted = TeleportInRunningEndLocation;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xAC
	/*@Error*/
	return TeleportInRunningAnimation;
	goto J0xB6;
	return TeleportInStandingAnimation;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetTeleportInExplosionEnabled(bool Enable)
{
	// End:0x3F
	if(__NFUN_130__(__NFUN_119__(TeleportInExplosion, none), IsAlive()))
	{
		TeleportInExplosion.SetEnabled(Enable);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function SetTeleportOutExplosionEnabled(bool Enable)
{
	// End:0x3F
	if(__NFUN_130__(__NFUN_119__(TeleportOutExplosion, none), IsAlive()))
	{
		TeleportOutExplosion.SetEnabled(Enable);
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	super.OnKilled(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	DestroyTeleportExplosions();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

// Export UAssassin::execDestroyTeleportExplosions(FFrame&, void* const)
native function DestroyTeleportExplosions();

defaultproperties
{
	TeleportInRunningAnimation="AS_TeleportEnd"
	TeleportInStandingAnimation="AS_TeleportEnd"
	TeleportToAILODOverrideTime=5.0000000
	TeleportInExplosionClass=Class'ShockAI.HavokPhysicsSpecial.AssassinExplosion'
	TeleportOutExplosionClass=Class'ShockAI.HavokPhysicsSpecial.AssassinImplosion'
	MimicPoseAnimations[0]="AS_PlayDeadBack_POSE"
	MimicPoseAnimations[1]="AS_PlayDeadStomach_POSE"
	SearchAnimations[0]="ME_Searching"
	FriendlyName="Houdini Splicer"
	ResearchTrack="Assassin"
	MinDistanceFromLastKnownLocationToLoseTarget=300.0000000
	HitFrontAnimations[0]="ME_hitFWD_A"
	HitFrontAnimations[1]="ME_hitFWD_B"
	HitFrontAnimations[2]="ME_hitFWD_C"
	HitFrontAnimations[3]="ME_hitFWD_D"
	HitLeftAnimations[0]="ME_hitFWD_D"
	HitRightAnimations[0]="ME_hitFWD_D"
	HitBackAnimations[0]="ME_hitBWD_A"
	HitBackAnimations[1]="ME_hitBWD_B"
	HitBackAnimations[2]="ME_hitBWD_C"
	HitBackAnimations[3]="ME_hitBWD_D"
	HitFrontDeathAnimations[0]="ME_hitFWD_D"
	HitFrontDeathAnimations[1]="ME_hitFWD_A"
	HitLeftDeathAnimations[0]="ME_hitFWD_D"
	HitRightDeathAnimations[0]="ME_hitFWD_D"
	HitBackDeathAnimations[0]="ME_hitBWD_D"
	EyeBoneName="eyes"
	bShouldUseLocomotion=true
	bShouldUseFootIKTracker=true
	bShouldUseQuickHitReaction=true
	bCanTeleport=true
	bHasRangedAttack=true
	bPrefersRangedAttack=true
	DodgeAnimations[0]="ME_dodgeLEFT_B"
	DodgeAnimations[1]="ME_dodgeRIGHT_B"
	DamageResistanceSetName="AssassinResistanceSet"
	MaxHealth=220.0000000
	MaxFrozenHealth=110.0000000
	Health=220.0000000
	CollisionRadius=50.0000000
	CollisionHeight=82.0000000
	bRotateToDesired=false
	RequiredAnimationGroups=/* Array type was not detected. */
}