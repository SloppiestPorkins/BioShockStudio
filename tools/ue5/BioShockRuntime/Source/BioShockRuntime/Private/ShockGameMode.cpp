#include "ShockGameMode.h"
#include "BaseShockAI.h"
#include "ShockPlayer.h"
#include "ShockWeapon.h"

#include "Camera/CameraComponent.h"
#include "CollisionQueryParams.h"
#include "Components/CapsuleComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/SkyLight.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/World.h"
#include "GameFramework/WorldSettings.h"
#include "Components/LightComponent.h"
#include "Components/SkyLightComponent.h"
#include "EngineUtils.h"
#include "GameFramework/Character.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/PlayerStart.h"
#include "HAL/PlatformMisc.h"
#include "Misc/CommandLine.h"

namespace
{
FRotator PlayableStartRotation(const AActor* Start)
{
	FRotator Look = Start ? Start->GetActorRotation() : FRotator::ZeroRotator;
	// Python unreal.Rotator(0, 90, 0) is roll/pitch/yaw, so possess prep stored pitch=90.
	if (FMath::IsNearlyZero(Look.Yaw, 1.0f)
		&& FMath::IsNearlyEqual(FMath::Abs(Look.Pitch), 90.0f, 1.0f))
	{
		Look.Yaw = 90.0f;
	}
	Look.Pitch = 0.0f;
	Look.Roll = 0.0f;
	return Look;
}

void EnableDynamicLighting(UWorld* World)
{
	if (!World)
	{
		return;
	}
	if (AWorldSettings* Settings = World->GetWorldSettings())
	{
		Settings->bForceNoPrecomputedLighting = true;
	}
	int32 Converted = 0;
	for (TActorIterator<AStaticMeshActor> It(World); It; ++It)
	{
		if (UStaticMeshComponent* Mesh = It->GetStaticMeshComponent())
		{
			if (Mesh->Mobility == EComponentMobility::Static)
			{
				Mesh->SetMobility(EComponentMobility::Movable);
				++Converted;
			}
		}
	}

	const FName FillTag(TEXT("BioShockSliceFill"));
	bool bHasFill = false;
	for (TActorIterator<ADirectionalLight> It(World); It; ++It)
	{
		if (It->Tags.Contains(FillTag))
		{
			bHasFill = true;
			break;
		}
	}
	if (!bHasFill)
	{
		FActorSpawnParameters Params;
		Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
		if (ADirectionalLight* Sun = World->SpawnActor<ADirectionalLight>(
				ADirectionalLight::StaticClass(),
				FVector::ZeroVector,
				FRotator(-46.0f, -35.0f, 0.0f),
				Params))
		{
			Sun->Tags.Add(FillTag);
			Sun->SetMobility(EComponentMobility::Movable);
			if (ULightComponent* Light = Sun->GetLightComponent())
			{
				Light->SetIntensity(12.0f);
			}
		}
		if (ASkyLight* Sky = World->SpawnActor<ASkyLight>(
				ASkyLight::StaticClass(), FVector::ZeroVector, FRotator::ZeroRotator, Params))
		{
			Sky->Tags.Add(FillTag);
			if (USkyLightComponent* SkyComp = Sky->GetLightComponent())
			{
				SkyComp->SetMobility(EComponentMobility::Movable);
				SkyComp->SetIntensity(1.0f);
				SkyComp->SetRealTimeCaptureEnabled(true);
				SkyComp->RecaptureSky();
			}
		}
	}

	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SLICE_LIGHTING movable=%d fill=%d"), Converted, bHasFill ? 0 : 1);
}
}

AShockGameMode::AShockGameMode()
{
	DefaultPawnClass = AShockPlayer::StaticClass();
}

AActor* AShockGameMode::ChoosePlayerStart_Implementation(AController* Player)
{
	if (UWorld* World = GetWorld())
	{
		for (TActorIterator<APlayerStart> It(World); It; ++It)
		{
			for (const FName& Tag : It->Tags)
			{
				if (Tag.ToString().StartsWith(TEXT("BioShockPossess=")))
				{
					UE_LOG(
						LogTemp,
						Display,
						TEXT("BIOSHOCK_CHOOSE_START tagged label=%s loc=%s"),
						*It->GetActorLabel(),
						*It->GetActorLocation().ToString());
					return *It;
				}
			}
		}
		for (TActorIterator<APlayerStart> It(World); It; ++It)
		{
			const FString Label = It->GetActorLabel();
			if (Label.Equals(TEXT("MedicalStart")) || Label.Equals(TEXT("BioShock_MedicalStart")))
			{
				UE_LOG(
					LogTemp,
					Display,
					TEXT("BIOSHOCK_CHOOSE_START label=%s loc=%s"),
					*Label,
					*It->GetActorLocation().ToString());
				return *It;
			}
		}
		UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_CHOOSE_START fallback to engine default"));
	}
	return Super::ChoosePlayerStart_Implementation(Player);
}

