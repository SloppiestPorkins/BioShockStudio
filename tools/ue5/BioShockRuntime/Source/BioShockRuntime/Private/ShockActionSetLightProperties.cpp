#include "ShockActionSetLightProperties.h"

#include "Components/LightComponent.h"
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
