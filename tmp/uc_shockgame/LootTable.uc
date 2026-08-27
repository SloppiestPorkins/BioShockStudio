class LootTable extends DeletableObject
	native
	config(LootTables)
	perobjectconfig;

struct native atomic ConfigableLootSpecification
{
	var config int Chance;
	var config name TableName;
	var config Class<Item> ItemClass;
	var config int MinStackSize;
	var config int MaxStackSize;
};

var config array<ConfigableLootSpecification> LootSpec;

function DumpTable()
{
	local int i;
	local LootTable tempTable;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x206
	/*@Error*/
	// End:0x11C
	if(__NFUN_254__(LootSpec[i].TableName, 'None'))
	{
		log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("      [", string(LootSpec[i].Chance)), ":"), string(LootSpec[i].ItemClass)), ":"), string(LootSpec[i].MinStackSize)), ":"), string(LootSpec[i].MaxStackSize)), "]"));
		goto J0x1F8;
		log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(" @@@ [", string(LootSpec[i].Chance)), ":"), string(LootSpec[i].TableName)), "] @@@"));
		tempTable = Class'ShockGame.LootTable'.static.Allocate(self,, string(LootSpec[i].TableName)).;
	}
	Construct_Void();
	tempTable.DumpTable();
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}
