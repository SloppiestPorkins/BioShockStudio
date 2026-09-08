#include "BaseShockAI.h"

#include "ShockAudioLibrary.h"
#include "ShockDamageLibrary.h"

#include "ShockAiArchetype.h"
#include "ShockAIBrain.h"
#include "ShockDamageLibrary.h"
#include "ShockPlayer.h"
#include "ShockPhysicsLibrary.h"
#include "ShockWeapon.h"
#include "AIController.h"
#include "Animation/AnimSequence.h"
#include "Animation/AnimSingleNodeInstance.h"
#include "CollisionQueryParams.h"
#include "Components/CapsuleComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "EngineUtils.h"
#include "Engine/World.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Materials/Material.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Navigation/PathFollowingComponent.h"
#include "NavigationSystem.h"
#include "PhysicsEngine/PhysicsAsset.h"
#include "TimerManager.h"

namespace
{
constexpr float WalkSpeed = 350.0f;
constexpr float RunSpeed = 550.0f;
// Aggressor.uc normal vision: 40-degree near cone and 20-degree long cone.
constexpr float NearSightHalfAngleDegrees = 20.0f;
constexpr float FarSightHalfAngleDegrees = 10.0f;
constexpr float NearSightDistance = 700.0f;
constexpr float GroupAlertRadius = 1000.0f;
constexpr float FleeDistance = 1000.0f;
constexpr float NavMoveRefreshInterval = 0.5f;
constexpr float NavMoveRetargetThreshold = 150.0f;

bool IsBlockingSightHit(const FHitResult& Hit, const AActor* Target)
{
	if (!Hit.bBlockingHit)
	{
		return false;
	}
	const AActor* HitActor = Hit.GetActor();
	return HitActor && HitActor != Target;
}

bool SlotNameLooksRanged(const FString& SlotName)
{
	if (SlotName.IsEmpty())
	{
		return false;
	}
	if (SlotName.Contains(TEXT("Pistol"), ESearchCase::IgnoreCase)
		|| SlotName.Contains(TEXT("Tommy"), ESearchCase::IgnoreCase)
		|| SlotName.Contains(TEXT("Gun"), ESearchCase::IgnoreCase)
		|| SlotName.Contains(TEXT("Leadhead"), ESearchCase::IgnoreCase)
		|| SlotName.Contains(TEXT("Thug"), ESearchCase::IgnoreCase)
		|| SlotName.Contains(TEXT("Ranged"), ESearchCase::IgnoreCase))
	{
		return true;
	}
	return false;
}

FName FirstPresentBone(const USkeletalMeshComponent* Body, const TCHAR* const* Names, int32 Count)
{
	if (!Body)
	{
		return NAME_None;
	}
	for (int32 i = 0; i < Count; ++i)
	{
		const FName Candidate(Names[i]);
		if (Body->GetBoneIndex(Candidate) != INDEX_NONE)
		{
			return Candidate;
		}
	}
	return NAME_None;
}

float MeasureMeshUprightDelta(USkeletalMeshComponent* Body)
{
	if (!Body || !Body->GetSkeletalMeshAsset())
	{
		return 0.0f;
	}

	static const TCHAR* HeadNames[] = {TEXT("Bip01_Head"), TEXT("Bip01 Head"), TEXT("Head")};
	static const TCHAR* FootNames[] = {TEXT("Bip01_L_Foot"), TEXT("Bip01_R_Foot"), TEXT("Bip01 L Foot")};
	const FName HeadBone = FirstPresentBone(Body, HeadNames, UE_ARRAY_COUNT(HeadNames));
	const FName FootBone = FirstPresentBone(Body, FootNames, UE_ARRAY_COUNT(FootNames));
	if (HeadBone.IsNone() || FootBone.IsNone())
	{
		return 0.0f;
	}

	Body->TickAnimation(0.0f, /*bNeedsValidRootMotion*/ false);
	Body->RefreshBoneTransforms();
	const float HeadZ = Body->GetBoneLocation(HeadBone).Z;
	const float FootZ = Body->GetBoneLocation(FootBone).Z;
	return HeadZ - FootZ;
}

bool ArchetypeHasRangedWeapon(const UShockAiArchetype* Archetype)
{
	if (!Archetype)
	{
		return false;
	}
	if (Archetype->bIsRanged)
	{
		return true;
	}
	if (SlotNameLooksRanged(Archetype->AITypeClassName))
	{
		return true;
	}
	for (const FShockAiArchetypeLoadoutSlot& Slot : Archetype->WeaponSlots)
	{
		if (SlotNameLooksRanged(Slot.Name) || SlotNameLooksRanged(Slot.Replacement))
		{
			return true;
		}
	}
	return false;
}
}

ABaseShockAI::ABaseShockAI()
{
	SchemaClassName = TEXT("BaseShockAI");
	AIControllerClass = AAIController::StaticClass();
	AutoPossessAI = EAutoPossessAI::PlacedInWorldOrSpawned;
	PrimaryActorTick.bCanEverTick = true;
	PrimaryActorTick.bStartWithTickEnabled = true;

	Brain = CreateDefaultSubobject<UShockAIBrain>(TEXT("ShockAIBrain"));

	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		// Walk on the ground in real play. Chase prefers AAIController path-following when nav data
		// exists; missing nav falls back to direct AddMovementInput (see UE5_FULL_PORT_PLAN §9).
		// Headless verification opts into floorless motion via EnableFloorlessMovement().
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

FName ABaseShockAI::GetBehaviourStateName() const
{
	switch (BehaviourState)
	{
	case EShockAIBehaviourState::Idle: return TEXT("Idle");
	case EShockAIBehaviourState::Patrol: return TEXT("Patrol");
	case EShockAIBehaviourState::Alert: return TEXT("Alert");
	case EShockAIBehaviourState::Investigate: return TEXT("Investigate");
	case EShockAIBehaviourState::Search: return TEXT("Search");
	case EShockAIBehaviourState::Combat: return TEXT("Combat");
	case EShockAIBehaviourState::Flee: return TEXT("Flee");
	default: return TEXT("Unknown");
	}
}

void ABaseShockAI::EnterBehaviourState(EShockAIBehaviourState NewState)
{
	if (BehaviourState == NewState)
	{
		return;
	}
	StopNavChase();
	BehaviourState = NewState;
	BehaviourStateSeconds = 0.0f;
	SearchTurnAccumulator = 0.0f;
	if (NewState == EShockAIBehaviourState::Search)
	{
		// EcologyFighter.uc MinSearchTime/MaxSearchTime.
		SearchDurationSeconds = FMath::FRandRange(12.0f, 20.0f);
	}
	if (NewState == EShockAIBehaviourState::Combat)
	{
		AlertNearbySplicers();
	}

	const FName Event =
		NewState == EShockAIBehaviourState::Investigate ? FName(TEXT("CurrentlyInvestigating")) :
		NewState == EShockAIBehaviourState::Search ? FName(TEXT("TargetLost")) :
		NewState == EShockAIBehaviourState::Flee ? FName(TEXT("Terrified")) :
		NAME_None;
	if (!Event.IsNone() && !bMuted)
	{
		UShockAudioLibrary::SpawnEventAttached(TEXT("ShockAI"), Event, RootComponent);
	}
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_AI state=%s archetype=%s hasPose=%d"),
		*GetBehaviourStateName().ToString(),
		*AITypeName.ToString(),
		GetPlayingAnimationNameForVerify().IsNone() ? 0 : 1);
}

void ABaseShockAI::NotifySuspiciousNoise(FVector NoiseLocation, float Loudness, FName NoiseCategory)
{
	if (!bHearingOn || bIsDead || Loudness <= 0.0f || BehaviourState == EShockAIBehaviourState::Combat)
	{
		return;
	}

	LastKnownTargetDirection = (NoiseLocation - GetActorLocation()).GetSafeNormal2D();
	LastKnownTargetLocation = NoiseLocation;
	StateMoveDestination = NoiseLocation;
	EnterBehaviourState(EShockAIBehaviourState::Alert);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_AI_HEARD ai=%s category=%s loudness=%.2f"),
		*GetName(), *NoiseCategory.ToString(), Loudness);
}

