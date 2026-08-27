class Aggressor extends EcologyFighter
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var private PatrolList Patrol;
var private bool bStartOutAsMimic;
var private bool bIsCurrentlyAMimic;
var private PoseData MimicInitialPose;
var config array<name> HealAtHealthStationAnimations;
var config array<name> PoisonedAtHealthStationAnimations;
var config array<name> MimicPoseAnimations;
var private config float HealAtHealthStationChance;
var private config float HealAtHealthStationHealthPct;
var private config Range HealAtHealthStationTimeRange;
var private config Range PoisonedAtHealthStationDamageRange;
var config float ChanceToRunAwayOnHitSpang;
var private config Vector TargetTrackingOffset;
var private config name TargetTrackingBoneName;

function SetScriptedPatrol(name PatrolName)
{
	//native.PatrolName;	
	@NULL
}

function OnPatrolChanged()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x69
	/*@Error*/
	AggressorCommanderAction(Commander.achievingAction).OnPatrolChanged();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function PatrolList GetPatrol()
{
	return Patrol;
	return;
	@NULL
}

function name GetPatrolName()
{
	// End:0x29
	if(__NFUN_119__(Patrol, none))
	{
		return Patrol.PatrolName;
		goto J0x33;
		return 'None';
		return;
	}
	@NULL
	CommanderAction
	J0x33:

	CommanderAction
}

function bool ShouldStartOutAsMimic()
{
	return bStartOutAsMimic;
	return;
	@NULL
}

function SetMimicInitialPose(PoseData inMimicInitialPose)
{
	MimicInitialPose = inMimicInitialPose;
	return;
	@NULL
	CommanderAction
}

function PoseData GetMimicInitialPose()
{
	return MimicInitialPose;
	return;
	@NULL
}

function SetIsMimic(bool bIsNowAMimic)
{
	// End:0x2B
	if(__NFUN_130__(__NFUN_129__(bIsCurrentlyAMimic), bIsNowAMimic))
	{
		NotifyMimicVisionDesired();
		goto J0x5D;
		// End:0x5D
		if(__NFUN_130__(bIsCurrentlyAMimic, __NFUN_129__(bIsNowAMimic)))
		{
		}
		NotifyMimicVisionNoLongerDesired();
		ResumeAllAnimations();
		bIsCurrentlyAMimic = bIsNowAMimic;
		return;
		@NULL
	}
	J0x5D:

	CommanderAction
	CommanderAction
	@NULL
}

// Export UAggressor::execIsMimic(FFrame&, void* const)
native function bool IsMimic();

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x24
	if(__NFUN_130__(IsAlive(), __NFUN_129__(IsMimic())))
	{
		return 2;		
	}
	else
	{
		// End:0x37
		if(CanBeUsedNow())
		{
			return 1;			
		}
		else
		{
			return 0;
		}
	}
	return;
}

