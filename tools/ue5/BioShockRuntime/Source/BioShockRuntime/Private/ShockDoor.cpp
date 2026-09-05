#include "ShockDoor.h"

#include "ShockPlayer.h"

#include "Components/BoxComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "EngineUtils.h"
#include "UObject/ConstructorHelpers.h"

AShockDoor::AShockDoor()
{
	PrimaryActorTick.bCanEverTick = true;

	DoorMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("DoorMesh"));
	SetRootComponent(DoorMesh);
	DoorMesh->SetMobility(EComponentMobility::Movable);
	DoorMesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	DoorMesh->SetCollisionProfileName(TEXT("BlockAll"));

	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(
		TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (CubeMesh.Succeeded())
	{
		DoorMesh->SetStaticMesh(CubeMesh.Object);
		// Thin door slab stand-in when no imported mesh is assigned.
		DoorMesh->SetRelativeScale3D(FVector(0.15f, 1.2f, 2.2f));
	}

	ProximityTrigger = CreateDefaultSubobject<UBoxComponent>(TEXT("ProximityTrigger"));
	ProximityTrigger->SetupAttachment(DoorMesh);
	ProximityTrigger->SetBoxExtent(FVector(ProximityRadius, ProximityRadius, ProximityRadius));
	ProximityTrigger->SetCollisionProfileName(TEXT("Trigger"));
	ProximityTrigger->SetGenerateOverlapEvents(true);
	ProximityTrigger->OnComponentBeginOverlap.AddDynamic(this, &AShockDoor::OnProximityBeginOverlap);
	ProximityTrigger->OnComponentEndOverlap.AddDynamic(this, &AShockDoor::OnProximityEndOverlap);

	ClosedRelativeRotation = FRotator::ZeroRotator;
}

void AShockDoor::BeginPlay()
{
	Super::BeginPlay();
	ClosedRelativeRotation = DoorMesh ? DoorMesh->GetRelativeRotation() : FRotator::ZeroRotator;
	ProximityTrigger->SetBoxExtent(FVector(ProximityRadius, ProximityRadius, ProximityRadius));
	ApplyVisualAndCollision(OpenAlpha);
}

void AShockDoor::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	const float Target = bOpen ? 1.0f : 0.0f;
	if (!FMath::IsNearlyEqual(OpenAlpha, Target))
	{
		const float Step = OpenDuration > KINDA_SMALL_NUMBER
			? (DeltaSeconds / OpenDuration)
			: 1.0f;
		if (bOpen)
		{
			OpenAlpha = FMath::Min(1.0f, OpenAlpha + Step);
		}
		else
		{
			OpenAlpha = FMath::Max(0.0f, OpenAlpha - Step);
		}
		ApplyVisualAndCollision(OpenAlpha);
	}

	UpdateProximityAutoClose(DeltaSeconds);
}

void AShockDoor::SetLocked(bool bInLocked)
{
	bLocked = bInLocked;
}

void AShockDoor::SetBroken(bool bInBroken)
{
	bBroken = bInBroken;
	if (bBroken && bOpen)
	{
		// Broken doors stay where they are; scripts may still ForceClose.
	}
}

bool AShockDoor::OpenDoor(bool bInStayOpen)
{
	if (bLocked || bBroken)
	{
		return false;
	}
	if (bInStayOpen)
	{
		bStayOpen = true;
	}
	bOpen = true;
	AutoCloseRemaining = -1.0f;
	return true;
}

bool AShockDoor::CloseDoor(bool bForce)
{
	if (!bForce && bStayOpen)
	{
		return false;
	}
	if (bForce)
	{
		bStayOpen = false;
	}
	bOpen = false;
	AutoCloseRemaining = -1.0f;
	return true;
}

bool AShockDoor::ToggleDoor()
{
	return bOpen ? CloseDoor(true) : OpenDoor(false);
}

void AShockDoor::ConfigureForVerify(FName Label, bool bInLocked, bool bInitiallyOpen)
{
	DoorLabel = Label;
	bLocked = bInLocked;
	bBroken = false;
	bStayOpen = false;
	bOpen = bInitiallyOpen;
	OpenAlpha = bInitiallyOpen ? 1.0f : 0.0f;
	AutoCloseRemaining = -1.0f;
	OverlappingPlayers = 0;
	if (DoorMesh)
	{
		ClosedRelativeRotation = DoorMesh->GetRelativeRotation();
	}
	ApplyVisualAndCollision(OpenAlpha);
}

