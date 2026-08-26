#include "ShockActionShockInventory.h"

UShockActionShockInventory::UShockActionShockInventory()
{
	ActionClassName = TEXT("ActionShockInventory");
	StackSize = 1;
}

void UShockActionShockInventory::ConfigureInventory(FName InItemClass, int32 InStackSize)
{
	ItemClass = InItemClass;
	StackSize = InStackSize;
}
