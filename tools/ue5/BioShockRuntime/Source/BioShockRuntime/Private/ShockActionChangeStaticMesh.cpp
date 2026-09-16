#include "ShockActionChangeStaticMesh.h"

#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "GameFramework/Actor.h"
#include "ShockScriptReflection.h"

namespace
{
	UStaticMesh* LoadAuthoredMesh(FName MeshName)
	{
		if (MeshName.IsNone())
		{
			return nullptr;
		}

		FString Value = MeshName.ToString();
		Value.TrimStartAndEndInline();
		Value.RemoveFromStart(TEXT("StaticMesh'"));
		Value.RemoveFromEnd(TEXT("'"));

		if (Value.StartsWith(TEXT("/Game/")))
		{
			if (UStaticMesh* Direct = LoadObject<UStaticMesh>(nullptr, *Value))
			{
				return Direct;
			}
		}

		FString Leaf = Value;
		int32 Separator = INDEX_NONE;
		if (Leaf.FindLastChar(TEXT('.'), Separator) || Leaf.FindLastChar(TEXT('/'), Separator))
		{
			Leaf = Leaf.Mid(Separator + 1);
		}
		if (Leaf.IsEmpty())
		{
			return nullptr;
		}

		static const TCHAR* MeshRoots[] = {
			TEXT("/Game/BioShockSlice/Content/Meshes"),
			TEXT("/Game/BioShockLevel/Content/Meshes"),
		};
		for (const TCHAR* Root : MeshRoots)
		{
			const FString PackagePath = FString::Printf(TEXT("%s/%s"), Root, *Leaf);
			const FString ObjectPath = FString::Printf(TEXT("%s.%s"), *PackagePath, *Leaf);
			if (UStaticMesh* Mesh = LoadObject<UStaticMesh>(nullptr, *ObjectPath))
			{
				return Mesh;
			}
		}
		return nullptr;
	}
}

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
	AActor* Target = ShockScriptReflection::ResolveTargetActor(World, TargetLabel);
	UStaticMesh* Mesh = LoadAuthoredMesh(StaticMeshName);
	if (!Target || !Mesh)
	{
		return 0;
	}
	UStaticMeshComponent* Component = Target->FindComponentByClass<UStaticMeshComponent>();
	if (!Component)
	{
		return 0;
	}
	Component->SetStaticMesh(Mesh);
	return Component->GetStaticMesh() == Mesh ? 1 : 0;
}

bool UShockActionChangeStaticMesh::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
