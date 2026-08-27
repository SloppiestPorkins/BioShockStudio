#include "ShockActionSetProperty.h"

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
