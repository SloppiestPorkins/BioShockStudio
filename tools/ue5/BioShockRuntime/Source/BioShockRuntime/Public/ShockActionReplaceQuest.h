#pragma once

#include "ShockAction.h"
#include "ShockActionReplaceQuest.generated.h"

/** UnrealScript `ActionReplaceQuest` (ActionQuestBase). Records replace request; no quests yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionReplaceQuest : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionReplaceQuest();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName QuestName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ReplacementQuestName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCopyObjectivesCompleted = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString UpdatedMessage;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastReplacementQuestName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InQuest, FName InReplacement, bool bInCopy, const FString& InMessage);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastReplacementQuestName() const { return LastReplacementQuestName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetUpdatedMessage() const { return UpdatedMessage; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestReplace();
};
