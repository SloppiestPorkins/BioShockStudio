#include "ShockActionSetLightProperties.h"

#include "Components/LightComponent.h"
#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockScriptReflection.h"

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

void UShockActionSetLightProperties::ConfigureLightType(
	bool bInChangeLightType,
	FName InLightTypeName,
	bool bInChangePeriod,
	float InPeriod,
	bool bInChangePhase,
	float InPhase)
{
	bChangeLightType = bInChangeLightType;
	LightTypeName = InLightTypeName;
	bChangeLightPeriod = bInChangePeriod;
	LightPeriod = InPeriod;
	bChangeLightPhase = bInChangePhase;
	LightPhase = InPhase;
}

EShockLightEffectType UShockActionSetLightProperties::ParseLightTypeName(FName TypeName)
{
	FString S = TypeName.ToString();
	S.ReplaceInline(TEXT("LT_"), TEXT(""), ESearchCase::IgnoreCase);
	if (S.Equals(TEXT("None"), ESearchCase::IgnoreCase))
	{
		return EShockLightEffectType::None;
	}
	if (S.Equals(TEXT("Flicker"), ESearchCase::IgnoreCase))
	{
		return EShockLightEffectType::Flicker;
	}
	if (S.Equals(TEXT("Pulse"), ESearchCase::IgnoreCase))
	{
		return EShockLightEffectType::Pulse;
	}
	if (S.Equals(TEXT("SubtlePulse"), ESearchCase::IgnoreCase))
	{
		return EShockLightEffectType::SubtlePulse;
	}
	if (S.Equals(TEXT("Blink"), ESearchCase::IgnoreCase))
	{
		return EShockLightEffectType::Blink;
	}
	if (S.Equals(TEXT("Strobe"), ESearchCase::IgnoreCase))
	{
		return EShockLightEffectType::Strobe;
	}
	// LT_Steady and unknown → steady (flicker→steady idiom lands here).
	return EShockLightEffectType::Steady;
}

bool UShockActionSetLightProperties::ApplyToActor(AActor* Target)
{
	if (Target == nullptr)
	{
		return false;
	}
	if (!bChangeBrightness && !bChangeColor && !bChangeLightType
		&& !bChangeLightPeriod && !bChangeLightPhase && !bChangeCastShadows)
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
	if (bChangeCastShadows)
	{
		Light->SetCastShadows(bCastsShadowMapShadows);
	}

	if (bChangeLightType || bChangeLightPeriod || bChangeLightPhase)
	{
		UShockLightEffectComponent* Effect = UShockLightEffectComponent::EnsureOnActor(Target);
		if (Effect)
		{
			const EShockLightEffectType Type = bChangeLightType
				? ParseLightTypeName(LightTypeName)
				: static_cast<EShockLightEffectType>(Effect->GetEffectTypeForVerify());
			const float Period = bChangeLightPeriod ? LightPeriod : Effect->PeriodSeconds;
			const float Phase = bChangeLightPhase ? LightPhase : Effect->Phase01;
			const float Base = bChangeBrightness ? Brightness : Light->Intensity;
			Effect->Configure(Type, Base, Period, Phase);
			LastAppliedEffectType = static_cast<uint8>(Type);
		}
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
	for (AActor* Actor : ShockScriptReflection::CollectActorsByLabel(World, ObjectLabel))
	{
		if (ApplyToActor(Actor))
		{
			++Applied;
		}
	}
	return Applied;
}

bool UShockActionSetLightProperties::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
