#include "ShockPhysicsLibrary.h"

#include "Components/PrimitiveComponent.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/StaticMesh.h"
#include "Engine/TargetPoint.h"
#include "EngineUtils.h"
#include "GameFramework/Actor.h"
#include "ShockActionApplyImpulse.h"
#include "ShockActionEnableOrDisableHavokForceActor.h"
#include "ShockActionFreezeHavokActor.h"
#include "ShockActionTriggerHavokForceActor.h"
#include "ShockDamageLibrary.h"
#include "ShockScriptReflection.h"

namespace
{
struct FShockPhysicsFrozenState
{
	bool bPriorSimulatePhysics = false;
};

TMap<TWeakObjectPtr<AActor>, FShockPhysicsFrozenState> GFrozenPriorState;
TSet<FName> GDisabledHavokForceActors;

UPrimitiveComponent* GetRootPrimitive(AActor* Actor)
{
	return Actor ? Cast<UPrimitiveComponent>(Actor->GetRootComponent()) : nullptr;
}

TArray<UPrimitiveComponent*> CollectSimulatingPrimitives(AActor* Actor)
{
	TArray<UPrimitiveComponent*> Simulating;
	if (!Actor)
	{
		return Simulating;
	}
	TArray<UPrimitiveComponent*> Primitives;
	Actor->GetComponents<UPrimitiveComponent>(Primitives);
	for (UPrimitiveComponent* Prim : Primitives)
	{
		if (Prim && Prim->IsSimulatingPhysics())
		{
			Simulating.Add(Prim);
		}
	}
	return Simulating;
}
} // namespace

AActor* UShockPhysicsLibrary::FindActorByLabel(UWorld* World, FName Label)
{
	TArray<AActor*> Found = ShockScriptReflection::CollectActorsByLabel(World, Label);
	return Found.Num() > 0 ? Found[0] : nullptr;
}

int32 UShockPhysicsLibrary::ApplyImpulse(AActor* Target, FVector Impulse, bool bVelChange, bool bWakeIfNeeded)
{
	if (!Target || Impulse.IsNearlyZero())
	{
		return 0;
	}

	TArray<UPrimitiveComponent*> Simulating = CollectSimulatingPrimitives(Target);
	if (Simulating.Num() == 0 && bWakeIfNeeded)
	{
		if (UPrimitiveComponent* Root = GetRootPrimitive(Target))
		{
			Root->SetMobility(EComponentMobility::Movable);
			Root->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			Root->BodyInstance.SetInstanceSimulatePhysics(true);
			Root->RecreatePhysicsState();
			Root->SetSimulatePhysics(true);
			if (Root->IsSimulatingPhysics())
			{
				Simulating.Add(Root);
			}
		}
	}

	int32 Applied = 0;
	for (UPrimitiveComponent* Prim : Simulating)
	{
		Prim->AddImpulse(Impulse, NAME_None, bVelChange);
		++Applied;
	}
	return Applied;
}

int32 UShockPhysicsLibrary::ApplyRadialImpulse(
	UWorld* World,
	FVector Origin,
	float Radius,
	float Strength,
	bool bVelChange)
{
	if (!World || Radius <= 0.0f || FMath::IsNearlyZero(Strength))
	{
		return 0;
	}

	int32 HitCount = 0;
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
		TArray<UPrimitiveComponent*> Primitives;
		Actor->GetComponents<UPrimitiveComponent>(Primitives);
		for (UPrimitiveComponent* Prim : Primitives)
		{
			if (!Prim || !Prim->IsSimulatingPhysics())
			{
				continue;
			}
			const float Dist = FVector::Dist(Origin, Prim->GetComponentLocation());
			if (Dist > Radius)
			{
				continue;
			}
			const float Falloff = 1.0f - (Dist / Radius);
			Prim->AddRadialImpulse(
				Origin,
				Radius,
				Strength * Falloff,
				ERadialImpulseFalloff::RIF_Constant,
				bVelChange);
			++HitCount;
		}
	}
	return HitCount;
}