void ABaseShockAI::BroadcastSuspiciousNoise(
	UWorld* World,
	FVector NoiseLocation,
	float Loudness,
	FName NoiseCategory,
	AActor* Source,
	float Radius)
{
	if (!World || Loudness <= 0.0f || Radius <= 0.0f)
	{
		return;
	}
	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		ABaseShockAI* AI = *It;
		if (AI && AI != Source && !AI->IsDead()
			&& FVector::DistSquared(AI->GetActorLocation(), NoiseLocation) <= FMath::Square(Radius))
		{
			AI->NotifySuspiciousNoise(NoiseLocation, Loudness, NoiseCategory);
		}
	}
}

void ABaseShockAI::SimulateSightEvent(AShockPawn* Target)
{
	if (!IsAliveTarget(Target))
	{
		return;
	}
	SetCombatTarget(Target);
	LastKnownTargetLocation = Target->GetActorLocation();
	LastKnownTargetDirection = Target->GetVelocity().GetSafeNormal2D();
	EnterBehaviourState(EShockAIBehaviourState::Combat);
}

void ABaseShockAI::AlertNearbySplicers()
{
	if (bGroupAlertSent || !GetWorld())
	{
		return;
	}
	bGroupAlertSent = true;
	const FVector AlertLocation = CombatTarget ? CombatTarget->GetActorLocation() : GetActorLocation();
	BroadcastSuspiciousNoise(
		GetWorld(), AlertLocation, 1.0f, TEXT("Combat"), this, GroupAlertRadius);
}

void ABaseShockAI::ApplyArchetypeLookup(FName LookupKey)
{
	if (UShockAiArchetype* Archetype = UShockAiArchetypeLibrary::FindByKey(LookupKey))
	{
		UShockAiArchetypeLibrary::ApplyToAI(this, Archetype);
		SpawnArchetypeWeaponIfNeeded(Archetype);
	}
}

void ABaseShockAI::EquipAIWeapon(AShockWeapon* Weapon)
{
	AIWeapon = Weapon;
}

void ABaseShockAI::SetSuppressCombatLineOfSight(bool bSuppress)
{
	bSuppressCombatLineOfSight = bSuppress;
}

int32 ABaseShockAI::GetAIWeaponFireCount() const
{
	return AIWeapon ? AIWeapon->GetFireCount() : 0;
}

void ABaseShockAI::SpawnArchetypeWeaponIfNeeded(const UShockAiArchetype* Archetype)
{
	if (!Archetype || AIWeapon || !ArchetypeHasRangedWeapon(Archetype))
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	FActorSpawnParameters Params;
	Params.Owner = this;
	Params.Instigator = this;
	AShockWeapon* Weapon = World->SpawnActor<AShockWeapon>(
		AShockWeapon::StaticClass(),
		GetActorLocation(),
		GetActorRotation(),
		Params);
	if (!Weapon)
	{
		return;
	}

	Weapon->ConfigureHitscan(20.0f, 10000.0f);
	EquipAIWeapon(Weapon);
}

void ABaseShockAI::ScriptedAttackTarget(AShockPawn* Target)
{
	CurrentScriptedAttackTarget = Target;
	if (IsAliveTarget(Target))
	{
		SetCombatTarget(Target);
		LastKnownTargetLocation = Target->GetActorLocation();
		EnterBehaviourState(EShockAIBehaviourState::Combat);
		if (bUseBrain && Brain)
		{
			Brain->NotifyPendingKillTarget(Target);
		}
		else
		{
			CombatState = EShockAICombatState::Chase;
		}
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
	if (EnragedRemaining > 0.0f && Cast<AShockPlayer>(DamageInstigator))
	{
		return;
	}

	bAggroOnDamage = true;
	AggroInstigator = DamageInstigator;
	if (IsAliveTarget(DamageInstigator))
	{
		SetCombatTarget(DamageInstigator);
		LastKnownTargetLocation = DamageInstigator->GetActorLocation();
		EnterBehaviourState(EShockAIBehaviourState::Combat);
		if (bUseBrain && Brain)
		{
			Brain->NotifyAggro(DamageInstigator);
		}
		else
		{
			CombatState = EShockAICombatState::Chase;
		}
	}
}

void ABaseShockAI::ReactToHit(float Amount, AActor* DamageInstigator)
{
	if (bIsDead || bCombatLoopStopped || Amount <= 0.0f)
	{
		return;
	}

	const float MaxHealth = AuthoredMaxHealth > 0.0f
		? AuthoredMaxHealth
		: FMath::Max(CurrentHealth + Amount, 100.0f);
	const float DamageFraction = FMath::Clamp(Amount / MaxHealth, 0.0f, 1.0f);
	const float StaggerDuration = FMath::Min(
		HitStaggerSeconds * (0.85f + 0.15f * DamageFraction),
		HitStaggerSeconds * 1.25f);

	if (HitReactRateLimitRemaining > 0.0f)
	{
		HitReactRemaining = FMath::Min(HitReactRemaining + 0.06f, HitStaggerSeconds * 1.5f);
		return;
	}

	HitReactRemaining = FMath::Max(HitReactRemaining, StaggerDuration);
	HitReactRateLimitRemaining = HitReactRateLimitSeconds;
	UShockAudioLibrary::SpawnEventAttached(TEXT("ShockAI"), TEXT("DamagedSpeech"), RootComponent);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_AUDIO vocal ai=%s event=DamagedSpeech"), *GetName());

	const FString AiName = ScriptLabel.IsNone() ? GetName() : ScriptLabel.ToString();
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_HIT_REACT ai=%s amount=%.0f stagger=%.2f"),
		*AiName,
		Amount,
		HitReactRemaining);

	if (!bCannotBecomeUnconscious && DamageInstigator)
	{
		FVector AwayDir = GetActorLocation() - DamageInstigator->GetActorLocation();
		AwayDir.Z = 0.0f;
		if (!AwayDir.IsNearlyZero())
		{
			AwayDir = AwayDir.GetSafeNormal();
			const float KnockScale = FMath::Clamp(0.35f + 0.65f * DamageFraction, 0.35f, 1.0f);
			const float ImpulseMag = FMath::Clamp(HitKnockback * KnockScale, 80.0f, HitKnockback);
			LaunchCharacter(AwayDir * ImpulseMag, true, true);
			const float KnockDist = FMath::Clamp(ImpulseMag * 0.08f, 12.0f, 48.0f);
			SetActorLocation(GetActorLocation() + AwayDir * KnockDist, true);
		}
	}

	ApplyHitFlash();
}

void ABaseShockAI::ReactToPlasmidStun(float Duration, AActor* DamageInstigator)
{
	if (bIsDead || bCombatLoopStopped || Duration <= 0.0f)
	{
		return;
	}

	HitReactRemaining = FMath::Max(HitReactRemaining, Duration);
	HitReactRateLimitRemaining = 0.0f;

	const FString AiName = ScriptLabel.IsNone() ? GetName() : ScriptLabel.ToString();
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PLASMID_STUN ai=%s duration=%.2f"),
		*AiName,
		HitReactRemaining);

	if (!bCannotBecomeUnconscious && DamageInstigator)
	{
		FVector AwayDir = GetActorLocation() - DamageInstigator->GetActorLocation();
		AwayDir.Z = 0.0f;
		if (!AwayDir.IsNearlyZero())
		{
			AwayDir = AwayDir.GetSafeNormal();
			const float ImpulseMag = HitKnockback * 0.5f;
			LaunchCharacter(AwayDir * ImpulseMag, true, true);
		}
	}

	ApplyHitFlash();
}

void ABaseShockAI::Ignite(float Seconds, float Dps, AActor* DamageInstigator)
{
	if (bIsDead || bCombatLoopStopped || Seconds <= 0.0f || Dps <= 0.0f)
	{
		return;
	}

	BurningRemaining = FMath::Max(BurningRemaining, Seconds);
	BurningDps = Dps;
	BurningInstigator = DamageInstigator;
}

