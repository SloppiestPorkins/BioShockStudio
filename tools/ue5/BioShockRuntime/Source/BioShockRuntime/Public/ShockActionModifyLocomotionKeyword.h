#pragma once

#include "ShockAction.h"
#include "ShockActionModifyLocomotionKeyword.generated.h"

/** UnrealScript `ActionModifyLocomotionKeyword`. Records keyword add/remove; no anim graph yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionModifyLocomotionKeyword : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionModifyLocomotionKeyword();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Keyword;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 KeywordPriority = 1;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bAddKeyword = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAI, FName InKeyword, int32 InPriority, bool bInAdd);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetAddKeyword() const { return bAddKeyword; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestModify();
};
