#include "ShockEffectsSubsystem.h"

#include "Components/AudioComponent.h"
#include "Components/DecalComponent.h"
#include "Components/SceneComponent.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
#include "Kismet/GameplayStatics.h"
#include "Materials/MaterialInterface.h"
#include "ShockAudioLibrary.h"
#include "ShockPlasmidFx.h"

namespace
{
struct FKeywordBundle
{
	const TCHAR* Keyword;
	FName Key;
};

// Substring match on the lower-cased Event+Tag text. Order matters: first match wins, so put
// more specific keywords before broad ones ("electric" before "arc").
const FKeywordBundle GKeywordTable[] = {
	{TEXT("steam"), TEXT("Steam")},
	{TEXT("vapor"), TEXT("Steam")},
	{TEXT("spark"), TEXT("Electric")},
	{TEXT("electric"), TEXT("Electric")},
	{TEXT("shock"), TEXT("Electric")},
	{TEXT("arc"), TEXT("Electric")},
	{TEXT("fire"), TEXT("Fire")},
	{TEXT("flame"), TEXT("Fire")},
	{TEXT("burn"), TEXT("Fire")},
	{TEXT("ignite"), TEXT("Fire")},
	{TEXT("blood"), TEXT("Blood")},
	{TEXT("gore"), TEXT("Blood")},
	{TEXT("wound"), TEXT("Blood")},
	{TEXT("splash"), TEXT("Water")},
	{TEXT("water"), TEXT("Water")},
	{TEXT("drip"), TEXT("Water")},
	{TEXT("wet"), TEXT("Water")},
	{TEXT("smoke"), TEXT("Smoke")},
	{TEXT("dust"), TEXT("Smoke")},
	{TEXT("debris"), TEXT("Smoke")},
	{TEXT("explo"), TEXT("Explosion")},
	{TEXT("blast"), TEXT("Explosion")},
	{TEXT("ice"), TEXT("Ice")},
	{TEXT("frost"), TEXT("Ice")},
	{TEXT("freeze"), TEXT("Ice")},
	{TEXT("frozen"), TEXT("Ice")},
};

const FName GGenericBundleKey(TEXT("Generic"));
} // namespace

UShockEffectsSubsystem* UShockEffectsSubsystem::Get(const UWorld* World)
{
	return World ? World->GetSubsystem<UShockEffectsSubsystem>() : nullptr;
}

UShockEffectsSubsystem* UShockEffectsSubsystem::GetForWorld(UObject* WorldContextObject)
{
	const UWorld* World = WorldContextObject ? WorldContextObject->GetWorld() : nullptr;
	return Get(World);
}

void UShockEffectsSubsystem::EnsureDefaultBundles()
{
	if (bDefaultBundlesSeeded)
	{
		return;
	}
	bDefaultBundlesSeeded = true;

	auto Add = [this](FName Key, FLinearColor Tint, float Life, float Radius, FName Sound = NAME_None) {
		FShockEffectBundle Bundle;
		Bundle.Tint = Tint;
		Bundle.LifeSeconds = Life;
		Bundle.Radius = Radius;
		Bundle.SoundCueName = Sound;
		Bundles.Add(Key, Bundle);
	};

	// No curated per-effect Niagara systems were recovered (docs/research/runtime-brain.md §6) —
	// every bundle leaves NiagaraAssetPath empty so AShockPlasmidFx falls back to its emissive
	// orb, tinted per category. Real per-event assets can populate NiagaraAssetPath later without
	// touching the dispatch code.
	Add(TEXT("Steam"), FLinearColor(0.85f, 0.9f, 0.95f, 1.0f), 0.9f, 30.0f);
	Add(TEXT("Electric"), FLinearColor(0.4f, 0.8f, 1.0f, 1.0f), 0.35f, 26.0f);
	Add(TEXT("Fire"), FLinearColor(1.0f, 0.45f, 0.1f, 1.0f), 0.7f, 32.0f);
	Add(TEXT("Blood"), FLinearColor(0.55f, 0.02f, 0.02f, 1.0f), 0.5f, 20.0f);
	Add(TEXT("Water"), FLinearColor(0.2f, 0.5f, 0.8f, 1.0f), 0.6f, 24.0f);
	Add(TEXT("Smoke"), FLinearColor(0.3f, 0.3f, 0.3f, 1.0f), 1.2f, 34.0f);
	Add(TEXT("Explosion"), FLinearColor(1.0f, 0.6f, 0.1f, 1.0f), 0.8f, 60.0f);
	Add(TEXT("Ice"), FLinearColor(0.7f, 0.9f, 1.0f, 1.0f), 0.8f, 26.0f);
	Add(GGenericBundleKey, FLinearColor(0.9f, 0.9f, 0.9f, 1.0f), 0.5f, 22.0f);
}

