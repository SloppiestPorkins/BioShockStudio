#pragma once

#include "GameFramework/Actor.h"
#include "ShockScript.generated.h"

class UShockScriptRegistry;
class UShockScriptRunner;

/**
 * First-slice stand-in for UnrealScript level-placed `Script` actors.
 *
 * Owns a UShockScriptRunner; Tick drives TickExecution with world time.
 * Not a full Script.uc port: no Concepts, no message UObject copies, no auto BeginPlay
 * register from package defaults — callers Configure + SetRegistry (or EnsureRegistry).
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockScript : public AActor
{
	GENERATED_BODY()

public:
	AShockScript();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UShockScriptRunner> Runner;

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void Configure(FName InLabel, const FString& InTriggeredBy);

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	UShockScriptRunner* GetRunner() const { return Runner; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	void SetRegistry(UShockScriptRegistry* InRegistry);

	/** Create a registry owned by this actor if none is set, then register Runner. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	UShockScriptRegistry* EnsureRegistry();

	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	UShockScriptRegistry* GetRegistry() const;

	/** Advance Runner with World->GetTimeSeconds() (or OverrideTimeSeconds if >= 0). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Script")
	bool TickScript(float OverrideTimeSeconds = -1.0f);

	virtual void Tick(float DeltaSeconds) override;

protected:
	virtual void BeginPlay() override;
};
