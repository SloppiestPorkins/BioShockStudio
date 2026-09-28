#include "ShockActionTestFact.h"

#include "ShockPlayer.h"

UShockActionTestFact::UShockActionTestFact()
{
	ActionClassName = TEXT("ActionTestFact");
}

void UShockActionTestFact::Configure(FName InSlot1, const FString& InSlot2, const FString& InSlot3)
{
	Slot1 = InSlot1;
	Slot2 = InSlot2;
	Slot3 = InSlot3;
}

bool UShockActionTestFact::RequestTest()
{
	bRequested = true;
	return true;
}

bool UShockActionTestFact::EvaluateBool() const
{
	// Needs a World to resolve the local player — use EvaluateInWorld from ActionIf.
	return false;
}

bool UShockActionTestFact::EvaluateInWorld(UWorld* World) const
{
	if (!World || Slot1.IsNone())
	{
		return false;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return false;
	}
	return Player->HasFact(Slot1, Slot2, Slot3);
}