void ABaseShockAI::ApplyChill(float Seconds)
{
	if (bIsDead || bCombatLoopStopped || Seconds <= 0.0f)
	{
		return;
	}

	ChillRemaining = FMath::Max(ChillRemaining, Seconds);
}

void ABaseShockAI::FreezeSolid(float Seconds, AActor* DamageInstigator)
{
	if (bIsDead || bCombatLoopStopped || Seconds <= 0.0f)
	{
		return;
	}

	const bool bWasFrozen = FrozenSolidRemaining > 0.0f;
	FrozenSolidRemaining = FMath::Max(FrozenSolidRemaining, Seconds);
	FrozenInstigator = DamageInstigator;

	if (!bWasFrozen)
	{
		UShockPhysicsLibrary::SetActorPhysicsFrozen(this, true);
	}
	ApplyFrozenFlash();
}

void ABaseShockAI::ApplyEnrage(float Seconds, AActor* DamageInstigator)
{
	(void)DamageInstigator;
	if (bIsDead || bCombatLoopStopped || Seconds <= 0.0f)
	{
		return;
	}

	EnragedRemaining = FMath::Max(EnragedRemaining, Seconds);
	if (CombatTarget && Cast<AShockPlayer>(CombatTarget))
	{
		ClearCombatTarget();
		if (bUseBrain && Brain)
		{
			Brain->NotifyPendingKillTarget(nullptr);
		}
	}
}

AShockPawn* ABaseShockAI::FindNearestOtherAIForEnrage() const
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return nullptr;
	}

	AShockPawn* Best = nullptr;
	float BestDistSq = TNumericLimits<float>::Max();
	const FVector Origin = GetActorLocation();

	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		ABaseShockAI* Other = *It;
		if (!Other || Other == this || Other->IsDead())
		{
			continue;
		}
		const float DistSq = FVector::DistSquared(Origin, Other->GetActorLocation());
		if (DistSq < BestDistSq)
		{
			BestDistSq = DistSq;
			Best = Other;
		}
	}
	return Best;
}

void ABaseShockAI::TickStatusEffects(float DeltaSeconds)
{
	if (ChillRemaining > 0.0f && !bIsDead)
	{
		ChillRemaining = FMath::Max(0.0f, ChillRemaining - DeltaSeconds);
	}

	if (FrozenSolidRemaining > 0.0f && !bIsDead)
	{
		FrozenSolidRemaining = FMath::Max(0.0f, FrozenSolidRemaining - DeltaSeconds);
		FrozenLogAccumulator += DeltaSeconds;
		if (FrozenLogAccumulator >= 1.0f)
		{
			FrozenLogAccumulator = 0.0f;
			const FString AiName = ScriptLabel.IsNone() ? GetName() : ScriptLabel.ToString();
			UE_LOG(
				LogTemp,
				Display,
				TEXT("BIOSHOCK_FROZEN ai=%s remaining=%.1f"),
				*AiName,
				FrozenSolidRemaining);
			ApplyFrozenFlash();
		}
		if (FrozenSolidRemaining <= 0.0f)
		{
			ClearFrozenState();
		}
	}

	if (EnragedRemaining > 0.0f && !bIsDead)
	{
		EnragedRemaining = FMath::Max(0.0f, EnragedRemaining - DeltaSeconds);
		if (EnragedRemaining <= 0.0f)
		{
			const FString AiName = ScriptLabel.IsNone() ? GetName() : ScriptLabel.ToString();
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_ENRAGE_END ai=%s"), *AiName);
			if (CombatTarget && Cast<ABaseShockAI>(CombatTarget))
			{
				ClearCombatTarget();
				if (bUseBrain && Brain)
				{
					Brain->NotifyPendingKillTarget(nullptr);
				}
			}
		}
	}

	if (BurningRemaining <= 0.0f || bIsDead)
	{
		return;
	}

	const float TickDamage = BurningDps * DeltaSeconds;
	if (TickDamage > 0.0f)
	{
		UShockDamageLibrary::ApplyDamage(this, TickDamage, BurningInstigator, FName(TEXT("Burning")));
	}

	BurningRemaining = FMath::Max(0.0f, BurningRemaining - DeltaSeconds);
	BurningLogAccumulator += DeltaSeconds;
	if (BurningLogAccumulator >= 1.0f)
	{
		BurningLogAccumulator = 0.0f;
		const FString AiName = ScriptLabel.IsNone() ? GetName() : ScriptLabel.ToString();
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_BURNING ai=%s remaining=%.1f"),
			*AiName,
			BurningRemaining);
		ApplyBurnFlash();
	}

	if (BurningRemaining <= 0.0f)
	{
		BurningDps = 0.0f;
		BurningInstigator = nullptr;
		BurningLogAccumulator = 0.0f;
	}
}

void ABaseShockAI::ApplyFrozenFlash()
{
	USkeletalMeshComponent* SkelMesh = GetMesh();
	if (!SkelMesh)
	{
		return;
	}

	const FLinearColor Blue(0.35f, 0.65f, 1.0f, 1.0f);
	const int32 NumMaterials = SkelMesh->GetNumMaterials();
	for (int32 Slot = 0; Slot < NumMaterials; ++Slot)
	{
		if (UMaterialInstanceDynamic* MID = SkelMesh->CreateAndSetMaterialInstanceDynamic(Slot))
		{
			MID->SetVectorParameterValue(TEXT("EmissiveColor"), Blue);
			MID->SetVectorParameterValue(TEXT("Emissive"), Blue);
			MID->SetScalarParameterValue(TEXT("EmissiveStrength"), 2.5f);
		}
	}
}

void ABaseShockAI::ClearFrozenState()
{
	FrozenSolidRemaining = 0.0f;
	FrozenInstigator = nullptr;
	FrozenLogAccumulator = 0.0f;
	UShockPhysicsLibrary::SetActorPhysicsFrozen(this, false, false);
	ClearHitFlash();
}

void ABaseShockAI::ApplyBurnFlash()
{
	USkeletalMeshComponent* SkelMesh = GetMesh();
	UWorld* World = GetWorld();
	if (!SkelMesh || !World)
	{
		return;
	}

	const FLinearColor Orange(1.0f, 0.45f, 0.1f, 1.0f);
	const int32 NumMaterials = SkelMesh->GetNumMaterials();
	for (int32 Slot = 0; Slot < NumMaterials; ++Slot)
	{
		if (UMaterialInstanceDynamic* MID = SkelMesh->CreateAndSetMaterialInstanceDynamic(Slot))
		{
			MID->SetVectorParameterValue(TEXT("EmissiveColor"), Orange);
			MID->SetVectorParameterValue(TEXT("Emissive"), Orange);
			MID->SetScalarParameterValue(TEXT("EmissiveStrength"), 3.0f);
		}
	}

	World->GetTimerManager().ClearTimer(HitFlashTimerHandle);
	World->GetTimerManager().SetTimer(
		HitFlashTimerHandle,
		this,
		&ABaseShockAI::ClearHitFlash,
		HitFlashSeconds,
		false);
}

void ABaseShockAI::ApplyHitFlash()
{
	USkeletalMeshComponent* SkelMesh = GetMesh();
	UWorld* World = GetWorld();
	if (!SkelMesh || !World)
	{
		return;
	}

	bool bFlashed = false;
	const int32 NumMaterials = SkelMesh->GetNumMaterials();
	for (int32 Slot = 0; Slot < NumMaterials && !bFlashed; ++Slot)
	{
		UMaterialInstanceDynamic* MID = SkelMesh->CreateAndSetMaterialInstanceDynamic(Slot);
		if (!MID)
		{
			continue;
		}
		const FLinearColor White(1.0f, 1.0f, 1.0f, 1.0f);
		MID->SetVectorParameterValue(TEXT("EmissiveColor"), White);
		MID->SetVectorParameterValue(TEXT("Emissive"), White);
		MID->SetScalarParameterValue(TEXT("EmissiveStrength"), 4.0f);
		bFlashed = SkelMesh->GetMaterial(Slot) != nullptr;
	}

	if (!bFlashed)
	{
		if (!HitFlashOverlayMID)
		{
			UMaterialInterface* BaseMat = UMaterial::GetDefaultMaterial(EMaterialDomain::MD_Surface);
			HitFlashOverlayMID = UMaterialInstanceDynamic::Create(BaseMat, this);
			if (HitFlashOverlayMID)
			{
				HitFlashOverlayMID->SetVectorParameterValue(
					TEXT("BaseColor"),
					FLinearColor(1.0f, 0.95f, 0.95f, 1.0f));
			}
		}
		if (HitFlashOverlayMID)
		{
			SkelMesh->SetOverlayMaterial(HitFlashOverlayMID);
			bHitFlashUsesOverlay = true;
		}
		else
		{
			SkelMesh->SetRenderCustomDepth(true);
			bHitFlashUsesCustomDepth = true;
		}
	}

	World->GetTimerManager().ClearTimer(HitFlashTimerHandle);
	World->GetTimerManager().SetTimer(
		HitFlashTimerHandle,
		this,
		&ABaseShockAI::ClearHitFlash,
		HitFlashSeconds,
		false);
}

