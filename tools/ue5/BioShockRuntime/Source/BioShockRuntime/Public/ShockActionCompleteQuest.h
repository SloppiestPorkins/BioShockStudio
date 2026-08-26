#pragma once

#include "ShockAction.h"
#include "ShockActionCompleteQuest.generated.h"

/** UnrealScript `ActionCompleteQuest` (ActionQuestBase). Records QuestName; no quests yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionCompleteQuest : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionCompleteQuest();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName QuestName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShowHUDFeedBack = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastQuestName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InQuest, bool bInShowHud);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastQuestName() const { return LastQuestName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestComplete();
};
