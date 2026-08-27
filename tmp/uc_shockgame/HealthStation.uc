class HealthStation extends DispenserMachine implements IDamagee
	native
	config(Machines)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

struct native atomic DropChance
{
	var() int NumberOfHypos "The number of hypo to drop";
	var() int Chance "The chance of this number of hypo being spawned";
};

var(Machine) private config float HealAmount;
var(Machine) private config StaticMesh BrokenStaticMesh;
var(Machine) private config SkeletalMesh BrokenMesh;
var private config localized string UsedFeedbackTextFullHealth;
var(Machine) private config name AnimBrokenStarted;
var(Machine) private config name AnimBrokenLoop;
var(Machine) private config Class<Item> HypoItemClass;
var(Machine) private config Class<Pickup> HypoPickupClass;
var(Machine) config array<DropChance> HypoDropChance;
var(Machine) bool bUsableByAIs;
var private config float Health;
var private config localized string BrokenString;
var private BaseShockAI CurrentAI;
var config string AggressorUsePointSocketName;
var /*0x00000000-0x01000000*/ const PathNode AggressorUseNavigationPoint;

function bool CanInteractWithAI()
{
	return false;
	return;
}

function SetUsableByAIs(bool inUsableByAIs)
{
	bUsableByAIs = inUsableByAIs;
	return;
	@NULL
	Item
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	Player.TriggerEffectEvent('MedStationHackSucceeded');
	return super(ShockMachine).OnHackSucceeded(Player, HackResult);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnAIInteract(BaseShockAI theAI)
{
	log('Machines', 3, __NFUN_112__(string(self), ": AI began interaction with machine"));
	assert(CanInteractWithAI());
	CurrentAI = theAI;
	__NFUN_113__('AIInteracting');
	return;
	@NULL
	Item
}

// Export UHealthStation::execSpawnHypos(FFrame&, void* const)
private native function SpawnHypos();

function bool IsBroken()
{
	return false;
	return;
}

function TakeDamage(DamageStimuliSet DamageStimuli, float CritChance, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, float DamageAttenuation, name HitHighBone, name HitLowBone, optional bool WasMeleeAttack)
{
	local float HealthReduction;
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x19A
	/*@Error*/
	HealthReduction = DamageStimuli.Stimulus[i].Amount;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x159
	/*@Error*/
	__NFUN_182__(HealthReduction, ShockPawn(Damager).ModifyStat('GlobalDamageAmplification_PercentBonus', 1.0000000));
	__NFUN_182__(HealthReduction, ShockPawn(Damager).ModifyStat(string(__NFUN_112__(string(DamageStimuli.Stimulus[i].Type), "DamageAmplification_PercentBonus")), 1.0000000));
	__NFUN_182__(HealthReduction, DamageAttenuation);
	__NFUN_185__(Health, HealthReduction);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x18C
	/*@Error*/
	__NFUN_113__('Broken');
	goto J0x19A;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

function TakeScriptedDamage(DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, float DamageChance, optional Actor Damager)
{
	local DamageStimuliSet DamageStimuli;
	local DamageStimulus theDamageStimulus;

	DamageStimuli = Class'Engine.DamageStimuliSet'.static.Allocate(self,,, 134217728).;
	Construct_Void();
	theDamageStimulus.Type = DamageType;
	theDamageStimulus.Amount = DamageAmount;
	theDamageStimulus.Chance = DamageChance;
	DamageStimuli.Stimulus[0] = theDamageStimulus;
	TakeDamage(DamageStimuli, 0.0000000, Damager, vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), 'None', 1.0000000, 'None', 'None');
	DamageStimuli.__NFUN_200__();
	return;
	@NULL
	Item
	Item
	@NULL
}

state Waiting
{	stop;
}

state Interacting
{
	protected latent function BeginInteracting()
	{
		FinishInteraction(true);
		return;
	}
	stop;
}

state AIInteracting
{
	ignores EndState, BeginState;

	function bool CanBeUsedNow()
	{
		return false;
		return;
	}

	function bool CanBeHackedNow(ShockPlayer Player)
	{
		return false;
		return;
	}

	protected function bool CanBeInteractedWith(ShockPlayer thePlayer, out string CannotInteractHUDFeedbackString, out name CannotInteractEffectEventContext)
	{
		return false;
		return;
	}
Begin:

	log('Machines', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), ": Beginning code for state "), string(__NFUN_284__())), ""));
	BeginInteractingStateVisualEffects();
	CurrentAI.OnInteractingWithMachine(self);
	__NFUN_113__('Waiting');
	stop;	
	@NULL
}

state Broken
{
	ignores GetHUDMessageForFocusAttained;

	function bool CanBeUsedNow()
	{
		return false;
		return;
	}

	function bool CanBeHackedNow(ShockPlayer Player)
	{
		return false;
		return;
	}

	protected function bool CanBeInteractedWith(ShockPlayer thePlayer, out string CannotInteractHUDFeedbackString, out name CannotInteractEffectEventContext)
	{
		return false;
		return;
	}

	function bool IsBroken()
	{
		return true;
		return;
	}

	function TakeDamage(DamageStimuliSet DamageStimuli, float CritChance, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, float DamageAttenuation, name HitHighBone, name HitLowBone, optional bool WasMeleeAttack)
	{
		return;
	}
Begin:

	log('Machines', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), ": Beginning code for state "), string(__NFUN_284__())), ""));
	CurrentPlayer = none;
	FinishAnimation(GetAnimationOnChannel(0));
	TriggerEffectEvent('Broken');
	PlayAnimationOnChannel(0, AnimBrokenStarted);
	FinishAnimation(GetAnimationOnChannel(0));
	// End:0xC3
	if(__NFUN_154__(int(DrawType), int(8)))
	{
		SetStaticMesh(BrokenStaticMesh);
		goto J0xD6;
		SetSkeletalMesh(BrokenMesh);
		SpawnHypos();
		PlayAnimationOnChannel(0, AnimBrokenLoop, 8);
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

defaultproperties
{
	HealAmount=500.0000000
	BrokenStaticMesh=StaticMesh'ShockGame.MA_Health.Broken_Health'
	UsedFeedbackTextFullHealth="Already at full health."
	HypoItemClass=Class'ShockGame.ShockDesignerClasses.MedHypo'
	HypoPickupClass=Class'ShockGame.ShockDesignerClasses.MedHypoPickup'
	HypoDropChance[0]=(NumberOfHypos=1,Chance=70)
	HypoDropChance[1]=(NumberOfHypos=2,Chance=24)
	HypoDropChance[2]=(NumberOfHypos=3,Chance=5)
	HypoDropChance[3]=(NumberOfHypos=4,Chance=1)
	bUsableByAIs=true
	Health=120.0000000
	BrokenString="Broken"
	AggressorUsePointSocketName="UseStation"
	PickupSpawnOffset=(X=28.0000000,Y=12.0000000,Z=74.0000000)
	HackInfoName="HealthStationDefault"
	HackingSuccessFeedbackText="RESULT OF SUCCESSFUL HACK:  Cost reduced, and enemies who use it will take damage."
	FriendlyName="Health Station"
	DrawType=8
}