const FShockEffectBundle& UShockEffectsSubsystem::ResolveBundle(FName Event, FName Tag)
{
	EnsureDefaultBundles();

	// Exact match: Tag first (more specific when a script sets one), then Event.
	if (!Tag.IsNone())
	{
		if (const FShockEffectBundle* Found = Bundles.Find(Tag))
		{
			LastResolvedBundleKey = Tag;
			return *Found;
		}
	}
	if (!Event.IsNone())
	{
		if (const FShockEffectBundle* Found = Bundles.Find(Event))
		{
			LastResolvedBundleKey = Event;
			return *Found;
		}
	}

	// Keyword heuristic over the combined text — BioShock effect event names are
	// self-describing ("SteamHiss", "ElectricArc", "WoodSplinterBreak", ...).
	const FString Haystack = (Event.ToString() + TEXT("_") + Tag.ToString()).ToLower();
	for (const FKeywordBundle& Entry : GKeywordTable)
	{
		if (Haystack.Contains(Entry.Keyword))
		{
			if (const FShockEffectBundle* Found = Bundles.Find(Entry.Key))
			{
				LastResolvedBundleKey = Entry.Key;
				return *Found;
			}
		}
	}

	LastResolvedBundleKey = GGenericBundleKey;
	return Bundles[GGenericBundleKey];
}

void UShockEffectsSubsystem::RegisterBundle(FName Key, const FShockEffectBundle& Bundle)
{
	EnsureDefaultBundles();
	if (!Key.IsNone())
	{
		Bundles.Add(Key, Bundle);
	}
}

int32 UShockEffectsSubsystem::PlayEffect(AActor* Target, FName Event, FName Tag)
{
	if (!Target)
	{
		return 0;
	}
	UWorld* World = Target->GetWorld();
	if (!World)
	{
		return 0;
	}

	const FShockEffectBundle& Bundle = ResolveBundle(Event, Tag);
	int32 SpawnedCount = 0;

	FShockActiveEffect Active;
	Active.Owner = Target;
	Active.Event = Event;

	AShockPlasmidFx* Fx = AShockPlasmidFx::SpawnBurst(
		World,
		Bundle.NiagaraAssetPath,
		Target->GetActorLocation(),
		Target->GetActorRotation(),
		Bundle.Tint,
		Bundle.LifeSeconds,
		Bundle.Radius,
		Target->GetRootComponent());
	if (Fx)
	{
		Active.FxActor = Fx;
		++SpawnedCount;
	}

	if (!Bundle.SoundCueName.IsNone())
	{
		if (UAudioComponent* Audio = UShockAudioLibrary::SpawnCueAtLocation(
				World, Bundle.SoundCueName, Target->GetActorLocation()))
		{
			Active.Audio = Audio;
			++SpawnedCount;
		}
	}

	if (!Bundle.DecalMaterialPath.IsEmpty())
	{
		if (UMaterialInterface* DecalMaterial =
				LoadObject<UMaterialInterface>(nullptr, *Bundle.DecalMaterialPath))
		{
			UGameplayStatics::SpawnDecalAtLocation(
				World,
				DecalMaterial,
				Bundle.DecalSize,
				Target->GetActorLocation(),
				Target->GetActorRotation(),
				Bundle.LifeSeconds > 0.0f ? Bundle.LifeSeconds * 4.0f : 0.0f);
			++SpawnedCount;
		}
	}

	if (Active.FxActor.IsValid() || Active.Audio.IsValid())
	{
		ActiveEffects.Add(Active);
	}
	return SpawnedCount;
}

int32 UShockEffectsSubsystem::StopEffect(AActor* Target, FName Event)
{
	int32 Stopped = 0;
	for (int32 Index = ActiveEffects.Num() - 1; Index >= 0; --Index)
	{
		FShockActiveEffect& Active = ActiveEffects[Index];
		const bool bOwnerMatches = Active.Owner.Get() == Target;
		const bool bEventMatches = Event.IsNone() || Active.Event == Event;
		if (!bOwnerMatches || !bEventMatches)
		{
			continue;
		}
		if (AShockPlasmidFx* Fx = Active.FxActor.Get())
		{
			Fx->Destroy();
		}
		if (UAudioComponent* Audio = Active.Audio.Get())
		{
			Audio->Stop();
		}
		ActiveEffects.RemoveAt(Index);
		++Stopped;
	}
	return Stopped;
}

void UShockEffectsSubsystem::PushContext(FName Context)
{
	if (!Context.IsNone())
	{
		ContextStack.Add(Context);
	}
}

void UShockEffectsSubsystem::RemoveContext(FName Context)
{
	ContextStack.RemoveSingle(Context);
}
