#pragma once

#include "ShockAction.h"
#include "ShockActionAwardAchievement.generated.h"

/** UnrealScript `ActionAwardAchievement` (Scripting.U). Records Achievement name; no platform API. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAwardAchievement : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAwardAchievement();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Achievement;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAchievement;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAchievement);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAchievement() const { return LastAchievement; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestAward();
};
