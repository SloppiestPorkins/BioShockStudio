#pragma once

#include "ShockAction.h"
#include "ShockActionSetLightProperties.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionSetLightProperties` (Scripting.U). Finds Engine.Light actors by label
 * (`Object`) and optionally writes brightness / colour / type / etc. when each nested
 * `*Property.ChangeProperty` is true.
 *
 * First slice: Object label + brightness + colour with ChangeProperty flags. Applies to the
 * first ULightComponentBase on the target actor (UE5 intensity = BioShock LightBrightness scale).
 * LightType / period / phase / shadow flags are still UNKNOWN here.
 *
 * Note: decompiled `LightBrightnessProperty` lists no value field (sibling structs do); the float
 * is inferred from Engine.Light's LightBrightness and level-import mapping — not from a recovered
 * .uc var line.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionSetLightProperties : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionSetLightProperties();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ObjectLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bChangeBrightness = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float Brightness = 1.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bChangeColor = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FColor LightColor = FColor::White;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAppliedActorName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(
		FName InObjectLabel,
		bool bInChangeBrightness,
		float InBrightness,
		bool bInChangeColor,
		FColor InLightColor);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetObjectLabel() const { return ObjectLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetChangeBrightness() const { return bChangeBrightness; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	float GetBrightness() const { return Brightness; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetChangeColor() const { return bChangeColor; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FColor GetLightColor() const { return LightColor; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAppliedActorName() const { return LastAppliedActorName; }

	/** Applies enabled brightness/colour to Target's first light component. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToActor(AActor* Target);

	/** Find actors by ObjectLabel and ApplyToActor each. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
