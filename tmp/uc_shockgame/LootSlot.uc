class LootSlot extends Object
	native
	editinlinenew
	hidecategories(Object);

var private export editinline LootSpecification LootSpec;
var private ItemStack Loot;

function SetLootSpec(LootSpecification newLootSpec)
{
	// End:0x1E
	if(__NFUN_119__(LootSpec, none))
	{
		LootSpec.__NFUN_200__();
		LootSpec = newLootSpec;
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function LootSpecification GetLootSpec()
{
	return LootSpec;
	return;
	@NULL
}

function ItemStack GetLoot()
{
	return Loot;
	return;
	@NULL
}

function SetLoot(ItemStack Loot, Object InOuter)
{
	//native.Loot;
	//native.InOuter;	
	@NULL
	@NULL
}

function RollLoot(Object InOuter)
{
	//native.InOuter;	
	@NULL
}

function DumpSlot(optional LootReport LootReport)
{
	log(,, "   ... Specification ...");
	LootSpec.DumpSpec(LootReport);
	log(,, "   ... Current Loot ...");
	// End:0x91
	if(__NFUN_119__(Loot, none))
	{
		log(,, Loot.DumpItem());
		goto J0xA3;
		log(,, "   [None]");
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD2
	/*@Error*/
	LootReport.AddCurrentLoot(Loot);
	return;
	@NULL
	Item
	Item
	@NULL
}
