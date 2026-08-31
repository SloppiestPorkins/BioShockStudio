#include "ShockSecurityDevice.h"

#include "BaseShockAI.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "EngineUtils.h"
#include "Engine/World.h"
#include "CollisionQueryParams.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
const TCHAR* AllegianceToString(EShockDeviceAllegiance Value)
{
	switch (Value)
	{
	case EShockDeviceAllegiance::Hostile:
		return TEXT("Hostile");
	case EShockDeviceAllegiance::Friendly:
		return TEXT("Friendly");
	case EShockDeviceAllegiance::Disabled:
		return TEXT("Disabled");
	default:
		return TEXT("Neutral");
	}
}

bool IsBlockingSightHit(const FHitResult& Hit, const AActor* Target)
{
	if (!Hit.bBlockingHit)
	{
		return false;
	}
	const AActor* HitActor = Hit.GetActor();
	return HitActor && HitActor != Target;
}
} // namespace

AShockSecurityDevice::AShockSecurityDevice()
{
	PrimaryActorTick.bCanEverTick = true;

	RootMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("RootMesh"));
	SetRootComponent(RootMesh);
	RootMesh->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	RootMesh->SetCollisionProfileName(TEXT("BlockAll"));

	static ConstructorHelpers::FObjectFinder<UStaticMesh> CubeMesh(
		TEXT("/Engine/BasicShapes/Cube.Cube"));
	if (CubeMesh.Succeeded())
	{
		RootMesh->SetStaticMesh(CubeMesh.Object);
		RootMesh->SetRelativeScale3D(FVector(0.6f, 0.6f, 0.8f));
	}
}

void AShockSecurityDevice::BeginPlay()
{
	Super::BeginPlay();
}

void AShockSecurityDevice::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	if (SecurityShutdownRemaining > 0.0f)
	{
		SecurityShutdownRemaining -= DeltaSeconds;
		if (SecurityShutdownRemaining <= 0.0f)
		{
			bInSecurityShutdown = false;
			EShockDeviceAllegiance Restore = AllegianceBeforeShutdown;
			if (Restore == EShockDeviceAllegiance::Friendly)
			{
				Restore = EShockDeviceAllegiance::Neutral;
			}
			SetAllegiance(Restore);
		}
	}

	if (Allegiance == EShockDeviceAllegiance::Disabled)
	{
		return;
	}

	TickDevice(DeltaSeconds);
}

void AShockSecurityDevice::TickDevice(float DeltaSeconds)
{
	(void)DeltaSeconds;
}

void AShockSecurityDevice::SetAllegiance(EShockDeviceAllegiance NewAllegiance)
{
	if (Allegiance == NewAllegiance)
	{
		return;
	}

	Allegiance = NewAllegiance;
	const FName Label = DeviceLabel.IsNone() ? GetFName() : DeviceLabel;
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_DEVICE label=%s allegiance=%s target=0"),
		*Label.ToString(),
		AllegianceToString(Allegiance));
}

bool AShockSecurityDevice::IsDeviceOperational() const
{
	return Health > 0.0f && Allegiance != EShockDeviceAllegiance::Disabled;
}

float AShockSecurityDevice::ApplyAuthoredDamage(float Damage)
{
	if (Damage <= 0.0f || Health <= 0.0f || Allegiance == EShockDeviceAllegiance::Disabled)
	{
		return Health;
	}

	Health = FMath::Max(0.0f, Health - Damage);
	if (Health <= 0.0f)
	{
		OnDeviceKilled();
	}
	return Health;
}

void AShockSecurityDevice::OnDeviceKilled()
{
	Health = 0.0f;
	SetAllegiance(EShockDeviceAllegiance::Disabled);

	UStaticMesh* DebrisMesh = RootMesh ? RootMesh->GetStaticMesh() : nullptr;
	if (!DebrisMesh || !GetWorld())
	{
		return;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AActor* Debris = GetWorld()->SpawnActor<AActor>(AActor::StaticClass(), GetActorLocation(), GetActorRotation(), Params);
	if (!Debris)
	{
		return;
	}

	UStaticMeshComponent* DebrisComp = NewObject<UStaticMeshComponent>(Debris, TEXT("DebrisMesh"));
	if (!DebrisComp)
	{
		Debris->Destroy();
		return;
	}
	Debris->SetRootComponent(DebrisComp);
	DebrisComp->SetStaticMesh(DebrisMesh);
	DebrisComp->SetWorldScale3D(FVector(0.25f));
	DebrisComp->SetMobility(EComponentMobility::Movable);
	DebrisComp->RegisterComponent();
}

void AShockSecurityDevice::ApplySecurityShutdown(float Duration)
{
	if (Duration <= 0.0f)
	{
		return;
	}

	if (!bInSecurityShutdown)
	{
		AllegianceBeforeShutdown = Allegiance;
		bInSecurityShutdown = true;
		SetAllegiance(EShockDeviceAllegiance::Disabled);
	}
	SecurityShutdownRemaining = FMath::Max(SecurityShutdownRemaining, Duration);
}

void AShockSecurityDevice::AdvanceDeviceForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f)
	{
		return;
	}
	Tick(DeltaSeconds);
}

