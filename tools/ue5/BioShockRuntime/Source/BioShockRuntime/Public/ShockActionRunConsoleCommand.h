#pragma once

#include "ShockAction.h"
#include "ShockActionRunConsoleCommand.generated.h"

/** UnrealScript `ActionRunConsoleCommand` (debug). Records Command; does not execute console. */
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

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InCommand);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetCommand() const { return Command; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastCommand() const { return LastCommand; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestRun();
};
