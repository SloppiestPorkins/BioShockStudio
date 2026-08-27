class ActionRemoveItemFromContainerSlot extends ActionShockInventory
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ContainerLabel;
var travel int Slot;

function Variable execute()
{
	local IHaveAContainer ContainerOwner;
	local Container Container;
	local ItemStack ExistingItem, NewItem;

	super(Action).execute();
	// End:0x64
	if(__NFUN_150__(StackSize, 0))
	{
		log(,, "ActionRemoveItemFromContainerSlot: Stack size is less than zero.");
		return none;
		ContainerOwner = IHaveAContainer(findByLabel(Class'Engine.Actor', ContainerLabel));
	}
	// End:0x10E
	if(__NFUN_114__(ContainerOwner, none))
	{
		log(,, __NFUN_112__(__NFUN_112__("ActionRemoveItemFromContainerSlot: Could not find a container with the label '", string(ContainerOwner)), "'."));
		return none;
		Container = ContainerOwner.GetContainer();
		// End:0x19A
		if(__NFUN_114__(Container, none))
		{
		}
		log(,, __NFUN_112__(__NFUN_112__("ActionRemoveItemFromContainerSlot: No container specified in '", string(ContainerOwner)), "'."));
		return none;
		// End:0x21C
		if(__NFUN_132__(__NFUN_150__(Slot, 0), __NFUN_153__(Slot, Container.3)))
		{
			log(,, __NFUN_112__(__NFUN_112__("ActionRemoveItemFromContainerSlot: Invalid slot number ", string(Slot)), "."));
		}
		return none;
		ExistingItem = Container.GetItem(Slot);
		// End:0x2B5
		if(__NFUN_114__(ExistingItem, none))
		{
			log(,, __NFUN_112__(__NFUN_112__("ActionRemoveItemFromContainerSlot: There are not any items in slot ", string(Slot)), "."));
		}
		return none;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x42C
		/*@Error*/
		// End:0x343
		if(__NFUN_132__(__NFUN_153__(StackSize, ExistingItem.StackSize), __NFUN_154__(StackSize, 0)))
		{
			Container.AddItem(Slot, none);
		}
		goto J0x429;
		NewItem = Class'ShockGame.ItemStack'.static.Allocate(self).;
		Construct_Void();
		NewItem.__NFUN_199__();
		NewItem.ItemClass = ExistingItem.ItemClass;
		NewItem.StackSize = __NFUN_147__(ExistingItem.StackSize, StackSize);
		Container.AddItem(Slot, NewItem, ContainerOwner);
	}
	NewItem.__NFUN_198__();
	goto J0x4DC;
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("ActionRemoveItemFromContainerSlot: The item at slot ", string(Slot)), " is not of type <"), string(ItemClass)), ">.  Set ItemClass to None to remove the item regardless of type."));
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x7A
	if(__NFUN_114__(ItemClass, none))
	{
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Remove ", string(StackSize)), " items of any type from "), string(ContainerLabel)), " at slot "), string(Slot)), ".");
		goto J0xE4;
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Remove ", string(StackSize)), " <"), string(ItemClass)), "> from "), string(ContainerLabel)), " at slot "), string(Slot)), ".");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Removes a specified number of items from the specified slot."
	actionHelp="Removes a specified number of items from the specified slot.  If ItemClass is set it will only remove items of that type.  If ItemClass is None the objects will be removed regardless of type.  Set StackSize to zero to remove all items in the specified slot."
	Category="Container"
}