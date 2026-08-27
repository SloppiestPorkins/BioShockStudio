class Pickup extends PhysicalReactiveActor implements ICanBeUsed
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Collision);

var private editconst export editinline LootSlot LootSlot;
var private bool EverRolled;
var bool bHasRagdoll;
var bool SkipEffectEventDestroyedReactionsWhenPickedUp;
var Rotator VendingSpawnOffset;
var DispenserMachine DispensedBy;

function int GetDesiredAnimationCapabilities()
{
	local int capabilities;

	capabilities = super(Actor).GetDesiredAnimationCapabilities();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3B
	/*@Error*/
	capabilities = __NFUN_158__(capabilities, 256);
	return capabilities;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

// Export UPickup::execRollLoot(FFrame&, void* const)
native function RollLoot();

// Export UPickup::execGetLoot(FFrame&, void* const)
native function ItemStack GetLoot();

function SetLoot(ItemStack theStack)
{
	//native.theStack;	
	@NULL
}

function bool CanBeUsedNow()
{
	return __NFUN_130__(__NFUN_119__(LootSlot, none), bShowHudElements);
	return;
	@NULL
	Item
}

function OnUsed(Pawn Pawn)
{
	local ItemStack stack;
	local int i;

	AssertWithDescription(Pawn.__NFUN_303__('ShockPlayer'), __NFUN_112__(string(Class.Name), " was used by someone other than a ShockPlayer."));
	super(ReactiveActor).OnUsed(Pawn);
	// End:0xA5
	if(__NFUN_129__(EverRolled))
	{
		RollLoot();
		EverRolled = true;
		stack = GetLoot();
		AssertWithDescription(__NFUN_119__(stack, none), __NFUN_112__(__NFUN_112__("Designer Bug: Pickup ", string(self)), " has no loot so cannot be picked up!"));
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x21D
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x21D
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1E5
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1E5
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D7
	/*@Error*/
	DestroyedReactions[i].Done = true;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x166;
	HavokActivate();
	LifeSpan = 0.2000000;
	FadeOutDuration = LifeSpan;
	bShowHudElements = false;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool CanBeFocusedNow()
{
	return __NFUN_119__(LootSlot, none);
	return;
	@NULL
}

function string GetFocusDisplayName()
{
	local ItemStack stack;

	// End:0x25
	if(__NFUN_129__(EverRolled))
	{
		RollLoot();
		EverRolled = true;
		stack = GetLoot();
	}
	// End:0x6C
	if(__NFUN_119__(stack, none))
	{
		return stack.ItemClass.default.FriendlyName;
		return __NFUN_112__(__NFUN_112__("<ERROR: GETLOOT() FAILED FOR ", string(self)), ">");
	}
	return;
	@NULL
	Item
	Item
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

// Export UPickup::execDestroyManagedObjects(FFrame&, void* const)
native function DestroyManagedObjects();

function Destroyed()
{
	DestroyManagedObjects();
	super.Destroyed();
	return;
	@NULL
}

function DumpPickup(optional LootReport LootReport)
{
	LootSlot.DumpSlot(LootReport);
	log(,, "");
	return;
	@NULL
	Item
}

defaultproperties
{
	SkipEffectEventDestroyedReactionsWhenPickedUp=true
	UseVerbText="PICK UP"
	HavokDataClass=Class'ShockGame.BasePickupRigidBody'
}