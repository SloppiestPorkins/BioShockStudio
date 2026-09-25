#pragma once

#include "Engine/GameInstance.h"
#include "ShockDifficulty.h"
#include "ShockGameInstance.generated.h"

class AShockPlayer;
class UShockCarryState;
class UShockLoadingScreen;
class UShockVariableScope;

/** Persists carry state across OpenLevel. Set in DefaultEngine.ini via setup_playable_slice.py. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockGameInstance : public UGameInstance
{
	GENERATED_BODY()

public:
	virtual void Init() override;
	virtual void Shutdown() override;

	UPROPERTY()
	TObjectPtr<UShockCarryState> PendingCarryState;

	/**
	 * Shared script variables whose names start with Global_ (SCR-B03). Lives on the game
	 * instance so values survive TravelToLevel / OpenLevel the same way PendingCarryState does.
	 * Not written into UShockSaveGame yet — saves only capture carry/inventory (follow-up).
	 */
	UPROPERTY()
	TObjectPtr<UShockVariableScope> GlobalVariables;

	UPROPERTY()
	bool bHasPendingArrival = false;

	UPROPERTY(BlueprintReadOnly, Category = "BioShock|Difficulty")
	EShockDifficulty SelectedDifficulty = EShockDifficulty::Medium;

	/**
	 * When true, New Game / Travel helpers record the destination but skip OpenLevel.
	 * Headless frontend verify sets this so travel can be asserted without tearing down the editor.
	 */
	UPROPERTY(BlueprintReadWrite, Category = "BioShock|Travel")
	bool bSuppressLevelTravel = false;

	UPROPERTY(BlueprintReadOnly, Category = "BioShock|Travel")
	FString LastTravelRequestMap;

	UPROPERTY(BlueprintReadOnly, Category = "BioShock|Travel")
	FString LastTravelOptions;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Difficulty")
	void SetSelectedDifficulty(EShockDifficulty Diff) { SelectedDifficulty = Diff; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Difficulty")
	EShockDifficulty GetSelectedDifficulty() const { return SelectedDifficulty; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Travel")
	bool HasPendingArrival() const { return bHasPendingArrival && PendingCarryState != nullptr; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Travel")
	FName GetPendingArrivalStartLabel() const;

	void SetPendingCarry(UShockCarryState* State, FName StartLabel);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel")
	void SetPendingCarryForVerify(UShockCarryState* State, FName StartLabel) { SetPendingCarry(State, StartLabel); }

	/** Restore onto Player, clear pending, log BIOSHOCK_ARRIVED. Returns false when nothing pending. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel")
	bool ConsumePendingArrival(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel")
	void ClearPendingArrival();

	/**
	 * OpenLevel with ShockGameMode options, unless bSuppressLevelTravel.
	 * Always records LastTravelRequestMap / LastTravelOptions.
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel", meta = (WorldContext = "WorldContextObject"))
	void RequestTravelToLevel(
		UObject* WorldContextObject,
		const FString& MapPackagePath,
		const FString& TravelOptions = TEXT("game=/Script/BioShockRuntime.ShockGameMode"));

	UFUNCTION(BlueprintCallable, Category = "BioShock|Travel", meta = (WorldContext = "WorldContextObject"))
	static UShockGameInstance* GetShockInstanceForVerify(UObject* WorldContextObject);

	static UShockGameInstance* GetShockInstance(const UWorld* World);

	/** Lazy-create the Global_ variable store (survives map travel with this game instance). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	UShockVariableScope* EnsureGlobalVariables();

private:
	void HandlePreLoadMap(const FString& MapName);
	void HandlePostLoadMap(UWorld* LoadedWorld);

	UPROPERTY(Transient)
	TObjectPtr<UShockLoadingScreen> ActiveLoadingScreen = nullptr;
};
