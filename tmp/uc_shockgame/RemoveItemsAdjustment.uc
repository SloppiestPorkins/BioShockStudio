class RemoveItemsAdjustment extends DifficultyAdjustment implements ILootDifficultyAdjustment
	abstract
	config(Difficulty);

var private config Class<Item> RemoveItemClass;

function GetRemoveParameters(Class<Item> CurrentItemClass, out int StackSize)
{
	// End:0x31
	if(__NFUN_258__(CurrentItemClass, RemoveItemClass))
	{
		StackSize = __NFUN_167__(__NFUN_145__(StackSize, 2));
		return;
		@NULL
		Item
		DifficultyAdjustment
	}
	@NULL
}

function ModifyLoot(LootSlot Slot, int NewStackSize)
{
	log('DifficultyAdjustment', 3, __NFUN_168__(__NFUN_112__("Removed ", string(__NFUN_147__(Slot.GetLoot().StackSize, NewStackSize))), Slot.static.GetLoot().ItemClass.default.FriendlyName));
	// End:0xCF
	if(__NFUN_154__(NewStackSize, 0))
	{
		Slot.SetLoot(none, DifficultyManager.GetGameDriver().GetLevel());
		goto J0xFD;
		Slot.GetLoot().StackSize = NewStackSize;
		return;
	}
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function bool ModifyContainer(Container Container)
{
	local int i;
	local LootSlot Slot;
	local int NewStackSize;

	// End:0x57
	if(__NFUN_129__(Container.AllowDifficultyRemove))
	{
		log('DifficultyAdjustment', 3, "Removing items not allowed in container");
		return false;
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x186
		/*@Error*/
	}
	J0x62:

	Slot = Container.GetLootSlot(i);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x178
	/*@Error*/
	NewStackSize = Slot.GetLoot().StackSize;
	GetRemoveParameters(Slot.GetLoot().ItemClass, NewStackSize);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x178
	/*@Error*/
	ModifyLoot(Slot, NewStackSize);
	AdjustmentOccured();
	return true;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x62;
	return false;
	return;
	@NULL
	Item
	Item
	@NULL
}
