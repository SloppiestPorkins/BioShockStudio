class RemoveAmmoAdjustment extends RemoveItemsAdjustment
	config(Difficulty);

function GetRemoveParameters(Class<Item> CurrentItemClass, out int StackSize)
{
	// End:0x19
	if(__NFUN_114__(RemoveItemClass, Class'ShockGame.Film'))
	{
		return;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x4A
		/*@Error*/
	}
	StackSize = __NFUN_167__(__NFUN_145__(StackSize, 2));
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	RemoveItemClass=Class'ShockGame.Ammunition'
}