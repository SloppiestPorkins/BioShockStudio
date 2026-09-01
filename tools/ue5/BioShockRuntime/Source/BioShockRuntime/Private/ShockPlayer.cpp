#include "ShockPlayer.h"

#include "ShockPlasmid.h"
#include "ShockSecurityDevice.h"
#include "ShockTurret.h"
#include "ShockWeapon.h"
#include "ShockWeaponDef.h"
#include "Animation/AnimSequence.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "CollisionQueryParams.h"
#include "DrawDebugHelpers.h"
#include "Engine/Scene.h"
#include "Engine/SkeletalMesh.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/PlayerController.h"
#include "TimerManager.h"

namespace
{
constexpr float WeaponRecoilRecoverSeconds = 0.12f;
constexpr float PlasmidTraceRange = 10000.0f;
constexpr float HackTraceRange = 800.0f;
constexpr float HackFailSelfDamage = 5.0f; // PLAUSIBLE — pipe minigame shock stand-in
}

AShockPlayer::AShockPlayer()
{
	SchemaClassName = TEXT("ShockPlayer");
	bUseControllerRotationYaw = true;
	bUseControllerRotationPitch = false;
	bUseControllerRotationRoll = false;
	AutoPossessPlayer = EAutoReceiveInput::Disabled;

	if (UCapsuleComponent* Capsule = GetCapsuleComponent())
	{
		Capsule->SetCapsuleRadius(34.0f);
		Capsule->SetCapsuleHalfHeight(68.0f);
	}
	if (UCharacterMovementComponent* Movement = GetCharacterMovement())
	{
		Movement->MaxWalkSpeed = 450.0f;
		Movement->JumpZVelocity = 525.0f;
	}
	if (USkeletalMeshComponent* BodyMesh = GetMesh())
	{
		BodyMesh->SetHiddenInGame(true);
		BodyMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	FirstPersonCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FirstPersonCamera"));
	FirstPersonCamera->SetupAttachment(GetCapsuleComponent());
	FirstPersonCamera->SetRelativeLocation(FVector(0.0f, 0.0f, BaseEyeHeight));
	FirstPersonCamera->bUsePawnControlRotation = true;
	FirstPersonCamera->PostProcessBlendWeight = 1.0f;
	FirstPersonCamera->PostProcessSettings.bOverride_AutoExposureMethod = true;
	FirstPersonCamera->PostProcessSettings.AutoExposureMethod = AEM_Manual;
	FirstPersonCamera->PostProcessSettings.bOverride_AutoExposureBias = true;
	FirstPersonCamera->PostProcessSettings.AutoExposureBias = 0.0f;

	ViewHands = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("ViewHands"));
	ViewHands->SetupAttachment(FirstPersonCamera);
	ViewHands->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	ViewHands->SetCastShadow(false);
	ViewHands->SetHiddenInGame(true);

	EquippedPlasmids.SetNum(3);
	WeaponSlots.SetNum(8);
}

void AShockPlayer::OnDeathFromDamage()
{
	OnDied();
}

void AShockPlayer::OnDied()
{
	if (bDeathHandled)
	{
		return;
	}
	bDeathHandled = true;
	++DeathNotifyCount;

	EnablePlayableInput(false);
	SetMovementDisabled(true);

	if (APlayerController* PC = Cast<APlayerController>(GetController()))
	{
		PC->DisableInput(PC);
	}

	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->StopMovementImmediately();
		Move->DisableMovement();
	}

	if (ViewHands)
	{
		ViewHands->SetHiddenInGame(true);
	}
	if (EquippedWeapon)
	{
		EquippedWeapon->SetActorHiddenInGame(true);
	}

	OnPlayerDied.Broadcast(this);
}

void AShockPlayer::ResetForRespawn(float Health)
{
	const float Seed = Health > 0.0f ? Health : (AuthoredMaxHealth > 0.0f ? AuthoredMaxHealth : 100.0f);
	CurrentHealth = Seed;
	bIsDead = false;
	bInvincible = false;
	bDeathHandled = false;
	SetMovementDisabled(false);
	EnablePlayableInput(true);

	if (APlayerController* PC = Cast<APlayerController>(GetController()))
	{
		PC->EnableInput(PC);
	}

	if (ViewHands && ViewHands->GetSkeletalMeshAsset())
	{
		ViewHands->SetHiddenInGame(false);
	}
	if (EquippedWeapon)
	{
		EquippedWeapon->SetActorHiddenInGame(false);
	}
}

void AShockPlayer::PossessedBy(AController* NewController)
{
	Super::PossessedBy(NewController);

	if (USkeletalMeshComponent* BodyMesh = GetMesh())
	{
		BodyMesh->SetHiddenInGame(true);
	}

	if (APlayerController* PC = Cast<APlayerController>(NewController))
	{
		PC->SetViewTarget(this);
	}
}

void AShockPlayer::EnsureViewHands()
{
	if (!ViewHands || ViewHands->GetSkeletalMeshAsset())
	{
		return;
	}

	USkeletalMesh* Hands = LoadObject<USkeletalMesh>(
		nullptr,
		TEXT("/Game/BioShockWeapons/NEWPlayerHands/NEWPlayerHands.NEWPlayerHands"));
	if (!Hands)
	{
		UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_VIEWMODEL hands=0"));
		return;
	}

	ViewHands->SetSkeletalMesh(Hands);
	ViewHands->SetHiddenInGame(false);
	ViewHands->SetOnlyOwnerSee(false);
	ViewHands->SetOwnerNoSee(false);

	if (UAnimSequence* Idle = LoadObject<UAnimSequence>(
			nullptr,
			TEXT("/Game/BioShockWeapons/NEWPlayerHands/Animations/FidgetTommygun.FidgetTommygun")))
	{
		ViewHands->PlayAnimation(Idle, true);
	}
}

