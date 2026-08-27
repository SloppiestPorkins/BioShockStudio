class PlayerEscortedGatherer extends Gatherer
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

var bool bIsARealPEG;
var bool bDontWaitForPlayer;
var float PanicEndTime;
var config float MaxPanicTime;
var config float MaxPanicTimeWhileGathering;

function PostBeginPlay()
{
	super(ShockAI).PostBeginPlay();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3A
	/*@Error*/
	bIsARealPEG = true;
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function bool IsInScriptedGatheringMode()
{
	return __NFUN_130__(bScriptedQuickHitReactionPrevention, bIsARealPEG);
	return;
	@NULL
	CommanderAction
}

function float GetMaxPanicTime()
{
	// End:0x1A
	if(bIsGathering)
	{
		return MaxPanicTimeWhileGathering;
		goto J0x24;
		return MaxPanicTime;
		return;
	}
	@NULL
	CommanderAction
	J0x24:

	EcologyFighterCommanderAction
}

function NotifyEscortIsAttacking(ShockPawn AttackTarget)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x90
	/*@Error*/
	PanicEndTime = float(__NFUN_250__(int(PanicEndTime), int(__NFUN_174__(Level.TimeSeconds, GetMaxPanicTime()))));
	super.NotifyEscortIsAttacking(AttackTarget);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OnAIIntentionallyDamaged(Actor Damager)
{
	local ShockPawn PawnDamager;

	super.OnAIIntentionallyDamaged(Damager);
	PawnDamager = ShockPawn(Damager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xED
	/*@Error*/
	PanicEndTime = float(__NFUN_250__(int(PanicEndTime), int(__NFUN_174__(Level.TimeSeconds, GetMaxPanicTime()))));
	NotifyEscortIsAttacking(PawnDamager);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

defaultproperties
{
	VulnerableState=0
}