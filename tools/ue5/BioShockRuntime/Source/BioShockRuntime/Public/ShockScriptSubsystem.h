#pragma once

#include "Subsystems/WorldSubsystem.h"
#include "ShockScriptSubsystem.generated.h"

class AActor;
class AShockAnimatedProp;
class UShockScriptRegistry;

/**
 * Shared home for the level's UShockScriptRegistry.
 *
 * Every AShockScript / trigger relay / SendTriggerMessage path must use this instance so
 * DispatchMessage fans out to all registered runners. Per-actor EnsureRegistry() without a
 * world used to create isolated registries — messages never reached sibling scripts.
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockScriptSubsystem : public UWorldSubsystem
{
	GENERATED_BODY()

public:
	static UShockScriptSubsystem* Get(const UWorld* World);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Script", meta = (WorldContext = "WorldContextObject"))
	static UShockScriptSubsystem* GetForWorld(UObject* WorldContextObject);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Script", meta = (WorldContext = "WorldContextObject"))
	static UShockScriptRegistry* GetRegistryForWorld(UObject* WorldContextObject);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	UShockScriptRegistry* GetOrCreateRegistry();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	int32 DispatchMessage(FName MessageClassName, const FString& SourceLabel);

	/**
	 * DispatchMessage plus a greppable `BIOSHOCK_MSG class=%s src=%s accepted=%d` Display line.
	 * Prefer this for gameplay senders so PIE logs stay searchable.
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	int32 DispatchMessageLogged(FName MessageClassName, const FString& SourceLabel);

	/** As DispatchMessageLogged, carrying the message's own fields for messageFilter matching. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	int32 DispatchMessageLoggedWithFields(
		FName MessageClassName, const FString& SourceLabel, const TMap<FString, FString>& Fields);

	/**
	 * Message source label for a world actor: AShockPlayer → "Player"; ABaseShockAI → ScriptLabel
	 * (else editor label); otherwise editor actor label / GetName. Empty when Actor is null.
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	static FString ResolveMessageSourceLabel(const AActor* Actor);

	/**
	 * Fire level-entry messages: map short name (e.g. "1-Medical"), plus "All" / "all".
	 * Fresh start → MessageLevelStarted; save restore (pending flag) → MessageSavegameRestored
	 * so _Resume ambient scripts restart (SCR-G11). Idempotent per world play session.
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	void DispatchLevelEntryMessages();

	/** Dispatch with an explicit mode (true = MessageSavegameRestored) — headless verify has no ShockGameInstance. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	void DispatchLevelEntryMessagesMode(bool bSaveRestore);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	void DispatchLevelEntryMessagesForVerify() { DispatchLevelEntryMessages(); }

	/** Reset the one-shot level-entry gate so a headless verify can re-dispatch. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	void ResetLevelEntryDispatchForVerify() { bDidLevelEntryDispatch = false; }

	/**
	 * MessageDoorKeypadUsed under KeypadLabel with Keycode field (SCR-G12). No keypad actor
	 * class yet (SCR-B17); call from verify / future keypad UI.
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	int32 DispatchDoorKeypadUsed(const FString& KeypadLabel, const FString& Keycode);

	/** ScriptableMover registration: MessageTrigger matching TriggeredBy toggles keyframes. */
	void RegisterAnimatedProp(AShockAnimatedProp* Prop);
	void UnregisterAnimatedProp(AShockAnimatedProp* Prop);
	/** Called from the registry after script dispatch so movers hear ActionSendTriggerMessage. */
	int32 NotifyAnimatedProps(FName MessageClassName, const FString& SourceLabel);

	virtual void OnWorldBeginPlay(UWorld& InWorld) override;

private:
	FString ResolveLevelEntryLabel() const;

	UPROPERTY()
	TObjectPtr<UShockScriptRegistry> Registry;

	UPROPERTY()
	TArray<TObjectPtr<AShockAnimatedProp>> RegisteredMovers;

	bool bDidLevelEntryDispatch = false;
};