void AShockGameMode::SnapPawnToStart(APawn* Pawn, AActor* Start)
{
	if (!Pawn || !Start)
	{
		return;
	}

	UWorld* World = Pawn->GetWorld();
	FVector Loc = Start->GetActorLocation();
	const FRotator Rot = PlayableStartRotation(Start);

	// PlayerStart is the authored capsule center. A downward trace that begins above the
	// room hits the roof first (MedicalStart +400 uu landed at Z=8248 — the hull top).
	if (ACharacter* Character = Cast<ACharacter>(Pawn))
	{
		const UCapsuleComponent* Capsule = Character->GetCapsuleComponent();
		const float HalfHeight = Capsule ? Capsule->GetScaledCapsuleHalfHeight() : 88.0f;
		if (World)
		{
			const FVector TraceStart = Loc + FVector(0.0f, 0.0f, 8.0f);
			const FVector TraceEnd = Loc - FVector(0.0f, 0.0f, HalfHeight + 40.0f);
			FHitResult Hit;
			FCollisionQueryParams Params(SCENE_QUERY_STAT(BioShockSnapSpawn), false, Pawn);
			if (World->LineTraceSingleByChannel(Hit, TraceStart, TraceEnd, ECC_WorldStatic, Params)
				&& Hit.ImpactNormal.Z > 0.5f)
			{
				Loc.Z = Hit.Location.Z + HalfHeight + 2.0f;
			}
		}
	}

	Pawn->SetActorLocationAndRotation(Loc, Rot, false, nullptr, ETeleportType::TeleportPhysics);
}

void AShockGameMode::EquipStarterWeapon(AShockPlayer* Player)
{
	if (!Player || Player->GetEquippedWeapon())
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	FActorSpawnParameters Params;
	Params.Owner = Player;
	Params.Instigator = Player;
	AShockWeapon* Weapon = World->SpawnActor<AShockWeapon>(
		AShockWeapon::StaticClass(),
		Player->GetActorLocation(),
		Player->GetActorRotation(),
		Params);
	if (!Weapon)
	{
		return;
	}

	Weapon->ConfigureHitscan(25.0f, 10000.0f);

	if (USkeletalMesh* TommyGun = LoadObject<USkeletalMesh>(
			nullptr,
			TEXT("/Game/BioShockWeapons/WP_TommyGun/WP_TommyGun.WP_TommyGun")))
	{
		Weapon->Mesh->SetSkeletalMesh(TommyGun);
	}

	Player->EquipWeapon(Weapon);
}

ABaseShockAI* AShockGameMode::SpawnSliceEnemy(AShockPlayer* Player, AActor* StartSpot)
{
	UWorld* World = GetWorld();
	if (!World || !Player)
	{
		return nullptr;
	}

	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		if (*It && (*It)->GetScriptLabel() == FName(TEXT("SliceBabyJane")))
		{
			return *It;
		}
	}

	FVector Forward = PlayableStartRotation(StartSpot).Vector();
	Forward.Z = 0.0f;
	if (Forward.IsNearlyZero())
	{
		Forward = FVector::YAxisVector;
	}
	Forward.Normalize();

	FVector SpawnLoc = Player->GetActorLocation() + Forward * 250.0f;
	SpawnLoc.Z = Player->GetActorLocation().Z;

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	ABaseShockAI* AI = World->SpawnActor<ABaseShockAI>(
		ABaseShockAI::StaticClass(),
		SpawnLoc,
		(-Forward).Rotation(),
		Params);
	if (!AI)
	{
		return nullptr;
	}

	AI->ConfigureIdentity(FName(TEXT("Agg_BabyJane")), FName(TEXT("SliceBabyJane")));
	AI->ApplyArchetypeLookup(FName(TEXT("Agg_BabyJane")));
	AI->EnsureHealthInitialized();
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_SLICE_SPAWN loc=%s player=%s"),
		*AI->GetActorLocation().ToString(),
		*Player->GetActorLocation().ToString());
	if (UCapsuleComponent* Capsule = AI->GetCapsuleComponent())
	{
		Capsule->SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		Capsule->SetCollisionObjectType(ECC_Pawn);
		Capsule->SetCollisionResponseToAllChannels(ECR_Ignore);
		Capsule->SetCollisionResponseToChannel(ECC_Pawn, ECR_Block);
		Capsule->SetCollisionResponseToChannel(ECC_Visibility, ECR_Block);
		Capsule->SetCollisionResponseToChannel(ECC_Camera, ECR_Block);
	}
