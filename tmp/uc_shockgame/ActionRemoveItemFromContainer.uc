class ActionRemoveItemFromContainer extends ActionShockInventory
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ContainerLabel;

function Variable execute()
{
	local IHaveAContainer ContainerOwner;
	local Container Container;
	local ItemStack ExistingItem, NewItem;
	local int i, LeftToRemove;
	local bool RemoveAll;

	super(Action).execute();
	// End:0x89
	if(__NFUN_132__(__NFUN_150__(StackSize, 0), __NFUN_114__(ItemClass, none)))
	{
		log(,, "ActionRemoveItemFromContainer: ItemClass is not set or stack size is less than zero.");
		return none;
		ContainerOwner = IHaveAContainer(findByLabel(Class'Engine.Actor', ContainerLabel));
	}
	// End:0x12F
	if(__NFUN_114__(ContainerOwner, none))
	{
		log(,, __NFUN_112__(__NFUN_112__("ActionRemoveItemFromContainer: Could not find a container with the label '", string(ContainerOwner)), "'."));
		return none;
		Container = ContainerOwner.GetContainer();
		// End:0x1B7
		if(__NFUN_114__(Container, none))
		{
		}
		log(,, __NFUN_112__(__NFUN_112__("ActionRemoveItemFromContainer: No container specified in '", string(ContainerOwner)), "'."));
		return none;
		LeftToRemove = StackSize;
		RemoveAll = __NFUN_154__(LeftToRemove, 0);
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3EE
		/*@Error*/
	}
	ExistingItem = Container.GetItem(i);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x3E0
	/*@Error*/
	// End:0x2E0
	if(__NFUN_132__(RemoveAll, __NFUN_153__(LeftToRemove, ExistingItem.StackSize)))
	{
		__NFUN_162__(LeftToRemove, ExistingItem.StackSize);
		Container.AddItem(i, none);
		goto J0x3E0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3E0
		/*@Error*/
		NewItem = Class'ShockGame.ItemStack'.static.Allocate(self).;
		Construct_Void();
		NewItem.__NFUN_199__();
		NewItem.ItemClass = ExistingItem.ItemClass;
		NewItem.StackSize = __NFUN_147__(ExistingItem.StackSize, LeftToRemove);
		Container.AddItem(i, NewItem, ContainerOwner);
	}
	NewItem.__NFUN_198__();
	LeftToRemove = 0;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x1EC;
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Remove ", string(StackSize)), " <"), string(ItemClass)), "> from "), string(ContainerLabel)), ".");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Removes a specified number of items of type ItemClass from the container."
	actionHelp="Removes a specified number of items of type ItemClass from the container.  Set StackSize to zero to remove all items in the specified slot."
	Category="Container"
}