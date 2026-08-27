class ActionPlaceItemInContainerSlot extends ActionShockInventory
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ContainerLabel;
var travel int Slot;
var travel bool OverwriteExistingItem;

function Variable execute()
{
	local IHaveAContainer ContainerOwner;
	local Actor ContainerOwnerActor;
	local Container Container;
	local ItemStack NewItem;
	local ShockPlayer thePlayer;

	super(Action).execute();
	thePlayer = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	// End:0xD0
	if(__NFUN_132__(__NFUN_114__(ItemClass, none), __NFUN_152__(StackSize, 0)))
	{
		log(,, "ActionPlaceItemInContainerSlot: No item class specified or stack size is less than one.");
		return none;
		// End:0x602
		foreach parentScript.allActorLabel(Class'Engine.Actor', ContainerOwnerActor, ContainerLabel)
		{
			ContainerOwner = IHaveAContainer(ContainerOwnerActor);
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x0AC! */
		// End:0x19B
		if(__NFUN_114__(ContainerOwner, none))
		{
			log(,, __NFUN_112__(__NFUN_112__("ActionPlaceItemInContainerSlot: Could not find a container with the label '", string(ContainerOwner)), "'."));
			continue;
			goto J0x602;
			Container = ContainerOwner.GetContainer();
			// End:0x226
			if(__NFUN_114__(Container, none))
			{
				log(,, __NFUN_112__(__NFUN_112__("ActionPlaceItemInContainerSlot: No container specified in '", string(ContainerOwner)), "'."));
			}
			continue;
			goto J0x602;
			// End:0x2A7
			if(__NFUN_132__(__NFUN_150__(Slot, 0), __NFUN_153__(Slot, Container.3)))
			{
				log(,, __NFUN_112__(__NFUN_112__("ActionPlaceItemInContainerSlot: Invalid slot number ", string(Slot)), "."));
			}
			continue;
			goto J0x602;
			// End:0x2F9
			if(__NFUN_129__(Container.HasEverBeenRolled()))
			{
				Container.RollLoot(Actor(ContainerOwner).Level);
				Container.SetEverInteracted();
				// End:0x409
				if(__NFUN_132__(__NFUN_114__(Container.GetItem(Slot), none), OverwriteExistingItem))
				{
				}
				NewItem = Class'ShockGame.ItemStack'.static.Allocate(self).;
				Construct_Void();
				NewItem.__NFUN_199__();
				NewItem.ItemClass = ItemClass;
			}
			NewItem.StackSize = StackSize;
			Container.AddItem(Slot, NewItem, ContainerOwner);
			NewItem.__NFUN_198__();
			goto J0x601;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x56C
			/*@Error*/
			NewItem = Class'ShockGame.ItemStack'.static.Allocate(self).;
			Construct_Void();
			NewItem.__NFUN_199__();
			NewItem.ItemClass = ItemClass;
			NewItem.StackSize = __NFUN_249__(__NFUN_146__(StackSize, Container.GetItem(Slot).StackSize), int(__NFUN_171__(float(ItemClass.default.MaximumStackSize), thePlayer.GetStackSizeModifier())));
		}
		Container.AddItem(Slot, NewItem, ContainerOwner);
		NewItem.__NFUN_198__();
		goto J0x601;
		log(,, __NFUN_112__(__NFUN_112__("ActionPlaceItemInContainerSlot: There is already an item at slot ", string(Slot)), ". Set OverwriteExistingItem to automatically overwrite it."));				
		return none;
		return;
		@NULL
		Item
		Item
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x032! */
}

function editorDisplayString(out string S)
{
	// End:0x25
	if(OverwriteExistingItem)
	{
		S = "Overwrite";
		goto J0x34;
		S = "Put";
	}
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(S, string(StackSize)), " <"), string(ItemClass)), "> in "), string(ContainerLabel)), " at slot "), string(Slot)), ".");
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Places an item into a container at a specified slot."
	actionHelp="Places an item into a container at a specified slot."
	Category="Container"
}