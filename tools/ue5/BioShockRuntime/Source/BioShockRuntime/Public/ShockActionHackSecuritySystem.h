#pragma once

#include "ShockAction.h"
#include "ShockActionHackSecuritySystem.generated.h"

class UWorld;

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionHackSecuritySystem : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionHackSecuritySystem();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float ShutdownTime = 30.f;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(float InSeconds);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetShutdownTime() const { return ShutdownTime; }
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestHack();
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