void AShockPlayer::FrameViewmodel(FName GripSocket)
{
	if (!FirstPersonCamera || !ViewHands)
	{
		return;
	}

	const FVector DesiredLocal(28.0f, 10.0f, -14.0f);
	const FVector SocketWorld = GripSocket.IsNone()
		? (EquippedWeapon ? EquippedWeapon->GetActorLocation() : ViewHands->GetComponentLocation())
		: ViewHands->GetSocketLocation(GripSocket);
	const FVector DesiredWorld =
		FirstPersonCamera->GetComponentTransform().TransformPosition(DesiredLocal);
	ViewHands->AddWorldOffset(DesiredWorld - SocketWorld);
}

void AShockPlayer::EquipWeapon(AShockWeapon* Weapon)
{
	EquippedWeapon = Weapon;
	if (!Weapon)
	{
		return;
	}

	Weapon->SetOwner(this);
	EnsureViewHands();

	FName GripSocket = NAME_None;
	if (ViewHands && ViewHands->GetSkeletalMeshAsset())
	{
		static const FName Candidates[] = {
			TEXT("TommyGun"), TEXT("R_Grip"), TEXT("R_grip")};
		for (const FName Candidate : Candidates)
		{
			if (ViewHands->DoesSocketExist(Candidate))
			{
				GripSocket = Candidate;
				break;
			}
		}
		Weapon->AttachToComponent(
			ViewHands,
			FAttachmentTransformRules::SnapToTargetNotIncludingScale,
			GripSocket);
		FrameViewmodel(GripSocket);
	}
	else if (FirstPersonCamera)
	{
		Weapon->AttachToComponent(
			FirstPersonCamera,
			FAttachmentTransformRules::SnapToTargetNotIncludingScale);
		Weapon->SetActorRelativeLocation(FVector(28.0f, 10.0f, -14.0f));
	}

	Weapon->SetActorHiddenInGame(false);
	if (USkeletalMeshComponent* WeaponMesh = Weapon->FindComponentByClass<USkeletalMeshComponent>())
	{
		WeaponMesh->SetOnlyOwnerSee(false);
		WeaponMesh->SetOwnerNoSee(false);
		WeaponMesh->SetCastShadow(false);
		WeaponMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_VIEWMODEL hands=%d socket=%s"),
		(ViewHands && ViewHands->GetSkeletalMeshAsset()) ? 1 : 0,
		*GripSocket.ToString());
}

void AShockPlayer::UpdateWeaponSlotVisibility(int32 VisibleSlot)
{
	for (int32 Index = 0; Index < WeaponSlots.Num(); ++Index)
	{
		if (AShockWeapon* SlotWeapon = WeaponSlots[Index].Get())
		{
			SlotWeapon->SetActorHiddenInGame(Index != VisibleSlot);
		}
	}
}

AShockWeapon* AShockPlayer::GiveWeaponByDef(FName DefName, int32 Slot)
{
	if (DefName.IsNone() || Slot < 0 || Slot >= WeaponSlots.Num())
	{
		return nullptr;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return nullptr;
	}

	if (AShockWeapon* Existing = WeaponSlots[Slot].Get())
	{
		if (EquippedWeapon == Existing)
		{
			EquippedWeapon = nullptr;
		}
		Existing->Destroy();
		WeaponSlots[Slot] = nullptr;
	}

	FActorSpawnParameters Params;
	Params.Owner = this;
	Params.Instigator = this;
	AShockWeapon* Weapon = World->SpawnActor<AShockWeapon>(
		AShockWeapon::StaticClass(),
		GetActorLocation(),
		GetActorRotation(),
		Params);
	if (!Weapon)
	{
		return nullptr;
	}

	if (UShockWeaponDef* Def = UShockWeaponDef::Resolve(DefName))
	{
		Weapon->ApplyDef(Def);
		Weapon->InitializeAmmoFullMag(Def->ReserveAmmo);
	}

	Weapon->SetOwner(this);
	Weapon->SetActorHiddenInGame(true);
	WeaponSlots[Slot] = Weapon;
	return Weapon;
}

AShockWeapon* AShockPlayer::GiveWeapon(TSubclassOf<AShockWeapon> WeaponClass, int32 Slot)
{
	if (!WeaponClass || Slot < 0 || Slot >= WeaponSlots.Num())
	{
		return nullptr;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return nullptr;
	}

	if (AShockWeapon* Existing = WeaponSlots[Slot].Get())
	{
		if (EquippedWeapon == Existing)
		{
			EquippedWeapon = nullptr;
		}
		Existing->Destroy();
		WeaponSlots[Slot] = nullptr;
	}

	FActorSpawnParameters Params;
	Params.Owner = this;
	Params.Instigator = this;
	AShockWeapon* Weapon = World->SpawnActor<AShockWeapon>(
		WeaponClass,
		GetActorLocation(),
		GetActorRotation(),
		Params);
	if (!Weapon)
	{
		return nullptr;
	}

	Weapon->SetOwner(this);
	Weapon->SetActorHiddenInGame(true);
	WeaponSlots[Slot] = Weapon;
	return Weapon;
}

AShockWeapon* AShockPlayer::GetWeaponInSlot(int32 Slot) const
{
	if (Slot < 0 || Slot >= WeaponSlots.Num())
	{
		return nullptr;
	}
	return WeaponSlots[Slot].Get();
}

bool AShockPlayer::IsWeaponSlotHidden(int32 Slot) const
{
	const AShockWeapon* Weapon = GetWeaponInSlot(Slot);
	return Weapon ? Weapon->IsHidden() : true;
}

bool AShockPlayer::SelectWeaponSlot(int32 Slot)
{
	if (Slot < 0 || Slot >= WeaponSlots.Num())
	{
		return false;
	}

	AShockWeapon* Weapon = WeaponSlots[Slot].Get();
	if (!Weapon)
	{
		return false;
	}

	ActiveWeaponSlot = Slot;
	UpdateWeaponSlotVisibility(Slot);
	EquipWeapon(Weapon);
	return true;
}

