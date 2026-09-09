#include "ShockTargetDummyPlasmid.h"

#include "BaseShockAI.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "ShockPlayer.h"

AShockPlasmidDecoy::AShockPlasmidDecoy()
{
	PrimaryActorTick.bCanEverTick = true;
	InitialLifeSpan = 12.0f;

	Body = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Body"));
	SetRootComponent(Body);
	Body->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Body->SetCastShadow(false);
	if (UStaticMesh* Capsule = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cylinder.Cylinder")))
	{
		Body->SetStaticMesh(Capsule);
		Body->SetWorldScale3D(FVector(0.4f, 0.4f, 1.8f));
	}
}

void AShockPlasmidDecoy::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	PulseAccumulator += DeltaSeconds;
	if (PulseAccumulator < 0.75f)
	{
		return;
	}
	PulseAccumulator = 0.0f;
	// Reuse w13's hearing bus: every splicer in range breaks to investigate the decoy.
	ABaseShockAI::BroadcastSuspiciousNoise(
		GetWorld(), GetActorLocation(), 1.0f, FName(TEXT("Decoy")), this, LureRadius);
}

UShockTargetDummyPlasmid::UShockTargetDummyPlasmid()
{
	PlasmidName = TEXT("TargetDummy");
	EveCost = 8.0f;
	CastCooldown = 0.75f;
	TargetingMode = EShockPlasmidTargetingMode::Trace;
	HandCastAnimation = TEXT("Generic_Fire");
	HandTint = FLinearColor(0.6f, 0.9f, 0.7f, 1.0f);
	CastFxAssetPath = TEXT("/Game/BioShockFX/Plasmids/NS_TargetDummy.NS_TargetDummy");
}

bool UShockTargetDummyPlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	if (!Caster)
	{
		return false;
	}
	UWorld* World = Caster->GetWorld();
	if (!World)
	{
		return false;
	}

	FVector At = Aim.bBlockingHit
		? FVector(Aim.ImpactPoint)
		: Caster->GetActorLocation() + Caster->GetControlRotation().Vector() * 500.0f;
	At.Z += 90.0f;

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AShockPlasmidDecoy* Decoy = World->SpawnActor<AShockPlasmidDecoy>(
		AShockPlasmidDecoy::StaticClass(), At, FRotator::ZeroRotator, Params);
	if (!Decoy)
	{
		return false;
	}
	Decoy->SetLifeSpan(DecoyLifeSeconds);
	LastDecoy = Decoy;

	SpawnCastBurst(Caster, At, FRotator::ZeroRotator, 0.5f, 20.0f);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_PLASMID cast=TargetDummy life=%.1f"), DecoyLifeSeconds);
	return true;
}
