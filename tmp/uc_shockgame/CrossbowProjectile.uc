class CrossbowProjectile extends ShockProjectile implements ICanBeUsed
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Animation);

var private config float MaxAngleOfDeflection;
var private config float ChanceToBreak;
var private config bool IsAPickup;
var private config float MinAntiGravitySpeedPercentage;
var private config float MinimumBreakSpeed;
var private ItemStack ItemStack;
var private config localized string UseVerbText;
var private bool CanBePickedUp;
var private float OriginalSpeed;

function Destroyed()
{
	// End:0x29
	if(__NFUN_119__(ItemStack, none))
	{
		ItemStack.__NFUN_198__();
		ItemStack = none;
		super(Actor).Destroyed();
		return;
		@NULL
	}
	Item
	stop;
	default.@NULL
}

// Export UCrossbowProjectile::execGetItemStack(FFrame&, void* const)
native function ItemStack GetItemStack();

function bool CanBeUsedNow()
{
	return __NFUN_130__(CanBePickedUp, __NFUN_119__(GetItemStack(), none));
	return;
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
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9D
	/*@Error*/
	__NFUN_279__();
	return;
	@NULL
	Item
	Item
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

function bool CanBeFocusedNow()
{
	return CanBeUsedNow();
	return;
}

function string GetFocusDisplayName()
{
	return ItemStack.ItemClass.default.FriendlyName;
	// End:0x58
	if(__NFUN_119__(GetItemStack(), none))
	{
		return ItemStack.ItemClass.default.FriendlyName;
		return __NFUN_112__(__NFUN_112__("<ERROR: NO ITEMSTACK FOR ", string(self)), ">");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function string GetHUDMessageForFocusAttained()
{
	return GetFocusDisplayName();
	return;
}

function bool ShouldHighlightWhenFocused()
{
	return CanBeUsedNow();
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

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	return 1;
	return;
}

function bool ActionBlockedByPawns()
{
	return true;
	return;
}

function float GetUseDistance()
{
	return 0.0000000;
	return;
}

function OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	local Vector ViewLocation;
	local Rotator ViewDirection;
	local Actor DummyActor;

	super.OnTelekinesisStartedThrowing(Telekinesis);
	EnableHitHandling(true);
	PlayerController(Telekinesis.Player.Controller).PlayerCalcView(DummyActor, ViewLocation, ViewDirection);
	OrientBolt(Vector(ViewDirection));
	PrepareBoltForThrowing();
	AlreadyTriggeredWeaponImpacted = false;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

event Actor GetActorAffected()
{
	return self;
	return;
}

function PreTelekinesis()
{
	__NFUN_262__(true, false, false);
	__NFUN_3970__(1);
	GravityModifier = 0.0000000;
	EnableHitHandling(false);
	CanBePickedUp = true;
	return;
	@NULL
	Item
}

function bool IsAffectedByTelekinesis()
{
	return true;
	return;
}

function OrientBolt(Vector direction)
{
	//native.direction;	
	@NULL
}

// Export UCrossbowProjectile::execPrepareBoltForThrowing(FFrame&, void* const)
native function PrepareBoltForThrowing();

function DetachAnyCrossbowBoltsFromActor(Actor ActorFromWhichToDetachBolts)
{
	//native.ActorFromWhichToDetachBolts;	
	@NULL
}

function DestroyAnyCrossbowBoltsOnActor(Actor ActorFromWhichToDestroyBolts)
{
	//native.ActorFromWhichToDestroyBolts;	
	@NULL
}

defaultproperties
{
	MaxAngleOfDeflection=35.0000000
	ChanceToBreak=0.5000000
	IsAPickup=true
	MinAntiGravitySpeedPercentage=0.5000000
	MinimumBreakSpeed=500.0000000
	UseVerbText="PICK UP"
}