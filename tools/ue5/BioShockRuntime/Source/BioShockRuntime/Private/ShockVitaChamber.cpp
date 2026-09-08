#include "ShockVitaChamber.h"

#include "ShockAudioLibrary.h"
#include "ShockPlayer.h"

#include "Components/BoxComponent.h"
#include "Components/PointLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "EngineUtils.h"
#include "Materials/MaterialInstanceDynamic.h"

AShockVitaChamber::AShockVitaChamber()
{
	PrimaryActorTick.bCanEverTick = true;

	StationMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("StationMesh"));
	SetRootComponent(StationMesh);
	StationMesh->SetCollisionProfileName(TEXT("BlockAll"));

	ActivationVolume = CreateDefaultSubobject<UBoxComponent>(TEXT("ActivationVolume"));
	ActivationVolume->SetupAttachment(StationMesh);
	ActivationVolume->SetBoxExtent(FVector(230.0f, 230.0f, 260.0f));
	ActivationVolume->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	ActivationVolume->SetCollisionResponseToAllChannels(ECR_Ignore);
	ActivationVolume->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);
	ActivationVolume->SetGenerateOverlapEvents(true);

	ChamberGlow = CreateDefaultSubobject<UPointLightComponent>(TEXT("ChamberGlow"));
	ChamberGlow->SetupAttachment(StationMesh);
	ChamberGlow->SetRelativeLocation(FVector(0.0f, 0.0f, 150.0f));
	ChamberGlow->SetLightColor(FLinearColor(0.18f, 0.75f, 1.0f));
	ChamberGlow->SetAttenuationRadius(500.0f);
	ChamberGlow->SetIntensity(1800.0f);
}

void AShockVitaChamber::BeginPlay()
{
	Super::BeginPlay();
	ActivationVolume->OnComponentBeginOverlap.AddDynamic(
		this, &AShockVitaChamber::OnActivationVolumeBeginOverlap);
	RefreshActiveAppearance();
	if (CanResurrect())
	{
		UShockAudioLibrary::SpawnEventAttached(
			TEXT("BaseResurrectionStation"), TEXT("Alive"), StationMesh);
	}
}

void AShockVitaChamber::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	if (MaterialisePulseRemaining > 0.0f)
	{
		MaterialisePulseRemaining = FMath::Max(0.0f, MaterialisePulseRemaining - DeltaSeconds);
		const float Pulse = 1.0f + 2.5f * FMath::Sin(MaterialisePulseRemaining * 16.0f);
		ChamberGlow->SetIntensity(6000.0f * FMath::Max(0.35f, Pulse));
		if (MaterialisePulseRemaining <= 0.0f)
		{
			RefreshActiveAppearance();
		}
	}
}

void AShockVitaChamber::ConfigureIdentity(FName InLabel, const FString& InSourceKey)
{
	ScriptLabel = InLabel;
	SourceKey = InSourceKey;
#if WITH_EDITOR
	if (!InLabel.IsNone())
	{
		SetActorLabel(InLabel.ToString());
	}
#endif
}

void AShockVitaChamber::SetStationMesh(UStaticMesh* InMesh)
{
	StationMesh->SetStaticMesh(InMesh);
}

void AShockVitaChamber::SetActive(bool bInActive)
{
	if (bActive == bInActive)
	{
		return;
	}
	bActive = bInActive;
	RefreshActiveAppearance();
	UShockAudioLibrary::SpawnEventAttached(
		TEXT("BaseResurrectionStation"),
		bActive ? FName(TEXT("OnActivated")) : FName(TEXT("OnDeactivated")),
		StationMesh);
}

void AShockVitaChamber::SetAvailable(bool bInAvailable)
{
	bAvailable = bInAvailable;
	RefreshActiveAppearance();
}

