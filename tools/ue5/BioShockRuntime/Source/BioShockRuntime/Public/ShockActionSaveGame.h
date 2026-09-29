#pragma once

#include "ShockAction.h"
#include "ShockActionSaveGame.generated.h"

class UWorld;

/** UnrealScript `ActionSaveGame` (ShockGame.U): a name-based scripted checkpoint save, distinct
 * from the player's own numbered save/load menu slots. ApplyInWorld captures the local player's
 * current carry state and writes it via UShockSaveGame::SaveScripted. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSaveGame : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionSaveGame();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString SaveGameName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastSavedName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastSaveOk = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InSaveGameName);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetSaveGameName() const { return SaveGameName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastSavedName() const { return LastSavedName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastSaveOk() const { return bLastSaveOk; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSave();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
