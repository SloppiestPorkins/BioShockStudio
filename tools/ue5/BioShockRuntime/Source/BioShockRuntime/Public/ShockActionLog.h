#pragma once

#include "ShockAction.h"
#include "ShockActionLog.generated.h"

/** UnrealScript `ActionLog`: write Text to the log (variable expansion not ported). */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionLog : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionLog();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Text;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastLoggedText;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InText);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetText() const { return Text; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastLoggedText() const { return LastLoggedText; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool Emit();
};