void ABaseShockAI::ClearHitFlash()
{
	if (USkeletalMeshComponent* SkelMesh = GetMesh())
	{
		if (bHitFlashUsesOverlay)
		{
			SkelMesh->SetOverlayMaterial(nullptr);
			bHitFlashUsesOverlay = false;
		}
		if (bHitFlashUsesCustomDepth)
		{
			SkelMesh->SetRenderCustomDepth(false);
			bHitFlashUsesCustomDepth = false;
		}
	}
}

void ABaseShockAI::OnDeathFromDamage()
{
	if (bDeathReactionHandled)
	{
		return;
	}
	bDeathReactionHandled = true;
	++DeathNotifyCount;
	UShockAudioLibrary::SpawnEventAttached(TEXT("ShockAI"), TEXT("DiedSpeech"), RootComponent);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_AUDIO vocal ai=%s event=DiedSpeech"), *GetName());
	bCombatLoopStopped = true;
	HitReactRemaining = 0.0f;
	HitReactRateLimitRemaining = 0.0f;
	BurningRemaining = 0.0f;
	BurningDps = 0.0f;
	BurningInstigator = nullptr;
	BurningLogAccumulator = 0.0f;
	ClearFrozenState();
	if (UWorld* World = GetWorld())
	{
		World->GetTimerManager().ClearTimer(HitFlashTimerHandle);
	}
	ClearHitFlash();
	CombatState = EShockAICombatState::Idle;
	ClearCombatTarget();
	StopNavChase();

	EnsureCombatMeshAndAnims();
	if (AnimDeath)
	{
		PlayCombatAnimation(AnimDeath, false);
		bDeathAnimStarted = true;
		LastAnimAbilityName = FName(TEXT("Death"));
	}

	if (UCapsuleComponent* Capsule = GetCapsuleComponent())
	{
		Capsule->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->StopMovementImmediately();
		Move->DisableMovement();
	}

	StartRagdoll();

	if (CorpseFadeSeconds > 0.0f)
	{
		if (UWorld* World = GetWorld())
		{
			World->GetTimerManager().SetTimer(
				CorpseFadeTimer,
				this,
				&ABaseShockAI::HideCorpse,
				CorpseFadeSeconds,
				false);
		}
	}
}

void ABaseShockAI::RecordRagdollHit(FVector Impulse, FVector HitLocation, FName HitBone)
{
	PendingRagdollImpulse = Impulse;
	PendingRagdollHitLocation = HitLocation;
	PendingRagdollHitBone = HitBone;
}

void ABaseShockAI::StartRagdoll()
{
	USkeletalMeshComponent* Body = GetMesh();
	if (!Body || !Body->GetSkeletalMeshAsset() || !Body->GetPhysicsAsset())
	{
		UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_RAGDOLL_UNAVAILABLE ai=%s physicsAsset=0"), *GetName());
		SetActorTickEnabled(false);
		return;
	}

	Body->SetCollisionProfileName(TEXT("Ragdoll"));
	Body->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	Body->SetCollisionResponseToChannel(ECC_WorldStatic, ECR_Block);
	Body->SetCollisionResponseToChannel(ECC_Pawn, ECR_Ignore);
	Body->SetCollisionResponseToChannel(ECC_Camera, ECR_Ignore);
	Body->SetAllBodiesSimulatePhysics(true);
	Body->SetSimulatePhysics(true);
	RagdollBlendWeight = AnimDeath ? 0.2f : 1.0f;
	Body->SetAllBodiesPhysicsBlendWeight(RagdollBlendWeight, false);
	Body->WakeAllRigidBodies();

	if (!PendingRagdollImpulse.IsNearlyZero())
	{
		const FName ImpulseBone =
			!PendingRagdollHitBone.IsNone() && Body->GetBoneIndex(PendingRagdollHitBone) != INDEX_NONE
				? PendingRagdollHitBone
				: NAME_None;
		Body->AddImpulseAtLocation(
			PendingRagdollImpulse,
			PendingRagdollHitLocation.IsNearlyZero() ? Body->GetComponentLocation() : PendingRagdollHitLocation,
			ImpulseBone);
	}

	bRagdollActive = true;
	SetActorTickEnabled(true);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_RAGDOLL_ACTIVE ai=%s physicsAsset=%s bone=%s impulse=%.1f"),
		*GetName(),
		*Body->GetPhysicsAsset()->GetName(),
		*PendingRagdollHitBone.ToString(),
		PendingRagdollImpulse.Size());
}

void ABaseShockAI::TickRagdollBlend(float DeltaSeconds)
{
	if (!bRagdollActive || RagdollBlendWeight >= 1.0f)
	{
		return;
	}
	RagdollBlendWeight = FMath::Min(1.0f, RagdollBlendWeight + DeltaSeconds / 0.2f);
	if (USkeletalMeshComponent* Body = GetMesh())
	{
		Body->SetAllBodiesPhysicsBlendWeight(RagdollBlendWeight, false);
	}
}

void ABaseShockAI::HideCorpse()
{
	SetActorHiddenInGame(true);
	if (USkeletalMeshComponent* Body = GetMesh())
	{
		Body->SetHiddenInGame(true);
	}
}

void ABaseShockAI::EnsureControllerForVerify()
{
	if (!GetController())
	{
		SpawnDefaultController();
	}
}

void ABaseShockAI::AdvanceAutonomousCombat(float DeltaSeconds)
{
	// Headless verification entry point — no world tick, no collision floor.
	EnableFloorlessMovement();
	Tick(DeltaSeconds);
	if (bNavChaseActive && !bNavUsingFallback)
	{
		if (AAIController* AIC = Cast<AAIController>(GetController()))
		{
			if (UPathFollowingComponent* PFC = AIC->GetPathFollowingComponent())
			{
				PFC->TickComponent(DeltaSeconds, LEVELTICK_All, nullptr);
			}
		}
	}
	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->TickComponent(DeltaSeconds, LEVELTICK_All, nullptr);
		if (FrozenSolidRemaining > 0.0f)
		{
			TickCombatMovementSpeed(DeltaSeconds);
			Move->StopMovementImmediately();
		}
	}
	if (USkeletalMeshComponent* Body = GetMesh())
	{
		Body->TickAnimation(DeltaSeconds, /*bNeedsValidRootMotion*/ false);
		Body->RefreshBoneTransforms();
	}
}

void ABaseShockAI::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	// Safety net: an AI that has fallen far below the playable level (bad spawn point, ran off
	// an edge with no collision) is gone — remove it rather than let it fall forever.
	if (GetActorLocation().Z < -30000.0f)
	{
		Destroy();
		return;
	}

	if (bIsDead)
	{
		TickRagdollBlend(DeltaSeconds);
		return;
	}
	TickBehaviour(DeltaSeconds);
	TickCombat(DeltaSeconds);
	TickAnimationDriver(DeltaSeconds);
}

bool ABaseShockAI::IsCombatLoopGated() const
{
	return bIsDead || bCombatLoopStopped || bToldToWait || !bCanAttack || FrozenSolidRemaining > 0.0f;
}

