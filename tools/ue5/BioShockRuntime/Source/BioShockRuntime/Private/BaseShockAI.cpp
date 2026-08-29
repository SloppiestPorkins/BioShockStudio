#include "BaseShockAI.h"

#include "ShockAiArchetype.h"
#include "ShockDamageLibrary.h"
#include "ShockPlayer.h"
#include "CollisionQueryParams.h"
#include "Components/CapsuleComponent.h"
#include "EngineUtils.h"
#include "Engine/World.h"
#include "GameFramework/CharacterMovementComponent.h"

namespace
{
constexpr float WalkSpeed = 350.0f;
constexpr float RunSpeed = 550.0f;
constexpr float SightConeHalfAngleDegrees = 45.0f;

bool IsBlockingSightHit(const FHitResult& Hit, const AActor* Target)
{
	if (!Hit.bBlockingHit)
	{
		return false;
	}
	const AActor* HitActor = Hit.GetActor();
	return HitActor && HitActor != Target;
}
}

ABaseShockAI::ABaseShockAI()
{
	SchemaClassName = TEXT("BaseShockAI");
	AutoPossessAI = EAutoPossessAI::Disabled;
	PrimaryActorTick.bCanEverTick = true;
	PrimaryActorTick.bStartWithTickEnabled = true;

	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		// Walk on the ground in real play. The slice uses direct AddMovementInput toward the
		// target (no nav-mesh yet — see UE5_FULL_PORT_PLAN §9). Headless verification, which has
		// no collision floor, opts into floorless motion via EnableFloorlessMovement().
		Move->MaxWalkSpeed = WalkSpeed;
		Move->MaxFlySpeed = RunSpeed;
	}
}

void ABaseShockAI::EnableFloorlessMovement()
{
	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->GravityScale = 0.0f;
		Move->SetMovementMode(MOVE_Flying);
	}
}

void ABaseShockAI::ConfigureIdentity(FName InType, FName InLabel)
{
	AITypeName = InType;
	ScriptLabel = InLabel;
}

void ABaseShockAI::ApplyArchetypeLookup(FName LookupKey)
{
	if (UShockAiArchetype* Archetype = UShockAiArchetypeLibrary::FindByKey(LookupKey))
	{
		UShockAiArchetypeLibrary::ApplyToAI(this, Archetype);
	}
}

void ABaseShockAI::ScriptedAttackTarget(AShockPawn* Target)
{
	CurrentScriptedAttackTarget = Target;
	if (IsAliveTarget(Target))
	{
		SetCombatTarget(Target);
		CombatState = EShockAICombatState::Chase;
	}
}

void ABaseShockAI::AddTargetToAttackOnSight(FName InTargetLabel)
{
	if (InTargetLabel.IsNone())
	{
		return;
	}
	AttackOnSightLabels.AddUnique(InTargetLabel);
}

bool ABaseShockAI::HasAttackOnSightLabel(FName InTargetLabel) const
{
	return AttackOnSightLabels.Contains(InTargetLabel);
}

void ABaseShockAI::SetAttachmentCategoryHidden(FName Category, bool bHideAttachments)
{
	if (Category.IsNone())
	{
		return;
	}
	HiddenAttachmentCategories.FindOrAdd(Category) = bHideAttachments;
}

bool ABaseShockAI::IsAttachmentCategoryHidden(FName Category) const
{
	if (const bool* Value = HiddenAttachmentCategories.Find(Category))
	{
		return *Value;
	}
	return false;
}

void ABaseShockAI::SetWeaponVisible(bool bVisible)
{
	bWeaponVisible = bVisible;
}

void ABaseShockAI::SetCollisionAvoidanceEnabled(bool bEnabled)
{
	bUseCollisionAvoidance = bEnabled;
}

void ABaseShockAI::BeginHeadTracking(FName TargetLabel, bool bQuickLook, float InDuration, FVector InOffset)
{
	bHeadTracking = true;
	HeadTrackTargetLabel = TargetLabel;
	bHeadTrackingQuickLook = bQuickLook;
	HeadTrackDuration = InDuration;
	HeadTrackOffset = InOffset;
}

void ABaseShockAI::NotifyAggroFromPlayer(AShockPawn* DamageInstigator)
{
	bAggroOnDamage = true;
	AggroInstigator = DamageInstigator;
	if (IsAliveTarget(DamageInstigator))
	{
		SetCombatTarget(DamageInstigator);
		CombatState = EShockAICombatState::Chase;
	}
}