void AShockPlayer::NextWeapon()
{
	if (WeaponSlots.Num() <= 0)
	{
		return;
	}

	const int32 Start = ActiveWeaponSlot >= 0 ? ActiveWeaponSlot : 0;
	for (int32 Step = 1; Step <= WeaponSlots.Num(); ++Step)
	{
		const int32 NextSlot = (Start + Step) % WeaponSlots.Num();
		if (WeaponSlots[NextSlot].Get())
		{
			SelectWeaponSlot(NextSlot);
			return;
		}
	}
}

void AShockPlayer::PrevWeapon()
{
	if (WeaponSlots.Num() <= 0)
	{
		return;
	}

	const int32 Start = ActiveWeaponSlot >= 0 ? ActiveWeaponSlot : 0;
	for (int32 Step = 1; Step <= WeaponSlots.Num(); ++Step)
	{
		const int32 PrevSlot = (Start - Step + WeaponSlots.Num()) % WeaponSlots.Num();
		if (WeaponSlots[PrevSlot].Get())
		{
			SelectWeaponSlot(PrevSlot);
			return;
		}
	}
}

void AShockPlayer::HandleWeaponNextInput()
{
	NextWeapon();
}

void AShockPlayer::HandleWeaponPrevInput()
{
	PrevWeapon();
}

void AShockPlayer::HandleWeaponSlot1Input()
{
	SelectWeaponSlot(0);
}

void AShockPlayer::HandleWeaponSlot2Input()
{
	SelectWeaponSlot(1);
}

void AShockPlayer::HandleWeaponSlot3Input()
{
	SelectWeaponSlot(2);
}

void AShockPlayer::HandleWeaponSlot4Input()
{
	SelectWeaponSlot(3);
}

void AShockPlayer::HandleWeaponSlot5Input()
{
	SelectWeaponSlot(5);
}

void AShockPlayer::HandleWeaponSlot6Input()
{
	SelectWeaponSlot(6);
}

void AShockPlayer::HandleFireReleasedInput()
{
	if (EquippedWeapon)
	{
		EquippedWeapon->StopBeam();
	}
}

void AShockPlayer::EnablePlayableInput(bool bEnable)
{
	bPlayableInputEnabled = bEnable;
}

bool AShockPlayer::TryFireEquippedWeapon()
{
	if (!EquippedWeapon)
	{
		return false;
	}

	FVector Start = GetActorLocation();
	if (FirstPersonCamera)
	{
		Start = FirstPersonCamera->GetComponentLocation();
	}
	else if (UCameraComponent* Cam = FindComponentByClass<UCameraComponent>())
	{
		Start = Cam->GetComponentLocation();
	}
	else
	{
		Start.Z += BaseEyeHeight;
	}

	FRotator Aim = GetActorRotation();
	if (AController* C = GetController())
	{
		Aim = C->GetControlRotation();
	}

	return EquippedWeapon->FireAt(this, Start, Aim.Vector());
}

void AShockPlayer::ApplyWeaponRecoil()
{
	static constexpr float KickDegrees = 0.6f;
	WeaponRecoilKickTotal = KickDegrees;
	WeaponRecoilKickRemaining = KickDegrees;

	if (AController* C = GetController())
	{
		FRotator Rot = C->GetControlRotation();
		Rot.Pitch = FMath::Clamp(Rot.Pitch - KickDegrees, -89.0f, 89.0f);
		C->SetControlRotation(Rot);
	}

	if (UWorld* World = GetWorld())
	{
		World->GetTimerManager().SetTimer(
			WeaponRecoilTimerHandle,
			this,
			&AShockPlayer::TickWeaponRecoil,
			0.01f,
			true);
	}
}

void AShockPlayer::AdvanceWeaponRecoilForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f || WeaponRecoilKickRemaining <= KINDA_SMALL_NUMBER)
	{
		WeaponRecoilKickRemaining = 0.0f;
		if (UWorld* World = GetWorld())
		{
			World->GetTimerManager().ClearTimer(WeaponRecoilTimerHandle);
		}
		return;
	}

	const float RecoverRate =
		WeaponRecoilKickTotal > KINDA_SMALL_NUMBER && WeaponRecoilRecoverSeconds > KINDA_SMALL_NUMBER
			? WeaponRecoilKickTotal / WeaponRecoilRecoverSeconds
			: 0.0f;
	const float Step = FMath::Min(RecoverRate * DeltaSeconds, WeaponRecoilKickRemaining);
	if (AController* C = GetController())
	{
		FRotator Rot = C->GetControlRotation();
		Rot.Pitch = FMath::Clamp(Rot.Pitch + Step, -89.0f, 89.0f);
		C->SetControlRotation(Rot);
	}
	WeaponRecoilKickRemaining -= Step;
	if (WeaponRecoilKickRemaining <= KINDA_SMALL_NUMBER)
	{
		WeaponRecoilKickRemaining = 0.0f;
		if (UWorld* World = GetWorld())
		{
			World->GetTimerManager().ClearTimer(WeaponRecoilTimerHandle);
		}
	}
}

void AShockPlayer::TickWeaponRecoil()
{
	AdvanceWeaponRecoilForVerify(0.01f);
}

void AShockPlayer::AddResearchPoints(FName Archetype, float Points)
{
	if (Archetype.IsNone() || Points <= 0.0f)
	{
		return;
	}

	const int32 OldLevel = GetResearchLevel(Archetype);
	ResearchPointsByArchetype.FindOrAdd(Archetype) += Points;
	const int32 NewLevel = GetResearchLevel(Archetype);
	if (NewLevel > OldLevel)
	{
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_RESEARCH archetype=%s level=%d->%d"),
			*Archetype.ToString(),
			OldLevel,
			NewLevel);
	}
}

