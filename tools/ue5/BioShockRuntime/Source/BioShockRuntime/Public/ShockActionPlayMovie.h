#pragma once

#include "ShockAction.h"
#include "ShockActionPlayMovie.generated.h"

/** UnrealScript `ActionPlayMovie`. Records MovieName; no FlashGUI play yet. */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionPlayMovie : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionPlayMovie();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName MovieName;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastMovieName;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InMovie);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastMovieName() const { return LastMovieName; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestPlay();
};
