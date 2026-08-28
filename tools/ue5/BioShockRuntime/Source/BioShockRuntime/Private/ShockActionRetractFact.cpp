#include "ShockActionRetractFact.h"

#include "ShockPlayer.h"

UShockActionRetractFact::UShockActionRetractFact()
{
	ActionClassName = TEXT("ActionRetractFact");
}

void UShockActionRetractFact::Configure(FName InSlot1, const FString& InSlot2, const FString& InSlot3)
{
	Slot1 = InSlot1;
	Slot2 = InSlot2;
	Slot3 = InSlot3;
}

bool UShockActionRetractFact::RequestRetract()
{
	if (Slot1.IsNone())
	{
		return false;
	}
	LastSlot1 = Slot1;
	return true;
}

int32 UShockActionRetractFact::ApplyInWorld(UWorld* World)
{
	if (!RequestRetract())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->RetractFact(Slot1, Slot2, Slot3);
	return 1;
}