int32 AShockPlayer::GetResearchLevel(FName Archetype) const
{
	const float Points = ResearchPointsByArchetype.FindRef(Archetype);
	int32 Level = 0;
	for (int32 Index = 0; Index < ResearchLevelThresholds.Num(); ++Index)
	{
		const float Threshold = ResearchLevelThresholds[Index];
		if (Threshold <= 0.0f)
		{
			continue;
		}
		if (Points >= Threshold)
		{
			Level = Index;
		}
		else
		{
			break;
		}
	}
	return Level;
}

float AShockPlayer::GetResearchDamageMultiplier(FName Archetype) const
{
	return 1.0f + static_cast<float>(GetResearchLevel(Archetype)) * ResearchDamageBonusPerLevel;
}

float AShockPlayer::GetResearchPointsForVerify(FName Archetype) const
{
	return ResearchPointsByArchetype.FindRef(Archetype);
}

TMap<FName, int32> AShockPlayer::GetInventoryStacksForTravel() const
{
	return InventoryStacks;
}

void AShockPlayer::RestoreInventoryStacksForTravel(const TMap<FName, int32>& Stacks)
{
	InventoryStacks = Stacks;
}

void AShockPlayer::HandleFireInput()
{
	TryFireEquippedWeapon();
}

bool AShockPlayer::TryReloadEquippedWeapon()
{
	if (!EquippedWeapon)
	{
		return false;
	}
	return EquippedWeapon->Reload();
}

void AShockPlayer::HandleReloadInput()
{
	TryReloadEquippedWeapon();
}

void AShockPlayer::HandleAmmoCycleInput()
{
	if (EquippedWeapon)
	{
		EquippedWeapon->CycleAmmoType();
	}
}

bool AShockPlayer::ConsumeEve(float Amount)
{
	if (bInfiniteEve || Amount <= 0.0f)
	{
		return Amount <= 0.0f;
	}
	if (CurrentEve + KINDA_SMALL_NUMBER < Amount)
	{
		return false;
	}
	CurrentEve = FMath::Max(0.0f, CurrentEve - Amount);
	return true;
}

void AShockPlayer::RefillEve(float Amount)
{
	if (Amount <= 0.0f)
	{
		return;
	}
	CurrentEve = FMath::Clamp(CurrentEve + Amount, 0.0f, MaxEve);
}

bool AShockPlayer::EquipPlasmid(TSubclassOf<UShockPlasmid> PlasmidClass, int32 Slot)
{
	if (!PlasmidClass || Slot < 0 || Slot >= EquippedPlasmids.Num())
	{
		return false;
	}

	UShockPlasmid* Instance = NewObject<UShockPlasmid>(this, PlasmidClass);
	if (!Instance)
	{
		return false;
	}
	EquippedPlasmids[Slot] = Instance;
	ActivePlasmidSlot = Slot;
	return true;
}

void AShockPlayer::ClearAllPlasmids()
{
	for (int32 Index = 0; Index < EquippedPlasmids.Num(); ++Index)
	{
		EquippedPlasmids[Index] = nullptr;
	}
}

UShockPlasmid* AShockPlayer::GetActivePlasmid() const
{
	if (ActivePlasmidSlot < 0 || ActivePlasmidSlot >= EquippedPlasmids.Num())
	{
		return nullptr;
	}
	return EquippedPlasmids[ActivePlasmidSlot];
}

float AShockPlayer::GetPlasmidCooldownRemaining() const
{
	const UShockPlasmid* Plasmid = GetActivePlasmid();
	const UWorld* World = GetWorld();
	if (!Plasmid || !World || LastPlasmidCastWorldSeconds < 0.0)
	{
		return 0.0f;
	}
	const double Elapsed = World->GetTimeSeconds() - LastPlasmidCastWorldSeconds;
	return FMath::Max(0.0f, Plasmid->CastCooldown - static_cast<float>(Elapsed));
}

bool AShockPlayer::PerformPlasmidAimTrace(FHitResult& OutHit) const
{
	const UWorld* World = GetWorld();
	if (!World)
	{
		return false;
	}

	FVector Start = GetActorLocation() + FVector(0.0f, 0.0f, BaseEyeHeight);
	FRotator AimRotation = GetControlRotation();
	if (FirstPersonCamera)
	{
		Start = FirstPersonCamera->GetComponentLocation();
		AimRotation = FirstPersonCamera->GetComponentRotation();
	}
	const FVector End = Start + AimRotation.Vector() * PlasmidTraceRange;

	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockPlasmidCast), false, this);
	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	return World->LineTraceSingleByObjectType(OutHit, Start, End, ObjectParams, Params);
}

bool AShockPlayer::CastActivePlasmid()
{
	UShockPlasmid* Plasmid = GetActivePlasmid();
	UWorld* World = GetWorld();
	if (!Plasmid || !World)
	{
		return false;
	}

	if (Plasmid->EnforcesCastCooldown(this) && GetPlasmidCooldownRemaining() > KINDA_SMALL_NUMBER)
	{
		return false;
	}

	const float EveNeeded = Plasmid->GetCastEveCost(this);
	if (!bInfiniteEve && EveNeeded > KINDA_SMALL_NUMBER && CurrentEve + KINDA_SMALL_NUMBER < EveNeeded)
	{
		return false;
	}

	FHitResult Hit;
	PerformPlasmidAimTrace(Hit);

	if (!Plasmid->Cast(this, Hit))
	{
		return false;
	}

	if (!bInfiniteEve && EveNeeded > KINDA_SMALL_NUMBER)
	{
		ConsumeEve(EveNeeded);
	}
	LastPlasmidCastWorldSeconds = World->GetTimeSeconds();
	return true;
}

