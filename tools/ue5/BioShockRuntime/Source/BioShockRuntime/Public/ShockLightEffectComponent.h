#pragma once

#include "Components/ActorComponent.h"
#include "ShockLightEffectComponent.generated.h"

class AActor;
class ULightComponent;

/** UE2 ELightType subset mapped onto a ticking intensity modulator (SCR-G07). */
UENUM(BlueprintType)
enum class EShockLightEffectType : uint8
{
	None = 0,
	Steady = 1,
	Pulse = 2,
	Blink = 3,
	Flicker = 4,
	Strobe = 5,
	SubtlePulse = 6,
};

/**
 * Attached to a light actor when ActionSetLightProperties changes LightType.
 * Steady / None are static; Flicker / Blink / Pulse / Strobe / SubtlePulse modulate intensity.
 */
UCLASS(ClassGroup = (BioShock), meta = (BlueprintSpawnableComponent))
class BIOSHOCKRUNTIME_API UShockLightEffectComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UShockLightEffectComponent();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Light")
	EShockLightEffectType EffectType = EShockLightEffectType::Steady;

	/** UE2 LightPeriod — length of one cycle in approximate seconds (byte/scale APPROXIMATED). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Light")
	float PeriodSeconds = 1.0f;

	/** UE2 LightPhase — offset into the cycle [0,1]. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Light")
	float Phase01 = 0.0f;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Light")
	float BaseIntensity = 1.0f;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Light")
	void Configure(
		EShockLightEffectType InType,
		float InBaseIntensity,
		float InPeriodSeconds,
		float InPhase01);

	/**
	 * Same as Configure, but the effect type is a plain int (EShockLightEffectType's ordinal).
	 * The Python API for this project's UE version cannot nativize an EnumProperty from a bare
	 * int or string, and this UENUM is never otherwise reflected into `unreal.*`, so a caller
	 * driving this from an importer script (SCR-G07 / W-BUG-03) has no other way to name a value.
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Light")
	void ConfigureFromInt(
		int32 InTypeOrdinal,
		float InBaseIntensity,
		float InPeriodSeconds,
		float InPhase01);

	UFUNCTION(BlueprintPure, Category = "BioShock|Light")
	uint8 GetEffectTypeForVerify() const { return static_cast<uint8>(EffectType); }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Light")
	static UShockLightEffectComponent* EnsureOnActor(AActor* Owner);

	virtual void TickComponent(
		float DeltaTime,
		ELevelTick TickType,
		FActorComponentTickFunction* ThisTickFunction) override;

private:
	ULightComponent* ResolveLight() const;
	float Elapsed = 0.0f;
};
