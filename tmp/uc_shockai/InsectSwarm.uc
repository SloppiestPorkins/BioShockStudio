class InsectSwarm extends ShockAI
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var private config float BaseTimeToLive;
var private float ExpirationTime;
var private config float AttackRange;
var private config Range AttackTimeDelta;
var private config float DamagePerSecond;
var private config name DamageStimuliSetName;
var private config float DispersePercentage;
var private config Class<Emitter> SwarmEmitterClass;
var private Emitter SwarmEmitterInstance;
var private config float SwarmRadius;
var const config float InitialMovementDistance;
var ShockPawn CurrentAttackTarget;
var ShockPawn ForcedAttackTarget;
var ShockPlayer SwarmPlayerOwner;
var private transient pointer HavokPhantom;

function PostBeginPlay()
{
	super.PostBeginPlay();
	return;
	@NULL
}

function AddCommanderAbility()
{
	assert(__NFUN_119__(CharacterAI, none));
	CharacterAI.addAbility_Class(Class'ShockAI.InsectSwarmCommanderAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function CharacterAICreated()
{
	super.CharacterAICreated();
	CharacterAI.addAbility_Class(Class'ShockAI.InsectSwarmSearchAction');
	CharacterAI.addAbility_Class(Class'ShockAI.InsectSwarmAttackAction');
	CharacterAI.addAbility_Class(Class'ShockAI.CharacterMoveToAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function MovementAICreated()
{
	super.MovementAICreated();
	MovementAI.addAbility_Class(Class'ShockAI.MoveToAction');
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
}

function SetSwarmPlayerOwner(ShockPlayer inSwarmPlayerOwner)
{
	assert(__NFUN_119__(inSwarmPlayerOwner, none));
	SwarmPlayerOwner = inSwarmPlayerOwner;
	return;
	@NULL
	CommanderAction
	CommanderAction
}

function ScriptedAttackTarget(ShockPawn Target)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x74
	/*@Error*/
	ForcedAttackTarget = Target;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x74
	/*@Error*/
	InsectSwarmCommanderAction(Commander.achievingAction).FindNewAttackTarget();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SpawnSwarm()
{
	TriggerEffectEvent('Spawned');
	TriggerEffectEvent('Swarming');
	SwarmEmitterInstance = __NFUN_278__(SwarmEmitterClass);
	assert(__NFUN_119__(SwarmEmitterInstance, none));
	SwarmEmitterInstance.__NFUN_298__(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function DisperseSwarm()
{
	// End:0x36
	if(__NFUN_119__(SwarmEmitterInstance, none))
	{
		SwarmEmitterInstance.LifeSpan = -1.0000000;
		SwarmEmitterInstance = none;
		ExpirationTime = 0.0000000;
		UnTriggerEffectEvent('Swarming');
	}
	TriggerEffectEvent('Dispersed');
	__NFUN_113__('Dead');
	__NFUN_279__();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function Destroyed()
{
	// End:0x36
	if(__NFUN_119__(SwarmEmitterInstance, none))
	{
		SwarmEmitterInstance.LifeSpan = -1.0000000;
		SwarmEmitterInstance = none;
		UnTriggerEffectEvent('Swarming');
	}
	super.Destroyed();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function LimitNumberOfInsectSwarms(InsectSwarm newInsectSwarm)
{
	//native.newInsectSwarm;	
	@NULL
}

function float GetBaseTimeToLive()
{
	return BaseTimeToLive;
	return;
	@NULL
}

function float GetExpirationTime()
{
	return ExpirationTime;
	return;
	@NULL
}

function float GetAttackRange()
{
	return AttackRange;
	return;
	@NULL
}

function Range GetAttackTimeDelta()
{
	return AttackTimeDelta;
	return;
	@NULL
}

function float GetRandomAttackTimeDelta()
{
	return RandRange(AttackTimeDelta.Min, AttackTimeDelta.Max);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetDamagePerSecond()
{
	return ShockPlayer(Level.GetLocalPlayerController().Pawn).ModifyStat('InsectSwarmDPS_Bonus', DamagePerSecond);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetHealthPercentage()
{
	return __NFUN_172__(GetHealth(), GetMaxHealth());
	return;
}

function name GetDamageStimuliSetName()
{
	return DamageStimuliSetName;
	return;
	@NULL
}

function UpdateTimeToLive(ShockPlayer Instigator)
{
	BaseTimeToLive = Instigator.ModifyStat('InsectSwarmLifespan_Bonus', GetBaseTimeToLive());
	return;
	@NULL
	CommanderAction
}

state CheckingForExpiration
{Begin:

	LimitNumberOfInsectSwarms(self);
	SpawnSwarm();
	ExpirationTime = __NFUN_174__(Level.TimeSeconds, BaseTimeToLive);
	// End:0x6F
	if(__NFUN_177__(ExpirationTime, Level.TimeSeconds))
	{
		__NFUN_256__(0.5000000);
		// [Loop Continue]
		goto J0x40;
		DisperseSwarm();
		stop;				
	}
	@NULL
	@NULL
	@NULL
	@NULL
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	/*@Error*/
}

state Dead
{Begin:

	__NFUN_279__();
	stop;				
}

defaultproperties
{
	BaseTimeToLive=25.0000000
	AttackRange=30.0000000
	AttackTimeDelta=(Min=0.1000000,Max=0.4000000)
	DamagePerSecond=10.0000000
	DispersePercentage=0.3000000
	SwarmRadius=50.0000000
	InitialMovementDistance=100.0000000
	bShouldApplyDisplacement=false
	bDropToGroundUponSpawning=false
	bVisionEnabled=true
	bUseQuickVision=true
	bCanFly=true
	bUseHavokPhantomCollisions=false
	bRollToDesired=true
	FlyAccelRate=1024.0000000
	Physics=6
	CollisionRadius=20.0000000
	CollisionHeight=40.0000000
	bCollideActors=false
	bBlockPlayers=false
	bBlockZeroExtentTraces=false
	bBlockNonZeroExtentTraces=false
	bUseCylinderCollision=false
}