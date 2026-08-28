#include "ShockActionForcePlayerMove.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockPlayer.h"

UShockActionForcePlayerMove::UShockActionForcePlayerMove()
{
	ActionClassName = TEXT("ActionForcePlayerMove");
}

void UShockActionForcePlayerMove::Configure(
	FName InMarker,
	FName InBone,
	float InTimeOut,
	float InLocDelta,
	float InRotDelta)
{
	MarkerLabel = InMarker;
	MarkerBoneName = InBone;
	TimeOut = InTimeOut;
	LocationDeltaPerSecond = InLocDelta;
	RotationDeltaPerSecond = InRotDelta;
}

bool UShockActionForcePlayerMove::RequestMove()
{
	if (MarkerLabel.IsNone())
	{
		return false;
	}
	LastMarkerLabel = MarkerLabel;
	return true;
}

int32 UShockActionForcePlayerMove::ApplyInWorld(UWorld* World)
{
	if (!RequestMove() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	const FString Want = MarkerLabel.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
#if WITH_EDITOR
		if (!Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			continue;
		}
		Player->SetActorLocation(Actor->GetActorLocation());
		return 1;
#endif
	}
	return 0;
}
