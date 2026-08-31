#include "ShockResearchCamera.h"

#include "BaseShockAI.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "CollisionQueryParams.h"
#include "ShockPlayer.h"

namespace
{
constexpr float IdealPhotoDistanceMin = 400.0f; // PLAUSIBLE — CameraDamageFactory size band
constexpr float IdealPhotoDistanceMax = 1200.0f; // PLAUSIBLE
constexpr float TooClosePhotoDistance = 200.0f; // PLAUSIBLE
constexpr float TooFarPhotoDistance = 2500.0f; // PLAUSIBLE
constexpr float CombatPhotoBonus = 0.15f; // PLAUSIBLE — training tip: combat photos earn extra
}

AShockResearchCamera::AShockResearchCamera()
{
	bEnforceAmmo = false;
	FireRate = 1.5f; // ResearchCamera.uc BaseFireRate
	HitscanDamage = 0.0f;
}

void AShockResearchCamera::ClearPhotoCooldownForVerify()
{
	LastGlobalPhotoWorldSeconds = -1.0;
	LastFireWorldSeconds = -1.0;
	LastPhotoTimeByTarget.Empty();
}

void AShockResearchCamera::AdvancePhotoCooldownForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f)
	{
		return;
	}
	if (LastGlobalPhotoWorldSeconds >= 0.0)
	{
		LastGlobalPhotoWorldSeconds -= static_cast<double>(DeltaSeconds);
	}
	TArray<TWeakObjectPtr<ABaseShockAI>> Keys;
	LastPhotoTimeByTarget.GetKeys(Keys);
	for (const TWeakObjectPtr<ABaseShockAI>& Key : Keys)
	{
		if (double* Time = LastPhotoTimeByTarget.Find(Key))
		{
			*Time -= static_cast<double>(DeltaSeconds);
		}
	}
}

bool AShockResearchCamera::HasLineOfSightTo(
	AActor* InstigatorActor,
	const FVector& Start,
	const ABaseShockAI* Target) const
{
	if (!Target)
	{
		return false;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return false;
	}

	const FVector End = Target->GetActorLocation();
	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockResearchCameraLoS), false, InstigatorActor);
	Params.AddIgnoredActor(this);
	if (InstigatorActor)
	{
		Params.AddIgnoredActor(InstigatorActor);
	}

	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	ObjectParams.AddObjectTypesToQuery(ECC_WorldStatic);

	if (!World->LineTraceSingleByObjectType(Hit, Start, End, ObjectParams, Params))
	{
		return true;
	}

	return Hit.GetActor() == Target;
}

float AShockResearchCamera::ComputePhotoScore(
	const FVector& Start,
	const FVector& NormDir,
	const ABaseShockAI* Target) const
{
	if (!Target)
	{
		return 0.0f;
	}

	const FVector ToTarget = Target->GetActorLocation() - Start;
	const float Dist = ToTarget.Size();
	if (Dist <= KINDA_SMALL_NUMBER || Dist > MaxPhotoRange)
	{
		return 0.0f;
	}

	const float CenterDot = FVector::DotProduct(NormDir, ToTarget / Dist);
	const float ConeCos = FMath::Cos(FMath::DegreesToRadians(PhotoConeHalfAngleDeg));
	if (CenterDot < ConeCos)
	{
		return 0.0f;
	}

	const float CenteringFactor = FMath::Clamp((CenterDot - ConeCos) / FMath::Max(1.0f - ConeCos, KINDA_SMALL_NUMBER), 0.0f, 1.0f);

	float DistanceFactor = 1.0f;
	if (Dist < IdealPhotoDistanceMin)
	{
		DistanceFactor = FMath::Clamp((Dist - TooClosePhotoDistance) / (IdealPhotoDistanceMin - TooClosePhotoDistance), 0.0f, 1.0f);
	}
	else if (Dist > IdealPhotoDistanceMax)
	{
		DistanceFactor = FMath::Clamp((TooFarPhotoDistance - Dist) / (TooFarPhotoDistance - IdealPhotoDistanceMax), 0.0f, 1.0f);
	}

	float Score = CenteringFactor * 0.6f + DistanceFactor * 0.4f;
	if (Target->GetCombatTargetPawn() != nullptr)
	{
		Score = FMath::Min(1.0f, Score + CombatPhotoBonus);
	}
	return FMath::Clamp(Score, 0.0f, 1.0f);
}

