class ActionPlaceItemInContainer extends ActionShockInventory
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ContainerLabel;

function Variable execute()
{
	local IHaveAContainer ContainerOwner;
	local Container Container;
	local ItemStack NewItem, ExistingItem;
	local int i, LeftToAdd;
	local ShockPlayer thePlayer;

	super(Action).execute();
	thePlayer = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	// End:0xCC
	if(__NFUN_132__(__NFUN_114__(ItemClass, none), __NFUN_152__(StackSize, 0)))
	{
		log(,, "ActionPlaceItemInContainer: No item class specified or stack size is less than one.");
		return none;
		ContainerOwner = IHaveAContainer(findByLabel(Class'Engine.Actor', ContainerLabel));
		// End:0x16F
		if(__NFUN_114__(ContainerOwner, none))
		{
		}
		log(,, __NFUN_112__(__NFUN_112__("ActionPlaceItemInContainer: Could not find a container with the label '", string(ContainerOwner)), "'."));
		return none;
		Container = ContainerOwner.GetContainer();
		// End:0x1F4
		if(__NFUN_114__(Container, none))
		{
			log(,, __NFUN_112__(__NFUN_112__("ActionPlaceItemInContainer: No container specified in '", string(ContainerOwner)), "'."));
		}
		return none;
		LeftToAdd = StackSize;
		// End:0x285
		if(__NFUN_177__(float(LeftToAdd), __NFUN_171__(float(ItemClass.default.MaximumStackSize), thePlayer.GetStackSizeModifier())))
		{
			LeftToAdd = int(__NFUN_171__(float(ItemClass.default.MaximumStackSize), thePlayer.GetStackSizeModifier()));
		}
		// End:0x2D7
		if(__NFUN_129__(Container.HasEverBeenRolled()))
		{
			Container.RollLoot(Actor(ContainerOwner).Level);
			Container.SetEverInteracted();
			i = 0;
			// End:0x568
			if(__NFUN_150__(i, Container.3))
			{
				ExistingItem = Container.GetItem(i);
			}
			// End:0x55A
			if(__NFUN_130__(__NFUN_119__(ExistingItem, none), __NFUN_114__(ExistingItem.ItemClass, ItemClass)))
			{
				NewItem = Class'ShockGame.ItemStack'.static.Allocate(self).;
			}
			Construct_Void();
			NewItem.__NFUN_199__();
			NewItem.ItemClass = ItemClass;
			// End:0x477
			if(__NFUN_176__(float(__NFUN_146__(LeftToAdd, ExistingItem.StackSize)), __NFUN_171__(float(ItemClass.default.MaximumStackSize), thePlayer.GetStackSizeModifier())))
			{
				NewItem.StackSize = __NFUN_146__(LeftToAdd, ExistingItem.StackSize);
				LeftToAdd = 0;
				goto J0x568;
				goto J0x519;
				NewItem.StackSize = int(__NFUN_171__(float(ItemClass.default.MaximumStackSize), thePlayer.GetStackSizeModifier()));
				__NFUN_162__(LeftToAdd, int(__NFUN_175__(__NFUN_171__(float(ItemClass.default.MaximumStackSize), thePlayer.GetStackSizeModifier()), float(ExistingItem.StackSize))));
				Container.AddItem(i, NewItem, ContainerOwner);
				NewItem.__NFUN_198__();
				__NFUN_163__(i);
				// [Loop Continue]
				goto J0x2F9;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x6AA
				/*@Error*/
				i = 0;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x6AA
				/*@Error*/
				ExistingItem = Container.GetItem(i);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x69C
				/*@Error*/
			}
			NewItem = Class'ShockGame.ItemStack'.static.Allocate(self).;
			Construct_Void();
			NewItem.__NFUN_199__();
			NewItem.ItemClass = ItemClass;
			NewItem.StackSize = LeftToAdd;
			Container.AddItem(i, NewItem, ContainerOwner);
			NewItem.__NFUN_198__();
			goto J0x6AA;
			__NFUN_163__(i);
			goto J0x582;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x711
			/*@Error*/
			log(,, "ActionPlaceItemInContainer: The container contains no open slots.");
		}
	}
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Put ", string(StackSize)), " <"), string(ItemClass)), "> in "), string(ContainerLabel)), ".");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Places an item into a container."
	actionHelp="Places an item into a container."
	Category="Container"
}