#pragma once

#include "ShockAction.h"
#include "ShockActionAISpeech.generated.h"

/**
 * UnrealScript `ActionAISpeech`: PlaySpeech / StopSpeech on AI by label.
 * First slice records the speech request; no speech system yet.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionAISpeech : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionAISpeech();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName AILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName SpeechEventLabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	bool bStopSpeech = false;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastAILabel;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName LastSpeechEventLabel;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InAILabel, FName InSpeechEvent, bool bInStopSpeech);

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool GetStopSpeech() const { return bStopSpeech; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastAILabel() const { return LastAILabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	FName GetLastSpeechEventLabel() const { return LastSpeechEventLabel; }

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	bool RequestSpeech();
};
