#include "ShockActionRetractFact.h"

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
