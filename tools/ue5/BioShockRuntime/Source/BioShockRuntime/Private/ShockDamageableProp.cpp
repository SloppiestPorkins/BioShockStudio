#include "ShockDamageableProp.h"

#include "ShockPlayer.h"

#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"

AShockDamageableProp::AShockDamageableProp()
{
	PrimaryActorTick.bCanEverTick = false;

	Mesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);
	// BlockAll (not the switches' QueryOnly-plus-Visibility-only setup): this actor has to be a
	// real hit for weapon hitscan's LineTraceSingleByObjectType(Pawn/WorldStatic/WorldDynamic), not
	// just selectable by the player's own interact trace.
	Mesh->SetCollisionProfileName(TEXT("BlockAll"));
	Mesh->SetCastShadow(true);

	SkeletalMeshComp = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("SkeletalMesh"));
	SkeletalMeshComp->SetupAttachment(Mesh);
	SkeletalMeshComp->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	SkeletalMeshComp->SetVisibility(false);
}

void AShockDamageableProp::Configure(FName InReactLabel, bool bInOneShot)
{
	ReactLabel = InReactLabel;
	bOneShot = bInOneShot;
}

bool AShockDamageableProp::ReactToDamage(AShockPlayer* Player)
{
	if (!Player || !CanReact())
	{
		return false;
	}
	bHasReacted = true;
	Player->NotifyReactedWithActor(this);
	return true;
}

void AShockDamageableProp::SetPropStaticMesh(UStaticMesh* InMesh)
{
	if (Mesh && InMesh)
	{
		Mesh->SetStaticMesh(InMesh);
	}
}

void AShockDamageableProp::SetPropSkeletalMesh(USkeletalMesh* InMesh)
{
	if (SkeletalMeshComp && InMesh)
	{
		SkeletalMeshComp->SetSkeletalMesh(InMesh);
		SkeletalMeshComp->SetVisibility(true);
		SkeletalMeshComp->SetCollisionProfileName(TEXT("BlockAll"));
	}
}