void AShockPlayer::CycleActivePlasmid()
{
	if (EquippedPlasmids.Num() <= 0)
	{
		return;
	}

	const int32 StartSlot = ActivePlasmidSlot;
	for (int32 Step = 1; Step <= EquippedPlasmids.Num(); ++Step)
	{
		const int32 NextSlot = (StartSlot + Step) % EquippedPlasmids.Num();
		if (EquippedPlasmids[NextSlot])
		{
			ActivePlasmidSlot = NextSlot;
			return;
		}
	}
}

void AShockPlayer::HandlePlasmidInput()
{
	CastActivePlasmid();
}

void AShockPlayer::HandlePlasmidCycleInput()
{
	CycleActivePlasmid();
}

bool AShockPlayer::PerformHackToolTrace(AShockSecurityDevice*& OutDevice) const
{
	OutDevice = nullptr;
	UWorld* World = GetWorld();
	if (!World || !FirstPersonCamera)
	{
		return false;
	}

	const FVector Start = FirstPersonCamera->GetComponentLocation();
	const FVector End = Start + FirstPersonCamera->GetForwardVector() * HackTraceRange;

	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockHackTool), false, this);
	FHitResult Hit;
	if (!World->LineTraceSingleByChannel(Hit, Start, End, ECC_Visibility, Params))
	{
		return false;
	}

	OutDevice = Cast<AShockSecurityDevice>(Hit.GetActor());
	if (!OutDevice && Hit.GetComponent())
	{
		OutDevice = Cast<AShockSecurityDevice>(Hit.GetComponent()->GetOwner());
	}
	return OutDevice != nullptr;
}

void AShockPlayer::HandleHackToolInput()
{
	AShockSecurityDevice* Device = nullptr;
	if (!PerformHackToolTrace(Device) || !Device)
	{
		return;
	}

	// PLAUSIBLE default difficulty when using the hack-tool key without a minigame.
	TryHackDevice(Device, 0.5f);
}

bool AShockPlayer::TryHackDevice(AShockSecurityDevice* Device, float Difficulty01)
{
	if (!Device || Device->GetAllegiance() == EShockDeviceAllegiance::Disabled)
	{
		return false;
	}

	const FName Label = Device->DeviceLabel.IsNone() ? Device->GetFName() : Device->DeviceLabel;
	const bool bSuccess = Difficulty01 <= HackSkill + KINDA_SMALL_NUMBER;
	if (bSuccess)
	{
		Device->SetAllegiance(EShockDeviceAllegiance::Friendly);
		SetTurretHacked(Label, true);
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_HACK label=%s result=ok"), *Label.ToString());
	}
	else
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_HACK label=%s result=fail"), *Label.ToString());
		ApplyAuthoredDamage(HackFailSelfDamage);
	}
	return bSuccess;
}

bool AShockPlayer::UnHackDevice(AShockSecurityDevice* Device)
{
	if (!Device)
	{
		return false;
	}

	const FName Label = Device->DeviceLabel.IsNone() ? Device->GetFName() : Device->DeviceLabel;
	Device->SetAllegiance(EShockDeviceAllegiance::Neutral);
	SetTurretHacked(Label, false);
	return true;
}

void AShockPlayer::MoveForward(float Value)
{
	if (Value == 0.0f || Controller == nullptr || bMovementDisabled)
	{
		return;
	}
	const FRotator YawRot(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
	AddMovementInput(FRotationMatrix(YawRot).GetUnitAxis(EAxis::X), Value);
}

void AShockPlayer::MoveRight(float Value)
{
	if (Value == 0.0f || Controller == nullptr || bMovementDisabled)
	{
		return;
	}
	const FRotator YawRot(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
	AddMovementInput(FRotationMatrix(YawRot).GetUnitAxis(EAxis::Y), Value);
}

void AShockPlayer::TurnAtRate(float Value)
{
	AddControllerYawInput(Value);
}

void AShockPlayer::LookUpAtRate(float Value)
{
	AddControllerPitchInput(Value);
}

int32 AShockPlayer::AddStackToInventory(FName ItemClass, int32 StackSize)
{
	if (ItemClass.IsNone() || StackSize <= 0)
	{
		return 0;
	}
	int32& Count = InventoryStacks.FindOrAdd(ItemClass);
	int32 MaxStack = MAX_int32;
	if (ItemClass == FName(TEXT("FirstAidKit")))
	{
		MaxStack = FMath::Max(0, MaxFirstAidKits);
	}
	else if (ItemClass == FName(TEXT("EveHypo")))
	{
		MaxStack = FMath::Max(0, MaxEveHypos);
	}
	Count = FMath::Min(Count + StackSize, MaxStack);
	return Count;
}

int32 AShockPlayer::RemoveStackFromInventory(FName ItemClass, int32 StackSize)
{
	if (ItemClass.IsNone() || StackSize <= 0)
	{
		return 0;
	}
	int32* Count = InventoryStacks.Find(ItemClass);
	if (!Count)
	{
		return 0;
	}
	Count[0] = FMath::Max(0, Count[0] - StackSize);
	return Count[0];
}

int32 AShockPlayer::GetInventoryStack(FName ItemClass) const
{
	if (const int32* Count = InventoryStacks.Find(ItemClass))
	{
		return *Count;
	}
	return 0;
}

float AShockPlayer::GetMaxHealth() const
{
	if (AuthoredMaxHealth > 0.0f)
	{
		return AuthoredMaxHealth;
	}
	if (AuthoredHealth > 0.0f)
	{
		return AuthoredHealth;
	}
	return 100.0f;
}

void AShockPlayer::SetCurrentHealthForVerify(float Value)
{
	EnsureHealthInitialized();
	CurrentHealth = FMath::Clamp(Value, 0.0f, GetMaxHealth());
	if (CurrentHealth > 0.0f)
	{
		bIsDead = false;
		bDeathHandled = false;
	}
}

void AShockPlayer::Heal(float Amount)
{
	if (Amount <= 0.0f)
	{
		return;
	}
	EnsureHealthInitialized();
	const float MaxHealth = GetMaxHealth();
	if (CurrentHealth >= MaxHealth - KINDA_SMALL_NUMBER)
	{
		return;
	}
	CurrentHealth = FMath::Min(CurrentHealth + Amount, MaxHealth);
}

bool AShockPlayer::UseFirstAidKit()
{
	if (GetInventoryStack(FName(TEXT("FirstAidKit"))) <= 0)
	{
		return false;
	}
	EnsureHealthInitialized();
	if (CurrentHealth >= GetMaxHealth() - KINDA_SMALL_NUMBER)
	{
		return false;
	}
	RemoveStackFromInventory(FName(TEXT("FirstAidKit")), 1);
	Heal(FirstAidHealAmount);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_CONSUMABLE item=FirstAidKit health=%.1f"),
		CurrentHealth);
	return true;
}

bool AShockPlayer::UseEveHypo()
{
	if (GetInventoryStack(FName(TEXT("EveHypo"))) <= 0)
	{
		return false;
	}
	if (CurrentEve >= MaxEve - KINDA_SMALL_NUMBER)
	{
		return false;
	}
	RemoveStackFromInventory(FName(TEXT("EveHypo")), 1);
	RefillEve(EveHypoAmount);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_CONSUMABLE item=EveHypo eve=%.1f"),
		CurrentEve);
	return true;
}

