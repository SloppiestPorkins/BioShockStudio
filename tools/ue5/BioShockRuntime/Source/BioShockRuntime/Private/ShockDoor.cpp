#include "ShockDoor.h"

#include "ShockPlayer.h"
#include "ShockScriptReflection.h"

#include "Animation/AnimSequence.h"
#include "Components/BoxComponent.h"
#include "Components/SceneComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/StaticMesh.h"
#include "EngineUtils.h"
#include "UObject/ConstructorHelpers.h"
#include "UObject/UObjectGlobals.h"

AShockDoor::AShockDoor()
{
	PrimaryActorTick.bCanEverTick = true;

	DoorRoot = CreateDefaultSubobject<USceneComponent>(TEXT("DoorRoot"));
	SetRootComponent(DoorRoot);

	DoorMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("DoorMesh"));
	DoorMesh->SetupAttachment(DoorRoot);
	DoorMesh->SetMobility(EComponentMobility::Movable);
	DoorMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);

	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(
		TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (CubeMesh.Succeeded())
	{
		DoorMesh->SetStaticMesh(CubeMesh.Object);
		// Thin door slab stand-in when no imported mesh is assigned.
		DoorMesh->SetRelativeScale3D(FVector(0.15f, 1.2f, 2.2f));
	}

	DoorSkeleton = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("DoorSkeleton"));
	DoorSkeleton->SetupAttachment(DoorRoot);
	DoorSkeleton->SetMobility(EComponentMobility::Movable);
	DoorSkeleton->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	DoorSkeleton->SetVisibility(false, true);

	DoorBlocker = CreateDefaultSubobject<UBoxComponent>(TEXT("DoorBlocker"));
	DoorBlocker->SetupAttachment(DoorRoot);
	DoorBlocker->SetBoxExtent(FVector(20.0f, 105.0f, 150.0f));
	DoorBlocker->SetCollisionProfileName(TEXT("BlockAll"));
	DoorBlocker->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

	ProximityTrigger = CreateDefaultSubobject<UBoxComponent>(TEXT("ProximityTrigger"));
	ProximityTrigger->SetupAttachment(DoorRoot);
	ProximityTrigger->SetBoxExtent(FVector(ProximityRadius, ProximityRadius, ProximityRadius));
	ProximityTrigger->SetCollisionProfileName(TEXT("Trigger"));
	ProximityTrigger->SetGenerateOverlapEvents(true);
	ProximityTrigger->OnComponentBeginOverlap.AddDynamic(this, &AShockDoor::OnProximityBeginOverlap);
	ProximityTrigger->OnComponentEndOverlap.AddDynamic(this, &AShockDoor::OnProximityEndOverlap);

}

