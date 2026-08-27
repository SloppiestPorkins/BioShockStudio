class InventoryManager extends Object implements IHandleMovieEvents, IObserveUseFocus
	native;

var travel ShockPlayer PlayerOwner;
var private travel Inventory ItemInventory;
var private travel Inventory ComponentInventory;
var private Inventory CurrentInventory;
var private Container CurrentContainer;
var travel array< Class<Item> > LockedItemList;
var localized string InventoryStackFullMessage;

function OpenContainer(Container inContainer)
{
	//native.inContainer;	
	@NULL
}

// Export UInventoryManager::execCloseContainer(FFrame&, void* const)
native function CloseContainer();

// Export UInventoryManager::execCanReRoll(FFrame&, void* const)
native function bool CanReRoll();

// Export UInventoryManager::execReRollContainer(FFrame&, void* const)
native function ReRollContainer();

// Export UInventoryManager::execOpenInventory(FFrame&, void* const)
native function OpenInventory();

// Export UInventoryManager::execCloseInventory(FFrame&, void* const)
native function CloseInventory();

// Export UInventoryManager::execSwitchInventory(FFrame&, void* const)
native function SwitchInventory();

function UnlockSlots(int NumSlots)
{
	//native.NumSlots;	
	@NULL
}

// Export UInventoryManager::execGetNumUnlockedSlots(FFrame&, void* const)
native function int GetNumUnlockedSlots();

function SetSelectedSlot(int slotId)
{
	//native.slotId;	
	@NULL
}

// Export UInventoryManager::execUseSelectedInventoryItem(FFrame&, void* const)
native function UseSelectedInventoryItem();

// Export UInventoryManager::execRecycleOrDestroySelectedInventoryItem(FFrame&, void* const)
native function RecycleOrDestroySelectedInventoryItem();

function RecycleOrDestroyContainerSlot(int Slot)
{
	//native.Slot;	
	@NULL
}

function SelectContainerSlot(int Slot)
{
	//native.Slot;	
	@NULL
}

// Export UInventoryManager::execSelectAllContainerSlots(FFrame&, void* const)
native function SelectAllContainerSlots();

function bool CanUseItem(Class<Item> ItemClass)
{
	//native.ItemClass;	
	@NULL
}

function UseItem(Class<Item> ItemClass)
{
	//native.ItemClass;	
	@NULL
}

function int GetNumberOfItems(Class<Item> ItemClass)
{
	//native.ItemClass;	
	@NULL
}

function GetInventoryClassesOfClass(Class<Item> ItemClass, out array< Class<Item> > InventoryClasses)
{
	//native.ItemClass;
	//native.InventoryClasses;	
	@NULL
	@NULL
}

function OnUsedInventoryItem(Class<Item> ItemClass, int AmountUsed)
{
	//native.ItemClass;
	//native.AmountUsed;	
	@NULL
	@NULL
}

function LockItem(Class<Item> ItemClass)
{
	//native.ItemClass;	
	@NULL
}

function UnLockItem(Class<Item> ItemClass)
{
	//native.ItemClass;	
	@NULL
}

function bool AddStackToInventory(ItemStack inStack)
{
	//native.inStack;	
	@NULL
}

function Container GetCurrentContainer()
{
	return CurrentContainer;
	return;
	@NULL
}

function OnMovieEvent(name Event, MovieEventData Data)
{
	//native.Event;
	//native.Data;	
	@NULL
	@NULL
}

function OnUseFocusChanged(ICanBeUsed OldFocus, ICanBeUsed NewFocus)
{
	// End:0x44
	if(__NFUN_130__(__NFUN_119__(PlayerOwner, none), __NFUN_129__(PlayerOwner.TakeAllTimer.Running)))
	{
		CloseContainer();
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function bool IsInventoryOpen()
{
	return __NFUN_119__(CurrentInventory, none);
	return;
	@NULL
}

// Export UInventoryManager::execResetUIState(FFrame&, void* const)
native function ResetUIState();

function DumpInventorySystem()
{
	log(,, "********************************************************");
	log(,, "*** Dumping Inventory System ***");
	// End:0x105
	if(__NFUN_119__(CurrentContainer, none))
	{
		log(,, "");
		log(,, "--------------------------------------------------------");
		log(,, "--- Current Container ---");
		log(,, "");
		CurrentContainer.DumpContainer();
		log(,, "");
	}
	log(,, "--------------------------------------------------------");
	log(,, "--- Item Inventory ---");
	// End:0x1A4
	if(__NFUN_114__(ItemInventory, CurrentInventory))
	{
		log(,, "---------OPEN---------");
		log(,, "");
		ItemInventory.DumpInventory();
	}
	log(,, "");
	log(,, "--------------------------------------------------------");
	log(,, "--- Component Inventory ---");
	// End:0x26D
	if(__NFUN_114__(ComponentInventory, CurrentInventory))
	{
		log(,, "------------OPEN-----------");
		log(,, "");
		ComponentInventory.DumpInventory();
	}
	log(,, "********************************************************");
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function CheckDups()
{
	ItemInventory.CheckDups();
	ComponentInventory.CheckDups();
	return;
	@NULL
	Item
}

defaultproperties
{
	InventoryStackFullMessage="You cannot carry any more of item: %s."
}