class Atlas extends EcologyFighter implements ICanBeHarvested
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

const NUMBER_OF_PHASES = 3;
const MIN_TIME_BETWEEN_CHARGE_DAMAGE = 3.0f;

var private config name AtlasChairLabel;
var private config Class<AIMeleeWeapon> MeleeWeaponClass;
var private config Class<AIRangedWeapon> RangedWeaponClassOne;
var private config Class<AIRangedWeapon> RangedWeaponClassTwo;
var private config Class<AIRangedWeapon> RangedWeaponClassThree;
var config name ChargeAttackPushBackEvent;
var config name TeleportAnimationName;
var config name AtlasInChairIdleAnimationName;
var config name GetUpFromChairAnimationName;
var config name GetUpFromChairNoKnockbackAnimationName;
var config name AdamDrainingInitialStabAnimationName;
var config name AdamDrainingAnimationName;
var config name ChairGetUpFromChairAnimationName;
var config name ChairGetUpFromChairNoKnockbackAnimationName;
var config name ChairAdamDrainingAnimationName;
var config name ChairAtlasInChairIdleAnimationName;
var config name ChairIdleAnimationName;
var config float RechargeThreshold;
var config float AdamDrainRate;
var config float AdamDrainDuration;
var config float HealthRechargeRate_1;
var config float HealthRechargeRate_2;
var config float HealthRechargeRate_3;
var config float MaxAdamDrainPercentage;
var config name TeleportLocationLabel;
var config name PlayerDrainPositionLabel;
var config float MaxDrainingDistance;
var config int AdamToPlayer;
var config float AdamToPlayerScaleFactor;
var config Range TeleportTimeRange;
var config float TeleportOutTelegraphTime;
var config float TeleportOutTransitionTime;
var config float TeleportInTelegraphTime;
var config float TeleportInTransitionTime;
var Actor AtlasChair;
var Actor PlayerDrainPosition;
var private AIRangedWeapon RangedWeaponOne;
var private AIRangedWeapon RangedWeaponTwo;
var private AIRangedWeapon RangedWeaponThree;
var private AIMeleeWeapon MeleeWeapon;
var int PhaseIndex;
var float LastChargeDamageTime;
var config float ChargeChance;
var config name UsingGathererToolEquipAnimationName;
var config name UsingGathererToolLoopAnimationName;
var config name UsingGathererToolUnEquipAnimationName;
var float CurrentHarvestAmount;
var float MaxHarvestAmount;
var float AdamPercentage;
var bool bInChair;
var bool bIsJumping;
var bool bAdamDraining;
var bool bTeleporting;
var bool bAdamWasDrained;
var bool bAdamDoneDraining;
var int StabHandle;
var int StabLoopHandle;
var int IdleLoopHandle;
var int ChairStabLoopHandle;
var int ChairIdleLoopHandle;
var int TeleportCounter;
var int KnockBackCounter;
var int AdamDrainCounter;
var float AdamDrainStartTime;
var int NumTimesAdamDrainCompleted;
var float FlashTweenStartTime;
var float FlashTweenTotalTime;
var config float StartFlashRate;
var config float EndFlashRate;

