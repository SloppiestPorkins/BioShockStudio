#include "ShockSaveGame.h"

#include "ShockCarryState.h"
#include "ShockGameInstance.h"
#include "ShockPlayer.h"

#include "Kismet/GameplayStatics.h"
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

FString UShockSaveGame::MakeScriptedSlotName(const FString& SlotName)
{
	return TEXT("BioshockScriptedSave_") + SlotName;
}

bool UShockSaveGame::SaveScripted(AShockPlayer* Player, const FString& SlotName)
{
	if (!Player || SlotName.IsEmpty())
	{
		return false;
	}
	UShockCarryState* Carry = UShockCarryState::Capture(Player);
	if (!Carry)
	{
		return false;
	}
	UShockSaveGame* Save = Cast<UShockSaveGame>(
		UGameplayStatics::CreateSaveGameObject(UShockSaveGame::StaticClass()));
	if (!Save)
	{
		return false;
	}

	EShockDifficulty Diff = EShockDifficulty::Medium;
	UWorld* World = Player->GetWorld();
	if (World)
	{
		if (UShockGameInstance* GI = UShockGameInstance::GetShockInstance(World))
		{
			Diff = GI->GetSelectedDifficulty();
		}
	}

	Save->CaptureFromCarryState(Carry, Diff);
	Save->LevelPackagePath = World && World->GetOutermost() ? World->GetOutermost()->GetName() : FString();
	if (Save->LevelPackagePath.IsEmpty())
	{
		Save->LevelPackagePath = TEXT("/Game/BioShockSlice/1-Medical");
	}
	FString Pretty = Save->LevelPackagePath;
	int32 Slash = INDEX_NONE;
	if (Pretty.FindLastChar(TEXT('/'), Slash))
	{
		Pretty = Pretty.Mid(Slash + 1);
	}
	Save->LevelDisplayName = Pretty.IsEmpty() ? TEXT("Unknown") : Pretty;
	Save->SavedUtcTicks = FDateTime::UtcNow().GetTicks();
	Save->SlotDisplayName = SlotName;

	const bool bOk = UGameplayStatics::SaveGameToSlot(Save, MakeScriptedSlotName(SlotName), 0);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_SAVE_SCRIPTED slot=%s ok=%d level=%s"),
		*SlotName,
		bOk ? 1 : 0,
		*Save->LevelPackagePath);
	return bOk;
}
