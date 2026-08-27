class MessageSomethingDoneToItem extends Message
	abstract
	native
	hidecategories(Object);

var int Amount;
var name ItemClass;
var Class<Item> ActualClass;

function Construct(Class<Item> inItemClass, int inAmount)
{
	ActualClass = inItemClass;
	ItemClass = inItemClass.Name;
	Amount = inAmount;
	return;
	@NULL
	Item
	Vector
	@NULL
}

function bool passesFilter(Message filterMsg)
{
	local MessageSomethingDoneToItem MSDtI;

	MSDtI = MessageSomethingDoneToItem(filterMsg);
	assert(__NFUN_119__(MSDtI, none));
	// End:0x160
	if(__NFUN_130__(__NFUN_119__(MSDtI.ActualClass, none), __NFUN_129__(__NFUN_258__(ActualClass, MSDtI.ActualClass))))
	{
		log('Inventory', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("  -> ", string(MSDtI.Outer.Name)), " message "), string(MSDtI.Name)), " FAILED filter because ACTUAL CLASS is wrong. Filter.ActualClass = "), string(ActualClass)), " Message.ActualClass = "), string(MSDtI.ActualClass)));
		return false;
		// End:0x294
		if(__NFUN_130__(__NFUN_255__(MSDtI.ItemClass, 'None'), __NFUN_255__(ItemClass, MSDtI.ItemClass)))
		{
			log('Inventory', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("  -> ", string(MSDtI.Outer.Name)), " message "), string(MSDtI.Name)), " FAILED filter because ITEM CLASS is wrong. Filter.ItemClass = "), string(ItemClass)), " Message.ItemClass = "), string(MSDtI.ItemClass)));
		}
		return false;
		// End:0x3B6
		if(__NFUN_130__(__NFUN_155__(MSDtI.Amount, 0), __NFUN_155__(MSDtI.Amount, Amount)))
		{
			log('Inventory', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("  -> ", string(MSDtI.Outer.Name)), " message "), string(MSDtI.Name)), " FAILED filter because AMOUNT is wrong. Filter.Amount = "), string(Amount)), " Message.Amount = "), string(MSDtI.Amount)));
		}
		return false;
		log('Inventory', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("  -> ", string(MSDtI.Outer.Name)), " message "), string(MSDtI.Name)), " PASSED filter. ( filterMsg = "), string(MSDtI.Name)), ", Amount = "), string(MSDtI.Amount)), ", ItemClass = "), string(MSDtI.ItemClass)), ", ActualClass = "), string(MSDtI.ActualClass)));
	}
	return true;
	return;
	@NULL
	Item
	Item
	@NULL
}

static function string editorDisplay(name TriggeredBy, Message filter)
{
	return "(Abstract) Something was done to an item.";
	return;
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

function AllItemClasses(LevelInfo Level, out array< Class<Item> > S)
{
	local Class theItemClass, BaseItemClass;

	BaseItemClass = Class'ShockGame.Item';
	// End:0x5A
	foreach AllClasses(BaseItemClass, theItemClass)
	{
		S[S.Length] = Class<Item>(theItemClass);				
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function AllItemClassNames(LevelInfo Level, out array<name> S)
{
	local Class theItemClass, BaseItemClass;

	BaseItemClass = Class'ShockGame.Item';
	// End:0x5E
	foreach AllClasses(BaseItemClass, theItemClass)
	{
		S[S.Length] = theItemClass.Name;				
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

defaultproperties
{
	specificTo=Class'ShockGame.ShockPlayer'
}