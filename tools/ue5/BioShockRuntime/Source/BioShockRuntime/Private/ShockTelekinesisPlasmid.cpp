#include "ShockTelekinesisPlasmid.h"

#include "Camera/CameraComponent.h"
#include "Components/PrimitiveComponent.h"
#include "DrawDebugHelpers.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"
#include "ShockDamageLibrary.h"
#include "ShockGrabbableActor.h"
#include "ShockPawn.h"
#include "ShockPhysicsLibrary.h"
#include "ShockPlayer.h"

namespace
{
const FName ActionGrab(TEXT("grab"));
const FName ActionThrow(TEXT("throw"));
}

UShockTelekinesisPlasmid::UShockTelekinesisPlasmid()
{
	PlasmidName = TEXT("Telekinesis");
	EveCost = 2.5f;
	CastCooldown = 0.5f;
	TargetingMode = EShockPlasmidTargetingMode::Trace;
}

float UShockTelekinesisPlasmid::GetCastEveCost(const AShockPlayer* Caster) const
{
	(void)Caster;
	// EVE on grab only — throw is free (PLAUSIBLE; TelekinesisAbility.uc body not fully wired).
	return HeldActor ? 0.0f : EveCost;
}

bool UShockTelekinesisPlasmid::EnforcesCastCooldown(const AShockPlayer* Caster) const
{
	(void)Caster;
	return !HeldActor;
}

FVector UShockTelekinesisPlasmid::ResolveAimDirection(AShockPlayer* Caster, const FHitResult& Aim) const
{
	if (Aim.bBlockingHit)
	{
		const FVector Start = Caster->GetActorLocation();
		FVector Dir = Aim.ImpactPoint - Start;
		Dir.Z = 0.0f;
		if (!Dir.IsNearlyZero())
		{
			return Dir.GetSafeNormal();
		}
	}
	if (Caster->FirstPersonCamera)
	{
		FVector Dir = Caster->FirstPersonCamera->GetForwardVector();
		Dir.Z = 0.0f;
		if (!Dir.IsNearlyZero())
		{
			return Dir.GetSafeNormal();
		}
	}
	return Caster->GetActorForwardVector().GetSafeNormal2D();
}

AActor* UShockTelekinesisPlasmid::TraceGrabbable(AShockPlayer* Caster) const
{
	UWorld* World = Caster ? Caster->GetWorld() : nullptr;
	if (!World)
	{
		return nullptr;
	}

	FVector Start = Caster->GetActorLocation() + FVector(0.0f, 0.0f, Caster->BaseEyeHeight);
	FRotator AimRotation = Caster->GetControlRotation();
	if (Caster->FirstPersonCamera)
	{
		Start = Caster->FirstPersonCamera->GetComponentLocation();
		AimRotation = Caster->FirstPersonCamera->GetComponentRotation();
	}
	const FVector End = Start + AimRotation.Vector() * GrabRange;

	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockTelekinesisGrab), false, Caster);
	FHitResult Hit;
	if (World->LineTraceSingleByChannel(Hit, Start, End, ECC_PhysicsBody, Params))
	{
		if (AActor* HitActor = Hit.GetActor())
		{
			if (::Cast<AShockGrabbableActor>(HitActor))
			{
				return HitActor;
			}
			TArray<UPrimitiveComponent*> Primitives;
			HitActor->GetComponents<UPrimitiveComponent>(Primitives);
			for (UPrimitiveComponent* Prim : Primitives)
			{
				if (Prim && Prim->IsSimulatingPhysics())
				{
					return HitActor;
				}
			}
		}
	}

	// Fallback: nearest grabbable in cone (headless verify spawn may miss precise trace).
	float BestDistSq = GrabRange * GrabRange;
	AActor* Best = nullptr;
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor || Actor == Caster)
		{
			continue;
		}
		if (!::Cast<AShockGrabbableActor>(Actor))
		{
			continue;
		}
		const float DistSq = FVector::DistSquared(Start, Actor->GetActorLocation());
		if (DistSq < BestDistSq)
		{
			BestDistSq = DistSq;
			Best = Actor;
		}
	}
	return Best;
}

void UShockTelekinesisPlasmid::TryThrowDamage(AShockPlayer* Caster, const FVector& ThrowDir)
{
	bLastThrowHit = false;
	UWorld* World = Caster ? Caster->GetWorld() : nullptr;
	if (!World || !HeldActor)
	{
		return;
	}

	const FVector Start = HeldActor->GetActorLocation();
	const FVector End = Start + ThrowDir * ThrowHitScanRange;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockTelekinesisThrow), false, Caster);
	Params.AddIgnoredActor(HeldActor);

	FHitResult Hit;
	if (World->LineTraceSingleByObjectType(
			Hit,
			Start,
			End,
			FCollisionObjectQueryParams(ECC_Pawn),
			Params))
	{
		if (AShockPawn* Pawn = ::Cast<AShockPawn>(Hit.GetActor()))
		{
			if (!Pawn->IsDead())
			{
				UShockDamageLibrary::ApplyDamage(
					Pawn,
					ThrowDamage,
					Caster,
					FName(TEXT("Telekinesis")));
				bLastThrowHit = true;
			}
		}
	}
}

bool UShockTelekinesisPlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	LastAction = NAME_None;
	bLastThrowHit = false;

	if (!Caster)
	{
		return false;
	}

	UWorld* World = Caster->GetWorld();

	if (HeldActor)
	{
		const FVector ThrowDir = ResolveAimDirection(Caster, Aim);
		TryThrowDamage(Caster, ThrowDir);
		UShockPhysicsLibrary::SetActorPhysicsFrozen(HeldActor, false, true);
		UShockPhysicsLibrary::ApplyImpulse(HeldActor, ThrowDir * ThrowLaunchSpeed, true);

		if (World)
		{
			DrawDebugLine(
				World,
				HeldActor->GetActorLocation(),
				HeldActor->GetActorLocation() + ThrowDir * 120.0f,
				FColor(180, 180, 255),
				false,
				0.2f,
				0,
				2.0f);
		}

		HeldActor = nullptr;
		LastAction = ActionThrow;

		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_PLASMID name=Telekinesis eve=%.1f action=throw hit=%d"),
			EveCost,
			bLastThrowHit ? 1 : 0);
		return true;
	}

	AActor* Target = TraceGrabbable(Caster);
	if (!Target)
	{
		return false;
	}

	// PLAUSIBLE stand-in: freeze at current location (no per-frame camera hold).
	UShockPhysicsLibrary::SetActorPhysicsFrozen(Target, true);
	HeldActor = Target;
	LastAction = ActionGrab;

	if (World)
	{
		DrawDebugSphere(World, Target->GetActorLocation(), 16.0f, 8, FColor(200, 200, 255), false, 0.2f);
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PLASMID name=Telekinesis eve=%.1f action=grab hit=0"),
		EveCost);
	return true;
}
