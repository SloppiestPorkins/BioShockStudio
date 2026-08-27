#pragma once

#include "ShockAction.h"
#include "ShockActionTeleportPawnToLocation.generated.h"

class UWorld;

/**
 * UnrealScript `ActionTeleportPawnToLocation`: move PawnLabel to MarkerLabel transform.
 * TeleportInWorld finds both by editor actor label and moves the pawn.
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

	/** Find PawnLabel + MarkerLabel in World; teleport pawn to marker transform. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool TeleportInWorld(UWorld* World);
};
