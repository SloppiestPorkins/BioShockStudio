#pragma once

#include "Subsystems/WorldSubsystem.h"
#include "ShockScriptSubsystem.generated.h"

class AActor;
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

	/**
	 * Message source label for a world actor: AShockPlayer → "Player"; ABaseShockAI → ScriptLabel
	 * (else editor label); otherwise editor actor label / GetName. Empty when Actor is null.
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	static FString ResolveMessageSourceLabel(const AActor* Actor);

	/**
	 * Fire level-entry MessageTriggers: map short name (e.g. "1-Medical"), plus "All" / "all".
	 * Scripts whose TriggeredBy lists those labels start (LoadRoomDoor, MedicalStart, …).
	 * Idempotent per world play session.
	 */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	void DispatchLevelEntryMessages();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Script")
	void DispatchLevelEntryMessagesForVerify() { DispatchLevelEntryMessages(); }

	virtual void OnWorldBeginPlay(UWorld& InWorld) override;

private:
	FString ResolveLevelEntryLabel() const;

	UPROPERTY()
	TObjectPtr<UShockScriptRegistry> Registry;

	bool bDidLevelEntryDispatch = false;
};