void AShockPlayer::AddMoney(int32 Amount)
{
	if (Amount > 0)
	{
		PlayerMoney += Amount;
	}
}

void AShockPlayer::TryAutoFirstAidAfterDamage()
{
	if (!bAutoFirstAid)
	{
		return;
	}
	const float MaxHealth = GetMaxHealth();
	if (MaxHealth <= 0.0f)
	{
		return;
	}
	if ((CurrentHealth / MaxHealth) < AutoFirstAidThreshold)
	{
		UseFirstAidKit();
	}
}

void AShockPlayer::HandleUseFirstAidInput()
{
	UseFirstAidKit();
}

void AShockPlayer::HandleUseEveHypoInput()
{
	UseEveHypo();
}

void AShockPlayer::SetForcedCrouch(bool bShouldCrouch)
{
	bForcedCrouch = bShouldCrouch;
	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->GetNavAgentPropertiesRef().bCanCrouch = true;
	}
	if (bShouldCrouch)
	{
		Crouch();
	}
	else
	{
		UnCrouch();
	}
}

void AShockPlayer::SetMovementDisabled(bool bDisable)
{
	bMovementDisabled = bDisable;
	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		if (bDisable)
		{
			Move->DisableMovement();
		}
		else
		{
			Move->SetMovementMode(MOVE_Walking);
		}
	}
}

void AShockPlayer::SetConceptEnabled(FName ConceptName, bool bEnable)
{
	if (ConceptName.IsNone())
	{
		return;
	}
	ConceptEnabled.FindOrAdd(ConceptName) = bEnable;
}

bool AShockPlayer::IsConceptEnabled(FName ConceptName) const
{
	if (ConceptName.IsNone())
	{
		return false;
	}
	if (const bool* Value = ConceptEnabled.Find(ConceptName))
	{
		return *Value;
	}
	return true;
}

void AShockPlayer::SetTipPriority(FName TipName, int32 Priority)
{
	if (TipName.IsNone())
	{
		return;
	}
	TipPriorities.FindOrAdd(TipName) = Priority;
}

int32 AShockPlayer::GetTipPriority(FName TipName) const
{
	if (const int32* Value = TipPriorities.Find(TipName))
	{
		return *Value;
	}
	return 0;
}

namespace
{
	FString MakeFactKey(FName Slot1, const FString& Slot2, const FString& Slot3)
	{
		return Slot1.ToString() + TEXT("|") + Slot2 + TEXT("|") + Slot3;
	}
}

void AShockPlayer::SetScriptedSequenceRunNow(FName SequenceLabel, int32 RunNow)
{
	if (SequenceLabel.IsNone())
	{
		return;
	}
	ScriptedSequenceRunNow.FindOrAdd(SequenceLabel) = RunNow;
}

int32 AShockPlayer::GetScriptedSequenceRunNow(FName SequenceLabel) const
{
	if (const int32* Value = ScriptedSequenceRunNow.Find(SequenceLabel))
	{
		return *Value;
	}
	return 0;
}

void AShockPlayer::SetInputContext(FName Context, bool bUnset)
{
	if (Context.IsNone())
	{
		return;
	}
	LastInputContext = Context;
	if (bUnset)
	{
		if (CurrentInputContext == Context)
		{
			CurrentInputContext = NAME_None;
		}
		return;
	}
	CurrentInputContext = Context;
}

void AShockPlayer::SetRegionPressure(FName RegionName, uint8 Pressure)
{
	if (RegionName.IsNone())
	{
		return;
	}
	RegionPressure.FindOrAdd(RegionName) = Pressure;
}

uint8 AShockPlayer::GetRegionPressure(FName RegionName) const
{
	if (const uint8* Value = RegionPressure.Find(RegionName))
	{
		return *Value;
	}
	return 0;
}

void AShockPlayer::AssertFact(FName Slot1, const FString& Slot2, const FString& Slot3)
{
	if (Slot1.IsNone())
	{
		return;
	}
	Facts.Add(MakeFactKey(Slot1, Slot2, Slot3));
}

void AShockPlayer::RetractFact(FName Slot1, const FString& Slot2, const FString& Slot3)
{
	if (Slot1.IsNone())
	{
		return;
	}
	Facts.Remove(MakeFactKey(Slot1, Slot2, Slot3));
}

