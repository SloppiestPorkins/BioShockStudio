class LootReport extends Object
	native;

var private native const noexport TMap_Padding CurrentLoot;
var private native const noexport TMap_Padding LootItemSpec;
var private native const noexport TMap_Padding LootTableSpec;

function AddCurrentLoot(ItemStack theStack)
{
	//native.theStack;	
	@NULL
}

function AddLootItemSpec(Class<Item> ItemClass, int MinStackSize, int MaxStackSize)
{
	//native.ItemClass;
	//native.MinStackSize;
	//native.MaxStackSize;	
	@NULL
	@NULL
	return default.@NULL;
}

function AddLootTableSpec(name TableName)
{
	//native.TableName;	
	@NULL
}

// Export ULootReport::execReportLoot(FFrame&, void* const)
native function ReportLoot();
