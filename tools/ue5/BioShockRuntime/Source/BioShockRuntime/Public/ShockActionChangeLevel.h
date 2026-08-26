#pragma once

#include "ShockAction.h"
#include "ShockActionChangeLevel.generated.h"

/** UnrealScript `ActionChangeLevel`. Records map travel options; no ServerTravel yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionChangeLevel : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionChangeLevel();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString MapName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString StartLocationLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShowLoadingMessage = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bPersist = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FString LastMapName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(const FString& InMap, const FString& InStart, bool bInShowLoading, bool bInPersist);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetPersist() const { return bPersist; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FString GetLastMapName() const { return LastMapName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestChange();
};
