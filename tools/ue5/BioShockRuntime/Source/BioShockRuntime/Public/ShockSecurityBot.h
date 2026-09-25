#pragma once

#include "BaseShockAI.h"
#include "ShockSecurityDeviceTypes.h"
#include "ShockSecurityBot.generated.h"

class AShockPlayer;
class AShockWeapon;

/**
 * Mobile security bot (SecurityBot.uc). Subclasses ABaseShockAI for brain + navigation;
 * allegiance mirrors turret hacking (Hostile→player, Friendly→splicers).
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockSecurityBot : public ABaseShockAI
{
	GENERATED_BODY()

public:
	AShockSecurityBot();

	/** PLAUSIBLE — minimum-tier bot HP; MediumSecurityBot.uc ships 300. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Bot")
	float BotHealth = 30.0f;

	/** SecurityBot.uc DetectRadius=2000. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Bot")
	float DetectRadius = 2000.0f;

	/** SecurityBot.uc AirSpeed=400 — faster than default splicer walk (350). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Bot")
	float BotMoveSpeed = 500.0f;

	/** TurretMiniGun.uc BaseFireRate=3 → 3 shots/s. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Bot")
	float FireInterval = 0.333333f;

	/** PLAUSIBLE — bot shock-gun trace damage. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Bot")
	float HitscanDamage = 8.0f;

	/** SecurityBot.uc MaximumAttackRange=800. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security|Bot")
	float HitscanRange = 800.0f;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security|Bot")
	void SetBotAllegiance(EShockDeviceAllegiance NewAllegiance);

	UFUNCTION(BlueprintPure, Category = "BioShock|Security|Bot")
	EShockDeviceAllegiance GetBotAllegiance() const { return BotAllegiance; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security|Bot")
	void ApplySecurityShutdown(float Duration);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security|Bot")
	void ActivateForPlayer(AShockPlayer* Player);

	/** Placed dormant bot (hackable; explodes on failed hack). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Security|Bot")
	void SetDormant(bool bInDormant);

	UFUNCTION(BlueprintPure, Category = "BioShock|Security|Bot")
	bool IsDormant() const { return bDormant; }

	/** Guide: dormant bot explodes after a failed hack (not after cancel/close). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Security|Bot")
	void ExplodeFromFailedHack();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security|Bot")
	void CommandAttackLabel(FName TargetLabel);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security|Bot")
	void ConfigureForVerify(FName Label, uint8 InAllegiance, float InHealth = 30.0f);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security|Bot")
	void AdvanceBotForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintPure, Category = "BioShock|Security|Bot")
	uint8 GetBotAllegianceForVerify() const { return static_cast<uint8>(BotAllegiance); }

	UFUNCTION(BlueprintPure, Category = "BioShock|Security|Bot")
	bool IsBotOperationalForVerify() const { return bBotOperational; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Security|Bot")
	int32 GetBotFireCountForVerify() const { return BotFireCount; }

	static void ForEachBot(UWorld* World, TFunctionRef<void(AShockSecurityBot*)> Fn);

protected:
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;
	virtual void OnDeathFromDamage() override;

private:
	void EnsureBotWeapon();
	void RefreshCombatTargeting();
	bool ShouldEngagePlayer(const AShockPlayer* Player) const;
	bool ShouldEngageAI(const ABaseShockAI* AI) const;

	UPROPERTY()
	TObjectPtr<AShockWeapon> BotWeapon;

	EShockDeviceAllegiance BotAllegiance = EShockDeviceAllegiance::Hostile;
	EShockDeviceAllegiance AllegianceBeforeShutdown = EShockDeviceAllegiance::Hostile;

	bool bBotOperational = true;
	bool bDormant = false;
	bool bInSecurityShutdown = false;
	float SecurityShutdownRemaining = 0.0f;
	int32 BotFireCount = 0;
};
