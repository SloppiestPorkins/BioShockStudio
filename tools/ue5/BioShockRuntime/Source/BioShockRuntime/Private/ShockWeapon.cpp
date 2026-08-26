#include "ShockWeapon.h"
#include "Components/SkeletalMeshComponent.h"

AShockWeapon::AShockWeapon()
{
	PrimaryActorTick.bCanEverTick = false;
	Mesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);
}