void AShockDoor::BeginPlay()
{
	Super::BeginPlay();
	ClosedRelativeLocation = FVector::ZeroVector;
	ProximityTrigger->SetBoxExtent(FVector(ProximityRadius, ProximityRadius, ProximityRadius));
	ApplyVisualAndCollision(OpenAlpha);
	if (DoorSkeleton && DoorSkeleton->GetSkeletalMeshAsset())
	{
		FString Prefix = DoorSkeleton->GetSkeletalMeshAsset()->GetName();
		Prefix.RemoveFromEnd(TEXT("Anim"));
		const FName ClosedPose(*FString::Printf(TEXT("%s_CLOSED"), *Prefix));
		if (LoadDoorAnimation(ClosedPose))
		{
			PlayDoorAnimation(ClosedPose, 1.0f, true);
		}
	}
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

void AShockDoor::ConfigureSkeletalDoor(USkeletalMesh* Mesh, bool bVisibleMesh)
{
	if (!DoorSkeleton)
	{
		return;
	}
	DoorSkeleton->SetSkeletalMeshAsset(Mesh);
	bSkeletalVisual = Mesh != nullptr;
	DoorSkeleton->SetVisibility(Mesh != nullptr && bVisibleMesh, true);
	if (Mesh && DoorMesh)
	{
		DoorMesh->SetVisibility(false, true);
	}
	// A genuinely skinned, visible door (LoadRoomDoor) is authored at true world size. The source
	// actor's DrawScale3D (e.g. 0.15/1.2/2.2) only ever squashed the generic LoadRoomDoorMESH block
	// stand-in; inheriting it here stretches the rig. Proxy-skeleton doors (bVisibleMesh=false)
	// keep their imported scale because their static leaves are positioned by it.
	if (Mesh && bVisibleMesh)
	{
		SetActorScale3D(FVector::OneVector);
	}
}

bool AShockDoor::AddDoorLeaf(
	UStaticMesh* Mesh,
	FName Socket,
	FVector RelativeLocation,
	FRotator RelativeRotation,
	bool bPhysical)
{
	if (!Mesh || !DoorSkeleton)
	{
		return false;
	}
	UStaticMeshComponent* Leaf = NewObject<UStaticMeshComponent>(this);
	if (!Leaf)
	{
		return false;
	}
	Leaf->CreationMethod = EComponentCreationMethod::Instance;
	Leaf->SetMobility(EComponentMobility::Movable);
	Leaf->SetStaticMesh(Mesh);
	Leaf->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	AddInstanceComponent(Leaf);
	Leaf->RegisterComponent();
	Leaf->AttachToComponent(
		DoorSkeleton,
		FAttachmentTransformRules::SnapToTargetNotIncludingScale,
		Socket);
	Leaf->SetRelativeLocation(RelativeLocation);
	Leaf->SetRelativeRotation(RelativeRotation);
	DoorLeaves.Add(Leaf);
	(void)bPhysical; // Source flag is represented by the common DoorBlocker until per-leaf physics exists.
	return true;
}

void AShockDoor::ClearDoorLeaves()
{
	for (UStaticMeshComponent* Leaf : DoorLeaves)
	{
		if (Leaf)
		{
			Leaf->DestroyComponent();
		}
	}
	DoorLeaves.Reset();
}

UAnimSequence* AShockDoor::LoadDoorAnimation(FName AnimationName) const
{
	if (!DoorSkeleton || !DoorSkeleton->GetSkeletalMeshAsset() || AnimationName.IsNone())
	{
		return nullptr;
	}
	FString MeshPath = DoorSkeleton->GetSkeletalMeshAsset()->GetPathName();
	int32 Slash = INDEX_NONE;
	if (!MeshPath.FindLastChar(TEXT('/'), Slash))
	{
		return nullptr;
	}
	const FString Folder = MeshPath.Left(Slash);
	const FString Leaf = AnimationName.ToString();
	const FString ObjectPath = FString::Printf(
		TEXT("%s/Animations/%s.%s"),
		*Folder,
		*Leaf,
		*Leaf);
	return LoadObject<UAnimSequence>(nullptr, *ObjectPath);
}

bool AShockDoor::PlayDoorAnimation(FName AnimationName, float PlaybackRate, bool bLoop)
{
	const FString Name = AnimationName.ToString();
	const bool bClosedHold = Name.Contains(TEXT("CLOSED"), ESearchCase::IgnoreCase);
	const bool bOpenedHold = Name.Contains(TEXT("OPENED"), ESearchCase::IgnoreCase);
	const bool bClosing = !bClosedHold && Name.Contains(TEXT("CLOSE"), ESearchCase::IgnoreCase);
	const bool bOpening = !bOpenedHold && Name.Contains(TEXT("OPEN"), ESearchCase::IgnoreCase);

	if (bOpening && !OpenDoor(true))
	{
		return false;
	}
	if (bClosing)
	{
		CloseDoor(true);
	}
	if (bOpenedHold)
	{
		bOpen = true;
		OpenAlpha = 1.0f;
		ApplyVisualAndCollision(OpenAlpha);
	}
	else if (bClosedHold)
	{
		bOpen = false;
		OpenAlpha = 0.0f;
		ApplyVisualAndCollision(OpenAlpha);
	}

	PlayingDoorAnimation = LoadDoorAnimation(AnimationName);
	if (PlayingDoorAnimation && DoorSkeleton)
	{
		DoorSkeleton->PlayAnimation(PlayingDoorAnimation, bLoop);
		DoorSkeleton->SetPlayRate(FMath::IsNearlyZero(PlaybackRate) ? 1.0f : PlaybackRate);
		DoorSkeleton->TickAnimation(0.0f, false);
		DoorSkeleton->RefreshBoneTransforms();
		if (bOpening || bClosing)
		{
			OpenDuration = PlayingDoorAnimation->GetPlayLength()
				/ FMath::Max(FMath::Abs(PlaybackRate), KINDA_SMALL_NUMBER);
		}
	}
	return bOpening || bClosing || bOpenedHold || bClosedHold || PlayingDoorAnimation != nullptr;
}

bool AShockDoor::IsDoorAnimationComplete(FName AnimationName) const
{
	const FString Name = AnimationName.ToString();
	if (Name.Contains(TEXT("OPEN"), ESearchCase::IgnoreCase))
	{
		return IsFullyOpen();
	}
	if (Name.Contains(TEXT("CLOSE"), ESearchCase::IgnoreCase))
	{
		return IsFullyClosed();
	}
	return true;
}

FName AShockDoor::GetPlayingDoorAnimationForVerify() const
{
	return PlayingDoorAnimation ? PlayingDoorAnimation->GetFName() : NAME_None;
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
		ClosedRelativeLocation = DoorMesh->GetRelativeLocation();
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
	return DoorBlocker
		&& DoorBlocker->GetCollisionEnabled() != ECollisionEnabled::NoCollision;
}

uint8 AShockDoor::GetCollisionEnabledForVerify() const
{
	if (!DoorBlocker)
	{
		return static_cast<uint8>(ECollisionEnabled::NoCollision);
	}
	return static_cast<uint8>(DoorBlocker->GetCollisionEnabled());
}

AShockDoor* AShockDoor::FindByLabel(UWorld* World, FName Label)
{
	TArray<AShockDoor*> All = CollectByLabel(World, Label);
	return All.Num() > 0 ? All[0] : nullptr;
}

TArray<AShockDoor*> AShockDoor::CollectByLabel(UWorld* World, FName Label)
{
	TArray<AShockDoor*> Out;
	if (!World || Label.IsNone())
	{
		return Out;
	}
	const FString Want = Label.ToString();
	for (TActorIterator<AShockDoor> It(World); It; ++It)
	{
		AShockDoor* Door = *It;
		if (Door && ShockScriptReflection::ActorMatchesLabel(Door, Want))
		{
			Out.Add(Door);
		}
	}
	return Out;
}

void AShockDoor::ApplyVisualAndCollision(float Alpha)
{
	// The source clip drives a configured skeleton. If no clip is available, preserve the
	// measured LoadRoomDoor_OPEN displacement as a clean local-Y slide of the visible fallback.
	if (!PlayingDoorAnimation)
	{
		const FVector Location = ClosedRelativeLocation + SlideOffset * Alpha;
		if (DoorMesh)
		{
			DoorMesh->SetRelativeLocation(Location);
		}
		if (DoorSkeleton)
		{
			DoorSkeleton->SetRelativeLocation(Location);
		}
	}

	// The blocker is independent of missing source PhysicsAssets and is gone at the open pose.
	const bool bBlocking = Alpha < 1.0f - KINDA_SMALL_NUMBER;
	DoorBlocker->SetCollisionEnabled(
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
