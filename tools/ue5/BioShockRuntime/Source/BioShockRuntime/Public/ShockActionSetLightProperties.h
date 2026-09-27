#pragma once

#include "ShockAction.h"
#include "ShockLightEffectComponent.h"
#include "ShockActionSetLightProperties.generated.h"

class AActor;
class UWorld;

/**
 * UnrealScript `ActionSetLightProperties` (Scripting.U). Finds Engine.Light actors by label
 * (`Object`) and optionally writes brightness / colour / type / etc. when each nested
 * `*Property.ChangeProperty` is true.
 *
 * Brightness + colour + LightType (steady vs flicker/pulse/blink) + period/phase (SCR-G07).
 * Shadow / ImportantDynamic flags recorded when ChangeProperty set but not applied to UE5 yet.
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
	bool bChangeLightType = false;

	/** UE2 ELightType name: LT_Steady, LT_Flicker, LT_None, … (with or without LT_ prefix). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LightTypeName = FName(TEXT("LT_Steady"));

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bChangeLightPeriod = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LightPeriod = 1.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bChangeLightPhase = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	float LightPhase = 0.0f;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bChangeCastShadows = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bCastsShadowMapShadows = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAppliedActorName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	uint8 LastAppliedEffectType = 0;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(
		FName InObjectLabel,
		bool bInChangeBrightness,
		float InBrightness,
		bool bInChangeColor,
		FColor InLightColor);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void ConfigureLightType(
		bool bInChangeLightType,
		FName InLightTypeName,
		bool bInChangePeriod,
		float InPeriod,
		bool bInChangePhase,
		float InPhase);

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
	bool GetChangeLightType() const { return bChangeLightType; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLightTypeName() const { return LightTypeName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAppliedActorName() const { return LastAppliedActorName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	uint8 GetLastAppliedEffectType() const { return LastAppliedEffectType; }

	/** Applies enabled brightness/colour/type to Target's first light component. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool ApplyToActor(AActor* Target);

	/** Find actors by ObjectLabel and ApplyToActor each. */
	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);

	static EShockLightEffectType ParseLightTypeName(FName TypeName);
};
