#include "ShockDoorKeypadControl.h"

#include "ShockDoor.h"
#include "ShockScriptSubsystem.h"

#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"

AShockDoorKeypadControl::AShockDoorKeypadControl()
{
	PrimaryActorTick.bCanEverTick = false;

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);
	Mesh->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	Mesh->SetCollisionObjectType(ECC_WorldStatic);
	Mesh->SetCollisionResponseToAllChannels(ECR_Ignore);
	// TickInteractionTrace (ShockPlayer) traces ECC_Visibility -- same collision-channel need as
	// AShockSwitchActor.
	Mesh->SetCollisionResponseToChannel(ECC_Visibility, ECR_Block);
	Mesh->SetCastShadow(true);

	SkeletalMeshComp = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("SkeletalMesh"));
	SkeletalMeshComp->SetupAttachment(Mesh);
	SkeletalMeshComp->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	SkeletalMeshComp->SetVisibility(false);
}

void AShockDoorKeypadControl::Configure(FName InKeypadLabel, FName InDoorLabel, bool bInHackable)
{
	KeypadLabel = InKeypadLabel;
	DoorLabel = InDoorLabel;
	bHackable = bInHackable;
}

bool AShockDoorKeypadControl::TryInteract(AShockPlayer* Player)
{
	if (!Player || !CanInteract())
	{
		return false;
	}
	bHasFired = true;

	if (UWorld* World = GetWorld())
	{
		if (!DoorLabel.IsNone())
		{
			// CollectByLabel (not FindByLabel), matching ActionUnlockDoor's own established
			// pattern -- a door can be made of multiple leaf pieces sharing the same label.
			for (AShockDoor* Door : AShockDoor::CollectByLabel(World, DoorLabel))
			{
				if (Door)
				{
					Door->SetLocked(false);
				}
			}
		}
		if (UShockScriptSubsystem* Sub = UShockScriptSubsystem::Get(World))
		{
			Sub->DispatchDoorKeypadUsed(KeypadLabel.ToString(), TEXT(""));
		}
	}
	return true;
}

void AShockDoorKeypadControl::SetKeypadStaticMesh(UStaticMesh* InMesh)
{
	if (Mesh && InMesh)
	{
		Mesh->SetStaticMesh(InMesh);
	}
}

void AShockDoorKeypadControl::SetKeypadSkeletalMesh(USkeletalMesh* InMesh)
{
	if (SkeletalMeshComp && InMesh)
	{
		SkeletalMeshComp->SetSkeletalMesh(InMesh);
		SkeletalMeshComp->SetVisibility(true);
		SkeletalMeshComp->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		SkeletalMeshComp->SetCollisionObjectType(ECC_WorldStatic);
		SkeletalMeshComp->SetCollisionResponseToAllChannels(ECR_Ignore);
		SkeletalMeshComp->SetCollisionResponseToChannel(ECC_Visibility, ECR_Block);
	}
}
