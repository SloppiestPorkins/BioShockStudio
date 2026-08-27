class LootItemSpecification extends LootSpecification
	native
	editinlinenew
	hidecategories(Object);

var Class<Item> ItemClass;
var int MinStackSize;
var int MaxStackSize;

function AllConcreteItemClasses(LevelInfo Level, out array< Class<Item> > S)
{
	//native.Level;
	//native.S;	
	@NULL
	@NULL
}

function string DisplayClassAsClassName(Class<Item> theItem)
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

function DumpSpec(optional LootReport LootReport)
{
	LootReport.AddLootItemSpec(ItemClass, MinStackSize, MaxStackSize);
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("[", string(ItemClass)), ":"), string(MinStackSize)), ":"), string(MaxStackSize)), "]"));
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	MinStackSize=1
	MaxStackSize=1
}