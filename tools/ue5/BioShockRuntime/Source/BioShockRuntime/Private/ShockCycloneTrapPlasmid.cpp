#include "ShockCycloneTrapPlasmid.h"

#include "Components/SphereComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "GameFramework/Character.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"

AShockCycloneTrap::AShockCycloneTrap()
{
	PrimaryActorTick.bCanEverTick = false;
	InitialLifeSpan = 60.0f;

	Trigger = CreateDefaultSubobject<USphereComponent>(TEXT("Trigger"));
	SetRootComponent(Trigger);
	Trigger->InitSphereRadius(90.0f);
	Trigger->SetCollisionProfileName(TEXT("OverlapAllDynamic"));
	Trigger->SetGenerateOverlapEvents(true);

	Marker = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Marker"));
	Marker->SetupAttachment(Trigger);
	Marker->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Marker->SetCastShadow(false);
	if (UStaticMesh* Disc = LoadObject<UStaticMesh>(nullptr, TEXT("/Engine/BasicShapes/Cylinder.Cylinder")))
	{
		Marker->SetStaticMesh(Disc);
		Marker->SetWorldScale3D(FVector(1.6f, 1.6f, 0.08f));
	}
}

void AShockCycloneTrap::BeginPlay()
{
	Super::BeginPlay();
	Trigger->OnComponentBeginOverlap.AddDynamic(this, &AShockCycloneTrap::OnTrapOverlap);
}

void AShockCycloneTrap::OnTrapOverlap(
	UPrimitiveComponent* /*OverlappedComponent*/,
	AActor* OtherActor,
	UPrimitiveComponent* /*OtherComp*/,
	int32 /*OtherBodyIndex*/,
	bool /*bFromSweep*/,
	const FHitResult& /*SweepResult*/)
{
	if (bTriggered)
	{
		return;
	}
	if (ACharacter* Character = ::Cast<ACharacter>(OtherActor))
	{
		bTriggered = true;
		Character->LaunchCharacter(FVector(0.0f, 0.0f, LaunchSpeed), true, true);
		SetLifeSpan(0.75f);
	}
}

UShockCycloneTrapPlasmid::UShockCycloneTrapPlasmid()
{
	PlasmidName = TEXT("CycloneTrap");
	EveCost = 16.0f;
	CastCooldown = 0.75f;
	TargetingMode = EShockPlasmidTargetingMode::Trace;
	HandCastAnimation = TEXT("Generic_Fire");
	HandTint = FLinearColor(0.5f, 0.8f, 1.0f, 1.0f);
	CastFxAssetPath = TEXT("/Game/BioShockFX/Plasmids/NS_CycloneTrap.NS_CycloneTrap");
}

bool UShockCycloneTrapPlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	if (!Caster || !Aim.bBlockingHit)
	{
		return false;
	}
	UWorld* World = Caster->GetWorld();
	if (!World)
	{
		return false;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	AShockCycloneTrap* Trap = World->SpawnActor<AShockCycloneTrap>(
		AShockCycloneTrap::StaticClass(),
		Aim.ImpactPoint + Aim.ImpactNormal * 6.0f,
		FRotator::ZeroRotator,
		Params);
	if (!Trap)
	{
		return false;
	}
	LastTrap = Trap;

	SpawnCastBurst(Caster, Trap->GetActorLocation(), FRotator::ZeroRotator, 0.5f, 18.0f);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_PLASMID cast=CycloneTrap placed=1"));
	return true;
}
