#pragma once

#include "ShockAction.h"
#include "ShockActionRunConsoleCommand.generated.h"

class UWorld;

/** UnrealScript `ActionRunConsoleCommand` (debug). ApplyInWorld calls GEngine->Exec. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionRunConsoleCommand : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionRunConsoleCommand();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Command;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastCommand;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bLastExecuted = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InCommand);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetCommand() const { return Command; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastCommand() const { return LastCommand; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetLastExecuted() const { return bLastExecuted; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestRun();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
