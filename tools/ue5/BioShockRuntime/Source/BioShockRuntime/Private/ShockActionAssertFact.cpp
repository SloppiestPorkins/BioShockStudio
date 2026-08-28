#include "ShockActionAssertFact.h"

#include "ShockPlayer.h"

UShockActionAssertFact::UShockActionAssertFact()
{
	ActionClassName = TEXT("ActionAssertFact");
}

void UShockActionAssertFact::Configure(FName InSlot1, const FString& InSlot2, const FString& InSlot3)
{
	Slot1 = InSlot1;
	Slot2 = InSlot2;
	Slot3 = InSlot3;
}

bool UShockActionAssertFact::RequestAssert()
{
	if (Slot1.IsNone())
	{
		return false;
	}
	LastSlot1 = Slot1;
	return true;
}

int32 UShockActionAssertFact::ApplyInWorld(UWorld* World)
{
	if (!RequestAssert())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->AssertFact(Slot1, Slot2, Slot3);
	return 1;
}
