#include "ShockLightEffectComponent.h"

#include "Components/LightComponent.h"
#include "GameFramework/Actor.h"

UShockLightEffectComponent::UShockLightEffectComponent()
{
	PrimaryComponentTick.bCanEverTick = true;
	PrimaryComponentTick.bStartWithTickEnabled = false;
}

UShockLightEffectComponent* UShockLightEffectComponent::EnsureOnActor(AActor* Owner)
{
	if (!Owner)
	{
		return nullptr;
	}
	if (UShockLightEffectComponent* Existing = Owner->FindComponentByClass<UShockLightEffectComponent>())
	{
		return Existing;
	}
	UShockLightEffectComponent* Comp =
		NewObject<UShockLightEffectComponent>(Owner, TEXT("ShockLightEffect"));
	Owner->AddInstanceComponent(Comp);
	Comp->RegisterComponent();
	return Comp;
}

void UShockLightEffectComponent::Configure(
	EShockLightEffectType InType,
	float InBaseIntensity,
	float InPeriodSeconds,
	float InPhase01)
{
	EffectType = InType;
	BaseIntensity = FMath::Max(0.0f, InBaseIntensity);
	PeriodSeconds = FMath::Max(KINDA_SMALL_NUMBER, InPeriodSeconds);
	Phase01 = FMath::Clamp(InPhase01, 0.0f, 1.0f);
	Elapsed = Phase01 * PeriodSeconds;

	const bool bAnimate = EffectType != EShockLightEffectType::Steady
		&& EffectType != EShockLightEffectType::None;
	SetComponentTickEnabled(bAnimate);

	if (ULightComponent* Light = ResolveLight())
	{
		if (EffectType == EShockLightEffectType::None)
		{
			Light->SetIntensity(0.0f);
		}
		else
		{
			Light->SetIntensity(BaseIntensity);
		}
	}
}

ULightComponent* UShockLightEffectComponent::ResolveLight() const
{
	const AActor* Owner = GetOwner();
	return Owner ? Owner->FindComponentByClass<ULightComponent>() : nullptr;
}

void UShockLightEffectComponent::TickComponent(
	float DeltaTime,
	ELevelTick TickType,
	FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);
	ULightComponent* Light = ResolveLight();
	if (!Light || DeltaTime <= 0.0f)
	{
		return;
	}

	Elapsed += DeltaTime;
	const float Period = FMath::Max(KINDA_SMALL_NUMBER, PeriodSeconds);
	const float Cycle = FMath::Fmod(Elapsed, Period) / Period;
	float Scale = 1.0f;

	switch (EffectType)
	{
	case EShockLightEffectType::Pulse:
		Scale = 0.5f + 0.5f * FMath::Sin(Cycle * 2.0f * UE_PI);
		break;
	case EShockLightEffectType::SubtlePulse:
		Scale = 0.85f + 0.15f * FMath::Sin(Cycle * 2.0f * UE_PI);
		break;
	case EShockLightEffectType::Blink:
		Scale = Cycle < 0.5f ? 1.0f : 0.0f;
		break;
	case EShockLightEffectType::Strobe:
		Scale = Cycle < 0.1f ? 1.0f : 0.0f;
		break;
	case EShockLightEffectType::Flicker:
		// Cheap pseudo-random from time; not byte-accurate to UE2 LT_Flicker.
		Scale = 0.35f + 0.65f * FMath::Frac(FMath::Sin(Elapsed * 37.13f) * 43758.5453f);
		break;
	default:
		Scale = 1.0f;
		break;
	}

	Light->SetIntensity(BaseIntensity * Scale);
}
