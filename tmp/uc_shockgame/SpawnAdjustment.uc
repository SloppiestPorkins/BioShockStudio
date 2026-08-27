class SpawnAdjustment extends DifficultyAdjustment implements ILootDifficultyAdjustment
	abstract
	config(Difficulty);

var private config DifficultyFloat MinSpawnRate;
var private config DifficultyFloat MaxSpawnRate;
var private config int MinStackSize;
var private config int MaxStackSize;
var private transient float NextSpawnLevelTime;

function AdjustmentStopped()
{
	super.AdjustmentStopped();
	NextSpawnLevelTime = 0.0000000;
	return;
	@NULL
	Item
}

function bool IsActive()
{
	return __NFUN_130__(super.IsActive(), __NFUN_177__(DifficultyManager.GetGameDriver().GetLevel().TimeSeconds, NextSpawnLevelTime));
	return;
	@NULL
	Item
	Item
	@NULL
}

function GetSpawnParameters(out Class<Item> ItemClass, out int StackSize)
{
	StackSize = __NFUN_146__(__NFUN_167__(__NFUN_147__(MaxStackSize, MinStackSize)), MinStackSize);
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function ModifyLoot(LootSlot Slot, Class<Item> ItemClass, int StackSize)
{
	local ItemStack ItemStack;

	ItemStack = Class'ShockGame.ItemStack'.static.Allocate(self).;
	Construct_Void();
	ItemStack.__NFUN_199__();
	ItemStack.ItemClass = ItemClass;
	ItemStack.StackSize = StackSize;
	log('DifficultyAdjustment', 3, __NFUN_112__("Spawning ", ItemClass.default.FriendlyName));
	Slot.SetLoot(ItemStack, DifficultyManager.GetGameDriver().GetLevel());
	ItemStack.__NFUN_198__();
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function bool ModifyContainer(Container Container)
{
	local int i;
	local LootSlot Slot;
	local Class<Item> ItemClass;
	local int StackSize;

	// End:0x51
	if(__NFUN_129__(Container.AllowDifficultySpawn))
	{
		log('DifficultyAdjustment', 3, "Spawning not allowed in container");
		return false;
		GetSpawnParameters(ItemClass, StackSize);
	}
	// End:0x7E
	if(__NFUN_114__(ItemClass, none))
	{
		return false;
		i = 0;
		// End:0x124
		if(__NFUN_150__(i, 3))
		{
			Slot = Container.GetLootSlot(i);
		}
		// End:0x116
		if(__NFUN_130__(__NFUN_119__(Slot.GetLoot(), none), __NFUN_114__(Slot.GetLoot().ItemClass, ItemClass)))
		{
			return false;
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x89;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2A2
			/*@Error*/
			Slot = Container.GetLootSlot(i);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x294
		/*@Error*/
	}
	NextSpawnLevelTime = __NFUN_174__(__NFUN_174__(DifficultyManager.GetGameDriver().GetLevel().TimeSeconds, DifficultyManager.GetDifficultyFloat(MinSpawnRate)), __NFUN_171__(__NFUN_195__(), __NFUN_175__(DifficultyManager.GetDifficultyFloat(MaxSpawnRate), DifficultyManager.GetDifficultyFloat(MinSpawnRate))));
	ModifyLoot(Slot, ItemClass, StackSize);
	AdjustmentOccured();
	return true;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x12F;
	return false;
	return;
	@NULL
	Item
	Item
	@NULL
}
