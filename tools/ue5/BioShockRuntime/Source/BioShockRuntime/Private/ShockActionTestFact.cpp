#include "ShockActionTestFact.h"

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
	// Native TestFact() is not ported yet — refuse a true result rather than invent one.
	return false;
}
