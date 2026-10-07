#include "ShockBakedLightLibrary.h"

#include "Components/StaticMeshComponent.h"
#include "Engine/StaticMesh.h"
#include "Rendering/ColorVertexBuffer.h"
#include "StaticMeshComponentLODInfo.h"
#include "StaticMeshResources.h"

namespace
{
	struct FAxisMap
	{
		int32 Axis[3];
		float Sign[3];
		float Scale;

		FVector Apply(const FVector& P) const
		{
			return FVector(Sign[0] * P[Axis[0]], Sign[1] * P[Axis[1]], Sign[2] * P[Axis[2]]) * Scale;
		}
	};

	FBox BoundsOf(const TArray<FVector>& Points)
	{
		FBox B(ForceInit);
		for (const FVector& P : Points)
		{
			B += P;
		}
		return B;
	}
}

int32 UShockBakedLightLibrary::ApplyBakedVertexLight(UStaticMeshComponent* Component,
	const TArray<FVector>& SourcePositions, const TArray<FColor>& SourceColors)
{
	if (!Component || SourcePositions.Num() == 0 || SourcePositions.Num() != SourceColors.Num())
	{
		return -1;
	}
	UStaticMesh* Mesh = Component->GetStaticMesh();
	if (!Mesh || !Mesh->GetRenderData() || Mesh->GetRenderData()->LODResources.Num() == 0)
	{
		return -1;
	}
	const FStaticMeshLODResources& LOD = Mesh->GetRenderData()->LODResources[0];
	const FPositionVertexBuffer& PosBuf = LOD.VertexBuffers.PositionVertexBuffer;
	const int32 NumRender = PosBuf.GetNumVertices();
	if (NumRender == 0)
	{
		return -1;
	}
	TArray<FVector> Render;
	Render.Reserve(NumRender);
	for (int32 i = 0; i < NumRender; ++i)
	{
		Render.Add(FVector(PosBuf.VertexPosition(i)));
	}
	const FBox RB = BoundsOf(Render);

	// Choose the source->render convention whose transformed bounds best match the render bounds.
	static const int32 Perms[6][3] = {{0, 1, 2}, {0, 2, 1}, {1, 0, 2}, {1, 2, 0}, {2, 0, 1}, {2, 1, 0}};
	static const float Scales[] = {1.f, 100.f, 0.01f};
	FAxisMap Best{};
	double BestErr = TNumericLimits<double>::Max();
	for (const auto& Perm : Perms)
	{
		for (int32 SignBits = 0; SignBits < 8; ++SignBits)
		{
			for (float Scale : Scales)
			{
				FAxisMap M{{Perm[0], Perm[1], Perm[2]},
					{(SignBits & 1) ? -1.f : 1.f, (SignBits & 2) ? -1.f : 1.f, (SignBits & 4) ? -1.f : 1.f}, Scale};
				FBox SB(ForceInit);
				for (const FVector& P : SourcePositions)
				{
					SB += M.Apply(P);
				}
				const double Err = (SB.Min - RB.Min).Size() + (SB.Max - RB.Max).Size();
				if (Err < BestErr)
				{
					BestErr = Err;
					Best = M;
				}
			}
		}
	}

	// Uniform grid over the transformed source points for nearest-neighbour lookup.
	TArray<FVector> Src;
	Src.Reserve(SourcePositions.Num());
	for (const FVector& P : SourcePositions)
	{
		Src.Add(Best.Apply(P));
	}
	const double Diag = FMath::Max(RB.GetSize().Size(), 1.0);
	const double Cell = Diag / 64.0;
	TMap<FIntVector, TArray<int32>> Grid;
	auto CellOf = [Cell](const FVector& P)
	{
		return FIntVector(FMath::FloorToInt(P.X / Cell), FMath::FloorToInt(P.Y / Cell), FMath::FloorToInt(P.Z / Cell));
	};
	for (int32 i = 0; i < Src.Num(); ++i)
	{
		Grid.FindOrAdd(CellOf(Src[i])).Add(i);
	}

	const double Tolerance = Diag * 1e-3 + 0.05;
	TArray<FColor> Colors;
	Colors.SetNumUninitialized(NumRender);
	int32 Matched = 0;
	for (int32 r = 0; r < NumRender; ++r)
	{
		const FIntVector C = CellOf(Render[r]);
		int32 BestIdx = INDEX_NONE;
		double BestD = TNumericLimits<double>::Max();
		for (int32 Ring = 0; Ring <= 2 && BestIdx == INDEX_NONE; ++Ring)
		{
			for (int32 dx = -Ring; dx <= Ring; ++dx)
			for (int32 dy = -Ring; dy <= Ring; ++dy)
			for (int32 dz = -Ring; dz <= Ring; ++dz)
			{
				if (const TArray<int32>* Bucket = Grid.Find(C + FIntVector(dx, dy, dz)))
				{
					for (int32 i : *Bucket)
					{
						const double D = FVector::DistSquared(Src[i], Render[r]);
						if (D < BestD)
						{
							BestD = D;
							BestIdx = i;
						}
					}
				}
			}
		}
		if (BestIdx == INDEX_NONE)
		{
			Colors[r] = FColor::Black;
			continue;
		}
		Colors[r] = SourceColors[BestIdx];
		if (FMath::Sqrt(BestD) <= Tolerance)
		{
			++Matched;
		}
	}

	Component->SetLODDataCount(1, Component->LODData.Num());
	FStaticMeshComponentLODInfo& Info = Component->LODData[0];
	if (Info.OverrideVertexColors)
	{
		BeginReleaseResource(Info.OverrideVertexColors);
		FlushRenderingCommands();
		delete Info.OverrideVertexColors;
	}
	Info.OverrideVertexColors = new FColorVertexBuffer;
	Info.OverrideVertexColors->InitFromColorArray(Colors);
	BeginInitResource(Info.OverrideVertexColors);
	Component->MarkRenderStateDirty();
	Component->Modify();
	return Matched;
}
