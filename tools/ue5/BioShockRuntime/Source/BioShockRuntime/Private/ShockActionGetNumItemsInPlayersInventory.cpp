#include "ShockActionGetNumItemsInPlayersInventory.h"

#include "ShockPlayer.h"

UShockActionGetNumItemsInPlayersInventory::UShockActionGetNumItemsInPlayersInventory()
{
	ActionClassName = TEXT("ActionGetNumItemsInPlayersInventory");
}

void UShockActionGetNumItemsInPlayersInventory::Configure(FName InItemClass)
{
	ItemClass = InItemClass;
}

bool UShockActionGetNumItemsInPlayersInventory::ApplyInWorld(const FShockActionContext& Ctx)
{
	ClearReturnValue();
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(Ctx.World);
	// No player (or no item class) holds none: a count of 0 is the honest answer, not a failure.
	const int32 Count = (Player && !ItemClass.IsNone()) ? Player->GetInventoryStack(ItemClass) : 0;
	SetReturnValueText(LexToString(static_cast<float>(Count)), TEXT("VariableFloat"));
	return true;
}
