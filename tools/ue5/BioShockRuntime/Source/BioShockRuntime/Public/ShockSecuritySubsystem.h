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

	/** PLAUSIBLE — concurrent alarm-response bots; guide: up to four on stacked alarms. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security")
	int32 MaxActiveBots = 4;

	/**
	 * Seconds after alarm clear before DespawnAllBots. Guide is silent on post-alarm bot lifetime
	 * (U03). Default -1 = never auto-despawn; bots stay until killed or an explicit shutdown.
	 * Positive values keep the old verify/opt-in delayed clear.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security")
	float BotLifetimeAfterAlarmClearSeconds = -1.0f;

	/** Confirmed against the shipped UnrealEd guide ("The alarm lasts 60 seconds") -- not a
	 * guess. An alarm the player never reaches a Bot Shutdown Panel for still clears itself. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Security")
	float AlarmDurationSeconds = 60.0f;

	void SetRequestedBotCount(int32 Count) { PendingBotSpawnCount = FMath::Max(0, Count); }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
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

	/**
	 * Real-gameplay driver, called every frame from AShockPlayer::Tick. This subsystem is a
	 * plain UWorldSubsystem (not UTickableWorldSubsystem), so nothing ticked it outside the
	 * headless verify harness before this -- AdvanceSecurityForVerify was the ONLY caller of
	 * the bot-despawn timer, meaning bots never auto-despawned and the alarm never
	 * auto-expired during actual play, regardless of how correct the underlying timer logic
	 * was. Shares AdvanceSecurity() with the verify path so both stay in sync.
	 */
	void TickSecurity(float DeltaSeconds);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	AShockSecurityBot* SpawnBotForVerify(FVector Location, AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	bool CommandBotsAttackTarget(FName AttackeeLabel);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Security")
	bool ActivateBotByLabel(FName BotLabel, FName OwnerLabel);

	FVector ResolveSpawnLocation(UWorld* World, FVector NearLocation) const;

	/** Player-relative band + LOS spawn resolve used by alarm bots. */
	FVector ResolveSpawnLocation(
		UWorld* World,
		FVector PlayerLocation,
		bool bVersusAI) const;

private:
	void ScheduleBotDespawn(float DelaySeconds);

	void TickBotDespawn(float DeltaSeconds);

	/** Shared by AdvanceSecurityForVerify and TickSecurity: bot despawn + alarm auto-expiry. */
	void AdvanceSecurity(float DeltaSeconds);

	void PurgeInvalidBots();

	bool HasLineOfSightToPoint(UWorld* World, FVector From, FVector To) const;

	bool IsPathNodeCandidate(const AActor* Actor) const;

	UPROPERTY()
	TArray<TObjectPtr<AShockSecurityBot>> ActiveBots;

	FName NextSpawnLocationLabel;

	int32 PendingBotSpawnCount = 0;

	float BotDespawnRemaining = -1.0f;

	int32 NextBotIndex = 0;

	/** -1 = no alarm running. Set to AlarmDurationSeconds when an alarm starts, counts down. */
	float AlarmRemainingSeconds = -1.0f;

	/** True when the current alarm's source label resolves to an AI (uses 1500–4000 band). */
	bool bAlarmVersusAI = false;

	TWeakObjectPtr<AShockPlayer> AlarmPlayer;
};