FTransform AShockVitaChamber::GetPlayerStartTransform() const
{
	const FVector Origin = GetActorLocation();
	const FRotator ActorRot = GetActorRotation();

	// The shipped PlayerStart bone is not retained by the static-mesh export, so probe the four
	// cardinal directions around the machine and stand the player in the most open one, FACING
	// AWAY from the machine (materialising looking out into the room). A fixed local offset put
	// the player against a wall or the machine's side and looking the wrong way.
	const FVector Dirs[] = {
		ActorRot.RotateVector(FVector::ForwardVector),
		ActorRot.RotateVector(FVector::BackwardVector),
		ActorRot.RotateVector(FVector::RightVector),
		ActorRot.RotateVector(FVector::LeftVector),
	};
	const float Probe = 240.0f;
	FVector BestDir = Dirs[0];
	float BestClear = -1.0f;
	if (const UWorld* World = GetWorld())
	{
		const FVector EyeOrigin = Origin + FVector(0.0f, 0.0f, 110.0f);
		for (const FVector& Dir : Dirs)
		{
			FHitResult Hit;
			FCollisionQueryParams Params(SCENE_QUERY_STAT(VitaChamberClearance), false, this);
			const bool bHit = World->LineTraceSingleByChannel(
				Hit, EyeOrigin, EyeOrigin + Dir * Probe, ECC_Visibility, Params);
			const float Clear = bHit ? Hit.Distance : Probe;
			if (Clear > BestClear)
			{
				BestClear = Clear;
				BestDir = Dir;
			}
		}
	}

	const float StandOff = FMath::Clamp(BestClear - 45.0f, 70.0f, 190.0f);
	const FVector Location =
		Origin + BestDir * StandOff + FVector(0.0f, 0.0f, PlayerStartOffset.Z);
	return FTransform(BestDir.Rotation(), Location);
}

void AShockVitaChamber::PlayMaterialiseEffects()
{
	MaterialisePulseRemaining = 1.5f;
	ChamberGlow->SetIntensity(12000.0f);
	if (!UShockAudioLibrary::SpawnEventAttached(
			TEXT("BaseResurrectionStation"), TEXT("ResurrectedPlayer"), StationMesh))
	{
		// The 1-Medical w1 event table has Alive/door/activation events but no resolved
		// ResurrectedPlayer response. machines_rez_use is the shipped, located machine cue.
		UShockAudioLibrary::SpawnCueAtLocation(
			GetWorld(), TEXT("machines_rez_use"), GetActorLocation());
	}
}

AShockVitaChamber* AShockVitaChamber::FindNearestActive(UWorld* World, const FVector& From)
{
	AShockVitaChamber* Nearest = nullptr;
	float NearestDistanceSq = TNumericLimits<float>::Max();
	if (!World)
	{
		return nullptr;
	}
	for (TActorIterator<AShockVitaChamber> It(World); It; ++It)
	{
		if (!It->CanResurrect())
		{
			continue;
		}
		const float DistanceSq = FVector::DistSquared(From, It->GetPlayerStartTransform().GetLocation());
		if (DistanceSq < NearestDistanceSq)
		{
			NearestDistanceSq = DistanceSq;
			Nearest = *It;
		}
	}
	return Nearest;
}

void AShockVitaChamber::OnActivationVolumeBeginOverlap(
	UPrimitiveComponent* OverlappedComponent,
	AActor* OtherActor,
	UPrimitiveComponent* OtherComponent,
	int32 OtherBodyIndex,
	bool bFromSweep,
	const FHitResult& SweepResult)
{
	if (bAvailable && !bActive && Cast<AShockPlayer>(OtherActor))
	{
		SetActive(true);
	}
}

void AShockVitaChamber::RefreshActiveAppearance()
{
	const bool bLit = CanResurrect();
	ChamberGlow->SetVisibility(bAvailable);
	ChamberGlow->SetLightColor(
		bLit ? FLinearColor(0.18f, 0.75f, 1.0f) : FLinearColor(0.35f, 0.05f, 0.02f));
	ChamberGlow->SetIntensity(bLit ? 1800.0f : 250.0f);

	for (int32 Index = 0; Index < StationMesh->GetNumMaterials(); ++Index)
	{
		UMaterialInstanceDynamic* Material = StationMesh->CreateAndSetMaterialInstanceDynamic(Index);
		if (Material)
		{
			Material->SetScalarParameterValue(TEXT("Active"), bLit ? 1.0f : 0.0f);
			Material->SetScalarParameterValue(TEXT("EmissiveStrength"), bLit ? 1.0f : 0.05f);
		}
	}
}
