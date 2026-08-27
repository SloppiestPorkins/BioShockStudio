class ActionSpawnPickup extends ActionSpawnActorAtActorLocation
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Class<Pickup> PickupClass;
var travel Class<Item> ItemClass;
var travel int StackSize;
var travel bool StartsPhysical;

function AllConcretePickupClasses(LevelInfo Level, out array< Class<Pickup> > S)
{
	//native.Level;
	//native.S;	
	@NULL
	@NULL
}

function AllConcreteItemClasses(LevelInfo Level, out array< Class<Item> > S)
{
	//native.Level;
	//native.S;	
	@NULL
	@NULL
}

function Variable execute()
{
	local Pickup SpawnedPickup;
	local ItemStack theStack;

	super(Action).execute();
	SpawnedPickup = Pickup(SpawnActor(PickupClass));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x15D
	/*@Error*/
	theStack = SpawnedPickup.GetLoot();
	// End:0xA0
	if(__NFUN_114__(theStack, none))
	{
		theStack = Class'ShockGame.ItemStack'.static.Allocate(self).;
		Construct_Void();
		theStack.__NFUN_199__();
		// End:0xDE
		if(__NFUN_119__(ItemClass, none))
		{
			theStack.ItemClass = ItemClass;
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x10D
		/*@Error*/
		theStack.StackSize = StackSize;
		SpawnedPickup.SetLoot(theStack);
		SpawnedPickup.HavokActivate(StartsPhysical);
	}
	theStack.__NFUN_198__();
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Spawn a pickup of class ", string(PickupClass)), " at "), string(TargetActorLabel)), " with label "), string(ActorLabel)), ".");
	return;
	@NULL
	Item
	Item
	@NULL
}

function string DisplayPickupClassAsClassName(Class<Pickup> thePickup)
{
	// End:0x24
	if(__NFUN_114__(thePickup, none))
	{
		return "No Class Specified";
		return __NFUN_112__(__NFUN_112__(string(GetSuperClass(thePickup).Name), ": "), string(thePickup.Name));
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function string DisplayItemClassAsClassName(Class<Item> theItem)
{
	local string displayString;

	// End:0x4D
	if(__NFUN_258__(theItem, Class'ShockGame.Ammunition'))
	{
		displayString = __NFUN_112__("Ammunition: ", string(theItem.Name));
		goto J0x46E;
		// End:0x9D
		if(__NFUN_258__(theItem, Class'ShockGame.ActivePlasmid'))
		{
			displayString = __NFUN_112__("ActivePlasmid: ", string(theItem.Name));
		}
		goto J0x46E;
		// End:0xEE
		if(__NFUN_258__(theItem, Class'ShockGame.EcologyPlasmid'))
		{
			displayString = __NFUN_112__("EcologyPlasmid: ", string(theItem.Name));
		}
		goto J0x46E;
		// End:0x143
		if(__NFUN_258__(theItem, Class'ShockGame.EngineeringPlasmid'))
		{
			displayString = __NFUN_112__("EngineeringPlasmid: ", string(theItem.Name));
		}
		goto J0x46E;
		// End:0x195
		if(__NFUN_258__(theItem, Class'ShockGame.PhysicalPlasmid'))
		{
			displayString = __NFUN_112__("PhysicalPlasmid: ", string(theItem.Name));
			goto J0x46E;
			// End:0x1E5
			if(__NFUN_258__(theItem, Class'ShockGame.WeaponPlasmid'))
			{
				displayString = __NFUN_112__("WeaponPlasmid: ", string(theItem.Name));
			}
			goto J0x46E;
			// End:0x22F
			if(__NFUN_258__(theItem, Class'ShockGame.Plasmid'))
			{
				displayString = __NFUN_112__("Plasmid: ", string(theItem.Name));
			}
			goto J0x46E;
			// End:0x276
			if(__NFUN_258__(theItem, Class'ShockGame.Hypo'))
			{
				displayString = __NFUN_112__("Hypo: ", string(theItem.Name));
				goto J0x46E;
				// End:0x2C3
				if(__NFUN_258__(theItem, Class'ShockGame.Ammunition'))
				{
				}
				displayString = __NFUN_112__("Ammunition: ", string(theItem.Name));
				goto J0x46E;
				// End:0x30D
				if(__NFUN_258__(theItem, Class'ShockGame.CraftingFormula'))
				{
					displayString = __NFUN_112__("Formula: ", string(theItem.Name));
				}
				goto J0x46E;
				// End:0x358
				if(__NFUN_258__(theItem, Class'ShockGame.QuestLog'))
				{
					displayString = __NFUN_112__("QuestLog: ", string(theItem.Name));
				}
				goto J0x46E;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x3A6
				/*@Error*/
				displayString = __NFUN_112__("Collectable: ", string(theItem.Name));
				goto J0x46E;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x3F3
				/*@Error*/
			}
			displayString = __NFUN_112__("Consumable: ", string(theItem.Name));
			goto J0x46E;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x43D
			/*@Error*/
			displayString = __NFUN_112__("Freebie: ", string(theItem.Name));
		}
		goto J0x46E;
		displayString = __NFUN_112__("Inventory: ", string(theItem.Name));
		return displayString;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Spawn a Pickup"
	actionHelp="Spawn a pickup at the location specified by an actor."
}