#include "ShockActionSetProperty.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionSetProperty::UShockActionSetProperty()
{
	ActionClassName = TEXT("ActionSetProperty");
}

void UShockActionSetProperty::Configure(FName InObjectLabel, FName InPropertyName, const FString& InNewValue)
{
	ObjectLabel = InObjectLabel;
	PropertyName = InPropertyName;
	NewValue = InNewValue;
}

bool UShockActionSetProperty::ApplyToActor(AActor* Target)
{
	if (!Target || PropertyName.IsNone())
	{
		return false;
	}

	const FString Prop = PropertyName.ToString();
	if (Prop.Equals(TEXT("Label"), ESearchCase::IgnoreCase)
		|| Prop.Equals(TEXT("ActorLabel"), ESearchCase::IgnoreCase))
	{
#if WITH_EDITOR
		Target->SetActorLabel(NewValue);
		return Target->GetActorLabel() == NewValue;
#else
		return false;
#endif
	}

	if (Prop.Equals(TEXT("bHidden"), ESearchCase::IgnoreCase)
		|| Prop.Equals(TEXT("Hidden"), ESearchCase::IgnoreCase))
	{
		const bool bHide = NewValue.ToBool()
			|| NewValue.Equals(TEXT("1"), ESearchCase::IgnoreCase)
			|| NewValue.Equals(TEXT("true"), ESearchCase::IgnoreCase);
		Target->SetActorHiddenInGame(bHide);
		return Target->IsHidden() == bHide;
	}

	// Full SetPropertyText coverage is deferred — native UE2 path, many property types.
	return false;
}

int32 UShockActionSetProperty::ApplyInWorld(UWorld* World)
{
	int32 Applied = 0;
	if (!World || ObjectLabel.IsNone())
	{
		return 0;
	}
	const FString Want = ObjectLabel.ToString();
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