void ABaseShockAI::AdvanceAutonomousCombat(float DeltaSeconds)
{
	// Headless verification entry point — no world tick, no collision floor.
	EnableFloorlessMovement();
	Tick(DeltaSeconds);
	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->TickComponent(DeltaSeconds, LEVELTICK_All, nullptr);
	}
}

void ABaseShockAI::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	TickCombat(DeltaSeconds);
}

bool ABaseShockAI::IsCombatLoopGated() const
{
	return bIsDead || bToldToWait || !bCanAttack;
}

bool ABaseShockAI::IsAliveTarget(const AShockPawn* Target) const
{
	return Target && !Target->IsDead() && Target->GetCurrentHealth() > 0.0f;
}

void ABaseShockAI::SetCombatTarget(AShockPawn* Target)
{
	CombatTarget = Target;
	OutOfSightTimer = 0.0f;
}

void ABaseShockAI::ClearCombatTarget()
{
	CombatTarget = nullptr;
	OutOfSightTimer = 0.0f;
}

float ABaseShockAI::DistanceToTarget(const AShockPawn* Target) const
{
	if (!Target)
	{
		return TNumericLimits<float>::Max();
	}
	return FVector::Dist2D(GetActorLocation(), Target->GetActorLocation());
}

void ABaseShockAI::FaceTargetYaw(const AShockPawn* Target)
{
	if (!Target)
	{
		return;
	}
	FVector ToTarget = Target->GetActorLocation() - GetActorLocation();
	ToTarget.Z = 0.0f;
	if (ToTarget.IsNearlyZero())
	{
		return;
	}
	SetActorRotation(FRotationMatrix::MakeFromX(ToTarget.GetSafeNormal()).Rotator());
}

FName ABaseShockAI::GetPlayerPerceptionLabel(const AShockPlayer* Player) const
{
	if (!Player)
	{
		return NAME_None;
	}
#if WITH_EDITOR
	return FName(*Player->GetActorLabel());
#else
	(void)Player;
	return NAME_None;
#endif
}

bool ABaseShockAI::CanPerceivePlayer(const AShockPlayer* Player) const
{
	if (!Player || !IsAliveTarget(Player))
	{
		return false;
	}

	const float Dist = DistanceToTarget(Player);
	if (Dist > SightRadius)
	{
		return false;
	}

	if (!bAlwaysSeePlayer)
	{
		const FVector Forward = GetActorForwardVector().GetSafeNormal2D();
		const FVector ToPlayer = (Player->GetActorLocation() - GetActorLocation()).GetSafeNormal2D();
		const float MinDot = FMath::Cos(FMath::DegreesToRadians(SightConeHalfAngleDegrees));
		if (FVector::DotProduct(Forward, ToPlayer) < MinDot)
		{
			return false;
		}

		UWorld* World = GetWorld();
		if (!World)
		{
			return false;
		}

		FVector EyeLoc = GetActorLocation();
		if (const UCapsuleComponent* Capsule = GetCapsuleComponent())
		{
			EyeLoc.Z += Capsule->GetScaledCapsuleHalfHeight();
		}
		const FVector TargetLoc = Player->GetActorLocation();

		FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockAISight), false, this);
		Params.AddIgnoredActor(Player);
		FHitResult Hit;
		if (World->LineTraceSingleByChannel(
				Hit,
				EyeLoc,
				TargetLoc,
				ECC_Visibility,
				Params))
		{
			if (IsBlockingSightHit(Hit, Player))
			{
				return false;
			}
		}
	}

	return true;
}

bool ABaseShockAI::TryAcquireTargetFromPerception()
{
	UWorld* World = GetWorld();
	if (!World || !bVisionOn)
	{
		return false;
	}

	for (TActorIterator<AShockPlayer> It(World); It; ++It)
	{
		AShockPlayer* Player = *It;
		if (!CanPerceivePlayer(Player))
		{
			continue;
		}

		const FName PlayerLabel = GetPlayerPerceptionLabel(Player);
		const bool bLabelMatch = HasAttackOnSightLabel(PlayerLabel);
		const bool bAggroMatch = bAggroOnDamage && Player == AggroInstigator;
		if (!bLabelMatch && !bAggroMatch)
		{
			continue;
		}

		SetCombatTarget(Player);
		return true;
	}
	return false;
}

