#include "ShockActionTeleportPawnToLocation.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"

namespace
{
	AActor* FindActorByEditorLabel(UWorld* World, const FName& Label)
	{
		if (!World || Label.IsNone())
		{
			return nullptr;
		}
		const FString Want = Label.ToString();
		for (TActorIterator<AActor> It(World); It; ++It)
		{
			AActor* Actor = *It;
			if (!Actor)
			{
				continue;
			}
#if WITH_EDITOR
			if (Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
			{
				return Actor;
			}
#endif
		}
		return nullptr;
	}
}

UShockActionTeleportPawnToLocation::UShockActionTeleportPawnToLocation()
{
	ActionClassName = TEXT("ActionTeleportPawnToLocation");
}

void UShockActionTeleportPawnToLocation::Configure(FName InPawnLabel, FName InMarkerLabel)
{
	PawnLabel = InPawnLabel;
	MarkerLabel = InMarkerLabel;
}

bool UShockActionTeleportPawnToLocation::RequestTeleport()
{
	if (PawnLabel.IsNone() || MarkerLabel.IsNone())
	{
		return false;
	}
	LastPawnLabel = PawnLabel;
	LastMarkerLabel = MarkerLabel;
	return true;
}

bool UShockActionTeleportPawnToLocation::TeleportInWorld(UWorld* World)
{
	if (!RequestTeleport())
	{
		return false;
	}
	AActor* PawnActor = FindActorByEditorLabel(World, PawnLabel);
	AActor* MarkerActor = FindActorByEditorLabel(World, MarkerLabel);
	if (!PawnActor || !MarkerActor)
	{
		return false;
	}
	PawnActor->SetActorLocationAndRotation(
		MarkerActor->GetActorLocation(),
		MarkerActor->GetActorRotation(),
		false,
		nullptr,
		ETeleportType::TeleportPhysics);
	return true;
}
