#include "ShockPlayer.h"

#include "ShockWeapon.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/PlayerController.h"

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

void AShockPlayer::EquipWeapon(AShockWeapon* Weapon)
{
	EquippedWeapon = Weapon;
	if (!Weapon)
	{
		return;
	}

	if (FirstPersonCamera)
	{
		Weapon->AttachToComponent(
			FirstPersonCamera,
			FAttachmentTransformRules::SnapToTargetNotIncludingScale);
		Weapon->SetActorHiddenInGame(false);
		if (USkeletalMeshComponent* WeaponMesh = Weapon->FindComponentByClass<USkeletalMeshComponent>())
		{
			WeaponMesh->SetOnlyOwnerSee(true);
			WeaponMesh->SetCastShadow(false);
		}
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

void AShockPlayer::HandleFireInput()
{
	TryFireEquippedWeapon();
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
	Count += StackSize;
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
	PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AShockPlayer::MoveForward);
	PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AShockPlayer::MoveRight);
	PlayerInputComponent->BindAxis(TEXT("Turn"), this, &AShockPlayer::TurnAtRate);
	PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &AShockPlayer::LookUpAtRate);
}
