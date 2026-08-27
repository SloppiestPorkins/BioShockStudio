class VendingLootTable extends DeletableObject
	native
	config(LootTables)
	perobjectconfig;

struct native atomic ConfigableVendingLootSpecification
{
	var config Class<Item> ItemClass;
	var config Class<Pickup> PickupClass;
	var config int StackSize;
	var config float CostAdjustment;
	var config bool DisplayWhenHacked;
	var config bool DisplayWhenUnHacked;
	var config int SupplySize;
	var int AmountPurchased;
	var int cost;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var config array<ConfigableVendingLootSpecification> VendingLootSpec;

function DumpTable()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x151
	/*@Error*/
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("      [", string(VendingLootSpec[i].ItemClass)), ":"), string(VendingLootSpec[i].PickupClass)), ":"), string(VendingLootSpec[i].StackSize)), ":"), string(VendingLootSpec[i].CostAdjustment)), ":"), string(VendingLootSpec[i].DisplayWhenHacked)), ":"), string(VendingLootSpec[i].DisplayWhenUnHacked)), "]"));
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}
