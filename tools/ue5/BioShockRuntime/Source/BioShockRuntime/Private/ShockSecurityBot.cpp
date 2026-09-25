#include "ShockSecurityBot.h"

#include "ShockDamageLibrary.h"
#include "ShockPlayer.h"
#include "ShockSecuritySubsystem.h"
#include "ShockWeapon.h"
#include "Components/CapsuleComponent.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"

AShockSecurityBot::AShockSecurityBot()
{
	SchemaClassName = TEXT("SecurityBot");
	SightRadius = 2000.0f;
	RangedRange = 800.0f;
	RangedCooldown = 0.333333f;
	bUseBrain = false;
	bAlwaysSeePlayer = true;
	CorpseFadeSeconds = 0.0f;

	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->MaxWalkSpeed = BotMoveSpeed;
		Move->MaxFlySpeed = BotMoveSpeed;
	}
}

void AShockSecurityBot::BeginPlay()
{
	Super::BeginPlay();
	SightRadius = DetectRadius;
	RangedRange = HitscanRange;
	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->MaxWalkSpeed = BotMoveSpeed;
		Move->MaxFlySpeed = BotMoveSpeed;
	}
	EnsureBotWeapon();
	RefreshCombatTargeting();
}

void AShockSecurityBot::EnsureBotWeapon()
{
	if (BotWeapon)
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	FActorSpawnParameters Params;
	Params.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
	BotWeapon = World->SpawnActor<AShockWeapon>(AShockWeapon::StaticClass(), GetActorLocation(), GetActorRotation(), Params);
	if (BotWeapon)
	{
		BotWeapon->ConfigureHitscan(HitscanDamage, HitscanRange);
		BotWeapon->SetEnforceAmmo(false);
		EquipAIWeapon(BotWeapon);
	}
}

void AShockSecurityBot::SetBotAllegiance(EShockDeviceAllegiance NewAllegiance)
{
	if (BotAllegiance == NewAllegiance)
	{
		return;
	}

	BotAllegiance = NewAllegiance;
	if (BotAllegiance == EShockDeviceAllegiance::Disabled)
	{
		bBotOperational = false;
		ClearCombatTargetPawn();
	}
	else
	{
		bBotOperational = true;
	}
	RefreshCombatTargeting();
}

void AShockSecurityBot::ApplySecurityShutdown(float Duration)
{
	if (Duration <= 0.0f)
	{
		return;
	}

	if (!bInSecurityShutdown)
	{
		AllegianceBeforeShutdown = BotAllegiance;
		bInSecurityShutdown = true;
		SetBotAllegiance(EShockDeviceAllegiance::Disabled);
	}
	SecurityShutdownRemaining = FMath::Max(SecurityShutdownRemaining, Duration);
}

void AShockSecurityBot::ActivateForPlayer(AShockPlayer* Player)
{
	AuthoredMaxHealth = BotHealth;
	AuthoredHealth = BotHealth;
	EnsureHealthInitialized();

	bDormant = false;
	SetBotAllegiance(EShockDeviceAllegiance::Hostile);
	EnsureBotWeapon();
	RefreshCombatTargeting();

	if (Player)
	{
#if WITH_EDITOR
		AddTargetToAttackOnSight(FName(*Player->GetActorLabel()));
#else
		(void)Player;
#endif
	}

	if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(GetWorld()))
	{
		Security->RegisterBot(this);
	}
}

void AShockSecurityBot::SetDormant(bool bInDormant)
{
	bDormant = bInDormant;
	if (bDormant)
	{
		bBotOperational = false;
		ClearCombatTargetPawn();
	}
	else if (BotAllegiance != EShockDeviceAllegiance::Disabled)
	{
		bBotOperational = true;
		RefreshCombatTargeting();
	}
}

void AShockSecurityBot::ExplodeFromFailedHack()
{
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_BOT_EXPLODE label=%s reason=failed_hack_dormant"),
		*GetScriptLabel().ToString());
	if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(GetWorld()))
	{
		Security->UnregisterBot(this);
	}
	bDormant = false;
	bBotOperational = false;
	Destroy();
}

void AShockSecurityBot::CommandAttackLabel(FName TargetLabel)
{
	if (TargetLabel.IsNone())
	{
		return;
	}

	AddTargetToAttackOnSight(TargetLabel);
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	for (TActorIterator<ABaseShockAI> It(World); It; ++It)
	{
		ABaseShockAI* AI = *It;
		if (AI && AI->GetScriptLabel() == TargetLabel)
		{
			SetCombatTargetPawn(AI);
			break;
		}
	}
	for (TActorIterator<AShockPlayer> PlayerIt(World); PlayerIt; ++PlayerIt)
	{
		AShockPlayer* Player = *PlayerIt;
#if WITH_EDITOR
		if (Player && FName(*Player->GetActorLabel()) == TargetLabel)
		{
			SetCombatTargetPawn(Player);
			break;
		}
#endif
	}
}

