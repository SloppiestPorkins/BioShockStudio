#include "ShockWeapon.h"

#include "ShockDamageLibrary.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"
#include "Components/PointLightComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "DrawDebugHelpers.h"
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

bool AShockWeapon::IsMuzzleFlashLightVisibleForVerify() const
{
	return MuzzleFlashLight && MuzzleFlashLight->IsVisible();
}

void AShockWeapon::AdvanceMuzzleFlashForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f || MuzzleFlashRemaining <= 0.0f)
	{
		return;
	}
	MuzzleFlashRemaining -= DeltaSeconds;
	if (MuzzleFlashRemaining <= 0.0f)
	{
		if (UWorld* World = GetWorld())
		{
			World->GetTimerManager().ClearTimer(MuzzleFlashTimerHandle);
		}
		HideMuzzleFlash();
	}
}

FVector AShockWeapon::ResolveMuzzleLocation(const FVector& TraceStart) const
{
	if (Mesh)
	{
		static const FName SocketCandidates[] = {
			TEXT("Muzzle"),
			TEXT("MuzzleFlash"),
			TEXT("BarrelTip"),
			TEXT("FireSocket")};
		for (const FName Socket : SocketCandidates)
		{
			if (Mesh->DoesSocketExist(Socket))
			{
				return Mesh->GetSocketLocation(Socket);
			}
		}
	}
	return TraceStart;
}

void AShockWeapon::EnsureMuzzleFlashLight()
{
	if (MuzzleFlashLight)
	{
		return;
	}

	MuzzleFlashLight = NewObject<UPointLightComponent>(this, TEXT("MuzzleFlashLight"));
	if (!MuzzleFlashLight)
	{
		return;
	}

	USceneComponent* AttachParent = Mesh ? static_cast<USceneComponent*>(Mesh.Get()) : RootComponent.Get();
	MuzzleFlashLight->SetupAttachment(AttachParent);
	MuzzleFlashLight->SetMobility(EComponentMobility::Movable);
	MuzzleFlashLight->SetIntensity(12000.0f);
	MuzzleFlashLight->SetAttenuationRadius(140.0f);
	MuzzleFlashLight->SetCastShadows(false);
	MuzzleFlashLight->SetVisibility(false);
	MuzzleFlashLight->RegisterComponent();
}

void AShockWeapon::HideMuzzleFlash()
{
	MuzzleFlashRemaining = 0.0f;
	if (MuzzleFlashLight)
	{
		MuzzleFlashLight->SetVisibility(false);
	}
}

void AShockWeapon::FlashMuzzleLight(
	const FVector& WorldLocation,
	const FLinearColor& Color,
	float Intensity,
	float Duration)
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	EnsureMuzzleFlashLight();
	if (!MuzzleFlashLight)
	{
		return;
	}

	MuzzleFlashLight->SetWorldLocation(WorldLocation);
	MuzzleFlashLight->SetLightColor(Color);
	MuzzleFlashLight->SetIntensity(Intensity);
	MuzzleFlashLight->SetVisibility(true);
	++MuzzleFlashCount;
	MuzzleFlashRemaining = Duration;

	World->GetTimerManager().ClearTimer(MuzzleFlashTimerHandle);
	World->GetTimerManager().SetTimer(
		MuzzleFlashTimerHandle,
		this,
		&AShockWeapon::HideMuzzleFlash,
		Duration,
		false);
}

void AShockWeapon::PlayDryFireFeedback(const FVector& TraceStart)
{
	const FVector MuzzleLoc = ResolveMuzzleLocation(TraceStart);
	FlashMuzzleLight(MuzzleLoc, FLinearColor(0.55f, 0.08f, 0.05f), 1200.0f, 0.03f);
}

void AShockWeapon::PlayFireFeedback(
	AActor* InstigatorActor,
	const FVector& MuzzleLocation,
	const FVector& VisualEnd,
	bool bPawnHit,
	bool bWorldHit)
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	FlashMuzzleLight(
		MuzzleLocation,
		FLinearColor(1.0f, 0.82f, 0.45f),
		12000.0f,
		0.04f);

	if (bDrawTracers)
	{
		DrawDebugLine(
			World,
			MuzzleLocation,
			VisualEnd,
			FColor(255, 220, 150),
			false,
			0.05f,
			0,
			1.5f);
		++TracerDrawCount;
	}

	if (bPawnHit)
	{
		DrawDebugSphere(World, VisualEnd, 4.0f, 8, FColor(255, 40, 40), false, 0.15f);
	}
	else if (bWorldHit)
	{
		DrawDebugSphere(World, VisualEnd, 3.0f, 6, FColor(255, 220, 50), false, 0.15f);
	}

	if (AShockPlayer* Player = Cast<AShockPlayer>(InstigatorActor))
	{
		Player->ApplyWeaponRecoil();
	}
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
		PlayDryFireFeedback(Start);
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

	const FVector NormDir = Direction.GetSafeNormal();
	const FVector End = Start + NormDir * HitscanRange;
	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockWeaponFire), false, InstigatorActor);
	Params.AddIgnoredActor(this);

	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	const bool bPawnTraceHit =
		World->LineTraceSingleByObjectType(Hit, Start, End, ObjectParams, Params);

	bool bDamaged = false;
	if (bPawnTraceHit)
	{
		if (AShockPawn* Victim = Cast<AShockPawn>(Hit.GetActor()))
		{
			UShockDamageLibrary::ApplyDamage(Victim, HitscanDamage, InstigatorActor, NAME_None);
			LastHitPawn = Victim;
			bDamaged = true;
		}
	}

	const FVector MuzzleLoc = ResolveMuzzleLocation(Start);
	FVector VisualEnd = End;
	bool bVisualPawnHit = false;
	bool bVisualWorldHit = false;
	FHitResult VisualHit;
	FCollisionObjectQueryParams VisualObjectParams;
	VisualObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	VisualObjectParams.AddObjectTypesToQuery(ECC_WorldStatic);
	if (World->LineTraceSingleByObjectType(VisualHit, MuzzleLoc, End, VisualObjectParams, Params))
	{
		VisualEnd = VisualHit.ImpactPoint;
		if (Cast<AShockPawn>(VisualHit.GetActor()))
		{
			bVisualPawnHit = true;
		}
		else
		{
			bVisualWorldHit = true;
		}
	}

	PlayFireFeedback(InstigatorActor, MuzzleLoc, VisualEnd, bVisualPawnHit, bVisualWorldHit);

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		TryAutoReloadOnEmpty();
	}
	return bDamaged;
}