function Actor GetTeleportPoint()
{
	return findByLabel(Class'Engine.Actor', TeleportLocationLabel);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Actor GetAtlasChair()
{
	return findByLabel(Class'Engine.Actor', AtlasChairLabel);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function Actor GetPlayerDrainPosition()
{
	return findByLabel(Class'Engine.Actor', PlayerDrainPositionLabel);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

// Export UAtlas::execCanBeDamaged(FFrame&, void* const)
native function bool CanBeDamaged();

function bool IsAtDrainingPosition(Pawn Player)
{
	return __NFUN_176__(VSizeSquared2D(__NFUN_216__(Player.Location, PlayerDrainPosition.Location)), __NFUN_171__(MaxDrainingDistance, MaxDrainingDistance));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool IsChargingOrPreparingToCharge()
{
	local int i;
	local ChargeAttackGoal ChargeGoal;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9E
	/*@Error*/
	ChargeGoal = ChargeAttackGoal(CharacterAI.goals[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x90
	/*@Error*/
	return true;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Tick(float DeltaTime)
{
	local ShockPlayerController PC;

	super(Actor).Tick(DeltaTime);
	PC = ShockPlayerController(Level.GetLocalPlayerController());
	// End:0x6C
	if(bInChair)
	{
		AddHealth(__NFUN_171__(DeltaTime, GetHealthRechargeRate()));
		goto J0x80;
		UpdateNeedleHUD_VisualFlashEffect(DeltaTime, false);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1F1
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1AB
		/*@Error*/
	}
	// End:0x15B
	if(__NFUN_130__(__NFUN_129__(bAdamWasDrained), __NFUN_177__(Level.TimeSeconds, __NFUN_174__(AdamDrainStartTime, AdamDrainDuration))))
	{
		__NFUN_185__(AdamPercentage, MaxAdamDrainPercentage);
		ShockPlayer(PC.Pawn).AddADAM(AdamToPlayer);
		bAdamWasDrained = true;
		UpdateNeedleHUD_VisualDrainEffect(0.0000000);
		__NFUN_163__(NumTimesAdamDrainCompleted);
		bAdamDoneDraining = true;
		goto J0x1AB;
		UpdateNeedleHUD_VisualDrainEffect(__NFUN_171__(__NFUN_246__(__NFUN_175__(1.0000000, __NFUN_172__(__NFUN_175__(Level.TimeSeconds, AdamDrainStartTime), AdamDrainDuration)), 0.0000000, 1.0000000), 100.0000000));
		PC.StartForcePlayerMove(PlayerDrainPosition.Location, PlayerDrainPosition.Rotation);
	}
	goto J0x229;
	PC.StopForcePlayerMove();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x229
	/*@Error*/
	UpdateNeedleHUD_VisualFlashEffect(DeltaTime, true);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function PostBeginPlay()
{
	super(ShockAI).PostBeginPlay();
	AtlasChair = GetAtlasChair();
	PlayerDrainPosition = GetPlayerDrainPosition();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function int GetDesiredAnimationCapabilities()
{
	return __NFUN_158__(super.GetDesiredAnimationCapabilities(), 16);
	return;
	@NULL
}

function bool DisallowHeadTracking()
{
	return bTeleporting;
	return;
	@NULL
}

function bool CanPlayQuickHitReaction()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(bTeleporting), __NFUN_129__(bInChair)), __NFUN_129__(bIsJumping)), super(ShockAI).CanPlayQuickHitReaction());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanPlayFullBodyHitReaction()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(bTeleporting), __NFUN_129__(bInChair)), __NFUN_129__(bIsJumping)), __NFUN_129__(IsChargingOrPreparingToCharge())), super(ShockAI).CanPlayFullBodyHitReaction());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

event OnAnimationEnded(int AnimationInstanceHandle)
{
	return;
}

function StartIdleLoop()
{
	IdleLoopHandle = PlayAnimationOnChannel(0, AtlasInChairIdleAnimationName, Class'Engine.Actor'.8);
	ChairIdleLoopHandle = AtlasChair.PlayAnimationOnChannel(0, ChairAtlasInChairIdleAnimationName, Class'Engine.Actor'.8);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function InstantStartIdleLoop()
{
	IdleLoopHandle = PlayAnimationOnChannelInstantEaseIn(0, AtlasInChairIdleAnimationName, Class'Engine.Actor'.8);
	ChairIdleLoopHandle = AtlasChair.PlayAnimationOnChannelInstantEaseIn(0, ChairAtlasInChairIdleAnimationName, Class'Engine.Actor'.8);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function StartStabLoop()
{
	StabLoopHandle = PlayAnimationOnChannel(0, AdamDrainingAnimationName, Class'Engine.Actor'.8);
	ChairStabLoopHandle = AtlasChair.PlayAnimationOnChannel(0, ChairAdamDrainingAnimationName, Class'Engine.Actor'.8);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Material GetTeleportInTelegraphShader()
{
	switch(PhaseIndex)
	{
		// End:0x19
		case 0:
			return TeleportInTelegraphShaderFire;
			// End:0x27
			case 1:
				return TeleportInTelegraphShaderIce;
			// End:0x36
			case 2:
				return TeleportInTelegraphShaderLightning;
				// End:0xFFFF
				default:
					break;/* Tried to find Switch scope, found Case instead */
			return;
			@NULL
			CommanderAction
			CommanderAction
		@NULL
}

function Material GetTeleportInTransitionShader()
{
	switch(PhaseIndex)
	{
		// End:0x19
		case 0:
			return TeleportInTransitionShaderFire;
			// End:0x27
			case 1:
				return TeleportInTransitionShaderIce;
			// End:0x36
			case 2:
				return TeleportInTransitionShaderLightning;
				// End:0xFFFF
				default:
					break;/* Tried to find Switch scope, found Case instead */
			return;
			@NULL
			CommanderAction
			CommanderAction
		@NULL
}

function Material GetTeleportOutTransitionShader()
{
	switch(PhaseIndex)
	{
		// End:0x19
		case 0:
			return TeleportOutTransitionShaderFire;
			// End:0x27
			case 1:
				return TeleportOutTransitionShaderIce;
			// End:0x36
			case 2:
				return TeleportOutTransitionShaderLightning;
				// End:0xFFFF
				default:
					break;/* Tried to find Switch scope, found Case instead */
			return;
			@NULL
			CommanderAction
			CommanderAction
		@NULL
}

function Material GetNormalSkin()
{
	switch(PhaseIndex)
	{
		// End:0x19
		case 0:
			return AtlasSkinFire;
			// End:0x27
			case 1:
				return AtlasSkinIce;
			// End:0x36
			case 2:
				return AtlasSkinLightning;
				// End:0xFFFF
				default:
					break;/* Tried to find Switch scope, found Case instead */
			return;
			@NULL
			CommanderAction
			CommanderAction
		@NULL
}

function float GetHealthRechargeRate()
{
	switch(PhaseIndex)
	{
		// End:0x19
		case 0:
			return HealthRechargeRate_1;
			// End:0x27
			case 1:
				return HealthRechargeRate_2;
			// End:0x36
			case 2:
				return HealthRechargeRate_3;
				// End:0xFFFF
				default:
					break;/* Tried to find Switch scope, found Case instead */
			return;
			@NULL
			CommanderAction
			CommanderAction
		@NULL
}

function AddInitialKeywords()
{
	super(ShockAI).AddInitialKeywords();
	return;
	@NULL
}

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.AtlasCommanderAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ChargeAttackAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.CharacterMoveToAction');
	CharacterAI.addAbility_Class(Class'ShockAI.AtlasAttackAction');
	CharacterAI.addAbility_Class(Class'ShockAI.HeadTrackingAction');
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

// Export UAtlas::execGetAtlasCommanderAction(FFrame&, void* const)
protected native function AtlasCommanderAction GetAtlasCommanderAction();

// Export UAtlas::execGetRangedWeapon(FFrame&, void* const)
native function AIRangedWeapon GetRangedWeapon();

function AIMeleeWeapon GetMeleeWeapon()
{
	return MeleeWeapon;
	return;
	@NULL
}

function CreateWeapons()
{
	assert(__NFUN_119__(RangedWeaponClassOne, none));
	assert(__NFUN_119__(RangedWeaponClassTwo, none));
	assert(__NFUN_119__(RangedWeaponClassThree, none));
	RangedWeaponOne = AIRangedWeapon(CreateAIWeapon(RangedWeaponClassOne));
	AddAvailableHoldable(RangedWeaponOne);
	RangedWeaponTwo = AIRangedWeapon(CreateAIWeapon(RangedWeaponClassTwo));
	AddAvailableHoldable(RangedWeaponTwo);
	RangedWeaponThree = AIRangedWeapon(CreateAIWeapon(RangedWeaponClassThree));
	AddAvailableHoldable(RangedWeaponThree);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x15E
	/*@Error*/
	MeleeWeapon = AIMeleeWeapon(CreateAIWeapon(MeleeWeaponClass));
	AddAvailableHoldable(MeleeWeapon);
	AttachToBone(MeleeWeapon, MeleeWeapon.GetAttachBone(self));
	Equip(MeleeWeapon);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function ChargeAttackPush(Actor Other)
{
	local ShockPlayer Pushee;
	local DamageStimuliSet StimuliSet;

	Pushee = ShockPlayer(OnPushGetPushee());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x14D
	/*@Error*/
	Pushee.OnPushed(ChargeAttackPushBackEvent, self);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x14D
	/*@Error*/
	StimuliSet = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet('AtlasChargeStimuliSet');
	Pushee.TakeDamage(StimuliSet, 0.0000000, self, vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), 'None', 1.0000000);
	LastChargeDamageTime = Level.TimeSeconds;
	StimuliSet.__NFUN_200__();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x24
	if(__NFUN_130__(IsAlive(), __NFUN_129__(bInChair)))
	{
		return 2;
		goto J0x3A;
		// End:0x37
		if(CanBeUsedNow())
		{
		}
		return 1;
		goto J0x3A;
		return 0;
		return;
	}
	@NULL
}

function NewPhase()
{
	assert(__NFUN_150__(PhaseIndex, 3));
	PhaseIndex = int(__NFUN_173__(float(__NFUN_146__(PhaseIndex, 1)), float(3)));
	SetSkin(0, GetNormalSkin());
	CurrentHarvestAmount = 0.0000000;
	return;
	@NULL
	EcologyCommanderAction
	CommanderAction
	@NULL
}

function bool CanBeUsedNow()
{
	local ShockPlayer Player;

	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(bInChair, __NFUN_129__(Player.IsBusy())), IsAtDrainingPosition(Player)), __NFUN_119__(Player.GetHarvestingTarget(), self));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnUsed(Pawn Pawn)
{
	AssertWithDescription(Pawn.__NFUN_303__('ShockPlayer'), __NFUN_112__(string(Class.Name), " was used by someone other than a ShockPlayer."));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF3
	/*@Error*/
	ShockPlayer(Pawn).DisableReticle();
	Level.GetLocalPlayerController().ConsoleCommand("PUSHINPUTCONTEXT NullInput");
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnNeedleInserted(Hands Hands)
{
	Hands.GetGathererTool().TriggerEffectEvent('AtlasNeedleInserted');
	StartStabLoop();
	return;
	@NULL
}

function OnNeedleRemoved(Hands Hands)
{
	Hands.GetGathererTool().UnTriggerEffectEvent('AtlasNeedleInserted');
	return;
	@NULL
}

function OnHarvestingStarted(Hands Hands)
{
	bAdamDraining = true;
	AdamDrainStartTime = Level.TimeSeconds;
	__NFUN_165__(AdamDrainCounter);
	dispatchMessage(Class'ShockAI.MessageAtlasAdamDrainStarted'.static.Allocate(self)., construct_Int(AdamDrainCounter));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnHarvestingFinished(Hands Hands)
{
	bAdamDraining = false;
	bAdamDoneDraining = false;
	ShockPlayer(Level.GetLocalPlayerController().Pawn).EnableReticle();
	// End:0x76
	if(__NFUN_153__(AdamDrainCounter, 2))
	{
		PlaySpeech('7_Ft_Recharge');
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x8D
		/*@Error*/
		StartIdleLoop();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
	@NULL
}

function float GetHarvestingTime(Hands Hands)
{
	return 10000000.0000000;
	return;
}

function float GetCurrentHarvestAmount(Hands Hands)
{
	return CurrentHarvestAmount;
	return;
	@NULL
}

function float GetMaxHarvestAmount(Hands Hands)
{
	return MaxHarvestAmount;
	return;
	@NULL
}

function OnHarvestedAmount(float AmountHarvested)
{
	__NFUN_184__(CurrentHarvestAmount, AmountHarvested);
	return;
	@NULL
	CommanderAction
}

function name GetHandEquippingAnimationName(Hands Hands)
{
	return UsingGathererToolEquipAnimationName;
	return;
	@NULL
}

function name GetHandLoopingAnimationName(Hands Hands)
{
	return UsingGathererToolLoopAnimationName;
	return;
	@NULL
}

function name GetHandUnequippingAnimationName(Hands Hands)
{
	return UsingGathererToolUnEquipAnimationName;
	return;
	@NULL
}

function bool ShouldPushHarvestingContext()
{
	return false;
	return;
}

function UpdateNeedleHUD_VisualFlashEffect(float DeltaTime, bool bOn)
{
	//native.DeltaTime;
	//native.bOn;	
	@NULL
	@NULL
}

function UpdateNeedleHUD_VisualDrainEffect(float VolumePercent)
{
	//native.VolumePercent;	
	@NULL
}

defaultproperties
{
	AtlasChairLabel="MegaPlasmidMachine_1"
	MeleeWeaponClass=Class'ShockAI.AtlasMeleeWeapon'
	RangedWeaponClassOne=Class'ShockAI.AtlasRangedWeaponOne'
	RangedWeaponClassTwo=Class'ShockAI.AtlasRangedWeaponTwo'
	RangedWeaponClassThree=Class'ShockAI.AtlasRangedWeaponThree'
	ChargeAttackPushBackEvent="PushedBackByAtlas"
	TeleportAnimationName="AT_teleport"
	AtlasInChairIdleAnimationName="AT_machineidle"
	GetUpFromChairAnimationName="AT_machinereleasemelee"
	GetUpFromChairNoKnockbackAnimationName="AT_machinerelease"
	AdamDrainingInitialStabAnimationName="AT_stab"
	AdamDrainingAnimationName="AT_stabloop"
	ChairGetUpFromChairAnimationName="MPM_machinereleasemelee"
	ChairGetUpFromChairNoKnockbackAnimationName="MPM_machinerelease"
	ChairAdamDrainingAnimationName="MPM_stabloop"
	ChairAtlasInChairIdleAnimationName="MPM_machineidle"
	ChairIdleAnimationName="MPM_empty"
	RechargeThreshold=1.0000000
	AdamDrainRate=0.0200000
	AdamDrainDuration=4.0000000
	HealthRechargeRate_1=240.0000000
	HealthRechargeRate_2=240.0000000
	HealthRechargeRate_3=240.0000000
	MaxAdamDrainPercentage=0.2500000
	TeleportLocationLabel="AtlasTeleport"
	PlayerDrainPositionLabel="PlayerDrainPosition"
	MaxDrainingDistance=80.0000000
	AdamToPlayer=250
	AdamToPlayerScaleFactor=10.0000000
	TeleportOutTelegraphTime=1.7500000
	TeleportOutTransitionTime=0.5000000
	TeleportInTelegraphTime=0.4000000
	TeleportInTransitionTime=1.0000000
	ChargeChance=0.8000000
	UsingGathererToolEquipAnimationName="EquipAdamGun"
	UsingGathererToolLoopAnimationName="FidgetAdamGun"
	UsingGathererToolUnEquipAnimationName="UnequipAdamGun"
	MaxHarvestAmount=1000.0000000
	AdamPercentage=1.0000000
	StartFlashRate=5.0000000
	EndFlashRate=1.0000000
	bCanSearch=false
	MinSearchTime=15.0000000
	MaxSearchTime=30.0000000
	UnintentionalDamageAggroPercentage=0.1500000
	AggroTargetTypeWeights[0]=(TargetTypeClass=Class'ShockAI.DecoyHumanAI',TargetWeight=15.0000000)
	AggroTargetTypeWeights[1]=(TargetTypeClass=Class'ShockAI.SecurityBot',TargetWeight=5.0000000)
	AggroTargetTypeWeights[2]=(TargetTypeClass=Class'ShockAI.SecurityCamera',TargetWeight=0.0000000)
	AggroTargetTypeWeights[3]=(TargetTypeClass=Class'ShockAI.Turret',TargetWeight=5.0000000)
	AggroTargetTypeWeights[4]=(TargetTypeClass=Class'ShockAI.Aggressor',TargetWeight=3.0000000)
	AggroTargetTypeWeights[5]=(TargetTypeClass=Class'ShockAI.Protector',TargetWeight=3.0000000)
	AggroTargetTypeWeights[6]=(TargetTypeClass=Class'ShockGame.ShockPlayer',TargetWeight=0.0000000)
	AggroTargetTypeWeights[7]=(TargetTypeClass=Class'ShockAI.Gatherer',TargetWeight=0.0000000)
	FriendlyName="Fontaine"
	UseVerbText="Drain Adam"
	MinDistanceFromLastKnownLocationToLoseTarget=300.0000000
	NormalVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=2000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	NormalVisionCones[1]=(NearGainTime=0.0100000,FarGainTime=0.0100000,FOV=360.0000000,NearDistance=4000.0000000,FarDistance=4000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	SearchingVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=2000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	SearchingVisionCones[1]=(NearGainTime=0.0100000,FarGainTime=0.0100000,FOV=360.0000000,NearDistance=4000.0000000,FarDistance=4000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	AttackingVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=2000.0000000,FarDistance=2000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	AttackingVisionCones[1]=(NearGainTime=0.0100000,FarGainTime=0.0100000,FOV=360.0000000,NearDistance=4000.0000000,FarDistance=4000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=none)
	BerserkVisionCones[0]=(NearGainTime=0.0000000,FarGainTime=0.0000000,FOV=360.0000000,NearDistance=4000.0000000,FarDistance=4000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=0,Yaw=0,Roll=0),PawnType=Class'ShockAI.DecoyHumanAI')
	BerserkVisionCones[1]=(NearGainTime=0.0100000,FarGainTime=0.0100000,FOV=360.0000000,NearDistance=4000.0000000,FarDistance=4000.0000000,bIsDoubtCone=false,PeripheralVision=0.0000000,ViewDirectionOffset=(Pitch=-3641,Yaw=0,Roll=0),PawnType=none)
	HitFrontAnimations[0]="AT_hitFWD_A"
	HitFrontAnimations[1]="AT_hitFWD_B"
	HitLeftAnimations[0]="AT_HitLEFT_A"
	HitLeftAnimations[1]="AT_HitLEFT_B"
	HitRightAnimations[0]="AT_HitRIGHT_A"
	HitRightAnimations[1]="AT_HitRIGHT_B"
	HitBackAnimations[0]="AT_hitBWD_A"
	HitBackAnimations[1]="AT_hitBWD_B"
	ShockedAnimations[0]="AT_ShockedLOOP"
	PostShatteredAnimations[0]="AT_BreakIce"
	EyeBoneName="KBone_L_eye"
	bShouldUseLocomotion=true
	bShouldUseFootIKTracker=true
	bShouldUseQuickHitReaction=true
	bCanTeleport=true
	bHasRangedAttack=true
	bPlayAnimationInsteadOfRagdollFall=true
	DamageResistanceSetName="AtlasResistanceSet"
	MaxHealth=4000.0000000
	MaxFrozenHealth=4000.0000000
	ShatteredDamageAmount=150.0000000
	DefaultDamageEventInfos=/* Array type was not detected. */
	AISourceDamageEventInfoOverrides=/* Array type was not detected. */
	CriticalHitDamageEvent=2
	PlayerSourceDamageEventInfoRanges=/* Array type was not detected. */
	PlayerSourceDamageEventInfoOverrides=/* Array type was not detected. */
	bVisionEnabled=true
	bHearingEnabled=true
	bHearingDisabledPermanently=false
	Health=4000.0000000
	CollisionRadius=80.0000000
	CollisionHeight=144.0000000
	bRotateToDesired=false
}