bool ABaseShockAI::IsAliveTarget(const AShockPawn* Target) const
{
	return Target && !Target->IsDead() && Target->GetCurrentHealth() > 0.0f;
}

bool ABaseShockAI::IsBelowFleeThreshold() const
{
	const float MaxHealth = AuthoredMaxHealth > 0.0f
		? AuthoredMaxHealth
		: FMath::Max(CurrentHealth, 100.0f);
	return MaxHealth > 0.0f && CurrentHealth / MaxHealth <= 0.25f;
}

void ABaseShockAI::TickMoveToLocation(FVector Destination, float DeltaSeconds, float AcceptanceRadius)
{
	FVector Offset = Destination - GetActorLocation();
	Offset.Z = 0.0f;
	if (Offset.SizeSquared2D() <= FMath::Square(AcceptanceRadius))
	{
		return;
	}
	const FVector Direction = Offset.GetSafeNormal2D();
	SetActorRotation(FRotationMatrix::MakeFromX(Direction).Rotator());
	AddMovementInput(Direction, 1.0f);
	if (GetVelocity().SizeSquared2D() < 1.0f)
	{
		SetActorLocation(
			GetActorLocation() + Direction * (bMovementShouldRun ? RunSpeed : WalkSpeed) * DeltaSeconds,
			true);
	}
}

void ABaseShockAI::TickBehaviour(float DeltaSeconds)
{
	if (IsCombatLoopGated())
	{
		return;
	}

	BehaviourStateSeconds += DeltaSeconds;

	if (!IsBelowFleeThreshold())
	{
		bFledAtCurrentLowHealth = false;
	}
	if (BehaviourState != EShockAIBehaviourState::Flee
		&& IsBelowFleeThreshold()
		&& !bFledAtCurrentLowHealth)
	{
		const FVector Threat = CombatTarget
			? CombatTarget->GetActorLocation()
			: (LastKnownTargetLocation.IsNearlyZero() ? GetActorLocation() - GetActorForwardVector() : LastKnownTargetLocation);
		FVector Away = (GetActorLocation() - Threat).GetSafeNormal2D();
		if (Away.IsNearlyZero())
		{
			Away = -GetActorForwardVector();
		}
		StateMoveDestination = GetActorLocation() + Away * FleeDistance;
		ClearCombatTarget();
		EnterBehaviourState(EShockAIBehaviourState::Flee);
	}

	switch (BehaviourState)
	{
	case EShockAIBehaviourState::Idle:
	case EShockAIBehaviourState::Patrol:
		PerceptionScanAccumulator += DeltaSeconds;
		if (PerceptionScanAccumulator >= PerceptionScanInterval)
		{
			PerceptionScanAccumulator = 0.0f;
			if (TryAcquireTargetFromPerception())
			{
				EnterBehaviourState(EShockAIBehaviourState::Combat);
			}
		}
		if (BehaviourState == EShockAIBehaviourState::Idle && !PatrolName.IsNone())
		{
			// The named PatrolList is retained by the importer. Until its points are imported,
			// remain at the authored spawn rather than inventing a random destination.
			EnterBehaviourState(EShockAIBehaviourState::Patrol);
		}
		break;

	case EShockAIBehaviourState::Alert:
	{
		const FVector Direction = (LastKnownTargetLocation - GetActorLocation()).GetSafeNormal2D();
		if (!Direction.IsNearlyZero())
		{
			SetActorRotation(FRotationMatrix::MakeFromX(Direction).Rotator());
		}
		// ShockAI.uc SpotEnemyTurnDelay.
		if (BehaviourStateSeconds >= 0.25f)
		{
			EnterBehaviourState(EShockAIBehaviourState::Investigate);
		}
		break;
	}

	case EShockAIBehaviourState::Investigate:
		bMovementShouldRun = false;
		TickMoveToLocation(StateMoveDestination, DeltaSeconds, 200.0f);
		if (FVector::Dist2D(GetActorLocation(), StateMoveDestination) <= 200.0f
			|| BehaviourStateSeconds >= LoseTargetSeconds + 4.0f)
		{
			EnterBehaviourState(EShockAIBehaviourState::Search);
		}
		break;

	case EShockAIBehaviourState::Search:
		bMovementShouldRun = false;
		SearchTurnAccumulator += DeltaSeconds;
		if (SearchTurnAccumulator >= 1.0f)
		{
			SearchTurnAccumulator = 0.0f;
			AddActorWorldRotation(FRotator(0.0f, 55.0f, 0.0f));
		}
		if (TryAcquireTargetFromPerception())
		{
			EnterBehaviourState(EShockAIBehaviourState::Combat);
		}
		else if (BehaviourStateSeconds >= SearchDurationSeconds)
		{
			UShockAudioLibrary::SpawnEventAttached(TEXT("ShockAI"), TEXT("FinishedSearching"), RootComponent);
			EnterBehaviourState(PatrolName.IsNone()
				? EShockAIBehaviourState::Idle
				: EShockAIBehaviourState::Patrol);
		}
		break;

	case EShockAIBehaviourState::Combat:
		if (!IsAliveTarget(CombatTarget))
		{
			ClearCombatTarget();
			EnterBehaviourState(PatrolName.IsNone()
				? EShockAIBehaviourState::Idle
				: EShockAIBehaviourState::Patrol);
			break;
		}
		if (HasClearLineOfSightTo(CombatTarget))
		{
			LastKnownTargetDirection = CombatTarget->GetVelocity().GetSafeNormal2D();
			LastKnownTargetLocation = CombatTarget->GetActorLocation();
			OutOfSightTimer = 0.0f;
		}
		else
		{
			OutOfSightTimer += DeltaSeconds;
			if (OutOfSightTimer >= LoseTargetSeconds)
			{
				StateMoveDestination = LastKnownTargetLocation;
				ClearCombatTarget();
				EnterBehaviourState(EShockAIBehaviourState::Investigate);
			}
		}
		break;

	case EShockAIBehaviourState::Flee:
		bMovementShouldRun = true;
		TickMoveToLocation(StateMoveDestination, DeltaSeconds, 75.0f);
		if (FVector::Dist2D(GetActorLocation(), StateMoveDestination) <= 75.0f)
		{
			bFledAtCurrentLowHealth = true;
			EnterBehaviourState(PatrolName.IsNone()
				? EShockAIBehaviourState::Idle
				: EShockAIBehaviourState::Patrol);
		}
		break;
	default:
		break;
	}
}

void ABaseShockAI::SetCombatTarget(AShockPawn* Target)
{
	const bool bNewTarget = Target && CombatTarget != Target;
	CombatTarget = Target;
	if (bNewTarget)
	{
		OutOfSightTimer = 0.0f;
		UShockAudioLibrary::SpawnEventAttached(
			TEXT("ShockAI"), TEXT("BeganAttackingSpeech"), RootComponent);
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_AUDIO vocal ai=%s event=BeganAttackingSpeech"),
			*GetName());
	}
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

bool ABaseShockAI::HasClearLineOfSightTo(const AShockPawn* Target) const
{
	if (bSuppressCombatLineOfSight)
	{
		return false;
	}
	if (!Target)
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
	const FVector TargetLoc = Target->GetActorLocation();

	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockAILoS), false, this);
	Params.AddIgnoredActor(Target);
	FHitResult Hit;
	if (World->LineTraceSingleByChannel(
			Hit,
			EyeLoc,
			TargetLoc,
			ECC_Visibility,
			Params))
	{
		if (IsBlockingSightHit(Hit, Target))
		{
			return false;
		}
	}
	return true;
}

FVector ABaseShockAI::ApplyAimSpread(FVector Direction) const
{
	if (AimSpreadDegrees <= 0.0f || Direction.IsNearlyZero())
	{
		return Direction.GetSafeNormal();
	}

	FRotator Rot = Direction.Rotation();
	Rot.Yaw += FMath::FRandRange(-AimSpreadDegrees, AimSpreadDegrees);
	Rot.Pitch += FMath::FRandRange(-AimSpreadDegrees, AimSpreadDegrees);
	return Rot.Vector().GetSafeNormal();
}

