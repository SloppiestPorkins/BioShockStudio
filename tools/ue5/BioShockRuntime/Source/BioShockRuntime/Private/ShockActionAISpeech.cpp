#include "ShockActionAISpeech.h"

#include "ShockAudioLibrary.h"
#include "ShockPawn.h"
#include "Components/AudioComponent.h"

UShockActionAISpeech::UShockActionAISpeech()
{
	ActionClassName = TEXT("ActionAISpeech");
}

void UShockActionAISpeech::Configure(FName InAILabel, FName InSpeechEvent, bool bInStopSpeech)
{
	AILabel = InAILabel;
	SpeechEventLabel = InSpeechEvent;
	bStopSpeech = bInStopSpeech;
}

bool UShockActionAISpeech::RequestSpeech()
{
	if (AILabel.IsNone() || SpeechEventLabel.IsNone())
	{
		return false;
	}
	LastAILabel = AILabel;
	LastSpeechEventLabel = SpeechEventLabel;
	return true;
}

bool UShockActionAISpeech::ApplyInWorld(const FShockActionContext& Ctx)
{
	if (!RequestSpeech() || !Ctx.World)
	{
		return false;
	}

	if (bStopSpeech)
	{
		if (ActiveSpeechComponent)
		{
			ActiveSpeechComponent->Stop();
			ActiveSpeechComponent = nullptr;
		}
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_AUDIO speech stop ai=%s event=%s"),
			*AILabel.ToString(),
			*SpeechEventLabel.ToString());
		return true;
	}

	for (AShockPawn* Pawn : AShockPawn::CollectLabeled(Ctx.World, AILabel))
	{
		if (!Pawn)
		{
			continue;
		}
		ActiveSpeechComponent = UShockAudioLibrary::SpawnEventAttached(
			TEXT("ShockAI"),
			SpeechEventLabel,
			Pawn->GetRootComponent());
		if (ActiveSpeechComponent)
		{
			UE_LOG(
				LogTemp,
				Display,
				TEXT("BIOSHOCK_AUDIO speech ai=%s event=%s component=1"),
				*AILabel.ToString(),
				*SpeechEventLabel.ToString());
			return true;
		}
	}

	UE_LOG(
		LogTemp,
		Warning,
		TEXT("BIOSHOCK_AUDIO speech unresolved ai=%s event=%s"),
		*AILabel.ToString(),
		*SpeechEventLabel.ToString());
	return false;
}
