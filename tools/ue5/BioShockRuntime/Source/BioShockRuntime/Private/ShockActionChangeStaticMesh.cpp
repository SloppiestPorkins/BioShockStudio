#include "ShockActionChangeStaticMesh.h"

#include "EngineUtils.h"
#include "GameFramework/Actor.h"

UShockActionChangeStaticMesh::UShockActionChangeStaticMesh()
{
	ActionClassName = TEXT("ActionChangeStaticMesh");
	TargetLabel = TEXT("UNSPECIFIED");
}

void UShockActionChangeStaticMesh::Configure(FName InTarget, FName InMesh)
{
	TargetLabel = InTarget;
	StaticMeshName = InMesh;
}

bool UShockActionChangeStaticMesh::RequestChange()
{
	if (TargetLabel.IsNone())
	{
		return false;
	}
	LastTargetLabel = TargetLabel;
	return true;
}

int32 UShockActionChangeStaticMesh::ApplyInWorld(UWorld* World)
{
	if (!RequestChange() || !World)
	{
		return 0;
	}
	const FString Want = TargetLabel.ToString();
	for (TActorIterator<AActor> It(World); It; ++It)
	{
		AActor* Actor = *It;
		if (!Actor)
		{
			continue;
		}
#if WITH_EDITOR
		if (!Actor->GetActorLabel().Equals(Want, ESearchCase::CaseSensitive))
		{
			continue;
		}
		if (!StaticMeshName.IsNone())
		{
			const FName MeshTag(*FString::Printf(TEXT("ShockMesh_%s"), *StaticMeshName.ToString()));
			Actor->Tags.AddUnique(MeshTag);
		}
		return 1;
#endif
	}
	return 0;
}
