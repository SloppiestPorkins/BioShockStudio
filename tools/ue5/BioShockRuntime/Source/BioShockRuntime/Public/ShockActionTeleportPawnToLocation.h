#pragma once

#include "ShockAction.h"
#include "ShockActionTeleportPawnToLocation.generated.h"

/**
 * UnrealScript `ActionTeleportPawnToLocation`: move PawnLabel to MarkerLabel transform.
 * First slice records the teleport request; no pawn move yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionTeleportPawnToLocation : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionTeleportPawnToLocation();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName PawnLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MarkerLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastPawnLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastMarkerLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InPawnLabel, FName InMarkerLabel);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastPawnLabel() const { return LastPawnLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastMarkerLabel() const { return LastMarkerLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestTeleport();
};
