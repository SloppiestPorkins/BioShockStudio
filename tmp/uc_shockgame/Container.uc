class Container extends Object
	native
	config
	editinlinenew
	hidecategories(Object);

const NUM_CONTAINER_SLOTS = 3;

var private editconstarray editconst export editinline LootSlot LootSlots[3];
var bool AllowDifficultySpawn;
var bool AllowDifficultyRemove;
var bool bDontEverMarkAsSearched;
var private int NumTimesRolled;
var private bool EverInteracted;
var private bool PlayerSearched;
var private InventoryManager InventoryManager;
var private Actor Owner;
var private const config localized string EmptyString;
var private const config localized string SearchedString;

// Export UContainer::execGetCopy(FFrame&, void* const)
native function Container GetCopy();

function RollLoot(LevelInfo theLevel)
{
	//native.theLevel;	
	@NULL
}

function ItemStack GetItem(int Slot)
{
	//native.Slot;	
	@NULL
}

function AddItem(int Slot, ItemStack NewItem, optional Object OverrideOuter)
{
	//native.Slot;
	//native.NewItem;
	//native.OverrideOuter;	
	@NULL
	@NULL
	return default.@NULL;
}

// Export UContainer::execIsEmpty(FFrame&, void* const)
native function bool IsEmpty();

function int GetNumberOfItems(Class<Item> ItemClass)
{
	//native.ItemClass;	
	@NULL
}

function SetOwner(Actor ContainerOwner)
{
	local int i;

	AssertWithDescription(ContainerOwner.__NFUN_303__('IHaveAContainer'), "ContainerOwner must implement the IHaveAContainer interface.");
	Owner = ContainerOwner;
	i = 0;
	// End:0x132
	if(__NFUN_150__(i, Class'ShockGame.DifficultyManager'.default.NoDifficultySpawnClassNames.Length))
	{
		// End:0x124
		if(ContainerOwner.__NFUN_303__(Class'ShockGame.DifficultyManager'.default.NoDifficultySpawnClassNames[i]))
		{
			log('Difficulty', 4, __NFUN_112__("Not allowing difficulty spawn for ", string(ContainerOwner)));
			AllowDifficultySpawn = false;
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x7F;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1F2
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1E4
			/*@Error*/
		}
	}
	log('Difficulty', 4, __NFUN_112__("Not allowing difficulty removal for ", string(ContainerOwner)));
	AllowDifficultyRemove = false;
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x13D;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function SetLootSlotTableName(int Slot, name TableName)
{
	local LootTableSpecification LootSpec;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x92
	/*@Error*/
	LootSpec = Class'ShockGame.LootTableSpecification'.static.Allocate(self).;
	Construct_Void();
	LootSpec.TableName = TableName;
	LootSlots[Slot].SetLootSpec(LootSpec);
	return;
	@NULL
	Item
	Item
	@NULL
}

function Actor GetOwner()
{
	AssertWithDescription(__NFUN_119__(Owner, none), "The container's owner was never set.  It's reccommended that this is done in (Pre|Post)BeginPlay.");
	return Owner;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool HasEverBeenRolled()
{
	return __NFUN_151__(NumTimesRolled, 0);
	return;
	@NULL
}

function int GetNumTimesRolled()
{
	return NumTimesRolled;
	return;
	@NULL
}

function SetEverInteracted()
{
	EverInteracted = true;
	return;
	@NULL
}

function bool HasEverInteracted()
{
	return EverInteracted;
	return;
	@NULL
}

function SetPlayerSearched()
{
	PlayerSearched = true;
	return;
	@NULL
}

function bool HasPlayerSearched()
{
	return PlayerSearched;
	return;
	@NULL
}

function LootSlot GetLootSlot(int Slot)
{
	assert(__NFUN_130__(__NFUN_153__(Slot, 0), __NFUN_150__(Slot, 3)));
	return LootSlots[Slot];
	return;
	@NULL
	Item
	Item
	@NULL
}

function ModifyHudMessage(out string Message)
{
	// End:0x48
	if(__NFUN_130__(HasEverBeenRolled(), IsEmpty()))
	{
		Message = __NFUN_112__(__NFUN_112__(__NFUN_112__(Message, " ("), EmptyString), ")");
		goto J0x7E;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x7E
		/*@Error*/
	}
	Message = __NFUN_112__(__NFUN_112__(__NFUN_112__(Message, " ("), SearchedString), ")");
	return;
	@NULL
	Item
	Item
	@NULL
}

function DumpContainer(optional LootReport LootReport)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x89
	/*@Error*/
	log(,, __NFUN_112__(__NFUN_112__("=== Loot Slot #", string(i)), " ==="));
	LootSlots[i].DumpSlot(LootReport);
	log(,, "");
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	AllowDifficultySpawn=true
	AllowDifficultyRemove=true
	EmptyString="Empty"
	SearchedString="Searched"
}