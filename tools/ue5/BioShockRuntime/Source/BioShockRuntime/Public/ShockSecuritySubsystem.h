#pragma once

#include "Subsystems/WorldSubsystem.h"
#include "ShockSecuritySubsystem.generated.h"

class AShockPlayer;
class AShockSecurityBot;
class AShockSecurityCamera;
class UWorld;

/**
 * Alarm-driven security-bot spawn bookkeeping (SecurityManager / camera alert slice).
 * Spawned bots are AShockSecurityBot actors — not slice encounter enemies.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockSecuritySubsystem : public UWorldSubsystem
{
	GENERATED_BODY()

public:
	static UShockSecuritySubsystem* Get(const UWorld* World);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security", meta = (WorldContext = "WorldContextObject"))
	static UShockSecuritySubsystem* GetForWorld(UObject* WorldContextObject);

	/** PLAUSIBLE — concurrent alarm-response bots; shipped cameras spawn NumSecurityBotsSpawned=1 each. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security")
	int32 MaxActiveBots = 2;

	/** PLAUSIBLE — despawn delay after alarm clears (no shipped lifetime-after-clear found). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security")
	float BotLifetimeAfterAlarmClearSeconds = 30.0f;

	void SetRequestedBotCount(int32 Count) { PendingBotSpawnCount = FMath::Max(0, Count); }

	void SetNextSpawnLocationLabel(FName Label) { NextSpawnLocationLabel = Label; }

	FName GetNextSpawnLocationLabel() const { return NextSpawnLocationLabel; }

	void OnAlarmStateChanged(AShockPlayer* Player, bool bOn, bool bWasOn, FName SourceLabel);

	void OnCameraAlert(AShockSecurityCamera* Camera);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	int32 SpawnBotsNear(FVector NearLocation, int32 Count, AShockPlayer* Player);

	void DespawnAllBots();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	void DespawnAllBotsForVerify() { DespawnAllBots(); }

	void ApplySecurityShutdown(float Duration);

	void RegisterBot(AShockSecurityBot* Bot);

	void UnregisterBot(AShockSecurityBot* Bot);

	void NotifyBotKilled(AShockSecurityBot* Bot);

	UFUNCTION(BlueprintPure, Category = "BioShock|Security")
	int32 GetActiveBotCountForVerify() const;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	void AdvanceSecurityForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	AShockSecurityBot* SpawnBotForVerify(FVector Location, AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	bool CommandBotsAttackTarget(FName AttackeeLabel);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	bool ActivateBotByLabel(FName BotLabel, FName OwnerLabel);

	FVector ResolveSpawnLocation(UWorld* World, FVector NearLocation) const;

private:
	void ScheduleBotDespawn(float DelaySeconds);

	void TickBotDespawn(float DeltaSeconds);

	void PurgeInvalidBots();

	UPROPERTY()
	TArray<TObjectPtr<AShockSecurityBot>> ActiveBots;

	FName NextSpawnLocationLabel;

	int32 PendingBotSpawnCount = 0;

	float BotDespawnRemaining = -1.0f;

	int32 NextBotIndex = 0;
};