bool AShockDoor::OpenForVerify()
{
	if (!OpenDoor(true))
	{
		return false;
	}
	OpenAlpha = 1.0f;
	ApplyVisualAndCollision(OpenAlpha);
	return true;
}

bool AShockDoor::CloseForVerify()
{
	if (!CloseDoor(true))
	{
		return false;
	}
	OpenAlpha = 0.0f;
	ApplyVisualAndCollision(OpenAlpha);
	return true;
}

void AShockDoor::AdvanceDoorForVerify(float DeltaSeconds)
{
	Tick(DeltaSeconds);
}

bool AShockDoor::IsBlockingCollisionEnabled() const
{
	return DoorMesh
		&& DoorMesh->GetCollisionEnabled() != ECollisionEnabled::NoCollision;
}

uint8 AShockDoor::GetCollisionEnabledForVerify() const
{
	if (!DoorMesh)
	{
		return static_cast<uint8>(ECollisionEnabled::NoCollision);
	}
	return static_cast<uint8>(DoorMesh->GetCollisionEnabled());
}

AShockDoor* AShockDoor::FindByLabel(UWorld* World, FName Label)
{
	if (!World || Label.IsNone())
	{
		return nullptr;
	}

	const FString Want = Label.ToString();
	for (TActorIterator<AShockDoor> It(World); It; ++It)
	{
		AShockDoor* Door = *It;
		if (!Door)
		{
			continue;
		}
		if (Door->DoorLabel.ToString().Equals(Want, ESearchCase::CaseSensitive))
		{
			return Door;
		}
#if WITH_EDITOR
		if (Door->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			return Door;
		}
#endif
	}
	return nullptr;
}

void AShockDoor::ApplyVisualAndCollision(float Alpha)
{
	if (!DoorMesh)
	{
		return;
	}

	const FRotator OpenRotation = ClosedRelativeRotation + FRotator(0.0f, OpenYawDegrees, 0.0f);
	DoorMesh->SetRelativeRotation(FMath::Lerp(ClosedRelativeRotation, OpenRotation, Alpha));

	// Walk-through once mostly open — mirrors the "collision updates when open" requirement.
	const bool bBlocking = Alpha < 0.85f;
	DoorMesh->SetCollisionEnabled(
		bBlocking ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
}

void AShockDoor::UpdateProximityAutoClose(float DeltaSeconds)
{
	if (!bOpen || bStayOpen || OverlappingPlayers > 0)
	{
		return;
	}
	if (AutoCloseRemaining < 0.0f)
	{
		// APPROXIMATED — StayOpenDuration exists on a few source doors (4 actors); default brief hold.
		AutoCloseRemaining = 1.25f;
	}
	AutoCloseRemaining -= DeltaSeconds;
	if (AutoCloseRemaining <= 0.0f)
	{
		CloseDoor(false);
	}
}

void AShockDoor::OnProximityBeginOverlap(
	UPrimitiveComponent* OverlappedComponent,
	AActor* OtherActor,
	UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex,
	bool bFromSweep,
	const FHitResult& SweepResult)
{
	(void)OverlappedComponent;
	(void)OtherComp;
	(void)OtherBodyIndex;
	(void)bFromSweep;
	(void)SweepResult;

	if (!Cast<AShockPlayer>(OtherActor))
	{
		return;
	}
	++OverlappingPlayers;
	AutoCloseRemaining = -1.0f;
	// APPROXIMATED — BioShock doors are often Use/script-driven; proximity-open is the v1 path
	// because ShockPlayer has no Interact bind yet (only UseFirstAid / UseEveHypo).
	OpenDoor(false);
}

void AShockDoor::OnProximityEndOverlap(
	UPrimitiveComponent* OverlappedComponent,
	AActor* OtherActor,
	UPrimitiveComponent* OtherComp,
	int32 OtherBodyIndex)
{
	(void)OverlappedComponent;
	(void)OtherComp;
	(void)OtherBodyIndex;

	if (!Cast<AShockPlayer>(OtherActor))
	{
		return;
	}
	OverlappingPlayers = FMath::Max(0, OverlappingPlayers - 1);
}
