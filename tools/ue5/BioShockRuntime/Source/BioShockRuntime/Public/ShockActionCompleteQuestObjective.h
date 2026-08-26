#pragma once

#include "ShockAction.h"
#include "ShockActionCompleteQuestObjective.generated.h"

/**
 * UnrealScript `ActionCompleteQuestObjective` (ActionQuestBase).
 * Records QuestName + NumberOfObjectivesCompleted (default 1).
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionCompleteQuestObjective : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionCompleteQuestObjective();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName QuestName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShowHUDFeedBack = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 NumberOfObjectivesCompleted = 1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastQuestName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InQuest, bool bInShowHud, int32 InCount);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetNumberOfObjectivesCompleted() const { return NumberOfObjectivesCompleted; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastQuestName() const { return LastQuestName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestComplete();
};