#if WITH_EDITOR
	AI->SetActorLabel(TEXT("SliceBabyJane"));
#endif

	// Fallback: if the archetype lookup did not resolve a mesh (asset not imported, or the
	// import could not map the manifest name to a UE asset), keep the known-good slice mesh so
	// the enemy is never invisible.
	if (USkeletalMeshComponent* Body = AI->GetMesh())
	{
		if (!Body->GetSkeletalMeshAsset())
		{
			if (USkeletalMesh* MeshAsset = LoadObject<USkeletalMesh>(
					nullptr,
					TEXT("/Game/BioShockCharacters/AggressorBabyJane/AggressorBabyJane.AggressorBabyJane")))
			{
				Body->SetSkeletalMesh(MeshAsset);
				Body->SetHiddenInGame(false);
				Body->SetCollisionEnabled(ECollisionEnabled::NoCollision);
			}
		}
	}

	return AI;
}

void AShockGameMode::VerifySliceFire(AShockPlayer* Player, ABaseShockAI* Enemy)
{
	if (!Player || !Enemy)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_SLICE_FAIL reason=missing_actor"));
		return;
	}

	const bool bMesh = Enemy->GetMesh() && Enemy->GetMesh()->GetSkeletalMeshAsset() != nullptr;
	const float HealthBefore = Enemy->GetCurrentHealth();

	if (APlayerController* PC = Cast<APlayerController>(Player->GetController()))
	{
		const FVector ToEnemy = Enemy->GetActorLocation() - Player->GetActorLocation();
		PC->SetControlRotation(ToEnemy.Rotation());
	}

	const bool bFired = Player->TryFireEquippedWeapon();
	const float HealthAfter = Enemy->GetCurrentHealth();
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_SLICE_OK enemy=SliceBabyJane mesh=%d health_before=%.1f health_after=%.1f fire=%d"),
		bMesh ? 1 : 0,
		HealthBefore,
		HealthAfter,
		bFired ? 1 : 0);
}

void AShockGameMode::PostLogin(APlayerController* NewPlayer)
{
	Super::PostLogin(NewPlayer);

	EnableDynamicLighting(GetWorld());

	APawn* Pawn = NewPlayer ? NewPlayer->GetPawn() : nullptr;
	if (Pawn && NewPlayer)
	{
		if (AActor* Start = ChoosePlayerStart_Implementation(NewPlayer))
		{
			SnapPawnToStart(Pawn, Start);
			NewPlayer->SetControlRotation(PlayableStartRotation(Start));
			if (AShockPlayer* Player = Cast<AShockPlayer>(Pawn))
			{
				EquipStarterWeapon(Player);
				NewPlayer->SetViewTarget(Player);
				ABaseShockAI* Enemy = SpawnSliceEnemy(Player, Start);
				if (FParse::Param(FCommandLine::Get(), TEXT("bioshockverifypossess")))
				{
					VerifySliceFire(Player, Enemy);
				}
			}
		}
		else if (AShockPlayer* Player = Cast<AShockPlayer>(Pawn))
		{
			EquipStarterWeapon(Player);
			NewPlayer->SetViewTarget(Player);
		}
	}

	const bool bVerifyPossess = FParse::Param(FCommandLine::Get(), TEXT("bioshockverifypossess"));
	if (!bVerifyPossess)
	{
		return;
	}

	if (!Pawn)
	{
		UE_LOG(LogTemp, Error, TEXT("BIOSHOCK_POSSESS_FAIL reason=no_pawn"));
	}
	else
	{
		const FVector Loc = Pawn->GetActorLocation();
		const AShockPlayer* Player = Cast<AShockPlayer>(Pawn);
		const bool bPlayable = Player && Player->IsPlayableInputEnabled();
		const bool bWeapon = Player && Player->GetEquippedWeapon() != nullptr;
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_POSSESS_OK class=%s x=%.2f y=%.2f z=%.2f playable=%d weapon=%d"),
			*Pawn->GetClass()->GetName(),
			Loc.X,
			Loc.Y,
			Loc.Z,
			bPlayable ? 1 : 0,
			bWeapon ? 1 : 0);
	}

	FGenericPlatformMisc::RequestExit(false);
}