bool UShockPhysicsLibrary::SetActorPhysicsFrozen(AActor* Target, bool bFrozen, bool bForceSimulateOnUnfreeze)
{
	UPrimitiveComponent* Root = GetRootPrimitive(Target);
	if (!Root)
	{
		return false;
	}

	if (bFrozen)
	{
		FShockPhysicsFrozenState State;
		State.bPriorSimulatePhysics = Root->IsSimulatingPhysics();
		GFrozenPriorState.Add(Target, State);
		Root->SetSimulatePhysics(false);
		Root->PutAllRigidBodiesToSleep();
		return true;
	}

	bool bRestoreSimulate = bForceSimulateOnUnfreeze;
	if (const FShockPhysicsFrozenState* Prior = GFrozenPriorState.Find(Target))
	{
		bRestoreSimulate = bForceSimulateOnUnfreeze || Prior->bPriorSimulatePhysics;
		GFrozenPriorState.Remove(Target);
	}

	Root->SetSimulatePhysics(bRestoreSimulate);
	if (bRestoreSimulate)
	{
		Root->WakeAllRigidBodies();
	}
	return true;
}

bool UShockPhysicsLibrary::IsActorFrozenForVerify(AActor* Target)
{
	return Target && GFrozenPriorState.Contains(Target);
}

void UShockPhysicsLibrary::SetHavokForceActorEnabled(FName Label, bool bEnabled)
{
	if (Label.IsNone())
	{
		return;
	}
	if (bEnabled)
	{
		GDisabledHavokForceActors.Remove(Label);
	}
	else
	{
		GDisabledHavokForceActors.Add(Label);
	}
}

bool UShockPhysicsLibrary::IsHavokForceActorEnabled(FName Label)
{
	return !Label.IsNone() && !GDisabledHavokForceActors.Contains(Label);
}

namespace
{
const FVector GTestBase(-17320.0f, 1272.0f, 7850.0f);

AStaticMeshActor* SpawnTestBox(UWorld* World, FName Label, FVector Location)
{
	if (!World)
	{
		return nullptr;
	}
	UStaticMesh* Cube = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (!Cube)
	{
		return nullptr;
	}
	const FTransform Transform(FRotator::ZeroRotator, Location);
	AStaticMeshActor* Actor = World->SpawnActorDeferred<AStaticMeshActor>(
		AStaticMeshActor::StaticClass(),
		Transform,
		nullptr,
		nullptr,
		ESpawnActorCollisionHandlingMethod::AlwaysSpawn);
	if (!Actor)
	{
		return nullptr;
	}
#if WITH_EDITOR
	Actor->SetActorLabel(Label.ToString());
#endif
	Actor->Tags.Add(Label);
	if (UStaticMeshComponent* Mesh = Actor->GetStaticMeshComponent())
	{
		Mesh->SetStaticMesh(Cube);
		Mesh->SetMobility(EComponentMobility::Movable);
		Mesh->SetCollisionProfileName(TEXT("PhysicsActor"));
		Mesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		Mesh->SetEnableGravity(true);
		Mesh->SetMassOverrideInKg(NAME_None, 50.0f, true);
	}
	Actor->FinishSpawning(Transform);
	if (UStaticMeshComponent* Mesh = Actor->GetStaticMeshComponent())
	{
		Mesh->SetSimulatePhysics(true);
	}
	return Actor;
}

bool VelocityAbove(UPrimitiveComponent* Prim, float MinSpeed)
{
	return Prim && Prim->GetPhysicsLinearVelocity().Size() >= MinSpeed;
}

UPrimitiveComponent* FindSimulatingPrimitive(UWorld* World)
{
	if (!World)
	{
		return nullptr;
	}
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		TArray<UPrimitiveComponent*> Primitives;
		It->GetComponents<UPrimitiveComponent>(Primitives);
		for (UPrimitiveComponent* Prim : Primitives)
		{
			if (Prim && Prim->IsSimulatingPhysics())
			{
				return Prim;
			}
		}
	}
	return nullptr;
}
} // namespace

