#include "ShockSwitchActor.h"

#include "ShockPlayer.h"

#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"

AShockSwitchActor::AShockSwitchActor()
{
	PrimaryActorTick.bCanEverTick = false;

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);
	Mesh->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
	Mesh->SetCollisionObjectType(ECC_WorldStatic);
	Mesh->SetCollisionResponseToAllChannels(ECR_Ignore);
	// TickInteractionTrace (ShockPlayer) traces ECC_Visibility -- without this the switch is a
	// solid-looking wall fixture the player can never actually select to interact with, the same
	// collision-channel gap already found and fixed for keypress pickups.
	Mesh->SetCollisionResponseToChannel(ECC_Visibility, ECR_Block);
	Mesh->SetCastShadow(true);

	SkeletalMeshComp = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("SkeletalMesh"));
	SkeletalMeshComp->SetupAttachment(Mesh);
	SkeletalMeshComp->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	SkeletalMeshComp->SetVisibility(false);
}

void AShockSwitchActor::Configure(FName InSwitchLabel, bool bInOneShot)
{
	SwitchLabel = InSwitchLabel;
	bOneShot = bInOneShot;
}

bool AShockSwitchActor::TryInteract(AShockPlayer* Player)
{
	if (!Player || !CanInteract())
	{
		return false;
	}
	bHasFired = true;
	Player->NotifyReactedWithActor(this);
	return true;
}

void AShockSwitchActor::SetSwitchStaticMesh(UStaticMesh* InMesh)
{
	if (Mesh && InMesh)
	{
		Mesh->SetStaticMesh(InMesh);
	}
}

void AShockSwitchActor::SetSwitchSkeletalMesh(USkeletalMesh* InMesh)
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
