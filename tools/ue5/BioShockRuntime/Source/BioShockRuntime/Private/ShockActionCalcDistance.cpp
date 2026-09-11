#include "ShockActionCalcDistance.h"

#include "GameFramework/Actor.h"
#include "ShockPhysicsLibrary.h"

UShockActionCalcDistance::UShockActionCalcDistance()
{
	ActionClassName = TEXT("ActionCalcDistance");
}

void UShockActionCalcDistance::Configure(FName InActorOne, FName InActorTwo)
{
	ActorOne = InActorOne;
	ActorTwo = InActorTwo;
}

bool UShockActionCalcDistance::ApplyInWorld(const FShockActionContext& Ctx)
{
	ClearReturnValue();
	AActor* A = UShockPhysicsLibrary::FindActorByLabel(Ctx.World, ActorOne);
	AActor* B = UShockPhysicsLibrary::FindActorByLabel(Ctx.World, ActorTwo);
	if (!A || !B)
	{
		return false;
	}
	SetReturnValueText(LexToString(FVector::Distance(A->GetActorLocation(), B->GetActorLocation())), TEXT("VariableFloat"));
	return true;
}