function float GetPoisonedDamageAmount()
{
	return RandRange(PoisonedAtHealthStationDamageRange.Min, PoisonedAtHealthStationDamageRange.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function int GetDesiredAnimationCapabilities()
{
	return __NFUN_158__(super.GetDesiredAnimationCapabilities(), 16);
	return;
	@NULL
}

function AddInitialKeywords()
{
	super(ShockAI).AddInitialKeywords();
	AddLocomotionKeyword('Hungry', -1);
	return;
	@NULL
}

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.AggressorCommanderAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.MimicAction');
	CharacterAI.addAbility_Class(Class'ShockAI.HealAtHealthStationAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ReactToAlertGathererAction');
	CharacterAI.addAbility_Class(Class'ShockAI.HeadTrackingAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CharacterMoveToAction');
	CharacterAI.addAbility_Class(Class'ShockAI.FleeAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function MovementAICreated()
{
	super(ShockAI).MovementAICreated();
	MovementAI.addAbility_Class(Class'ShockAI.MoveToAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function AggressorCommanderAction GetAggressorCommanderAction()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x50
	/*@Error*/
	return AggressorCommanderAction(Commander.achievingAction);
	goto J0x52;
	return none;
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function bool ApplyDeadPenalty()
{
	return __NFUN_130__(__NFUN_132__(super(ShockAI).ApplyDeadPenalty(), bIsCurrentlyAMimic), __NFUN_254__(DeadPhotoLabel, 'None'));
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function string GetFocusDisplayName()
{
	// End:0x25
	if(__NFUN_130__(IsAlive(), __NFUN_129__(IsMimic())))
	{
		return " ";		
	}
	else
	{
		return GetFriendlyName();
		return;
		@NULL
	}
}

function bool ShouldHighlightWhenFocused()
{
	// End:0x23
	if(__NFUN_130__(IsAlive(), __NFUN_129__(IsMimic())))
	{
		return false;		
	}
	else
	{
		return true;
	}
	return;
}

function NotifyCausedGathererAlert(Gatherer AlertGatherer, Protector ThreateningProtector)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x3A
	/*@Error*/
	GetAggressorCommanderAction().NotifyCausedGathererAlert(AlertGatherer, ThreateningProtector);
	return;
	@NULL
	CommanderAction
}

function NotifyGathererAlertOver(Gatherer FormerAlertGatherer, Protector FormerThreateningProtector)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x3A
	/*@Error*/
	GetAggressorCommanderAction().NotifyGathererAlertOver(FormerAlertGatherer, FormerThreateningProtector);
	return;
	@NULL
	CommanderAction
}

function NotifyThreatened(Protector ThreateningProtector)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x31
	/*@Error*/
	GetAggressorCommanderAction().NotifyProtectorThreatening(ThreateningProtector);
	return;
	@NULL
}

function NotifyKnockedBackByThreateningProtector(Protector ThreateningProtector)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x31
	/*@Error*/
	GetAggressorCommanderAction().NotifyKnockedBackByThreateningProtector(ThreateningProtector);
	return;
	@NULL
}

function name GetHealAtHealthStationAnimation(bool bIsHealthStationHacked)
{
	// End:0x27
	if(bIsHealthStationHacked)
	{
		return PoisonedAtHealthStationAnimations[__NFUN_167__(PoisonedAtHealthStationAnimations.Length)];
		goto J0x3E;
		return HealAtHealthStationAnimations[__NFUN_167__(HealAtHealthStationAnimations.Length)];
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetHealAtHealthStationTime()
{
	return RandRange(HealAtHealthStationTimeRange.Min, HealAtHealthStationTimeRange.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnAcquiredState(name StateName, Actor Instigator)
{
	local ShockPawn ShockPawnInstigator;

	super(ShockAI).OnAcquiredState(StateName, Instigator);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBF
	/*@Error*/
	ShockPawnInstigator = ShockPawn(Instigator);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xBF
	/*@Error*/
	AddForcedEnemy(ShockPawnInstigator);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

protected function bool CanHealAtHealthStation()
{
	return true;
	return;
}

function OnAIIntentionallyDamaged(Actor Damager)
{
	local float HealthPct;

	super(ShockAI).OnAIIntentionallyDamaged(Damager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB5
	/*@Error*/
	HealthPct = __NFUN_172__(Health, GetMaxHealth());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB5
	/*@Error*/
	AggressorCommanderAction(Commander.achievingAction).HealAtHealthStation();
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function OnKilled(DamageStimuliSet DamageStimuli, float TotalDamageDealt, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, bool bIsCriticalHit, optional name HitHighBone, optional name HitLowBone)
{
	// End:0x6C
	if(AggressorCommanderAction(Commander.achievingAction).IsRunningHealAtHealthStationBehavior())
	{
		ShockGameDriver(Level.GetGameDriver()).GetPlayerStatsManager().AggressorKilledGoingToHealthStation();
		super(ShockAI).OnKilled(DamageStimuli, TotalDamageDealt, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, bIsCriticalHit, HitHighBone, HitLowBone);
	}
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

// Export UAggressor::execGetUsableMimicSpot(FFrame&, void* const)
native function NavigationPoint GetUsableMimicSpot();

function bool IsSuspectingAttackFrom(ShockPawn Target)
{
	return __NFUN_130__(IsAlive(), GetAggressorCommanderAction().IsSuspectingAttackFrom(Target));
	return;
	@NULL
}

defaultproperties
{
	HealAtHealthStationAnimations[0]="GetHealthLoop"
	PoisonedAtHealthStationAnimations[0]="GetHealthHackedLoop"
	HealAtHealthStationChance=0.6600000
	HealAtHealthStationHealthPct=0.2500000
	HealAtHealthStationTimeRange=(Min=3.0000000,Max=3.0000000)
	PoisonedAtHealthStationDamageRange=(Min=300.0000000,Max=800.0000000)
	ChanceToRunAwayOnHitSpang=0.2500000
	TargetTrackingOffset=(X=0.0000000,Y=0.0000000,Z=30.0000000)
	TargetTrackingBoneName="Bip01_Spine_2"
	MinSearchTime=15.0000000
	MaxSearchTime=30.0000000
	NormalVisionDecayTime=10.0000000
	SearchingVisionDecayTime=10.0000000
	AttackingVisionDecayTime=4.0000000
	MimicVisionDecayTime=1.0000000
	BerserkVisionDecayTime=1.0000000
	PatrolVisionDecayTime=1.0000000
	NormalVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=2000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	NormalVisionCones[1]=(NearGainTime=3.0000000,FarGainTime=3.0000000,FOV=360.0000000,NearDistance=250.0000000,FarDistance=250.0000000,bIsDoubtCone=true,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	NormalVisionCones[2]=(NearGainTime=0.0100000,FarGainTime=0.1000000,FOV=40.0000000,NearDistance=500.0000000,FarDistance=700.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	NormalVisionCones[3]=(NearGainTime=0.3000000,FarGainTime=0.3000000,FOV=20.0000000,NearDistance=1000.0000000,FarDistance=1000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	NormalVisionCones[4]=(NearGainTime=0.6000000,FarGainTime=1.0000000,FOV=20.0000000,NearDistance=1800.0000000,FarDistance=2200.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	NormalVisionCones[5]=(NearGainTime=0.2000000,FarGainTime=0.2000000,FOV=100.0000000,NearDistance=1400.0000000,FarDistance=1400.0000000,bIsDoubtCone=true,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-5461,Yaw=0,Roll=0),PawnType=none)
	NormalVisionCones[6]=(NearGainTime=0.4000000,FarGainTime=0.4000000,FOV=60.0000000,NearDistance=3000.0000000,FarDistance=3000.0000000,bIsDoubtCone=true,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=2000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	SearchingVisionCones[1]=(NearGainTime=3.0000000,FarGainTime=3.0000000,FOV=360.0000000,NearDistance=250.0000000,FarDistance=250.0000000,bIsDoubtCone=true,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[2]=(NearGainTime=0.0100000,FarGainTime=0.1000000,FOV=40.0000000,NearDistance=500.0000000,FarDistance=700.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[3]=(NearGainTime=0.4000000,FarGainTime=0.4000000,FOV=20.0000000,NearDistance=1000.0000000,FarDistance=1000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[4]=(NearGainTime=0.6000000,FarGainTime=1.0000000,FOV=20.0000000,NearDistance=1800.0000000,FarDistance=2200.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[5]=(NearGainTime=0.2500000,FarGainTime=0.2500000,FOV=120.0000000,NearDistance=1400.0000000,FarDistance=1400.0000000,bIsDoubtCone=true,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-5461,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[6]=(NearGainTime=0.4500000,FarGainTime=0.4500000,FOV=60.0000000,NearDistance=3000.0000000,FarDistance=3000.0000000,bIsDoubtCone=true,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	AttackingVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=2000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	AttackingVisionCones[1]=(NearGainTime=0.1000000,FarGainTime=0.4000000,FOV=180.0000000,NearDistance=1000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	MimicVisionCones[0]=(NearGainTime=0.1000000,FarGainTime=0.1000000,FOV=360.0000000,NearDistance=400.0000000,FarDistance=400.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	BerserkVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=4000.0000000,FarDistance=4000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	BerserkVisionCones[1]=(NearGainTime=0.0100000,FarGainTime=0.0100000,FOV=360.0000000,NearDistance=4000.0000000,FarDistance=4000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	PatrolVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=2000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	PatrolVisionCones[1]=(NearGainTime=1.5000000,FarGainTime=1.5000000,FOV=360.0000000,NearDistance=250.0000000,FarDistance=250.0000000,bIsDoubtCone=true,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	PatrolVisionCones[2]=(NearGainTime=0.0100000,FarGainTime=0.3000000,FOV=20.0000000,NearDistance=500.0000000,FarDistance=1400.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	PatrolVisionCones[3]=(NearGainTime=0.2000000,FarGainTime=0.3000000,FOV=100.0000000,NearDistance=1400.0000000,FarDistance=2000.0000000,bIsDoubtCone=true,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	FlailingAnimations[0]="ThrownInAirLoop"
	JumpInWaterAnimations[0]="JumpInWater"
	ShockedAnimations[0]="ShockedLOOP"
	PostShatteredAnimations[0]="BreakIce"
	EventReactionOverrides[0]=(Event=3,Reaction=(ReactionType=3,Duration=(Min=1.5000000,Max=2.0000000),Delay=(Min=0.0000000,Max=0.3000000)))
	bConsiderAsBootyForGatherersWhenDead=true
	ShatteredDamageAmount=2000.0000000
	DefaultDamageEventInfos=/* Array type was not detected. */
	AISourceDamageEventInfoOverrides=/* Array type was not detected. */
	PlayerSourceDamageEventInfoRanges=/* Array type was not detected. */
	PlayerSourceDamageEventInfoOverrides=/* Array type was not detected. */
	DamageMultiplierSetName="AggressorDamageMultiplierSet"
	bVisionEnabled=true
	bHearingEnabled=true
	bHearingDisabledPermanently=false
	DeadFadeRadius=0.0000000
}