#pragma once

#include "Components/ActorComponent.h"
#include "ShockTriggerRelayComponent.generated.h"

class AActor;
class UPrimitiveComponent;

/**
 * Bridges an imported TriggerBox / TriggerSphere into UShockScriptRegistry::DispatchMessage.
 *
 * On player overlap → EnterMessageClass (default MessageTriggerVolumeEnter) with SourceLabel =
 * the volume's actor label. Optional EndOverlap → ExitMessageClass (MessageTriggerVolumeExit /
 * MessageTriggerExit). One-shot by default (matches triggerOnlyOnce when present).
 *
 * SCR-G20: TriggerOnlyByLabels / TriggeredByFilter / TriggerOnlyByClasses from the regionActor
 * export gate who may fire. MaxEnterCount / RequireClearTrace are not in the export — use
 * bTriggerOnlyOnce (enter once) when present.
 */
UCLASS(ClassGroup = (BioShock), meta = (BlueprintSpawnableComponent))
class BIOSHOCKRUNTIME_API UShockTriggerRelayComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	UShockTriggerRelayComponent();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	FString VolumeLabel;

	/** When true, only the first overlapping player fires enter. Safe default when export omits the flag. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	bool bTriggerOnlyOnce = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	bool bDisabled = false;

	/** When true (default), only AShockPlayer overlaps count — unless FilterLabels is non-empty. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	bool bPlayerOnly = true;

	/**
	 * UE2 triggeredByFilter / TriggerOnlyByLabels. When non-empty, only actors whose message
	 * source label is in this list may fire (Medical almost always lists Player).
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	TArray<FString> FilterLabels;

	/**
	 * UE2 TriggerOnlyByClasses — short class names from the export. When non-empty, OtherActor's
	 * class name must match one entry (IgnoreCase); empty means no class gate.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	TArray<FString> FilterClassNames;

	/** UE2 class for begin-overlap. TriggerVolume → MessageTriggerVolumeEnter; TriggerRadius → MessageTriggerEnter. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	FName EnterMessageClass = FName(TEXT("MessageTriggerVolumeEnter"));

	/**
	 * UE2 class for end-overlap. NAME_None disables exit dispatch.
	 * TriggerVolume → MessageTriggerVolumeExit; TriggerRadius → MessageTriggerExit.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Trigger")
	FName ExitMessageClass;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Trigger")
	void Configure(const FString& InLabel, bool bInTriggerOnlyOnce, bool bInDisabled);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Trigger")
	void ConfigureMessages(FName InEnterMessageClass, FName InExitMessageClass);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Trigger")
	void ConfigureFilters(const TArray<FString>& InFilterLabels, const TArray<FString>& InFilterClassNames);

	/** Create or reuse a relay on Owner; binds Begin/End overlap on the first primitive with overlap events. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Trigger")
	static UShockTriggerRelayComponent* InstallOnActor(
		AActor* Owner,
		const FString& InLabel,
		bool bInTriggerOnlyOnce = true,
		bool bInDisabled = false,
		FName InEnterMessageClass = FName(TEXT("MessageTriggerVolumeEnter")),
		FName InExitMessageClass = FName(TEXT("MessageTriggerVolumeExit")));

	/** Headless: fire enter as if a player overlapped (skips actor-type filter). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Trigger")
	int32 FireForVerify();

	/** Headless: fire exit as if a player left (skips actor-type filter). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Trigger")
	int32 FireExitForVerify();

	/** Headless: evaluate filter against a candidate actor (does not dispatch). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Trigger")
	bool PassesFiltersForVerify(AActor* OtherActor) const { return PassesFilters(OtherActor); }

	UFUNCTION(BlueprintPure, Category = "BioShock|Trigger")
	bool HasFired() const { return bHasFired; }

protected:
	virtual void BeginPlay() override;

private:
	void BindOverlap();
	bool PassesFilters(AActor* OtherActor) const;

	UFUNCTION()
	void OnBeginOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex,
		bool bFromSweep,
		const FHitResult& SweepResult);

	UFUNCTION()
	void OnEndOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex);

	int32 DispatchNow(FName MessageClass);

	bool bHasFired = false;
	bool bBound = false;
};
