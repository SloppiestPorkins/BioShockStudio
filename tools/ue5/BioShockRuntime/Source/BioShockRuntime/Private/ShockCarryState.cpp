#include "ShockCarryState.h"

#include "ShockPlayer.h"
#include "ShockResearchCamera.h"
#include "ShockWeapon.h"
#include "ShockPlasmid.h"

#include "UObject/UObjectGlobals.h"

UShockCarryState* UShockCarryState::Capture(AShockPlayer* Player)
{
	if (!Player)
	{
		return nullptr;
	}

	UShockCarryState* State = NewObject<UShockCarryState>();
	State->Health = Player->GetCurrentHealth();
	State->MaxEve = Player->MaxEve;
	State->CurrentEve = Player->GetCurrentEve();
	State->ActiveWeaponSlot = Player->GetActiveWeaponSlot();
	State->ActivePlasmidSlot = Player->ActivePlasmidSlot;
	State->Money = Player->GetMoney();
	State->Research = Player->ResearchPointsByArchetype;
	State->Inventory = Player->GetInventoryStacksForTravel();

	for (int32 Slot = 0; Slot < Player->WeaponSlots.Num(); ++Slot)
	{
		const AShockWeapon* Weapon = Player->GetWeaponInSlot(Slot);
		if (!Weapon)
		{
			continue;
		}

		FShockCarriedWeapon Entry;
		Entry.Slot = Slot;
		Entry.Mag = Weapon->GetRoundsInMagazine();
		Entry.Reserve = Weapon->GetReserveAmmo();
		if (Weapon->IsA<AShockResearchCamera>())
		{
			Entry.ClassPath = Weapon->GetClass()->GetPathName();
		}
		else
		{
			Entry.DefName = Weapon->GetWeaponDefName();
		}
		State->Weapons.Add(Entry);
	}

	for (int32 Slot = 0; Slot < Player->EquippedPlasmids.Num(); ++Slot)
	{
		const UShockPlasmid* Plasmid = Player->EquippedPlasmids[Slot].Get();
		if (!Plasmid)
		{
			continue;
		}

		FShockCarriedPlasmid Entry;
		Entry.Slot = Slot;
		Entry.PlasmidName = Plasmid->PlasmidName;
		State->Plasmids.Add(Entry);
	}

	return State;
}

void UShockCarryState::RestoreOnto(AShockPlayer* Player) const
{
	if (!Player)
	{
		return;
	}

	Player->EnsureHealthInitialized();
	Player->SetCurrentHealthForVerify(Health);
	Player->MaxEve = MaxEve;
	Player->SetCurrentEveForVerify(CurrentEve);

	for (int32 Slot = 0; Slot < Player->WeaponSlots.Num(); ++Slot)
	{
		if (AShockWeapon* Existing = Player->GetWeaponInSlot(Slot))
		{
			if (Player->GetEquippedWeapon() == Existing)
			{
				Player->EquipWeapon(nullptr);
			}
			Existing->Destroy();
			Player->WeaponSlots[Slot] = nullptr;
		}
	}

	for (const FShockCarriedWeapon& Entry : Weapons)
	{
		AShockWeapon* Weapon = nullptr;
		if (!Entry.ClassPath.IsEmpty())
		{
			if (UClass* WeaponClass = StaticLoadClass(
					AShockWeapon::StaticClass(),
					nullptr,
					*Entry.ClassPath))
			{
				Weapon = Player->GiveWeapon(WeaponClass, Entry.Slot);
			}
		}
		else if (!Entry.DefName.IsNone())
		{
			Weapon = Player->GiveWeaponByDef(Entry.DefName, Entry.Slot);
		}

		if (Weapon)
		{
			Weapon->SetAmmoStateForVerify(Entry.Mag, Entry.Reserve);
		}
	}

	if (ActiveWeaponSlot >= 0)
	{
		Player->SelectWeaponSlot(ActiveWeaponSlot);
	}

	Player->ClearAllPlasmids();
	for (const FShockCarriedPlasmid& Entry : Plasmids)
	{
		const TSubclassOf<UShockPlasmid> PlasmidClass = UShockPlasmid::ResolvePlasmidClass(Entry.PlasmidName);
		if (PlasmidClass)
		{
			Player->EquipPlasmid(PlasmidClass, Entry.Slot);
		}
	}
	Player->ActivePlasmidSlot = ActivePlasmidSlot;

	Player->ResearchPointsByArchetype = Research;
	Player->RestoreInventoryStacksForTravel(Inventory);
	Player->PlayerMoney = Money;
}
