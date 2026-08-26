#include "ShockActionAISpeech.h"

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
