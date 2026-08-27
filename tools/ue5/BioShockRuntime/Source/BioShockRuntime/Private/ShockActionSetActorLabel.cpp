#include "ShockActionSetActorLabel.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionSetActorLabel::UShockActionSetActorLabel()
{
	ActionClassName = TEXT("ActionSetActorLabel");
}

void UShockActionSetActorLabel::Configure(FName InActorLabel, FName InNewLabel)
{
	ActorLabel = InActorLabel;
	NewLabel = InNewLabel;
}

bool UShockActionSetActorLabel::ApplyToActor(AActor* Target)
{
	if (!Target || NewLabel.IsNone())
	{
		return false;
	}
#if WITH_EDITOR
	Target->SetActorLabel(NewLabel.ToString());
	LastNewLabel = NewLabel;
	return Target->GetActorLabel() == NewLabel.ToString();
#else
	return false;
#endif
}

int32 UShockActionSetActorLabel::ApplyInWorld(UWorld* World)
{
	int32 Applied = 0;
	if (!World || ActorLabel.IsNone())
	{
		return 0;
	}
	const FString Want = ActorLabel.ToString();
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
		if (ApplyToActor(Actor))
		{
			++Applied;
		}
#endif
	}
	return Applied;
}
