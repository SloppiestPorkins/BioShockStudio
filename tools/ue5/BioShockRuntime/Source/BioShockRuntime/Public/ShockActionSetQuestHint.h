#pragma once

#include "ShockAction.h"
#include "ShockActionSetQuestHint.generated.h"

class UWorld;

/**
 * UnrealScript `actionSetQuestHint` (lowercase class name in ShockGame.U).
 * Records QuestName + HintName; no quest UI yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetQuestHint : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetQuestHint();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName QuestName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName HintName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastHintName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InQuest, FName InHint);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastHintName() const { return LastHintName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSet();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
