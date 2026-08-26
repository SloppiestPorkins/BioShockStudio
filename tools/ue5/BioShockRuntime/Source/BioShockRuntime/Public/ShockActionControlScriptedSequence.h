#pragma once

#include "ShockAction.h"
#include "ShockActionControlScriptedSequence.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionControlScriptedSequence : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionControlScriptedSequence();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 RunNow = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LastRunNow = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTargetLabel, int32 InRunNow);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLastRunNow() const { return LastRunNow; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestControl();
};