void AShockSecurityDevice::ConfigureForVerify(FName Label, uint8 InAllegiance, float InHealth)
{
	DeviceLabel = Label;
	Health = InHealth;
	SetAllegiance(static_cast<EShockDeviceAllegiance>(InAllegiance));
	bInSecurityShutdown = false;
	SecurityShutdownRemaining = 0.0f;
}

float AShockSecurityDevice::GetEffectiveDetectionRange() const
{
	float Range = DetectionRange;
	if (UWorld* World = GetWorld())
	{
		if (const AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World))
		{
			if (Player->IsSecurityAlarmOn())
			{
				Range *= AlarmRangeMultiplier;
			}
		}
	}
	return Range;
}

bool AShockSecurityDevice::IsOpposingSide(const AActor* Target) const
{
	if (!Target || Allegiance == EShockDeviceAllegiance::Neutral || Allegiance == EShockDeviceAllegiance::Disabled)
	{
		return false;
	}

	if (Cast<const AShockPlayer>(Target))
	{
		return Allegiance == EShockDeviceAllegiance::Hostile;
	}

	if (Cast<const ABaseShockAI>(Target))
	{
		return Allegiance == EShockDeviceAllegiance::Friendly;
	}

	return false;
}

bool AShockSecurityDevice::CanDetectActor(const AActor* Target) const
{
	if (!Target || !IsOpposingSide(Target))
	{
		return false;
	}

	const AShockPawn* Pawn = Cast<AShockPawn>(Target);
	if (!Pawn || Pawn->IsDead())
	{
		return false;
	}

	const float Dist = FVector::Dist(GetActorLocation(), Target->GetActorLocation());
	if (Dist > GetEffectiveDetectionRange())
	{
		return false;
	}

	const FVector Forward = GetActorForwardVector().GetSafeNormal2D();
	const FVector ToTarget = (Target->GetActorLocation() - GetActorLocation()).GetSafeNormal2D();
	const float MinDot = FMath::Cos(FMath::DegreesToRadians(DetectionHalfAngleDeg));
	if (FVector::DotProduct(Forward, ToTarget) < MinDot)
	{
		return false;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return false;
	}

	FVector EyeLoc = GetActorLocation();
	if (RootMesh)
	{
		EyeLoc.Z += RootMesh->Bounds.BoxExtent.Z;
	}
	const FVector TargetLoc = Target->GetActorLocation();

	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockDeviceSight), false, this);
	Params.AddIgnoredActor(Target);
	FHitResult Hit;
	if (World->LineTraceSingleByChannel(Hit, EyeLoc, TargetLoc, ECC_Visibility, Params))
	{
		if (IsBlockingSightHit(Hit, Target))
		{
			return false;
		}
	}

	return true;
}

AShockSecurityDevice* AShockSecurityDevice::FindByLabel(UWorld* World, FName Label)
{
	if (!World || Label.IsNone())
	{
		return nullptr;
	}

	const FString Want = Label.ToString();
	for (TActorIterator<AShockSecurityDevice> It(World); It; ++It)
	{
		AShockSecurityDevice* Device = *It;
		if (!Device)
		{
			continue;
		}
		if (Device->DeviceLabel.ToString().Equals(Want, ESearchCase::CaseSensitive))
		{
			return Device;
		}
#if WITH_EDITOR
		if (Device->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			return Device;
		}
#endif
	}
	return nullptr;
}

void AShockSecurityDevice::ForEachDevice(UWorld* World, TFunctionRef<void(AShockSecurityDevice*)> Fn)
{
	if (!World)
	{
		return;
	}
	for (TActorIterator<AShockSecurityDevice> It(World); It; ++It)
	{
		if (*It)
		{
			Fn(*It);
		}
	}
}