bool AShockPlayer::HasFact(FName Slot1, const FString& Slot2, const FString& Slot3) const
{
	if (Slot1.IsNone())
	{
		return false;
	}
	return Facts.Contains(MakeFactKey(Slot1, Slot2, Slot3));
}

void AShockPlayer::InitiateQuest(FName QuestName, bool bSetActive)
{
	if (QuestName.IsNone())
	{
		return;
	}
	QuestState.FindOrAdd(QuestName) = 1;
	if (bSetActive)
	{
		ActiveQuest = QuestName;
	}
}

void AShockPlayer::CompleteQuestObjective(FName QuestName, int32 Count)
{
	if (QuestName.IsNone() || Count <= 0)
	{
		return;
	}
	QuestObjectiveCount.FindOrAdd(QuestName) += Count;
}

void AShockPlayer::CompleteQuest(FName QuestName)
{
	if (QuestName.IsNone())
	{
		return;
	}
	QuestState.FindOrAdd(QuestName) = 2;
}

void AShockPlayer::FailQuest(FName QuestName)
{
	if (QuestName.IsNone())
	{
		return;
	}
	QuestState.FindOrAdd(QuestName) = 3;
}

int32 AShockPlayer::GetQuestState(FName QuestName) const
{
	if (const uint8* Value = QuestState.Find(QuestName))
	{
		return *Value;
	}
	return 0;
}

int32 AShockPlayer::GetQuestObjectiveCount(FName QuestName) const
{
	if (const int32* Value = QuestObjectiveCount.Find(QuestName))
	{
		return *Value;
	}
	return 0;
}

void AShockPlayer::SetQuestHint(FName QuestName, FName HintName)
{
	if (QuestName.IsNone())
	{
		return;
	}
	QuestHints.FindOrAdd(QuestName) = HintName;
}

FName AShockPlayer::GetQuestHint(FName QuestName) const
{
	if (const FName* Value = QuestHints.Find(QuestName))
	{
		return *Value;
	}
	return NAME_None;
}

void AShockPlayer::SetAutoSaveCommand(const FString& Command)
{
	LastAutoSaveCommand = Command;
}

void AShockPlayer::SetPendingTimerSeconds(float Seconds)
{
	PendingTimerSeconds = Seconds;
}

void AShockPlayer::StopTimerForScript(FName InScriptLabel)
{
	StoppedTimerLabel = InScriptLabel;
	PendingTimerSeconds = 0.0f;
}

void AShockPlayer::SetMapHUDRegion(const FString& Description)
{
	LastMapHUDRegion = Description;
}

void AShockPlayer::SetTrainingMessage(FName MessageName)
{
	LastTrainingMessage = MessageName;
}

void AShockPlayer::SetFadeVolumeOverride(float Volume, float Duration)
{
	FadeVolumeOverride = Volume;
	FadeVolumeDuration = Duration;
}

void AShockPlayer::SetLevelSavingDisabled(bool bDisable)
{
	bLevelSavingDisabled = bDisable;
}

void AShockPlayer::SetLevelSwitchingDisabled(bool bDisable)
{
	bLevelSwitchingDisabled = bDisable;
}

void AShockPlayer::SetHUDEnabled(bool bEnable)
{
	bHUDEnabled = bEnable;
}

void AShockPlayer::SetResurrectionStationActivated(FName Station, bool bActivated)
{
	if (Station.IsNone())
	{
		return;
	}
	ResurrectionStationActivated.FindOrAdd(Station) = bActivated;
}

bool AShockPlayer::IsResurrectionStationActivated(FName Station) const
{
	if (const bool* Value = ResurrectionStationActivated.Find(Station))
	{
		return *Value;
	}
	return false;
}

void AShockPlayer::SetResurrectionStationEnabled(FName Station, bool bEnabled)
{
	if (Station.IsNone())
	{
		return;
	}
	ResurrectionStationEnabled.FindOrAdd(Station) = bEnabled;
}

bool AShockPlayer::IsResurrectionStationEnabled(FName Station) const
{
	if (const bool* Value = ResurrectionStationEnabled.Find(Station))
	{
		return *Value;
	}
	return true;
}

void AShockPlayer::UnlockBathysphereDestination(FName System, FName MapName)
{
	if (System.IsNone() || MapName.IsNone())
	{
		return;
	}
	UnlockedBathysphereDestinations.Add(FString::Printf(TEXT("%s|%s"), *System.ToString(), *MapName.ToString()));
}

bool AShockPlayer::IsBathysphereDestinationUnlocked(FName System, FName MapName) const
{
	if (System.IsNone() || MapName.IsNone())
	{
		return false;
	}
	return UnlockedBathysphereDestinations.Contains(
		FString::Printf(TEXT("%s|%s"), *System.ToString(), *MapName.ToString()));
}

void AShockPlayer::RemoveAvailableHoldable(FName HoldableClass)
{
	if (HoldableClass.IsNone())
	{
		return;
	}
	RemovedHoldables.Add(HoldableClass);
}

bool AShockPlayer::IsHoldableRemoved(FName HoldableClass) const
{
	return RemovedHoldables.Contains(HoldableClass);
}

void AShockPlayer::SetClientMessage(const FString& Text)
{
	LastClientMessage = Text;
}

void AShockPlayer::SetHUDPlaying(bool bPlaying)
{
	bHUDPlaying = bPlaying;
}

void AShockPlayer::SetSecurityAlarmOn(bool bOn, FName TargetLabel)
{
	bSecurityAlarmOn = bOn;
	if (!TargetLabel.IsNone())
	{
		LastAlarmTarget = TargetLabel;
	}
}

void AShockPlayer::SetSpawnZoneRepopulation(FName Zone, uint8 Aggressor, uint8 Protector)
{
	if (Zone.IsNone())
	{
		return;
	}
	SpawnZoneAggressor.FindOrAdd(Zone) = Aggressor;
	SpawnZoneProtector.FindOrAdd(Zone) = Protector;
}

