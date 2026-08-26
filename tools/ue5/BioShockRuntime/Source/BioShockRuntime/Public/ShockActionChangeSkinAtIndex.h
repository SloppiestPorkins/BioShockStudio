#pragma once

#include "ShockAction.h"
#include "ShockActionChangeSkinAtIndex.generated.h"

/**
 * UnrealScript `ActionChangeSkinAtIndex`: SetSkin(Index, Material) on TargetLabel.
 * First slice records the skin change; no mesh material apply yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangeSkinAtIndex : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangeSkinAtIndex();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName TargetLabel;

	/** Material object path / name from schema (object ref not resolved yet). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MaterialName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 Index = 0;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastTargetLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	int32 LastIndex = -1;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, FName InMaterial, int32 InIndex);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetIndex() const { return Index; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastTargetLabel() const { return LastTargetLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 GetLastIndex() const { return LastIndex; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestChangeSkin();
};
