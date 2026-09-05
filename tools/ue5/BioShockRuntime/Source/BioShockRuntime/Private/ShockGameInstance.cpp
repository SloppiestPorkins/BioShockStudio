#include "ShockGameInstance.h"

#include "ShockCarryState.h"
#include "ShockLoadingScreen.h"
#include "ShockPlayer.h"

#include "Blueprint/UserWidget.h"
#include "Engine/Engine.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"
#include "UObject/UObjectGlobals.h"

void UShockGameInstance::Init()
{
	Super::Init();
	FCoreUObjectDelegates::PreLoadMap.AddUObject(this, &UShockGameInstance::HandlePreLoadMap);
	FCoreUObjectDelegates::PostLoadMapWithWorld.AddUObject(this, &UShockGameInstance::HandlePostLoadMap);
}

void UShockGameInstance::Shutdown()
{
	FCoreUObjectDelegates::PreLoadMap.RemoveAll(this);
	FCoreUObjectDelegates::PostLoadMapWithWorld.RemoveAll(this);
	if (ActiveLoadingScreen)
	{
		ActiveLoadingScreen->HideLoadingScreen();
		ActiveLoadingScreen = nullptr;
	}
	Super::Shutdown();
}

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

void UShockGameInstance::RequestTravelToLevel(
	UObject* WorldContextObject,
	const FString& MapPackagePath,
	const FString& TravelOptions)
{
	LastTravelRequestMap = MapPackagePath;
	LastTravelOptions = TravelOptions;

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_TRAVEL_REQUEST to=%s options=%s suppress=%d"),
		*MapPackagePath,
		*TravelOptions,
		bSuppressLevelTravel ? 1 : 0);

	if (bSuppressLevelTravel || MapPackagePath.IsEmpty())
	{
		return;
	}

	UGameplayStatics::OpenLevel(
		WorldContextObject ? WorldContextObject : this,
		FName(*MapPackagePath),
		true,
		TravelOptions);
}

void UShockGameInstance::HandlePreLoadMap(const FString& MapName)
{
	if (bSuppressLevelTravel)
	{
		return;
	}
	if (!ActiveLoadingScreen)
	{
		ActiveLoadingScreen = CreateWidget<UShockLoadingScreen>(this, UShockLoadingScreen::StaticClass());
	}
	if (ActiveLoadingScreen)
	{
		ActiveLoadingScreen->ShowForMap(MapName);
	}
}

void UShockGameInstance::HandlePostLoadMap(UWorld* LoadedWorld)
{
	(void)LoadedWorld;
	if (ActiveLoadingScreen)
	{
		ActiveLoadingScreen->HideLoadingScreen();
		ActiveLoadingScreen = nullptr;
	}
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
