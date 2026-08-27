class ActionRemoveItemsFromPlayer extends ActionShockInventory
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local Weapon theWeapon;
	local ShockPlayer thePlayer;
	local int i;
	local bool Found;

	super(Action).execute();
	thePlayer = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x132
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x132
	/*@Error*/
	theWeapon = Weapon(thePlayer.GetHoldable(i));
	// End:0x124
	if(__NFUN_119__(theWeapon, none))
	{
		// End:0x124
		if(__NFUN_114__(theWeapon.GetCurrentAmmoSelection(), ItemClass))
		{
			theWeapon.SetCurrentAmmoSelection(none);
			Found = true;
			goto J0x132;
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x71;
			thePlayer.UseUpItem(ItemClass, StackSize);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x191
			/*@Error*/
			theWeapon.SetCurrentAmmoSelection(Class<Ammunition>(ItemClass));
			return none;
			return;
			@NULL
		}
	}
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Remove ", string(StackSize)), " <"), string(ItemClass)), "> from the player");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Remove Items from the Player"
	actionHelp="Removes some items from the player's inventory"
}