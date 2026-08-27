class EcologyFighter extends EcologyAI
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

struct native atomic UnreachableTargetInfo
{
	var ShockPawn UnreachableTarget;
	var float UnreachableTime;
	var float LastUnreachableTime;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic AggroTargetTypeWeight
{
	var config Class<ShockPawn> TargetTypeClass;
	var config float TargetWeight;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic AggroDamageInfo
{
	var ShockPawn Target;
	var float TargetDamageDone;
	var float LastTimeDamaged;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var const Actor SpawnPoint;
var array<ShockPawn> ForcedEnemies;
var private bool bCanAttack;
var private bool bCanSearch;
var array<name> TargetsToAttackOnSight;
var config array<name> SearchAnimations;
var private config float MinSearchTime;
var private config float MaxSearchTime;
var private config float DistanceToRunWhileSearching;
var private config float UnintentionalDamageAggroPercentage;
var array<UnreachableTargetInfo> UnreachableTargetInfos;
var private config float UnreachableTargetRecentTime;
var private config float UnreachableTargetAttackTimeout;
var private float LastTimeCheckedMoveToUnreachableTarget;
var private config float MinTimeBetweenUnreachableChecks;
var private config float MinTimeBetweenUnreachableTargetChecks;
var private config float AggroDistanceNumerator;
var private config float AggroDistanceMultiplier;
var private config Range AggroDistanceWeightRange;
var array<AggroDamageInfo> AggroDamageInfos;
var private config Range AggroDamageRange;
var private config float AggroVisibleTargetWeight;
var config array<AggroTargetTypeWeight> AggroTargetTypeWeights;
var private config float AggroTargetTypeOtherWeight;
var private config float AggroWeightBonusForCurrentTarget;
var private config float AggroWeightBonusWhenBerserkNonPlayerTarget;

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.MoveToSpawnPointAction');
	CharacterAI.addAbility_Class(Class'ShockAI.PatrolAction');
	CharacterAI.addAbility_Class(Class'ShockAI.SearchAction');
	CharacterAI.addAbility_Class(Class'ShockAI.InvestigateAction');
	CharacterAI.addAbility_Class(Class'ShockAI.FrozenAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ShockedAction');
	CharacterAI.addAbility_Class(Class'ShockAI.FullBodyReactionAction');
	CharacterAI.addAbility_Class(Class'ShockAI.BurningAction');
	CharacterAI.addAbility_Class(Class'ShockAI.ReactToSwarmAction');
	CharacterAI.addSensorActionClass(Class'ShockAI.VisionSensorAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function PreLevelTravel()
{
	super(ShockAI).PreLevelTravel();
	// End:0x6C
	if(__NFUN_130__(__NFUN_130__(IsAlive(), __NFUN_119__(Commander, none)), __NFUN_119__(Commander.achievingAction, none)))
	{
		Commander.achievingAction.instantFail(1);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC4
		/*@Error*/
		ClearForcedEnemies();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC4
		/*@Error*/
	}
	__NFUN_267__(SpawnPoint.Location);
	__NFUN_299__(SpawnPoint.Rotation);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function bool CanSearch()
{
	return __NFUN_177__(MaxSearchTime, 0.0000000);
	return;
	@NULL
}

function bool IsAtSpawnPoint()
{
	return __NFUN_130__(__NFUN_119__(SpawnPoint, none), ReachedDestination(SpawnPoint));
	return;
	@NULL
	CommanderAction
}

function bool CanAttack()
{
	return bCanAttack;
	return;
	@NULL
}

function SetCanAttack(bool inCanAttack)
{
	bCanAttack = inCanAttack;
	return;
	@NULL
	EcologyCommanderAction
}

function ResetAttackTarget(ShockPawn Target)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x94
	/*@Error*/
	// End:0x81
	if(__NFUN_130__(__NFUN_130__(IsAlive(), __NFUN_119__(Commander, none)), __NFUN_119__(Commander.achievingAction, none)))
	{
		EcologyFighterCommanderAction(Commander.achievingAction).ResetAttackTarget(Target);
		OnAttackTargetReset(Target);
		return;
		@NULL
		EcologyCommanderAction
		CommanderAction
	}
	@NULL
}

function OnAttackTargetReset(ShockPawn Target)
{
	return;
}

function AddForcedEnemy(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function RemoveForcedEnemy(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function IsForcedEnemy(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function ClearForcedEnemies()
{
	ForcedEnemies.Remove(0, ForcedEnemies.Length);
	return;
	@NULL
	CommanderAction
}

function AddTargetToAttackOnSight(name TargetLabel)
{
	//native.TargetLabel;	
	@NULL
}

function bool IsTargetToAttackOnSight(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function Investigate(Vector InvestigateLocation, Vector InvestigateDirection)
{
	EcologyFighterCommanderAction(Commander.achievingAction).Investigate(InvestigateLocation, InvestigateDirection);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function NotifyAboutToBeAttackedByAnotherAI(ShockAI Attacker)
{
	AddForcedEnemy(Attacker);
	return;
	@NULL
}

function int GetDesiredAnimationCapabilities()
{
	return __NFUN_158__(super(ShockAI).GetDesiredAnimationCapabilities(), 64);
	return;
	@NULL
}

function OnHitByAirBlast()
{
	local ShockPlayer Player;

	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6D
	/*@Error*/
	AddForcedEnemy(Player);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnHitBySpringboardTrap()
{
	local ShockPlayer Player;

	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6D
	/*@Error*/
	AddForcedEnemy(Player);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function UpdateIntentionalDamage(Actor Damager, DamageStimuliSet DamageStimuli, float TotalDamageDealt)
{
	local ShockPawn ShockPawnDamager;

	super(ShockAI).UpdateIntentionalDamage(Damager, DamageStimuli, TotalDamageDealt);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9D
	/*@Error*/
	ShockPawnDamager = ShockPawn(Damager);
	AddDamager(ShockPawnDamager, TotalDamageDealt, AttackerShouldBeConsideredIntentional(ShockPawnDamager));
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function AddDamager(ShockPawn Damager, float DamageDealt, bool bAttackerShouldBeConsideredIntentional)
{
	//native.Damager;
	//native.DamageDealt;
	//native.bAttackerShouldBeConsideredIntentional;	
	@NULL
	BioshockCharacterAction
	return default.@NULL;
}

function bool GetLastTimeDamagedByDamager(ShockPawn Damager, out float LastTimeDamaged)
{
	//native.Damager;
	//native.LastTimeDamaged;	
	@NULL
	BioshockCharacterAction
}

function AddUnreachableTarget(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function RemoveUnreachableTarget(ShockPawn Target)
{
	//native.Target;	
	@NULL
}

function bool HasTargetBeenUnreachableForACertainAmountOfTime(ShockPawn Target, float UnreachableTargetTime)
{
	//native.Target;
	//native.UnreachableTargetTime;	
	@NULL
	@NULL
}

function name GetSearchAnimation()
{
	return SearchAnimations[__NFUN_167__(SearchAnimations.Length)];
	return;
	@NULL
	CommanderAction
}

function bool ShouldRunWhileInvestigating()
{
	return false;
	return;
}

function float GetSearchTime()
{
	return RandRange(MinSearchTime, MaxSearchTime);
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function float GetDistanceToRunWhileSearching()
{
	return DistanceToRunWhileSearching;
	return;
	@NULL
}

defaultproperties
{
	bCanAttack=true
	bCanSearch=true
	MinSearchTime=12.0000000
	MaxSearchTime=20.0000000
	DistanceToRunWhileSearching=2000.0000000
	UnintentionalDamageAggroPercentage=0.5000000
	UnreachableTargetRecentTime=5.0000000
	UnreachableTargetAttackTimeout=15.0000000
	MinTimeBetweenUnreachableChecks=0.2500000
	MinTimeBetweenUnreachableTargetChecks=2.5000000
	AggroDistanceNumerator=500.0000000
	AggroDistanceMultiplier=1.0000000
	AggroDistanceWeightRange=(Min=0.0000000,Max=1.0000000)
	AggroDamageRange=(Min=0.0000000,Max=7.0000000)
	AggroVisibleTargetWeight=1.0000000
	AggroTargetTypeWeights[0]=(TargetTypeClass=Class'ShockAI.DecoyHumanAI',TargetWeight=15.0000000)
	AggroTargetTypeWeights[1]=(TargetTypeClass=Class'ShockAI.SecurityBot',TargetWeight=5.0000000)
	AggroTargetTypeWeights[2]=(TargetTypeClass=Class'ShockAI.SecurityCamera',TargetWeight=5.0000000)
	AggroTargetTypeWeights[3]=(TargetTypeClass=Class'ShockAI.Turret',TargetWeight=5.0000000)
	AggroTargetTypeWeights[4]=(TargetTypeClass=Class'ShockAI.Aggressor',TargetWeight=3.0000000)
	AggroTargetTypeWeights[5]=(TargetTypeClass=Class'ShockAI.Protector',TargetWeight=3.0000000)
	AggroTargetTypeWeights[6]=(TargetTypeClass=Class'ShockGame.ShockPlayer',TargetWeight=1.0000000)
	AggroTargetTypeWeights[7]=(TargetTypeClass=Class'ShockAI.Gatherer',TargetWeight=0.0000000)
	AggroTargetTypeOtherWeight=1.0000000
	AggroWeightBonusForCurrentTarget=1.0000000
	AggroWeightBonusWhenBerserkNonPlayerTarget=15.0000000
	bOptimizeAIPhysicsAtLowDetail=true
	OptimizedPhysicsWalkSpeed=200.0000000
	OptimizedPhysicsRunSpeed=450.0000000
	TargetBumpDetectionTime=2.0000000
	ShadowMapScale=2.0000000
	bBlockActors=true
}