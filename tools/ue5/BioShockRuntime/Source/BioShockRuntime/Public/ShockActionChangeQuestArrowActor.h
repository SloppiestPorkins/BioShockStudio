#pragma once

#include "ShockAction.h"
#include "ShockActionChangeQuestArrowActor.generated.h"

/**
 * UnrealScript `ActionChangeQuestArrowActor` (ActionQuestBase).
 * Records QuestName + ArrowActor labels; no quest arrow yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangeQuestArrowActor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangeQuestArrowActor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName QuestName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ArrowActor;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ArrowActorLevelLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastArrowActor;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InQuest, FName InArrow, FName InLevelLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastArrowActor() const { return LastArrowActor; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestChange();
};
