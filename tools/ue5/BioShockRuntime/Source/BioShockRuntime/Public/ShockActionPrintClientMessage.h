#pragma once

#include "ShockAction.h"
#include "ShockActionPrintClientMessage.generated.h"

class UWorld;

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPrintClientMessage : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionPrintClientMessage();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString MessageText;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MessageType;
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastPrintedText;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InText, FName InType);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastPrintedText() const { return LastPrintedText; }
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestPrint();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