void ABaseShockAI::TryRangedFire()
{
	if (!AIWeapon || !CombatTarget)
	{
		return;
	}

	FVector MuzzleLoc = GetActorLocation();
	if (const UCapsuleComponent* Capsule = GetCapsuleComponent())
	{
		MuzzleLoc.Z += Capsule->GetScaledCapsuleHalfHeight() * 0.8f;
	}

	FVector Direction = CombatTarget->GetActorLocation() - MuzzleLoc;
	Direction = ApplyAimSpread(Direction);
	AIWeapon->FireAt(this, MuzzleLoc, Direction);
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
		const float HalfAngle = Dist <= NearSightDistance
			? NearSightHalfAngleDegrees
			: FarSightHalfAngleDegrees;
		const float MinDot = FMath::Cos(FMath::DegreesToRadians(HalfAngle));
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
		if (!bLabelMatch && !bAggroMatch && !bHostileToAnyPlayer)
		{
			continue;
		}

		SetCombatTarget(Player);
		return true;
	}
	return false;
}

void ABaseShockAI::StopNavChase()
{
	if (bNavChaseActive)
	{
		if (AAIController* AIC = Cast<AAIController>(GetController()))
		{
			AIC->StopMovement();
		}
	}
	bNavChaseActive = false;
	NavMoveRefreshTimer = 0.0f;
	NavLastMoveGoal = FVector::ZeroVector;
}

void ABaseShockAI::TickChaseDirectMovement(AShockPawn* Target, float DeltaSeconds)
{
	if (!Target)
	{
		return;
	}

	const FVector ToTarget = Target->GetActorLocation() - GetActorLocation();
	FVector MoveDir = ToTarget;
	MoveDir.Z = 0.0f;
	if (MoveDir.IsNearlyZero())
	{
		return;
	}

	const FVector Before = GetActorLocation();
	const FVector Norm = MoveDir.GetSafeNormal();
	AddMovementInput(Norm, 1.0f);
	// When nothing moved us (headless with no floor, or a frame where input was not consumed yet),
	// close the distance directly so the slice still works without nav data.
	if (FVector::Dist2D(Before, GetActorLocation()) < 1.0f)
	{
		const float Speed = bMovementShouldRun ? RunSpeed : WalkSpeed;
		SetActorLocation(Before + Norm * Speed * DeltaSeconds, true);
	}
}

bool ABaseShockAI::TryTickNavChase(AShockPawn* Target, float DeltaSeconds)
{
	if (!bUseNavigation || !Target)
	{
		StopNavChase();
		return false;
	}

	UWorld* World = GetWorld();
	UNavigationSystemV1* NavSys = UNavigationSystemV1::GetCurrent(World);
	if (!NavSys)
	{
		if (!bNavUsingFallback)
		{
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_NAV_FALLBACK"));
			bNavUsingFallback = true;
		}
		StopNavChase();
		return false;
	}

	AAIController* AIC = Cast<AAIController>(GetController());
	if (!AIC)
	{
		if (!bNavUsingFallback)
		{
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_NAV_FALLBACK"));
			bNavUsingFallback = true;
		}
		StopNavChase();
		return false;
	}

	const FVector TargetLoc = Target->GetActorLocation();
	FNavLocation Projected;
	if (!NavSys->ProjectPointToNavigation(TargetLoc, Projected))
	{
		if (!bNavUsingFallback)
		{
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_NAV_FALLBACK"));
			bNavUsingFallback = true;
		}
		StopNavChase();
		return false;
	}

	NavMoveRefreshTimer -= DeltaSeconds;
	const bool bTargetMoved = FVector::Dist(NavLastMoveGoal, TargetLoc) > NavMoveRetargetThreshold;
	const bool bNeedRefresh = !bNavChaseActive || NavMoveRefreshTimer <= 0.0f || bTargetMoved;
	if (bNeedRefresh)
	{
		NavMoveRefreshTimer = NavMoveRefreshInterval;
		NavLastMoveGoal = TargetLoc;
		const float AcceptRadius = MeleeRange * 0.8f;
		const EPathFollowingRequestResult::Type Result = AIC->MoveToActor(Target, AcceptRadius);
		if (Result == EPathFollowingRequestResult::Failed)
		{
			if (!bNavUsingFallback)
			{
				UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_NAV_FALLBACK"));
				bNavUsingFallback = true;
			}
			StopNavChase();
			return false;
		}
		bNavChaseActive = true;
		bNavUsingFallback = false;
	}

	return true;
}

void ABaseShockAI::TickCombat(float DeltaSeconds)
{
	TickCombatCooldowns(DeltaSeconds);
	TickCombatMovementSpeed(DeltaSeconds);

	if (IsCombatLoopGated())
	{
		StopNavChase();
		CombatState = EShockAICombatState::Idle;
		ClearCombatTarget();
		return;
	}

	if (BehaviourState != EShockAIBehaviourState::Combat)
	{
		return;
	}

	if (bUseBrain && Brain)
	{
		if (!Brain->GetAbilityCount())
		{
			Brain->InitializeForAI(this);
		}
		Brain->Think(DeltaSeconds);
		return;
	}

	TickCombatFsm(DeltaSeconds);
}

void ABaseShockAI::TickCombatCooldowns(float DeltaSeconds)
{
	if (HitReactRemaining > 0.0f)
	{
		HitReactRemaining = FMath::Max(0.0f, HitReactRemaining - DeltaSeconds);
	}
	TickStatusEffects(DeltaSeconds);
	if (HitReactRateLimitRemaining > 0.0f)
	{
		HitReactRateLimitRemaining = FMath::Max(0.0f, HitReactRateLimitRemaining - DeltaSeconds);
	}
	if (MeleeCooldownRemaining > 0.0f)
	{
		MeleeCooldownRemaining = FMath::Max(0.0f, MeleeCooldownRemaining - DeltaSeconds);
	}
	if (RangedCooldownRemaining > 0.0f)
	{
		RangedCooldownRemaining = FMath::Max(0.0f, RangedCooldownRemaining - DeltaSeconds);
	}
}

void ABaseShockAI::TickCombatMovementSpeed(float DeltaSeconds)
{
	(void)DeltaSeconds;
	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		float SpeedMult = 1.0f;
		if (HitReactRemaining > 0.0f)
		{
			SpeedMult *= HitReactMovementScale;
		}
		if (ChillRemaining > 0.0f)
		{
			SpeedMult *= ChillMovementScale;
		}
		if (FrozenSolidRemaining > 0.0f)
		{
			SpeedMult = 0.0f;
		}
		const float Speed = (bMovementShouldRun ? RunSpeed : WalkSpeed) * SpeedMult;
		Move->MaxWalkSpeed = Speed;
		Move->MaxFlySpeed = Speed;
	}
}

float ABaseShockAI::GetMaxWalkSpeedForVerify() const
{
	if (const UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		return Move->MaxWalkSpeed;
	}
	return 0.0f;
}

void ABaseShockAI::SetCombatTargetPawn(AShockPawn* Target)
{
	SetCombatTarget(Target);
}

void ABaseShockAI::ClearCombatTargetPawn()
{
	ClearCombatTarget();
}

void ABaseShockAI::HandlePlayerRespawned()
{
	if (bIsDead)
	{
		return;
	}
	const bool bWasAlerted = CombatTarget != nullptr
		|| CurrentScriptedAttackTarget != nullptr
		|| BehaviourState == EShockAIBehaviourState::Combat;
	CurrentScriptedAttackTarget = nullptr;
	ClearCombatTarget();
	StopNavChase();
	CombatState = EShockAICombatState::Idle;
	MeleeCooldownRemaining = 0.0f;
	RangedCooldownRemaining = 0.0f;
	EnterBehaviourState(
		bWasAlerted ? EShockAIBehaviourState::Search : EShockAIBehaviourState::Idle);
}

bool ABaseShockAI::IsAliveCombatTarget(const AShockPawn* Target) const
{
	return IsAliveTarget(Target);
}

