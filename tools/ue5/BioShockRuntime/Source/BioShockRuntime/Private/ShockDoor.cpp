#include "ShockDoor.h"

#include "ShockPlayer.h"

#include "Animation/AnimSequence.h"
#include "Components/BoxComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/SkeletalMesh.h"
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

	DoorSkeletalMesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("DoorSkeletalMesh"));
	DoorSkeletalMesh->SetupAttachment(DoorMesh);
	DoorSkeletalMesh->SetMobility(EComponentMobility::Movable);
	DoorSkeletalMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	DoorSkeletalMesh->SetHiddenInGame(true);
	DoorSkeletalMesh->SetVisibility(false);

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

	if (bSkeletalClipPlaying)
	{
		SkeletalClipRemaining -= DeltaSeconds;
		if (SkeletalClipRemaining <= 0.0f)
		{
			bSkeletalClipPlaying = false;
		}
	}

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
	if (bUseSkeletalDoor && OpenClip)
	{
		PlaySkeletalClip(OpenClip, false);
	}
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
	if (bUseSkeletalDoor && CloseClip)
	{
		PlaySkeletalClip(CloseClip, false);
	}
	return true;
}

void AShockDoor::ConfigureSkeletalDoor(
	USkeletalMesh* Mesh,
	UAnimSequence* OpenAnim,
	UAnimSequence* OpenedAnim,
	UAnimSequence* CloseAnim,
	UAnimSequence* ClosedAnim)
{
	if (!Mesh || !OpenAnim || !DoorSkeletalMesh)
	{
		return;
	}
	OpenClip = OpenAnim;
	OpenedClip = OpenedAnim;
	CloseClip = CloseAnim;
	ClosedClip = ClosedAnim;
	bUseSkeletalDoor = true;

	DoorSkeletalMesh->SetSkeletalMesh(Mesh);
	DoorSkeletalMesh->SetHiddenInGame(false);
	DoorSkeletalMesh->SetVisibility(true);
	DoorSkeletalMesh->SetRelativeTransform(FTransform::Identity);

	// The static slab stays as the invisible collision blocker (Tick toggles it by OpenAlpha).
	if (DoorMesh)
	{
		DoorMesh->SetHiddenInGame(true);
		DoorMesh->SetVisibility(false);
	}

	OpenDuration = FMath::Max(0.1f, OpenAnim->GetPlayLength());

	// Rest on the closed pose.
	if (ClosedClip)
	{
		PlaySkeletalClip(ClosedClip, false);
	}
	else
	{
		PlaySkeletalClip(CloseClip ? CloseClip.Get() : OpenAnim, false);
		DoorSkeletalMesh->Stop();
		DoorSkeletalMesh->SetPosition(0.0f, false);
	}
	bSkeletalClipPlaying = false;
}

void AShockDoor::PlaySkeletalClip(UAnimSequence* Clip, bool bLoop)
{
	if (!DoorSkeletalMesh || !Clip)
	{
		return;
	}
	DoorSkeletalMesh->PlayAnimation(Clip, bLoop);
	DoorSkeletalMesh->TickAnimation(0.0f, false);
	DoorSkeletalMesh->RefreshBoneTransforms();
	bSkeletalClipPlaying = !bLoop;
	SkeletalClipRemaining = bLoop ? 0.0f : Clip->GetPlayLength();
}

bool AShockDoor::PlayDoorClip(FName ClipName)
{
	const FString Name = ClipName.ToString();
	const bool bOpened = Name.Contains(TEXT("OPENED"), ESearchCase::IgnoreCase);
	const bool bClosed = Name.Contains(TEXT("CLOSED"), ESearchCase::IgnoreCase);
	const bool bOpening = !bOpened && Name.Contains(TEXT("OPEN"), ESearchCase::IgnoreCase);
	const bool bClosing = !bClosed && Name.Contains(TEXT("CLOS"), ESearchCase::IgnoreCase);

	if (!bUseSkeletalDoor)
	{
		// Static swing fallback — *OPEN* opens, *CLOS* closes.
		if (bOpened || bOpening) { return OpenDoor(true); }
		if (bClosed || bClosing) { return CloseDoor(true); }
		return false;
	}

	if (bOpened)
	{
		// "OPENED" is the script's "stay-open" confirmation that follows "OPEN". If the slide
		// is still playing, let it finish — don't snap past the animation.
		bStayOpen = true;
		AutoCloseRemaining = -1.0f;
		if (bOpen && bSkeletalClipPlaying)
		{
			return true;
		}
		bOpen = true;
		OpenAlpha = 1.0f;
		PlaySkeletalClip(OpenedClip ? OpenedClip.Get() : OpenClip.Get(), false);
		if (!OpenedClip && OpenClip)
		{
			DoorSkeletalMesh->SetPosition(OpenClip->GetPlayLength(), false);
		}
		bSkeletalClipPlaying = false;
		ApplyVisualAndCollision(OpenAlpha);
		return true;
	}
	if (bClosed)
	{
		bOpen = false;
		OpenAlpha = 0.0f;
		PlaySkeletalClip(ClosedClip ? ClosedClip.Get() : (CloseClip ? CloseClip.Get() : OpenClip.Get()), false);
		DoorSkeletalMesh->SetPosition(0.0f, false);
		bSkeletalClipPlaying = false;
		ApplyVisualAndCollision(OpenAlpha);
		return true;
	}
	if (bOpening) { return OpenDoor(true); }
	if (bClosing) { return CloseDoor(true); }
	return false;
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

	// Skeletal doors: the anim clip drives the visible mesh; the static slab stays put as an
	// invisible blocker. Swing doors: lerp the slab's yaw.
	if (!bUseSkeletalDoor)
	{
		const FRotator OpenRotation = ClosedRelativeRotation + FRotator(0.0f, OpenYawDegrees, 0.0f);
		DoorMesh->SetRelativeRotation(FMath::Lerp(ClosedRelativeRotation, OpenRotation, Alpha));
	}

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
	if (bEnableProximityOpen)
	{
		OpenDoor(false);
	}
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
