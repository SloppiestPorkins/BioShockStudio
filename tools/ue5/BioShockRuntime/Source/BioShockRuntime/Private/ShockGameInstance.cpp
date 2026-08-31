#include "ShockGameInstance.h"

#include "ShockCarryState.h"
#include "ShockPlayer.h"

#include "Engine/Engine.h"
#include "Engine/World.h"

FName UShockGameInstance::GetPendingArrivalStartLabel() const
{
	if (!PendingCarryState || PendingCarryState->ArrivalStartLabel.IsEmpty())
	{
		return NAME_None;
	}
	return FName(*PendingCarryState->ArrivalStartLabel);
}

void UShockGameInstance::SetPendingCarry(UShockCarryState* State, FName StartLabel)
{
	PendingCarryState = State;
	bHasPendingArrival = State != nullptr;
	if (PendingCarryState)
	{
		PendingCarryState->ArrivalStartLabel = StartLabel.ToString();
	}
}

bool UShockGameInstance::ConsumePendingArrival(AShockPlayer* Player)
{
	if (!bHasPendingArrival || !PendingCarryState || !Player)
	{
		return false;
	}

	PendingCarryState->RestoreOnto(Player);

	const float Health = Player->GetCurrentHealth();
	const int32 WeaponCount = PendingCarryState->GetWeaponCount();
	const int32 PlasmidCount = PendingCarryState->GetPlasmidCount();
	const FString StartLabel = PendingCarryState->ArrivalStartLabel;

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_ARRIVED start=%s health=%.1f weapons=%d plasmids=%d"),
		*StartLabel,
		Health,
		WeaponCount,
		PlasmidCount);

	PendingCarryState = nullptr;
	bHasPendingArrival = false;
	return true;
}

void UShockGameInstance::ClearPendingArrival()
{
	PendingCarryState = nullptr;
	bHasPendingArrival = false;
}

UShockGameInstance* UShockGameInstance::GetShockInstanceForVerify(UObject* WorldContextObject)
{
	if (UWorld* World = GEngine ? GEngine->GetWorldFromContextObject(
			WorldContextObject,
			EGetWorldErrorMode::ReturnNull) : nullptr)
	{
		return GetShockInstance(World);
	}
	return nullptr;
}

UShockGameInstance* UShockGameInstance::GetShockInstance(const UWorld* World)
{
	if (!World)
	{
		return nullptr;
	}
	return Cast<UShockGameInstance>(World->GetGameInstance());
}
