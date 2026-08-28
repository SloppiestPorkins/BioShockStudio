#pragma once

#include "ShockAction.h"
#include "ShockActionAutoSave.generated.h"

class UWorld;

UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAutoSave : public UShockAction
{
	GENERATED_BODY()
public:
	UShockActionAutoSave();
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString Command = TEXT("savegame autosave");
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastSavedCommand;
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InCommand);
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetCommand() const { return Command; }
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastSavedCommand() const { return LastSavedCommand; }
	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSave();

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	int32 ApplyInWorld(UWorld* World);
};
