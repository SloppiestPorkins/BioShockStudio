#pragma once

#include "ShockAction.h"
#include "ShockActionToggleQuestVisibility.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionToggleQuestVisibility : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionToggleQuestVisibility();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName QuestName;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastQuestName;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InQuest);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestToggle();
};
