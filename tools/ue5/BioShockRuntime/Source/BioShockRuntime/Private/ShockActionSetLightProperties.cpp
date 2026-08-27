#include "ShockActionSetLightProperties.h"

#include "Components/LightComponent.h"
#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionSetLightProperties::UShockActionSetLightProperties()
{
	ActionClassName = TEXT("ActionSetLightProperties");
}

void UShockActionSetLightProperties::Configure(
	FName InObjectLabel,
	bool bInChangeBrightness,
	float InBrightness,
	bool bInChangeColor,
	FColor InLightColor)
{
	ObjectLabel = InObjectLabel;
	bChangeBrightness = bInChangeBrightness;
	Brightness = InBrightness;
	bChangeColor = bInChangeColor;
	LightColor = InLightColor;
}

bool UShockActionSetLightProperties::ApplyToActor(AActor* Target)
{
	if (Target == nullptr)
	{
		return false;
	}
	if (!bChangeBrightness && !bChangeColor)
	{
		return false;
	}

	ULightComponent* Light = Target->FindComponentByClass<ULightComponent>();
	if (Light == nullptr)
	{
		return false;
	}

	if (bChangeBrightness)
	{
		Light->SetIntensity(Brightness);
	}
	if (bChangeColor)
	{
		Light->SetLightColor(FLinearColor(LightColor));
	}

	LastAppliedActorName = Target->GetFName();
	return true;
}

int32 UShockActionSetLightProperties::ApplyInWorld(UWorld* World)
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