float ABaseShockAI::GetDistanceToCombatTarget(const AShockPawn* Target) const
{
	return DistanceToTarget(Target);
}

void ABaseShockAI::FaceCombatTarget(const AShockPawn* Target)
{
	FaceTargetYaw(Target);
}

bool ABaseShockAI::HasCombatLineOfSightTo(const AShockPawn* Target) const
{
	return HasClearLineOfSightTo(Target);
}

void ABaseShockAI::StopCombatNavChase()
{
	StopNavChase();
}

bool ABaseShockAI::TryTickCombatNavChase(AShockPawn* Target, float DeltaSeconds)
{
	return TryTickNavChase(Target, DeltaSeconds);
}

void ABaseShockAI::TickCombatChaseDirectMovement(AShockPawn* Target, float DeltaSeconds)
{
	TickChaseDirectMovement(Target, DeltaSeconds);
}

void ABaseShockAI::TryCombatRangedFire()
{
	TryRangedFire();
}

void ABaseShockAI::TickRangedCombatCadence(float DeltaSeconds)
{
	AShockPawn* Target = CombatTarget;
	if (!AIWeapon || !IsAliveTarget(Target))
	{
		return;
	}

	if (RangedRepositionRemaining > 0.0f)
	{
		RangedRepositionRemaining = FMath::Max(0.0f, RangedRepositionRemaining - DeltaSeconds);
		const FVector ToTarget = (Target->GetActorLocation() - GetActorLocation()).GetSafeNormal2D();
		const FVector Side(-ToTarget.Y, ToTarget.X, 0.0f);
		StateMoveDestination = GetActorLocation() + Side * 400.0f;
		bMovementShouldRun = true;
		TickMoveToLocation(StateMoveDestination, DeltaSeconds, 75.0f);
		return;
	}

	bMovementShouldRun = false;
	FaceTargetYaw(Target);
	if (RangedCooldownRemaining > 0.0f || HitReactRemaining > 0.0f)
	{
		return;
	}

	if (RangedBurstShotsRemaining <= 0)
	{
		// RangedAggressorPistolWeaponAmmo.uc RandomRangeBurstShots=(5,7).
		RangedBurstShotsRemaining = FMath::RandRange(5, 7);
	}

	TryRangedFire();
	--RangedBurstShotsRemaining;
	if (RangedBurstShotsRemaining > 0)
	{
		// UC permits 0..0.75 seconds between pistol burst shots.
		RangedCooldownRemaining = FMath::FRandRange(0.05f, 0.75f);
	}
	else
	{
		// Pistol TimeToStartMovingAgainRange=(2,4); this is a tactical strafe when no
		// imported cover-node graph is available.
		RangedRepositionRemaining = FMath::FRandRange(2.0f, 4.0f);
		RangedCooldownRemaining = RangedRepositionRemaining;
	}
}

void ABaseShockAI::TickBrainIdlePerception(float DeltaSeconds)
{
	PerceptionScanAccumulator += DeltaSeconds;
	if (PerceptionScanAccumulator >= PerceptionScanInterval)
	{
		PerceptionScanAccumulator = 0.0f;
		TryAcquireTargetFromPerception();
	}
}

