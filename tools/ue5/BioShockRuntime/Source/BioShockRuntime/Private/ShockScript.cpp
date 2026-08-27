#include "ShockScript.h"

#include "Engine/World.h"
#include "ShockScriptRegistry.h"
#include "ShockScriptRunner.h"

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
	if (Runner && Runner->Registry == nullptr)
	{
		EnsureRegistry();
	}
}

void AShockScript::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);
	TickScript(-1.0f);
}
