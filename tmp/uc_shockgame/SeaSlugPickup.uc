class SeaSlugPickup extends Pickup implements ICanBeHarvested
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Collision);

var private float CurrentHarvestAmount;
var private float MaxHarvestAmount;
var private config name SeaSlugEquipAnimationName;
var private config name SeaSlugLoopAnimationName;
var private config name SeaSlugUnEquipAnimationName;
var private int SeaSlugAnimationHandle;
var private config name SeaSlugSocket;

function PostBeginPlay()
{
	super(ReactiveActor).PostBeginPlay();
	LootSlot.RollLoot(Level);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function SetADAMValue(int NewStackSize)
{
	local ItemStack theStack;

	theStack = LootSlot.GetLoot();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x92
	/*@Error*/
	theStack.ItemClass = Class'ShockGame.ADAM';
	theStack.StackSize = NewStackSize;
	MaxHarvestAmount = float(theStack.StackSize);
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool CanBeUsedNow()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_119__(LootSlot, none), ShockPlayer(Level.GetLocalPlayerController().Pawn).CanHarvestAdam()), __NFUN_176__(CurrentHarvestAmount, MaxHarvestAmount));
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUsed(Pawn Pawn)
{
	ShockPlayer(Pawn).BeginHarvestingAdam(self);
	return;
	@NULL
	Item
}

function bool ShouldBeHarvested()
{
	return true;
	return;
}

function OnNeedleInserted(Hands Hands)
{
	SeaSlugAnimationHandle = PlayAnimationOnChannelFlatEaseIn(0, SeaSlugLoopAnimationName, 0.0000000, 8);
	return;
	@NULL
	Item
	Item
}

function OnNeedleRemoved(Hands Hands)
{
	SeaSlugAnimationHandle = PlayAnimationOnChannelFlatEaseIn(0, SeaSlugUnEquipAnimationName, 0.0000000, 4);
	return;
	@NULL
	Item
	Item
}

function OnHarvestingStarted(Hands Hands)
{
	DrawPriority = 1;
	GetRagdoll().Rise(true);
	Hands.AttachToBone(self, SeaSlugSocket);
	SeaSlugAnimationHandle = PlayAnimationOnChannelFlatEaseIn(0, SeaSlugEquipAnimationName, 0.0000000, 4);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnHarvestingFinished(Hands Hands)
{
	StopAnimation(SeaSlugAnimationHandle);
	Hands.DetachFromBone(self);
	DrawPriority = 0;
	GetRagdoll().Fall();
	// End:0x7A
	if(CanBeUsedNow())
	{
		PlayAnimationOnChannelFlatEaseIn(0, SeaSlugLoopAnimationName, 0.0000000, 8);
		goto J0x98;
		LifeSpan = 10.0000000;
		FadeOutDuration = 1.0000000;
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

function float GetHarvestingTime(Hands Hands)
{
	return Hands.HarvestingAdamCollectionTime;
	return;
	@NULL
	Item
}

function float GetCurrentHarvestAmount(Hands Hands)
{
	return CurrentHarvestAmount;
	return;
	@NULL
}

function float GetMaxHarvestAmount(Hands Hands)
{
	local ItemStack theStack;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x89
	/*@Error*/
	theStack = LootSlot.GetLoot();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x89
	/*@Error*/
	MaxHarvestAmount = float(theStack.StackSize);
	return MaxHarvestAmount;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnHarvestedAmount(float AmountHarvested)
{
	__NFUN_184__(CurrentHarvestAmount, AmountHarvested);
	__NFUN_162__(LootSlot.GetLoot().StackSize, int(AmountHarvested));
	return;
	@NULL
	Item
	Item
	@NULL
}

function Container GetContainer()
{
	return none;
	return;
}

function name GetHandEquippingAnimationName(Hands Hands)
{
	return Hands.UsingGathererToolEquipAnimationName;
	return;
	@NULL
	Item
}

function name GetHandLoopingAnimationName(Hands Hands)
{
	return Hands.UsingGathererToolLoopAnimationName;
	return;
	@NULL
	Item
}

function name GetHandUnequippingAnimationName(Hands Hands)
{
	return Hands.UsingGathererToolUnEquipAnimationName;
	return;
	@NULL
	Item
}

function bool ShouldPushHarvestingContext()
{
	return true;
	return;
}

defaultproperties
{
	SeaSlugLoopAnimationName="Slugfish_anim_thrash"
	SeaSlugSocket="GathererAttach"
	UseVerbText="HARVEST"
	DrawType=2
	CollisionRadius=15.0000000
	CollisionHeight=4.0000000
	bCollideWorld=true
	bUseCylinderCollision=true
}