#include "ShockWaterVolume.h"

#include "Components/BoxComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/OverlapResult.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "Materials/MaterialInterface.h"
#include "UObject/ConstructorHelpers.h"

namespace ShockWaterVolumePrivate
{
	static const TCHAR* StillMaterialPath = TEXT("/Game/BioShock/Water/M_ShockWater.M_ShockWater");
	static const TCHAR* CascadingMaterialPath =
		TEXT("/Game/BioShock/Water/MI_ShockWater_Cascading.MI_ShockWater_Cascading");
	// Engine plane is 100x100 uu in XY.
	static constexpr float PlaneHalfSize = 50.0f;
}

AShockWaterVolume::AShockWaterVolume()
{
	PrimaryActorTick.bCanEverTick = false;

	Volume = CreateDefaultSubobject<UBoxComponent>(TEXT("Volume"));
	SetRootComponent(Volume);
	Volume->SetBoxExtent(FVector(200.0f, 200.0f, 100.0f));
	Volume->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	Volume->SetCollisionResponseToAllChannels(ECR_Ignore);
	Volume->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
	Volume->SetGenerateOverlapEvents(true);
	Volume->SetHiddenInGame(true);
	Volume->SetVisibility(false);

	Surface = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Surface"));
	Surface->SetupAttachment(Volume);
	Surface->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Surface->SetCastShadow(false);
	Surface->SetHiddenInGame(false);
	Surface->SetVisibility(true);
	static ConstructorHelpers::FObjectFinder<UStaticMesh> PlaneMesh(
		TEXT("/Engine/BasicShapes/Plane.Plane"));
	if (PlaneMesh.Succeeded())
	{
		Surface->SetStaticMesh(PlaneMesh.Object);
	}
}

bool AShockWaterVolume::IsActorInWater(const AActor* Actor)
{
	if (!Actor)
	{
		return false;
	}

	UWorld* World = Actor->GetWorld();
	if (!World)
	{
		return false;
	}

	for (TActorIterator<AShockWaterVolume> It(World); It; ++It)
	{
		const AShockWaterVolume* Water = *It;
		if (!Water || !Water->bIsWater || !Water->Volume)
		{
			continue;
		}
		if (Water->Volume->IsOverlappingActor(Actor))
		{
			return true;
		}
		// Headless editor spawn may not fire overlap events; fall back to bounds test.
		const FBox Box = Water->Volume->Bounds.GetBox();
		if (Box.IsInside(Actor->GetActorLocation()))
		{
			return true;
		}
	}
	return false;
}

void AShockWaterVolume::ConfigureFromHalfExtent(FVector HalfExtent, bool bInCascading)
{
	bCascading = bInCascading;
	if (Volume)
	{
		Volume->SetBoxExtent(HalfExtent.GetAbs(), false);
	}
	RefreshSurface();
}

void AShockWaterVolume::RefreshSurface()
{
	if (!Surface || !Volume)
	{
		return;
	}

	const FVector Ext = Volume->GetUnscaledBoxExtent();
	// Top face of the AABB — XY sized to the volume, Z flush with the waterline.
	Surface->SetRelativeLocation(FVector(0.0f, 0.0f, Ext.Z));
	Surface->SetRelativeRotation(FRotator::ZeroRotator);
	const float ScaleX = FMath::Max(Ext.X / ShockWaterVolumePrivate::PlaneHalfSize, 0.01f);
	const float ScaleY = FMath::Max(Ext.Y / ShockWaterVolumePrivate::PlaneHalfSize, 0.01f);
	Surface->SetRelativeScale3D(FVector(ScaleX, ScaleY, 1.0f));
	Surface->SetHiddenInGame(false);
	Surface->SetVisibility(true);

	const TCHAR* MatPath = bCascading ? ShockWaterVolumePrivate::CascadingMaterialPath
									  : ShockWaterVolumePrivate::StillMaterialPath;
	if (UMaterialInterface* Mat = LoadObject<UMaterialInterface>(nullptr, MatPath))
	{
		Surface->SetMaterial(0, Mat);
	}
}

void AShockWaterVolume::RefreshOverlapsForVerify()
{
	if (Volume)
	{
		Volume->UpdateOverlaps();
	}
}

bool AShockWaterVolume::HasVisibleSurfaceForVerify() const
{
	if (!Surface || !Surface->GetStaticMesh())
	{
		return false;
	}
	if (Surface->bHiddenInGame || !Surface->IsVisible())
	{
		return false;
	}
	return Surface->GetMaterial(0) != nullptr;
}
