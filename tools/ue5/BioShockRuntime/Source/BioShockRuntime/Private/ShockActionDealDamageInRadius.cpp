#include "ShockActionDealDamageInRadius.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockPawn.h"

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

UShockActionDealDamageInRadius::UShockActionDealDamageInRadius()
{
	ActionClassName = TEXT("ActionDealDamageInRadius");
	DamageAmount = 100.0f;
	DamageType = 8;
	InnerRadius = 256;
	OuterRadius = 256;
}

void UShockActionDealDamageInRadius::Configure(FName InSource, float InDamage, int32 InInner, int32 InOuter)
{
	SourceActorLabel = InSource;
	DamageAmount = InDamage;
	InnerRadius = InInner;
	OuterRadius = InOuter;
}

bool UShockActionDealDamageInRadius::RequestDeal()
{
	if (SourceActorLabel.IsNone())
	{
		return false;
	}
	LastSourceActorLabel = SourceActorLabel;
	return true;
}

int32 UShockActionDealDamageInRadius::ApplyInWorld(UWorld* World)
{
	if (!RequestDeal() || !World || DamageAmount <= 0.0f || OuterRadius <= 0)
	{
		return 0;
	}
	AActor* Source = FindActorByEditorLabel(World, SourceActorLabel);
	if (!Source)
	{
		return 0;
	}
	const FVector Origin = Source->GetActorLocation();
	const float RadiusSq = static_cast<float>(OuterRadius) * static_cast<float>(OuterRadius);
	int32 Applied = 0;
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AShockPawn* Pawn = Cast<AShockPawn>(*It);
		if (!Pawn)
		{
			continue;
		}
		if (FVector::DistSquared(Origin, Pawn->GetActorLocation()) > RadiusSq)
		{
			continue;
		}
		Pawn->EnsureHealthInitialized();
		Pawn->ApplyAuthoredDamage(DamageAmount);
		++Applied;
	}
	return Applied;
}