void ABaseShockAI::TickCombatFsm(float DeltaSeconds)
{
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
			StopNavChase();
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
				StopNavChase();
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
			StopNavChase();
			CombatState = EShockAICombatState::Attack;
			break;
		}

		if (AIWeapon && Dist <= RangedRange && Dist > MeleeRange && HasClearLineOfSightTo(CombatTarget))
		{
			StopNavChase();
			CombatState = EShockAICombatState::RangedAttack;
			break;
		}

		FaceTargetYaw(CombatTarget);
		if (!TryTickNavChase(CombatTarget, DeltaSeconds))
		{
			TickChaseDirectMovement(CombatTarget, DeltaSeconds);
		}
		break;
	}
	case EShockAICombatState::RangedAttack:
	{
		if (!IsAliveTarget(CombatTarget))
		{
			StopNavChase();
			ClearCombatTarget();
			CombatState = EShockAICombatState::Idle;
			break;
		}

		const float Dist = DistanceToTarget(CombatTarget);
		if (Dist <= MeleeRange)
		{
			StopNavChase();
			CombatState = EShockAICombatState::Attack;
			break;
		}
		if (Dist > RangedRange || !HasClearLineOfSightTo(CombatTarget))
		{
			CombatState = EShockAICombatState::Chase;
			break;
		}

		FaceTargetYaw(CombatTarget);
		if (RangedCooldownRemaining <= 0.0f && HitReactRemaining <= 0.0f)
		{
			TryRangedFire();
			RangedCooldownRemaining = RangedCooldown;
		}
		break;
	}
	case EShockAICombatState::Attack:
	{
		if (!IsAliveTarget(CombatTarget))
		{
			StopNavChase();
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
		if (MeleeCooldownRemaining <= 0.0f && HitReactRemaining <= 0.0f)
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

void ABaseShockAI::ApplyCombatSkeletalMesh(
	USkeletalMeshComponent* Body,
	USkeletalMesh* MeshAsset,
	bool bDisableMeshCollision)
{
	if (!Body || !MeshAsset)
	{
		return;
	}

	Body->SetSkeletalMesh(MeshAsset);
	Body->SetHiddenInGame(false);
	if (bDisableMeshCollision)
	{
		// Pre-existing ApplyToAI choice: capsule keeps QueryAndPhysics; mesh is display-only.
		// Unrelated to orientation — flagged here so it is not "fixed" as part of a mesh-up bug.
		Body->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	// ACharacter defaults mesh RelRotation to (0, -90, 0) for the UE mannequin (+Y mesh forward).
	// BioShock full-body rigs are authored +X forward, +Z up (docs/research/ANIMATION_COORDINATE_SYSTEM.md,
	// CONFIRMED_BYTES on AggressorBabyJane). Identity maps mesh forward onto character forward.
	// That is a fixed yaw-convention correction only — it cannot flip up/down. If world-space
	// head.Z - feet.Z is still large and negative after this, the imported asset itself is inverted;
	// do not invent a pitch/roll here (a wrong guess looks "less wrong" but is still wrong).
	Body->SetRelativeRotation(FRotator::ZeroRotator);

	const float UprightDelta = MeasureMeshUprightDelta(Body);
	if (UprightDelta < -50.0f)
	{
		UE_LOG(
			LogTemp, Warning,
			TEXT("BIOSHOCK_AI_MESH inverted uprightDelta=%.1f mesh=%s — import/bind pose fault; "
				 "no compensating pitch/roll applied"),
			UprightDelta, *MeshAsset->GetName());
	}
	else
	{
		UE_LOG(
			LogTemp, Display,
			TEXT("BIOSHOCK_AI_MESH relRot=Identity uprightDelta=%.1f mesh=%s"),
			UprightDelta, *MeshAsset->GetName());
	}
}

void ABaseShockAI::EnsureCombatMeshAndAnims()
{
	if (USkeletalMeshComponent* Body = GetMesh())
	{
		if (!Body->GetSkeletalMeshAsset())
		{
			if (USkeletalMesh* MeshAsset = LoadObject<USkeletalMesh>(
					nullptr,
					TEXT("/Game/BioShockCharacters/AggressorBabyJane/AggressorBabyJane.AggressorBabyJane")))
			{
				ApplyCombatSkeletalMesh(Body, MeshAsset, /*bDisableMeshCollision*/ true);
			}
		}
		else
		{
			// Level-serialized actors may already carry the mesh from an earlier assign while
			// still holding ACharacter's mannequin RelRotation (0, -90, 0). Re-assert Identity.
			const FRotator Rel = Body->GetRelativeRotation();
			if (!Rel.Equals(FRotator::ZeroRotator, 0.25f))
			{
				Body->SetRelativeRotation(FRotator::ZeroRotator);
			}
		}
	}

	if (bAnimAssetsLoaded)
	{
		return;
	}

	auto LoadAnim = [](const TCHAR* Path) -> UAnimSequence*
	{
		UAnimSequence* Seq = LoadObject<UAnimSequence>(nullptr, Path);
		if (!Seq)
		{
			UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_AI_ANIM missing=%s"), Path);
		}
		return Seq;
	};

	AnimIdle = LoadAnim(
		TEXT("/Game/BioShockCharacters/AggressorBabyJane/Animations/ME_Fidget_A_idle.ME_Fidget_A_idle"));
	AnimWalk = LoadAnim(
		TEXT("/Game/BioShockCharacters/AggressorBabyJane/Animations/ME_WalkFWD_A_agg.ME_WalkFWD_A_agg"));
	AnimRun = LoadAnim(
		TEXT("/Game/BioShockCharacters/AggressorBabyJane/Animations/ME_runFWD_A_agg.ME_runFWD_A_agg"));
	AnimMelee = LoadAnim(
		TEXT("/Game/BioShockCharacters/AggressorBabyJane/Animations/ME_attackMelee_A.ME_attackMelee_A"));
	AnimHitReact = LoadAnim(
		TEXT("/Game/BioShockCharacters/AggressorBabyJane/Animations/ME_hitFWD_A.ME_hitFWD_A"));
	AnimDeath = LoadAnim(
		TEXT("/Game/BioShockCharacters/AggressorBabyJane/Animations/Death_StumbleFWD.Death_StumbleFWD"));
	bAnimAssetsLoaded = AnimIdle != nullptr || AnimWalk != nullptr || AnimRun != nullptr;
}

bool ABaseShockAI::IsOneShotAbilityName(FName AbilityName)
{
	const FString Name = AbilityName.ToString();
	return Name.Contains(TEXT("MeleeAttack"), ESearchCase::IgnoreCase)
		|| Name.Contains(TEXT("HitReact"), ESearchCase::IgnoreCase);
}

UAnimSequence* ABaseShockAI::ResolveAnimationForAbility(FName AbilityName) const
{
	const FString Name = AbilityName.ToString();
	if (Name.Contains(TEXT("HitReact"), ESearchCase::IgnoreCase))
	{
		return AnimHitReact;
	}
	if (Name.Contains(TEXT("MeleeAttack"), ESearchCase::IgnoreCase))
	{
		return AnimMelee;
	}
	if (Name.Contains(TEXT("MoveTo"), ESearchCase::IgnoreCase)
		|| Name.Contains(TEXT("Flee"), ESearchCase::IgnoreCase)
		|| Name.Contains(TEXT("Patrol"), ESearchCase::IgnoreCase))
	{
		if (bMovementShouldRun && AnimRun)
		{
			return AnimRun;
		}
		return AnimWalk ? AnimWalk : AnimRun;
	}
	return AnimIdle;
}

void ABaseShockAI::PlayCombatAnimation(UAnimSequence* Sequence, bool bLoop)
{
	USkeletalMeshComponent* Body = GetMesh();
	if (!Body || !Sequence)
	{
		return;
	}
	const UAnimSingleNodeInstance* ExistingNode =
		Cast<UAnimSingleNodeInstance>(Body->GetAnimInstance());
	const bool bSequenceActuallyInstalled =
		ExistingNode && ExistingNode->GetAnimationAsset() == Sequence;
	if (Sequence == LastPlayedAnim && bLoop == !bPlayingOneShotAnim && bSequenceActuallyInstalled)
	{
		return;
	}

	Body->PlayAnimation(Sequence, bLoop);
	Body->TickAnimation(0.0f, /*bNeedsValidRootMotion*/ false);
	Body->RefreshBoneTransforms();
	LastPlayedAnim = Sequence;

	if (bLoop)
	{
		bPlayingOneShotAnim = false;
		OneShotAnimRemaining = 0.0f;
	}
	else
	{
		bPlayingOneShotAnim = true;
		OneShotAnimRemaining = Sequence->GetPlayLength();
	}
}

void ABaseShockAI::TickAnimationDriver(float DeltaSeconds)
{
	EnsureCombatMeshAndAnims();

	USkeletalMeshComponent* Body = GetMesh();
	if (!Body || !Body->GetSkeletalMeshAsset())
	{
		return;
	}

	// SetSkeletalMesh and runtime anim-instance recreation both clear the single-node player.
	// LastPlayedAnim alone is therefore not proof that the mesh is being posed.
	const UAnimSingleNodeInstance* SingleNode =
		Cast<UAnimSingleNodeInstance>(Body->GetAnimInstance());
	if (!SingleNode || !SingleNode->GetAnimationAsset())
	{
		LastPlayedAnim = nullptr;
		LastAnimAbilityName = NAME_None;
		UAnimSequence* SafeLoop = AnimIdle ? AnimIdle : (AnimWalk ? AnimWalk : AnimRun);
		if (SafeLoop)
		{
			PlayCombatAnimation(SafeLoop, true);
			if (!bPoseLogged && GetPlayingAnimationNameForVerify() != NAME_None)
			{
				bPoseLogged = true;
				UE_LOG(
					LogTemp,
					Display,
					TEXT("BIOSHOCK_AI state=%s archetype=%s hasPose=1"),
					*GetBehaviourStateName().ToString(),
					*AITypeName.ToString());
			}
		}
	}

	if (bIsDead || bDeathAnimStarted)
	{
		if (bPlayingOneShotAnim)
		{
			OneShotAnimRemaining = FMath::Max(0.0f, OneShotAnimRemaining - DeltaSeconds);
			if (OneShotAnimRemaining <= 0.0f)
			{
				bPlayingOneShotAnim = false;
			}
		}
		return;
	}

	if (bPlayingOneShotAnim)
	{
		OneShotAnimRemaining = FMath::Max(0.0f, OneShotAnimRemaining - DeltaSeconds);
		if (OneShotAnimRemaining <= 0.0f)
		{
			bPlayingOneShotAnim = false;
			if (AnimIdle && LastPlayedAnim != AnimIdle)
			{
				PlayCombatAnimation(AnimIdle, true);
			}
		}
	}

	FName AbilityName = NAME_None;
	if (bUseBrain && Brain)
	{
		AbilityName = Brain->GetActiveAbilityName();
	}

	SingleNode = Cast<UAnimSingleNodeInstance>(Body->GetAnimInstance());
	if (AbilityName == LastAnimAbilityName && LastPlayedAnim != nullptr
		&& SingleNode && SingleNode->GetAnimationAsset() == LastPlayedAnim)
	{
		return;
	}

	LastAnimAbilityName = AbilityName;
	UAnimSequence* Sequence = nullptr;
	if (BehaviourState == EShockAIBehaviourState::Investigate
		|| BehaviourState == EShockAIBehaviourState::Flee)
	{
		Sequence = bMovementShouldRun && AnimRun ? AnimRun : (AnimWalk ? AnimWalk : AnimRun);
	}
	else
	{
		Sequence = ResolveAnimationForAbility(AbilityName);
	}
	if (!Sequence)
	{
		Sequence = AnimIdle ? AnimIdle : (AnimWalk ? AnimWalk : AnimRun);
	}
	const bool bLoop = !IsOneShotAbilityName(AbilityName);
	PlayCombatAnimation(Sequence, bLoop);
	if (!bPoseLogged && GetPlayingAnimationNameForVerify() != NAME_None)
	{
		bPoseLogged = true;
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_AI state=%s archetype=%s hasPose=1"),
			*GetBehaviourStateName().ToString(),
			*AITypeName.ToString());
	}
}

FName ABaseShockAI::GetPlayingAnimationNameForVerify() const
{
	if (LastPlayedAnim)
	{
		return LastPlayedAnim->GetFName();
	}
	if (const USkeletalMeshComponent* Body = GetMesh())
	{
		if (const UAnimSingleNodeInstance* Single =
				Cast<UAnimSingleNodeInstance>(Body->GetAnimInstance()))
		{
			if (const UAnimationAsset* Anim = Single->GetAnimationAsset())
			{
				return Anim->GetFName();
			}
		}
	}
	return NAME_None;
}

float ABaseShockAI::GetMeshUprightDeltaForVerify() const
{
	return MeasureMeshUprightDelta(const_cast<USkeletalMeshComponent*>(GetMesh()));
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