void ABaseShockAI::TickCombat(float DeltaSeconds)
{
	if (MeleeCooldownRemaining > 0.0f)
	{
		MeleeCooldownRemaining = FMath::Max(0.0f, MeleeCooldownRemaining - DeltaSeconds);
	}

	if (IsCombatLoopGated())
	{
		CombatState = EShockAICombatState::Idle;
		ClearCombatTarget();
		return;
	}

	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		const float Speed = bMovementShouldRun ? RunSpeed : WalkSpeed;
		Move->MaxWalkSpeed = Speed;
		Move->MaxFlySpeed = Speed;
	}

	switch (CombatState)
	{
	case EShockAICombatState::Idle:
	{
		if (IsAliveTarget(CurrentScriptedAttackTarget))
		{
			SetCombatTarget(CurrentScriptedAttackTarget);
			CombatState = EShockAICombatState::Chase;
			break;
		}

		PerceptionScanAccumulator += DeltaSeconds;
		if (PerceptionScanAccumulator >= PerceptionScanInterval)
		{
			PerceptionScanAccumulator = 0.0f;
			if (TryAcquireTargetFromPerception())
			{
				CombatState = EShockAICombatState::Chase;
			}
		}
		break;
	}
	case EShockAICombatState::Chase:
	{
		if (!IsAliveTarget(CombatTarget))
		{
			ClearCombatTarget();
			CombatState = EShockAICombatState::Idle;
			break;
		}

		const float Dist = DistanceToTarget(CombatTarget);
		const float LoseRadius = SightRadius * 1.5f;
		if (Dist > LoseRadius)
		{
			OutOfSightTimer += DeltaSeconds;
			if (OutOfSightTimer >= LoseTargetSeconds)
			{
				ClearCombatTarget();
				CombatState = EShockAICombatState::Idle;
				break;
			}
		}
		else
		{
			OutOfSightTimer = 0.0f;
		}

		if (Dist <= MeleeRange)
		{
			CombatState = EShockAICombatState::Attack;
			break;
		}

		FaceTargetYaw(CombatTarget);
		const FVector ToTarget = CombatTarget->GetActorLocation() - GetActorLocation();
		FVector MoveDir = ToTarget;
		MoveDir.Z = 0.0f;
		if (!MoveDir.IsNearlyZero())
		{
			const FVector Before = GetActorLocation();
			const FVector Norm = MoveDir.GetSafeNormal();
			AddMovementInput(Norm, 1.0f);
			// The engine ticks the movement component itself in real play. When nothing moved us
			// (headless with no floor, or a frame where input hadn't been consumed yet), close the
			// distance directly so the slice still works without a nav-mesh.
			if (FVector::Dist2D(Before, GetActorLocation()) < 1.0f)
			{
				const float Speed = bMovementShouldRun ? RunSpeed : WalkSpeed;
				SetActorLocation(Before + Norm * Speed * DeltaSeconds, true);
			}
		}
		break;
	}
	case EShockAICombatState::Attack:
	{
		if (!IsAliveTarget(CombatTarget))
		{
			ClearCombatTarget();
			CombatState = EShockAICombatState::Idle;
			break;
		}

		const float Dist = DistanceToTarget(CombatTarget);
		if (Dist > MeleeRange)
		{
			CombatState = EShockAICombatState::Chase;
			break;
		}

		FaceTargetYaw(CombatTarget);
		if (MeleeCooldownRemaining <= 0.0f)
		{
			UShockDamageLibrary::ApplyDamage(CombatTarget, MeleeDamage, this, FName(TEXT("Melee")));
			MeleeCooldownRemaining = MeleeCooldown;
		}
		break;
	}
	default:
		CombatState = EShockAICombatState::Idle;
		break;
	}
}

TArray<ABaseShockAI*> ABaseShockAI::CollectLabeled(UWorld* World, FName Label)
{
	TArray<ABaseShockAI*> Out;
	if (!World || Label.IsNone())
	{
		return Out;
	}
	const FString Want = Label.ToString();
	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		ABaseShockAI* AI = *It;
		if (!AI)
		{
			continue;
		}
#if WITH_EDITOR
		if (AI->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			Out.Add(AI);
			continue;
		}
#endif
		if (AI->GetScriptLabel().ToString().Equals(Want, ESearchCase::CaseSensitive))
		{
			Out.Add(AI);
		}
	}
	return Out;
}
