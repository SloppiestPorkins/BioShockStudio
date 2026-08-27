#include "ShockPlayer.h"

#include "ShockWeapon.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"

AShockPlayer::AShockPlayer()
{
	SchemaClassName = TEXT("ShockPlayer");
	bUseControllerRotationYaw = true;
	bUseControllerRotationPitch = false;
	bUseControllerRotationRoll = false;
	AutoPossessPlayer = EAutoReceiveInput::Disabled;

	FirstPersonCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FirstPersonCamera"));
	FirstPersonCamera->SetupAttachment(GetCapsuleComponent());
	FirstPersonCamera->SetRelativeLocation(FVector(0.0f, 0.0f, BaseEyeHeight));
	FirstPersonCamera->bUsePawnControlRotation = true;
}

void AShockPlayer::EquipWeapon(AShockWeapon* Weapon)
{
	EquippedWeapon = Weapon;
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
	if (Value == 0.0f || Controller == nullptr)
	{
		return;
	}
	const FRotator YawRot(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
	AddMovementInput(FRotationMatrix(YawRot).GetUnitAxis(EAxis::X), Value);
}

void AShockPlayer::MoveRight(float Value)
{
	if (Value == 0.0f || Controller == nullptr)
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
