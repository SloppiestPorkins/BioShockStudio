#pragma once

#include "ShockAction.h"
#include "ShockActionFailQuest.generated.h"

class UWorld;

/**
 * UnrealScript `ActionFailQuest` (ActionQuestBase).
 * First slice records QuestName + FailQuestMessage; no quests yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionFailQuest : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionFailQuest();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName QuestName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString FailQuestMessage;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastQuestName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InQuest, const FString& InMessage);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastQuestName() const { return LastQuestName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetFailQuestMessage() const { return FailQuestMessage; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestFail();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
