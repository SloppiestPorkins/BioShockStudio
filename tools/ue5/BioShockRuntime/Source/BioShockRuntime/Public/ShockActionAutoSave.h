#pragma once

#include "ShockAction.h"
#include "ShockActionAutoSave.generated.h"

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAutoSave : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionAutoSave();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Command = TEXT("savegame autosave");
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InCommand);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetCommand() const { return Command; }
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSave();
};
