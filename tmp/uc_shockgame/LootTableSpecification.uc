class LootTableSpecification extends LootSpecification
	native
	editinlinenew
	hidecategories(Object);

var name TableName;

function AllTableNames(LevelInfo Level, out array<name> S)
{
	local int i;
	local TableList TableList;

	TableList = Class'ShockGame.TableList'.static.Allocate(self).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	S[i] = TableList.TableName[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x3C;
	TableList.__NFUN_200__();
	return;
	@NULL
	Item
	Item
	@NULL
}

function DumpSpec(optional LootReport LootReport)
{
	local LootTable tempTable;

	log(,, __NFUN_112__(__NFUN_112__("   @@@ ", string(TableName)), " @@@"));
	tempTable = Class'ShockGame.LootTable'.static.Allocate(self,, string(TableName)).;
	Construct_Void();
	tempTable.DumpTable();
	LootReport.AddLootTableSpec(TableName);
	return;
	@NULL
	Item
	Item
	@NULL
}
