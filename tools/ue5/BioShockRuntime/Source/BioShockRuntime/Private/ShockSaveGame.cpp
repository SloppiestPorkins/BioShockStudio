#include "ShockSaveGame.h"

#include "ShockCarryState.h"

#include "Misc/DateTime.h"
#include "UObject/UObjectGlobals.h"

void UShockSaveGame::CaptureFromCarryState(const UShockCarryState* Carry, EShockDifficulty InDifficulty)
{
	Difficulty = InDifficulty;
	if (!Carry)
	{
		return;
	}
	Health = Carry->Health;
	MaxEve = Carry->MaxEve;
	CurrentEve = Carry->CurrentEve;
	Weapons = Carry->Weapons;
	ActiveWeaponSlot = Carry->ActiveWeaponSlot;
	Plasmids = Carry->Plasmids;
	ActivePlasmidSlot = Carry->ActivePlasmidSlot;
	Research = Carry->Research;
	Inventory = Carry->Inventory;
	Money = Carry->Money;
	ArrivalStartLabel = Carry->ArrivalStartLabel;
}

UShockCarryState* UShockSaveGame::RestoreToCarryState(UObject* Outer) const
{
	UShockCarryState* Carry = NewObject<UShockCarryState>(Outer ? Outer : GetTransientPackage());
	Carry->Health = Health;
	Carry->MaxEve = MaxEve;
	Carry->CurrentEve = CurrentEve;
	Carry->Weapons = Weapons;
	Carry->ActiveWeaponSlot = ActiveWeaponSlot;
	Carry->Plasmids = Plasmids;
	Carry->ActivePlasmidSlot = ActivePlasmidSlot;
	Carry->Research = Research;
	Carry->Inventory = Inventory;
	Carry->Money = Money;
	Carry->ArrivalStartLabel = ArrivalStartLabel;
	return Carry;
}

FString UShockSaveGame::GetTimestampDisplay() const
{
	if (SavedUtcTicks <= 0)
	{
		return TEXT("—");
	}
	const FDateTime When = FDateTime(SavedUtcTicks);
	return When.ToString(TEXT("%Y-%m-%d %H:%M"));
}

FString UShockSaveGame::MakeSlotName(int32 SlotIndex)
{
	return FString::Printf(TEXT("BioshockSave_%d"), FMath::Clamp(SlotIndex, 0, MaxSlots - 1));
}
