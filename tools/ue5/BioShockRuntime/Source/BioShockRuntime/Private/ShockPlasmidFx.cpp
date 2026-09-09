#include "ShockPlasmidFx.h"

#include "Components/SceneComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "NiagaraComponent.h"
#include "NiagaraSystem.h"
#include "UObject/ConstructorHelpers.h"

AShockPlasmidFx::AShockPlasmidFx()
{
	PrimaryActorTick.bCanEverTick = false;

	SceneRoot = CreateDefaultSubobject<USceneComponent>(TEXT("SceneRoot"));
	SetRootComponent(SceneRoot);

	Niagara = CreateDefaultSubobject<UNiagaraComponent>(TEXT("Niagara"));
	Niagara->SetupAttachment(SceneRoot);
	Niagara->SetAutoActivate(false);

	OrbMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("OrbMesh"));
	OrbMesh->SetupAttachment(SceneRoot);
	OrbMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	OrbMesh->SetCastShadow(false);

	BeamMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BeamMesh"));
	BeamMesh->SetupAttachment(SceneRoot);
	BeamMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	BeamMesh->SetCastShadow(false);

	static ConstructorHelpers::FObjectFinder<UStaticMesh> Sphere(
		TEXT("/Engine/BasicShapes/Sphere.Sphere"));
	static ConstructorHelpers::FObjectFinder<UStaticMesh> Cylinder(
		TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
	if (Sphere.Succeeded())
	{
		OrbMesh->SetStaticMesh(Sphere.Object);
	}
	if (Cylinder.Succeeded())
	{
		BeamMesh->SetStaticMesh(Cylinder.Object);
	}
	OrbMesh->SetVisibility(false);
	BeamMesh->SetVisibility(false);
}

void AShockPlasmidFx::ConfigureCommon(
	const FString& SystemAssetPath,
	const FLinearColor& Tint,
	float LifeSeconds)
{
	RequestedAssetPath = SystemAssetPath;
	if (UNiagaraSystem* System = LoadObject<UNiagaraSystem>(nullptr, *SystemAssetPath))
	{
		Niagara->SetAsset(System);
		Niagara->SetVariableLinearColor(TEXT("User.Color"), Tint);
		Niagara->SetVariableLinearColor(TEXT("Color"), Tint);
		Niagara->Activate(true);
		bNiagaraAssetLoaded = true;
	}

	UMaterialInterface* BaseMaterial = LoadObject<UMaterialInterface>(
		nullptr,
		TEXT("/Game/BioShockFX/Plasmids/M_PlasmidFx_Base.M_PlasmidFx_Base"));
	for (UStaticMeshComponent* Visual : {OrbMesh.Get(), BeamMesh.Get()})
	{
		if (!Visual || !BaseMaterial)
		{
			continue;
		}
		UMaterialInstanceDynamic* Dynamic = UMaterialInstanceDynamic::Create(BaseMaterial, this);
		if (Dynamic)
		{
			Dynamic->SetVectorParameterValue(TEXT("Tint"), Tint);
			Visual->SetMaterial(0, Dynamic);
		}
	}

	SetLifeSpan(FMath::Max(0.05f, LifeSeconds));
}

AShockPlasmidFx* AShockPlasmidFx::SpawnBurst(
	UWorld* World,
	const FString& SystemAssetPath,
	const FVector& WorldLocation,
	const FRotator& WorldRotation,
	const FLinearColor& Tint,
	float LifeSeconds,
	float Radius,
	USceneComponent* AttachParent)
{
	if (!World)
	{
		return nullptr;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AShockPlasmidFx* Fx = World->SpawnActor<AShockPlasmidFx>(
		AShockPlasmidFx::StaticClass(), WorldLocation, WorldRotation, Params);
	if (!Fx)
	{
		return nullptr;
	}
	if (AttachParent)
	{
		Fx->AttachToComponent(AttachParent, FAttachmentTransformRules::KeepWorldTransform);
	}
	Fx->OrbMesh->SetVisibility(true);
	Fx->OrbMesh->SetWorldScale3D(FVector(FMath::Max(1.0f, Radius) / 50.0f));
	Fx->ConfigureCommon(SystemAssetPath, Tint, LifeSeconds);
	return Fx;
}

AShockPlasmidFx* AShockPlasmidFx::SpawnBeam(
	UWorld* World,
	const FString& SystemAssetPath,
	const FVector& Start,
	const FVector& End,
	const FLinearColor& Tint,
	float LifeSeconds,
	float Radius)
{
	if (!World)
	{
		return nullptr;
	}
	const FVector Delta = End - Start;
	const float Length = Delta.Size();
	if (Length <= KINDA_SMALL_NUMBER)
	{
		return SpawnBurst(World, SystemAssetPath, Start, FRotator::ZeroRotator, Tint, LifeSeconds, Radius);
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	const FVector Midpoint = (Start + End) * 0.5f;
	const FQuat BeamRotation = FQuat::FindBetweenNormals(FVector::UpVector, Delta / Length);
	AShockPlasmidFx* Fx = World->SpawnActor<AShockPlasmidFx>(
		AShockPlasmidFx::StaticClass(), Midpoint, BeamRotation.Rotator(), Params);
	if (!Fx)
	{
		return nullptr;
	}
	Fx->BeamMesh->SetVisibility(true);
	Fx->BeamMesh->SetRelativeScale3D(FVector(
		FMath::Max(0.5f, Radius) / 50.0f,
		FMath::Max(0.5f, Radius) / 50.0f,
		Length / 100.0f));
	Fx->ConfigureCommon(SystemAssetPath, Tint, LifeSeconds);
	return Fx;
}