void AShockSecurityBot::ConfigureForVerify(FName Label, uint8 InAllegiance, float InHealth)
{
	ConfigureIdentity(FName(TEXT("SecurityBot")), Label);
	BotHealth = InHealth;
	SetBotAllegiance(static_cast<EShockDeviceAllegiance>(InAllegiance));
	bInSecurityShutdown = false;
	SecurityShutdownRemaining = 0.0f;
	AuthoredMaxHealth = InHealth;
	AuthoredHealth = InHealth;
	EnsureHealthInitialized();
	EnsureBotWeapon();
}

void AShockSecurityBot::AdvanceBotForVerify(float DeltaSeconds)
{
	if (!bBotOperational || BotAllegiance == EShockDeviceAllegiance::Disabled)
	{
		return;
	}
	EnableFloorlessMovement();
	EnsureControllerForVerify();
	AdvanceAutonomousCombat(DeltaSeconds);
}

bool AShockSecurityBot::ShouldEngagePlayer(const AShockPlayer* Player) const
{
	if (!Player || !bBotOperational || BotAllegiance != EShockDeviceAllegiance::Hostile)
	{
		return false;
	}

	if (!IsAliveCombatTarget(Player))
	{
		return false;
	}

	if (Player->IsSecurityAlarmOn())
	{
		return GetDistanceToCombatTarget(Player) <= SightRadius;
	}

	return bAlwaysSeePlayer && GetDistanceToCombatTarget(Player) <= SightRadius;
}

bool AShockSecurityBot::ShouldEngageAI(const ABaseShockAI* AI) const
{
	if (!AI || !bBotOperational || BotAllegiance != EShockDeviceAllegiance::Friendly)
	{
		return false;
	}

	if (Cast<AShockSecurityBot>(AI))
	{
		return false;
	}

	return IsAliveCombatTarget(AI) && GetDistanceToCombatTarget(AI) <= SightRadius;
}

void AShockSecurityBot::RefreshCombatTargeting()
{
	ClearCombatTargetPawn();
	if (!bBotOperational || BotAllegiance == EShockDeviceAllegiance::Disabled)
	{
		return;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	if (BotAllegiance == EShockDeviceAllegiance::Hostile)
	{
		for (TActorIterator<AShockPlayer> It(World); It; ++It)
		{
			if (ShouldEngagePlayer(*It))
			{
				SetCombatTargetPawn(*It);
				return;
			}
		}
	}
	else if (BotAllegiance == EShockDeviceAllegiance::Friendly)
	{
		for (TActorIterator<ABaseShockAI> It(World); It; ++It)
		{
			if (ShouldEngageAI(*It))
			{
				SetCombatTargetPawn(*It);
				return;
			}
		}
	}
}

void AShockSecurityBot::Tick(float DeltaSeconds)
{
	if (SecurityShutdownRemaining > 0.0f)
	{
		SecurityShutdownRemaining -= DeltaSeconds;
		if (SecurityShutdownRemaining <= 0.0f)
		{
			bInSecurityShutdown = false;
			if (IsValid(this) && !bIsDead)
			{
				if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(GetWorld()))
				{
					Security->UnregisterBot(this);
				}
				UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_BOT_DESPAWN label=%s reason=shutdown_expired"), *GetScriptLabel().ToString());
				Destroy();
				return;
			}
		}
	}

	if (bBotOperational && BotAllegiance != EShockDeviceAllegiance::Disabled)
	{
		RefreshCombatTargeting();
		Super::Tick(DeltaSeconds);

		if (BotWeapon)
		{
			BotFireCount = BotWeapon->GetFireCount();
		}
	}
}

void AShockSecurityBot::OnDeathFromDamage()
{
	Super::OnDeathFromDamage();
	SetBotAllegiance(EShockDeviceAllegiance::Disabled);
	if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(GetWorld()))
	{
		Security->NotifyBotKilled(this);
	}
}

void AShockSecurityBot::ForEachBot(UWorld* World, TFunctionRef<void(AShockSecurityBot*)> Fn)
{
	if (!World)
	{
		return;
	}
	for (TActorIterator<AShockSecurityBot> It(World); It; ++It)
	{
		if (*It)
		{
			Fn(*It);
		}
	}
}
