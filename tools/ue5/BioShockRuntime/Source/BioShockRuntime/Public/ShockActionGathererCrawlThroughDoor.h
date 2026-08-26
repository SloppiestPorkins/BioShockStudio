#pragma once

#include "ShockAction.h"
#include "ShockActionGathererCrawlThroughDoor.generated.h"

/** UnrealScript `ActionGathererCrawlThroughDoor`. Records crawl params; no Tyrion goal yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionGathererCrawlThroughDoor : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionGathererCrawlThroughDoor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName Target;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName DoorLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShouldUnlock = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShouldRun = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bShouldBeAggressive = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastDoorLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InTarget, FName InDoor, bool bInUnlock, bool bInRun, bool bInAggressive);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetShouldUnlock() const { return bShouldUnlock; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastDoorLabel() const { return LastDoorLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestCrawl();
};