bool UShockPhysicsLibrary::RunHeadlessSelfTest(UWorld* World, FString& OutError)
{
	OutError.Reset();
	if (!World)
	{
		OutError = TEXT("no_world");
		return false;
	}

	GDisabledHavokForceActors.Empty();
	GFrozenPriorState.Empty();

	AStaticMeshActor* ImpulseBoxActor = SpawnTestBox(World, TEXT("ImpulseBox"), GTestBase);
	AActor* ImpulseTarget = ImpulseBoxActor;
	if (UPrimitiveComponent* ExistingSim = FindSimulatingPrimitive(World))
	{
		if (ImpulseBoxActor)
		{
			ImpulseBoxActor->Destroy();
		}
		ImpulseTarget = ExistingSim->GetOwner();
		if (ImpulseTarget)
		{
			ImpulseTarget->Tags.AddUnique(TEXT("ImpulseBox"));
#if WITH_EDITOR
			ImpulseTarget->SetActorLabel(TEXT("ImpulseBox"));
#endif
		}
	}
	ATargetPoint* ForceOrigin = World->SpawnActor<ATargetPoint>(
		ATargetPoint::StaticClass(),
		ImpulseTarget ? ImpulseTarget->GetActorLocation() : GTestBase,
		FRotator::ZeroRotator);
	if (ForceOrigin)
	{
#if WITH_EDITOR
		ForceOrigin->SetActorLabel(TEXT("ForceOrigin"));
#endif
		ForceOrigin->Tags.Add(TEXT("ForceOrigin"));
	}

	if (!ImpulseTarget || !ForceOrigin)
	{
		OutError = TEXT("spawn");
		return false;
	}

	UPrimitiveComponent* ImpulsePrim = Cast<UPrimitiveComponent>(ImpulseTarget->GetRootComponent());
	if (!ImpulsePrim || !ImpulsePrim->IsSimulatingPhysics())
	{
		OutError = TEXT("not_simulating");
		return false;
	}

	UShockActionApplyImpulse* ImpulseAction = NewObject<UShockActionApplyImpulse>();
	ImpulseAction->Configure(TEXT("ImpulseBox"), FVector(0.0f, 0.0f, 800.0f), NAME_None);
	if (!FindActorByLabel(World, TEXT("ImpulseBox")))
	{
		OutError = TEXT("find_impulse");
		return false;
	}
	if (ApplyImpulse(ImpulseTarget, FVector(0.0f, 0.0f, 800.0f), true, true) < 1)
	{
		OutError = TEXT("library_impulse_before_action");
		return false;
	}
	if (ImpulseAction->ApplyInWorld(World) < 1)
	{
		OutError = TEXT("apply_impulse_action");
		return false;
	}
	if (!VelocityAbove(ImpulsePrim, 10.0f))
	{
		OutError = TEXT("impulse_velocity");
		return false;
	}

	if (ApplyImpulse(ImpulseTarget, FVector(100.0f, 0.0f, 0.0f), true, true) < 1)
	{
		OutError = TEXT("library_impulse");
		return false;
	}

	const FVector RadialOrigin = ImpulseTarget->GetActorLocation();
	const float SpeedBeforeRadial = ImpulsePrim->GetPhysicsLinearVelocity().Size();
	if (ApplyRadialImpulse(World, RadialOrigin, 300.0f, 40000.0f, true) < 1)
	{
		OutError = TEXT("radial_count");
		return false;
	}
	if (ImpulsePrim->GetPhysicsLinearVelocity().Size() <= SpeedBeforeRadial)
	{
		OutError = TEXT("radial_velocity");
		return false;
	}

	UShockActionFreezeHavokActor* FreezeAction = NewObject<UShockActionFreezeHavokActor>();
	FreezeAction->Configure(TEXT("ImpulseBox"), true);
	if (FreezeAction->ApplyInWorld(World) < 1 || ImpulsePrim->IsSimulatingPhysics())
	{
		OutError = TEXT("freeze");
		return false;
	}
	UShockActionFreezeHavokActor* UnfreezeAction = NewObject<UShockActionFreezeHavokActor>();
	UnfreezeAction->Configure(TEXT("ImpulseBox"), false);
	if (UnfreezeAction->ApplyInWorld(World) < 1 || !ImpulsePrim->IsSimulatingPhysics())
	{
		OutError = TEXT("unfreeze");
		return false;
	}

	UShockActionEnableOrDisableHavokForceActor* DisableForce = NewObject<UShockActionEnableOrDisableHavokForceActor>();
	DisableForce->Configure(TEXT("ForceOrigin"), false);
	DisableForce->ApplyInWorld(World);
	UShockActionTriggerHavokForceActor* TriggerForce = NewObject<UShockActionTriggerHavokForceActor>();
	TriggerForce->Configure(TEXT("ForceOrigin"));
	if (TriggerForce->ApplyInWorld(World) != 0)
	{
		OutError = TEXT("force_disabled");
		return false;
	}
	UShockActionEnableOrDisableHavokForceActor* EnableForce = NewObject<UShockActionEnableOrDisableHavokForceActor>();
	EnableForce->Configure(TEXT("ForceOrigin"), true);
	EnableForce->ApplyInWorld(World);
	if (TriggerForce->ApplyInWorld(World) < 1)
	{
		OutError = TEXT("force_trigger");
		return false;
	}

	for (AActor* Actor : {ForceOrigin})
	{
		if (Actor)
		{
			Actor->Destroy();
		}
	}
	return true;
}
