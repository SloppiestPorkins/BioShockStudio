#include "ShockActionSetActorLabel.h"

#include "GameFramework/Actor.h"

UShockActionSetActorLabel::UShockActionSetActorLabel()
{
	ActionClassName = TEXT("ActionSetActorLabel");
}

void UShockActionSetActorLabel::Configure(FName InActorLabel, FName InNewLabel)
{
	ActorLabel = InActorLabel;
	NewLabel = InNewLabel;
}

bool UShockActionSetActorLabel::ApplyToActor(AActor* Target)
{
	if (!Target || NewLabel.IsNone())
	{
		return false;
	}
#if WITH_EDITOR
	Target->SetActorLabel(NewLabel.ToString());
	LastNewLabel = NewLabel;
	return Target->GetActorLabel() == NewLabel.ToString();
#else
	return false;
#endif
}
