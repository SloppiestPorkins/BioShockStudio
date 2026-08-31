#pragma once

#include "ShockAction.h"
#include "ShockActionHackTurret.generated.h"

class UWorld;

/** UnrealScript `ActionHackTurret`. ApplyInWorld stores hacked flag on ShockPlayer by turret label. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionHackTurret : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionHackTurret();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TurretLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bSetHacked = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTurretLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTurret, bool bInHacked);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetSetHacked() const { return bSetHacked; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTurretLabel() const { return LastTurretLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestHack();

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
