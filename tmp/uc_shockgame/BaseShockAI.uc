class BaseShockAI extends ShockPawn
	abstract
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

const LOOT_LOCKED_SLOT_NUMBER = 2;
const kInitialSoundDistanceMultiplier = 1.0;

var bool bDropToGroundUponSpawning;
var private bool bHasDroppedToGroundOnce;
var config name HoldableSocket;
var config name LockedSlotLootTableName;
var int DelayCorpseRemoval;
var bool bDebugAIAttacking;

function PostBeginPlay()
{
	super(Pawn).PostBeginPlay();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x21
	/*@Error*/
	DropToGround();
	return;
	@NULL
	Item
}

function DropToGround()
{
	__NFUN_3970__(4);
	return;
}

function Landed(Vector HitNormal)
{
	super(Pawn).Landed(HitNormal);
	bHasDroppedToGroundOnce = true;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool ShouldTriggerLandedEffectEvent()
{
	return __NFUN_132__(__NFUN_129__(bDropToGroundUponSpawning), bHasDroppedToGroundOnce);
	return;
	@NULL
	Item
}

function NotifyPlayingScriptedLoopingAnimation(int LoopingAnimationHandle)
{
	return;
}

protected function bool ShouldInstantlyEquip()
{
	return true;
	return;
}

function bool IsSuspectingAttackFrom(ShockPawn Target)
{
	return false;
	return;
}

function OnInteractingWithMachine(ShockMachine Machine)
{
	return;
}

protected function bool LootSlotLocked()
{
	return false;
	return;
}

function RollLoot(int slotNumber, LootSlot LootSlot, Object InOuter)
{
	local LootTableSpecification LootSpec;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xC0
	/*@Error*/
	// End:0x38
	if(LootSlotLocked())
	{
		LootSlot.SetLootSpec(none);
		goto J0xC0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xC0
		/*@Error*/
	}
	LootSpec = Class'ShockGame.LootTableSpecification'.static.Allocate(self).;
	Construct_Void();
	LootSpec.TableName = LockedSlotLootTableName;
	LootSlot.SetLootSpec(LootSpec);
	LootSlot.RollLoot(InOuter);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function NotifyEscortIsAttacking(ShockPawn AttackTarget)
{
	return;
}

function BecomeSaved()
{
	return;
}

function BecomeStunned()
{
	return;
}

event bool IsStunned()
{
	return;
}

event bool IsPanicking()
{
	return false;
	return;
}

event bool CanSaveOrPacify()
{
	return false;
	return;
}

function ShockPawn GetShockPawnEscort()
{
	return none;
	return;
}

function PlayerFinishedInteractingWithGatherer(ShockPlayer thePlayer, bool WasPacified)
{
	return;
}

function PlayerStartedInteractingWithGatherer(ShockPlayer thePlayer, bool WasPacified)
{
	return;
}

function PlayerInterruptedInteractingWithGatherer(ShockPlayer thePlayer, bool WasPacified)
{
	return;
}

function SetSwarmPlayerOwner(ShockPlayer inSwarmPlayerOwner)
{
	return;
}

function UpdateTimeToLive(ShockPlayer Instigator)
{
	return;
}

function UpdateEscortedGathererHealth()
{
	return;
}

event bool IsHackedByPlayer()
{
	return false;
	return;
}
