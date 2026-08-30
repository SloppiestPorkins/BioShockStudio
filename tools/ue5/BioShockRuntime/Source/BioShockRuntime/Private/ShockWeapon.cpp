#include "ShockWeapon.h"

#include "ShockDamageLibrary.h"
#include "ShockPawn.h"
#include "Components/SkeletalMeshComponent.h"
#include "Engine/World.h"
#include "CollisionQueryParams.h"
#include "TimerManager.h"

AShockWeapon::AShockWeapon()
{
	PrimaryActorTick.bCanEverTick = false;
	Mesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);
	Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Mesh->SetCollisionResponseToAllChannels(ECR_Ignore);
	Mesh->SetCastShadow(false);
}

void AShockWeapon::ConfigureHitscan(float InDamage, float InRange)
{
	HitscanDamage = InDamage;
	HitscanRange = InRange;
}

void AShockWeapon::ConfigureAmmo(int32 InMagazineSize, int32 InReserveAmmo, float InFireRate, float InReloadSeconds)
{
	MagazineSize = FMath::Max(1, InMagazineSize);
	ReserveAmmo = FMath::Max(0, InReserveAmmo);
	FireRate = FMath::Max(0.1f, InFireRate);
	ReloadSeconds = FMath::Max(0.01f, InReloadSeconds);
	bEnforceAmmo = true;
}

void AShockWeapon::InitializeAmmoFullMag(int32 InReserveAmmo)
{
	RoundsInMagazine = MagazineSize;
	ReserveAmmo = FMath::Max(0, InReserveAmmo);
	LogAmmoState();
}

int32 AShockWeapon::AddReserveAmmo(int32 Amount)
{
	if (Amount <= 0)
	{
		return ReserveAmmo;
	}
	ReserveAmmo += Amount;
	LogAmmoState();
	return ReserveAmmo;
}

float AShockWeapon::GetMinFireInterval() const
{
	return FireRate > KINDA_SMALL_NUMBER ? 1.0f / FireRate : 0.0f;
}

bool AShockWeapon::CanFireNow(UWorld* World) const
{
	if (!World || (bEnforceAmmo && bIsReloading))
	{
		return false;
	}
	if (!bEnforceAmmo)
	{
		return true;
	}
	const float Interval = GetMinFireInterval();
	if (Interval <= 0.0f || LastFireWorldSeconds < 0.0)
	{
		return true;
	}
	return (World->GetTimeSeconds() - LastFireWorldSeconds) >= static_cast<double>(Interval) - KINDA_SMALL_NUMBER;
}

void AShockWeapon::LogAmmoState() const
{
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_AMMO mag=%d reserve=%d"),
		RoundsInMagazine,
		ReserveAmmo);
}

void AShockWeapon::TryAutoReloadOnEmpty()
{
	if (bAutoReload && RoundsInMagazine <= 0 && ReserveAmmo > 0 && !bIsReloading)
	{
		Reload();
	}
}

bool AShockWeapon::Reload()
{
	if (bIsReloading || RoundsInMagazine >= MagazineSize || ReserveAmmo <= 0)
	{
		return false;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return false;
	}

	bIsReloading = true;
	ReloadCountdown = ReloadSeconds;
	World->GetTimerManager().SetTimer(
		ReloadTimerHandle,
		this,
		&AShockWeapon::FinishReload,
		ReloadSeconds,
		false);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_WEAPON_RELOAD start seconds=%.2f"), ReloadSeconds);
	return true;
}

void AShockWeapon::FinishReload()
{
	bIsReloading = false;
	ReloadCountdown = 0.0f;
	const int32 Need = MagazineSize - RoundsInMagazine;
	const int32 Transfer = FMath::Min(Need, ReserveAmmo);
	RoundsInMagazine += Transfer;
	ReserveAmmo -= Transfer;
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_WEAPON_RELOAD done transferred=%d"), Transfer);
	LogAmmoState();
}

void AShockWeapon::AdvanceReloadForVerify(float DeltaSeconds)
{
	if (!bIsReloading || DeltaSeconds <= 0.0f)
	{
		return;
	}
	ReloadCountdown -= DeltaSeconds;
	if (ReloadCountdown > 0.0f)
	{
		return;
	}
	if (UWorld* World = GetWorld())
	{
		World->GetTimerManager().ClearTimer(ReloadTimerHandle);
	}
	FinishReload();
}

void AShockWeapon::ClearFireCooldownForVerify()
{
	LastFireWorldSeconds = -1.0;
}

void AShockWeapon::AdvanceFireRateClockForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f || LastFireWorldSeconds < 0.0)
	{
		return;
	}
	LastFireWorldSeconds -= static_cast<double>(DeltaSeconds);
}

bool AShockWeapon::FireAt(AActor* InstigatorActor, FVector Start, FVector Direction)
{
	UWorld* World = GetWorld();
	if (!World || Direction.IsNearlyZero())
	{
		return false;
	}

	if (bEnforceAmmo && bIsReloading)
	{
		return false;
	}

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_WEAPON_DRY"));
		TryAutoReloadOnEmpty();
		return false;
	}

	if (!CanFireNow(World))
	{
		return false;
	}

	LastFireWorldSeconds = World->GetTimeSeconds();
	if (bEnforceAmmo)
	{
		--RoundsInMagazine;
		LogAmmoState();
	}
	++FireCount;
	LastHitPawn = nullptr;

	const FVector End = Start + Direction.GetSafeNormal() * HitscanRange;
	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockWeaponFire), false, InstigatorActor);
	Params.AddIgnoredActor(this);

	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	if (!World->LineTraceSingleByObjectType(Hit, Start, End, ObjectParams, Params))
	{
		if (bEnforceAmmo && RoundsInMagazine <= 0)
		{
			TryAutoReloadOnEmpty();
		}
		return false;
	}

	AShockPawn* Victim = Cast<AShockPawn>(Hit.GetActor());
	if (!Victim)
	{
		if (bEnforceAmmo && RoundsInMagazine <= 0)
		{
			TryAutoReloadOnEmpty();
		}
		return false;
	}

	UShockDamageLibrary::ApplyDamage(Victim, HitscanDamage, InstigatorActor, NAME_None);
	LastHitPawn = Victim;

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		TryAutoReloadOnEmpty();
	}
	return true;
}
