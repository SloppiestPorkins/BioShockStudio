#include "ShockAudioLibrary.h"

#include "Components/AudioComponent.h"
#include "Components/SceneComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Sound/SoundBase.h"

namespace
{
FString SafeAudioName(FString Value)
{
	for (TCHAR& Character : Value)
	{
		if (!FChar::IsAlnum(Character) && Character != TEXT('_'))
		{
			Character = TEXT('_');
		}
	}
	if (Value.IsEmpty())
	{
		Value = TEXT("Unnamed");
	}
	if (FChar::IsDigit(Value[0]))
	{
		Value.InsertAt(0, TEXT('_'));
	}
	return Value;
}

USoundBase* LoadGeneratedSound(const FString& Folder, const FString& Name)
{
	const FString Safe = SafeAudioName(Name);
	const FString Path = FString::Printf(
		TEXT("/Game/BioShockAudio/_1_Medical/%s/%s.%s"),
		*Folder,
		*Safe,
		*Safe);
	return LoadObject<USoundBase>(nullptr, *Path);
}
}

FString UShockAudioLibrary::CueObjectPath(FName CueName)
{
	const FString Safe = SafeAudioName(CueName.ToString());
	return FString::Printf(
		TEXT("/Game/BioShockAudio/_1_Medical/Cues/%s.%s"),
		*Safe,
		*Safe);
}

FString UShockAudioLibrary::EventObjectPath(FName SourceClassName, FName EventName)
{
	const FString Safe = SafeAudioName(SourceClassName.ToString() + TEXT("__") + EventName.ToString());
	return FString::Printf(
		TEXT("/Game/BioShockAudio/_1_Medical/Events/%s.%s"),
		*Safe,
		*Safe);
}

USoundBase* UShockAudioLibrary::LoadCue(FName CueName)
{
	return CueName.IsNone() ? nullptr : LoadGeneratedSound(TEXT("Cues"), CueName.ToString());
}

USoundBase* UShockAudioLibrary::LoadEventCue(FName SourceClassName, FName EventName)
{
	if (SourceClassName.IsNone() || EventName.IsNone())
	{
		return nullptr;
	}
	return LoadGeneratedSound(
		TEXT("Events"),
		SourceClassName.ToString() + TEXT("__") + EventName.ToString());
}

UAudioComponent* UShockAudioLibrary::SpawnCueAttached(
	FName CueName,
	USceneComponent* AttachTo,
	FName SocketName)
{
	USoundBase* Sound = LoadCue(CueName);
	if (!Sound || !AttachTo)
	{
		return nullptr;
	}
	return UGameplayStatics::SpawnSoundAttached(
		Sound,
		AttachTo,
		SocketName,
		FVector::ZeroVector,
		FRotator::ZeroRotator,
		EAttachLocation::KeepRelativeOffset,
		true);
}

UAudioComponent* UShockAudioLibrary::SpawnEventAttached(
	FName SourceClassName,
	FName EventName,
	USceneComponent* AttachTo)
{
	USoundBase* Sound = LoadEventCue(SourceClassName, EventName);
	if (!Sound || !AttachTo)
	{
		return nullptr;
	}
	return UGameplayStatics::SpawnSoundAttached(
		Sound,
		AttachTo,
		NAME_None,
		FVector::ZeroVector,
		FRotator::ZeroRotator,
		EAttachLocation::KeepRelativeOffset,
		true);
}

UAudioComponent* UShockAudioLibrary::SpawnCueAtLocation(
	UWorld* World,
	FName CueName,
	FVector Location)
{
	USoundBase* Sound = LoadCue(CueName);
	if (!World || !Sound)
	{
		return nullptr;
	}
	return UGameplayStatics::SpawnSoundAtLocation(World, Sound, Location);
}
