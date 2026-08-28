#pragma once

#include "ShockAction.h"
#include "ShockActionInitiateQuest.generated.h"

class UWorld;

/**
 * UnrealScript `ActionInitiateQuest` (ActionQuestBase): QuestName + HUD + SetAsActiveQuest.
 * First slice records the initiate request; no quest system yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionInitiateQuest : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionInitiateQuest();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName QuestName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShowHUDFeedBack = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bSetAsActiveQuest = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString NewQuestMessage;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastQuestName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InQuest, bool bInShowHud, bool bInSetActive, const FString& InMessage);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetSetAsActiveQuest() const { return bSetAsActiveQuest; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastQuestName() const { return LastQuestName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestInitiate();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
