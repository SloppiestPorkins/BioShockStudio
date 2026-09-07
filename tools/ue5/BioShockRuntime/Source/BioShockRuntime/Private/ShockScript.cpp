#include "ShockScript.h"

#include "Engine/World.h"
#include "ShockScriptRegistry.h"
#include "ShockScriptRunner.h"
#include "ShockScriptSubsystem.h"

AShockScript::AShockScript()
{
	PrimaryActorTick.bCanEverTick = true;
	PrimaryActorTick.bStartWithTickEnabled = true;
	Runner = CreateDefaultSubobject<UShockScriptRunner>(TEXT("Runner"));
}

void AShockScript::Configure(FName InLabel, const FString& InTriggeredBy)
{
	if (!Runner)
	{
		Runner = NewObject<UShockScriptRunner>(this, TEXT("Runner"));
	}
	Runner->Configure(InLabel);
	Runner->SetTriggeredBy(InTriggeredBy);
}

void AShockScript::SetRegistry(UShockScriptRegistry* InRegistry)
{
	if (!Runner)
	{
		return;
	}
	Runner->SetRegistry(InRegistry);
}

UShockScriptRegistry* AShockScript::EnsureRegistry()
{
	if (!Runner)
	{
		Runner = NewObject<UShockScriptRunner>(this, TEXT("Runner"));
	}
	if (Runner->Registry)
	{
		return Runner->Registry;
	}
	// Prefer the world-shared registry so DispatchMessage reaches every script in the level.
	if (UWorld* World = GetWorld())
	{
		if (UShockScriptSubsystem* Sub = UShockScriptSubsystem::Get(World))
		{
			UShockScriptRegistry* Shared = Sub->GetOrCreateRegistry();
			Runner->SetRegistry(Shared);
			return Shared;
		}
	}
	UShockScriptRegistry* Owned = NewObject<UShockScriptRegistry>(this, TEXT("Registry"));
	Runner->SetRegistry(Owned);
	return Owned;
}

UShockScriptRegistry* AShockScript::GetRegistry() const
{
	return Runner ? Runner->Registry.Get() : nullptr;
}

bool AShockScript::TickScript(float OverrideTimeSeconds)
{
	if (!Runner)
	{
		return false;
	}
	float TimeSeconds = OverrideTimeSeconds;
	if (TimeSeconds < 0.0f)
	{
		const UWorld* World = GetWorld();
		TimeSeconds = World ? World->GetTimeSeconds() : 0.0f;
	}
	return Runner->TickExecution(TimeSeconds);
}

void AShockScript::BeginPlay()
{
	Super::BeginPlay();
	if (!Runner)
	{
		return;
	}
	// Always bind to THIS world's shared registry at play time. import_scripts.py sets a
	// registry at editor time; that reference is stale (or null) once the map is reloaded for
	// play, and EnsureRegistry()'s early-out on a non-null Registry would then leave the runner
	// registered nowhere — so level-entry DispatchMessage never reached LoadRoomDoor etc.
	UShockScriptRegistry* Shared = nullptr;
	if (UWorld* World = GetWorld())
	{
		if (UShockScriptSubsystem* Sub = UShockScriptSubsystem::Get(World))
		{
			Shared = Sub->GetOrCreateRegistry();
		}
	}
	if (Shared && Runner->Registry != Shared)
	{
		Runner->SetRegistry(Shared);
	}
	else if (!Runner->Registry)
	{
		EnsureRegistry();
	}
}

void AShockScript::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	TickScript(-1.0f);
}