uint8 AShockPlayer::GetSpawnZoneAggressor(FName Zone) const
{
	if (const uint8* Value = SpawnZoneAggressor.Find(Zone))
	{
		return *Value;
	}
	return 0;
}

void AShockPlayer::SetSpotlightTarget(FName Spotlight, FName Target)
{
	if (Spotlight.IsNone())
	{
		return;
	}
	SpotlightTarget.FindOrAdd(Spotlight) = Target;
}

FName AShockPlayer::GetSpotlightTarget(FName Spotlight) const
{
	if (const FName* Value = SpotlightTarget.Find(Spotlight))
	{
		return *Value;
	}
	return NAME_None;
}

void AShockPlayer::SetSpotlightOn(FName Spotlight, bool bOn)
{
	if (Spotlight.IsNone())
	{
		return;
	}
	SpotlightOn.FindOrAdd(Spotlight) = bOn;
}

bool AShockPlayer::IsSpotlightOn(FName Spotlight) const
{
	if (const bool* Value = SpotlightOn.Find(Spotlight))
	{
		return *Value;
	}
	return false;
}

void AShockPlayer::SetQuestLogWait(FName QuestLogClass)
{
	LastQuestLogWait = QuestLogClass;
}

void AShockPlayer::SetMaterialSwitchIndex(FName MaterialSwitch, float Index)
{
	if (MaterialSwitch.IsNone())
	{
		return;
	}
	MaterialSwitchIndex.FindOrAdd(MaterialSwitch) = Index;
}

float AShockPlayer::GetMaterialSwitchIndex(FName MaterialSwitch) const
{
	if (const float* Value = MaterialSwitchIndex.Find(MaterialSwitch))
	{
		return *Value;
	}
	return -1.0f;
}

void AShockPlayer::SetSecurityHacked(bool bHacked, float ShutdownTime)
{
	bSecurityHacked = bHacked;
	SecurityHackShutdownTime = bHacked ? ShutdownTime : 0.0f;
	if (bHacked)
	{
		if (UWorld* World = GetWorld())
		{
			AShockSecurityDevice::ForEachDevice(
				World,
				[ShutdownTime](AShockSecurityDevice* Device)
				{
					if (Device)
					{
						Device->ApplySecurityShutdown(ShutdownTime);
					}
				});
		}
	}
}

void AShockPlayer::SetTurretHacked(FName Turret, bool bHacked)
{
	if (Turret.IsNone())
	{
		return;
	}
	TurretHacked.FindOrAdd(Turret) = bHacked;
}

bool AShockPlayer::IsTurretHacked(FName Turret) const
{
	if (const bool* Value = TurretHacked.Find(Turret))
	{
		return *Value;
	}
	return false;
}

void AShockPlayer::SetDoorBroken(FName Door, bool bBroken)
{
	if (Door.IsNone())
	{
		return;
	}
	DoorBroken.FindOrAdd(Door) = bBroken;
}

bool AShockPlayer::IsDoorBroken(FName Door) const
{
	if (const bool* Value = DoorBroken.Find(Door))
	{
		return *Value;
	}
	return false;
}

AShockPlayer* AShockPlayer::FindLocalOrFirst(UWorld* World)
{
	if (!World)
	{
		return nullptr;
	}
	if (APlayerController* PC = World->GetFirstPlayerController())
	{
		if (AShockPlayer* Possessed = Cast<AShockPlayer>(PC->GetPawn()))
		{
			return Possessed;
		}
	}
	for (TActorIterator<AShockPlayer> It(World); It; ++It)
	{
		if (*It)
		{
			return *It;
		}
	}
	return nullptr;
}

void AShockPlayer::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);
	if (!PlayerInputComponent || !bPlayableInputEnabled)
	{
		return;
	}
	PlayerInputComponent->BindAction(TEXT("Fire"), IE_Pressed, this, &AShockPlayer::HandleFireInput);
	PlayerInputComponent->BindAction(TEXT("Fire"), IE_Released, this, &AShockPlayer::HandleFireReleasedInput);
	PlayerInputComponent->BindAction(TEXT("Reload"), IE_Pressed, this, &AShockPlayer::HandleReloadInput);
	PlayerInputComponent->BindAction(TEXT("AmmoTypeCycle"), IE_Pressed, this, &AShockPlayer::HandleAmmoCycleInput);
	PlayerInputComponent->BindAction(TEXT("Plasmid"), IE_Pressed, this, &AShockPlayer::HandlePlasmidInput);
	PlayerInputComponent->BindAction(TEXT("PlasmidCycle"), IE_Pressed, this, &AShockPlayer::HandlePlasmidCycleInput);
	PlayerInputComponent->BindAction(TEXT("HackTool"), IE_Pressed, this, &AShockPlayer::HandleHackToolInput);
	PlayerInputComponent->BindAction(TEXT("UseFirstAid"), IE_Pressed, this, &AShockPlayer::HandleUseFirstAidInput);
	PlayerInputComponent->BindAction(TEXT("UseEveHypo"), IE_Pressed, this, &AShockPlayer::HandleUseEveHypoInput);
	PlayerInputComponent->BindAction(TEXT("WeaponNext"), IE_Pressed, this, &AShockPlayer::HandleWeaponNextInput);
	PlayerInputComponent->BindAction(TEXT("WeaponPrev"), IE_Pressed, this, &AShockPlayer::HandleWeaponPrevInput);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot1"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot1Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot2"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot2Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot3"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot3Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot4"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot4Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot5"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot5Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot6"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot6Input);
	PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AShockPlayer::MoveForward);
	PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AShockPlayer::MoveRight);
	PlayerInputComponent->BindAxis(TEXT("Turn"), this, &AShockPlayer::TurnAtRate);
	PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &AShockPlayer::LookUpAtRate);
}