ABaseShockAI* AShockResearchCamera::FindBestPhotoSubject(
	UWorld* World,
	AActor* InstigatorActor,
	const FVector& Start,
	const FVector& NormDir) const
{
	if (!World || NormDir.IsNearlyZero())
	{
		return nullptr;
	}

	ABaseShockAI* Best = nullptr;
	float BestDistSq = TNumericLimits<float>::Max();

	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		ABaseShockAI* AI = *It;
		if (!AI || AI->IsDead() || AI->AITypeName.IsNone())
		{
			continue;
		}

		const FVector ToTarget = AI->GetActorLocation() - Start;
		const float DistSq = ToTarget.SizeSquared();
		if (DistSq <= KINDA_SMALL_NUMBER || DistSq > FMath::Square(MaxPhotoRange))
		{
			continue;
		}

		const float CenterDot = FVector::DotProduct(NormDir, ToTarget.GetSafeNormal());
		const float ConeCos = FMath::Cos(FMath::DegreesToRadians(PhotoConeHalfAngleDeg));
		if (CenterDot < ConeCos)
		{
			continue;
		}

		if (!HasLineOfSightTo(InstigatorActor, Start, AI))
		{
			continue;
		}

		if (DistSq < BestDistSq)
		{
			BestDistSq = DistSq;
			Best = AI;
		}
	}

	return Best;
}

bool AShockResearchCamera::FireAt(AActor* InstigatorActor, FVector Start, FVector Direction)
{
	UWorld* World = GetWorld();
	if (!World || Direction.IsNearlyZero())
	{
		return false;
	}

	AShockPlayer* Photographer = Cast<AShockPlayer>(InstigatorActor);
	if (!Photographer)
	{
		return false;
	}

	if (!CanFireNow(World))
	{
		return false;
	}

	LastFireWorldSeconds = World->GetTimeSeconds();
	LastGlobalPhotoWorldSeconds = LastFireWorldSeconds;
	++FireCount;

	const FVector NormDir = Direction.GetSafeNormal();
	ABaseShockAI* Subject = FindBestPhotoSubject(World, InstigatorActor, Start, NormDir);
	LastPhotoScore = ComputePhotoScore(Start, NormDir, Subject);
	LastPhotoPoints = 0.0f;

	if (!Subject || LastPhotoScore <= KINDA_SMALL_NUMBER)
	{
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_PHOTO archetype=None score=%.3f points=0.000 level=0"),
			LastPhotoScore);
		return false;
	}

	const double Now = World->GetTimeSeconds();
	if (const double* LastTime = LastPhotoTimeByTarget.Find(Subject))
	{
		if ((Now - *LastTime) < static_cast<double>(PhotoCooldownSeconds) - KINDA_SMALL_NUMBER)
		{
			UE_LOG(
				LogTemp,
				Display,
				TEXT("BIOSHOCK_PHOTO archetype=%s score=%.3f points=0.000 level=%d (cooldown)"),
				*Subject->AITypeName.ToString(),
				LastPhotoScore,
				Photographer->GetResearchLevel(Subject->AITypeName));
			return false;
		}
	}

	LastPhotoPoints = LastPhotoScore * BasePhotoPoints;
	const int32 LevelBefore = Photographer->GetResearchLevel(Subject->AITypeName);
	Photographer->AddResearchPoints(Subject->AITypeName, LastPhotoPoints);
	const int32 LevelAfter = Photographer->GetResearchLevel(Subject->AITypeName);
	LastPhotoTimeByTarget.Add(Subject, Now);

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PHOTO archetype=%s score=%.3f points=%.3f level=%d"),
		*Subject->AITypeName.ToString(),
		LastPhotoScore,
		LastPhotoPoints,
		LevelAfter);
	(void)LevelBefore;
	return LastPhotoPoints > 0.0f;
}
