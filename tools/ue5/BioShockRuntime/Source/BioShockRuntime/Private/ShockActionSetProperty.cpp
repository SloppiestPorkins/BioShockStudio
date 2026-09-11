#include "ShockActionSetProperty.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockScriptReflection.h"

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

	// Everything else: generic FProperty reflection (R2.1) — supports a dotted component step
	// ("StaticMeshComponent.Mobility") our component-based port needs beyond BioShock's flat
	// Object.Property, plus bool/numeric/name/string/struct/enum coercion via ImportText_Direct.
	FString Error;
	const bool bOk = ShockScriptReflection::SetPropertyFromText(Target, Prop, NewValue, &Error);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_SETPROP target=%s prop=%s value=%s ok=%d%s%s"),
		*ObjectLabel.ToString(),
		*Prop,
		*NewValue,
		bOk ? 1 : 0,
		bOk ? TEXT("") : TEXT(" reason="),
		bOk ? TEXT("") : *Error);
	return bOk;
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

bool UShockActionSetProperty::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
