#pragma once

#include "Components/ActorComponent.h"
#include "ShockTriggerRelayComponent.generated.h"

class AActor;
class UPrimitiveComponent;

/**
 * Bridges an imported TriggerBox (UE2 TriggerVolume) into UShockScriptRegistry::DispatchMessage.
 *
 * On player overlap → MessageTrigger with SourceLabel = the volume's actor label so scripts whose
 * TriggeredBy lists that label start. One-shot by default (matches triggerOnlyOnce when present).
 */
UCLASS(ClassGroup = (BioShock), meta = (BlueprintSpawnableComponent))
class BIOSHOCKRUNTIME_API UShockTriggerRelayComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UShockTriggerRelayComponent();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	FString VolumeLabel;

	/** When true, only the first overlapping player fires. Safe default when export omits the flag. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	bool bTriggerOnlyOnce = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	bool bDisabled = false;

	/** When true (default), only AShockPlayer overlaps count. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	bool bPlayerOnly = true;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Trigger")
	void Configure(const FString& InLabel, bool bInTriggerOnlyOnce, bool bInDisabled);

	/** Create or reuse a relay on Owner; binds BeginOverlap on the first primitive with overlap events. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Trigger")
	static UShockTriggerRelayComponent* InstallOnActor(
		AActor* Owner,
		const FString& InLabel,
		bool bInTriggerOnlyOnce = true,
		bool bInDisabled = false);

	/** Headless: fire as if a player overlapped (skips actor-type filter). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Trigger")
	int32 FireForVerify();

	UFUNCTION(BlueprintPure, Category = "BioShock|Trigger")
	bool HasFired() const { return bHasFired; }

protected:
	virtual void BeginPlay() override;

private:
	void BindOverlap();

	UFUNCTION()
	void OnBeginOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex,
		bool bFromSweep,
		const FHitResult& SweepResult);

	int32 DispatchNow();

	bool bHasFired = false;
	bool bBound = false;
};
