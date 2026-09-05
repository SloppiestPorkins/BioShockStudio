#pragma once

#include "CoreMinimal.h"
#include "ShockDifficulty.generated.h"

/** BioShock New Game difficulty (Feral Remastered manual wording). */
UENUM(BlueprintType)
enum class EShockDifficulty : uint8
{
	Easy UMETA(DisplayName = "Easy"),
	Medium UMETA(DisplayName = "Medium"),
	Hard UMETA(DisplayName = "Hard"),
	Survivor UMETA(DisplayName = "Survivor"),
};

namespace ShockDifficultyText
{
inline const TCHAR* DisplayName(EShockDifficulty Diff)
{
	switch (Diff)
	{
	case EShockDifficulty::Easy:
		return TEXT("Easy");
	case EShockDifficulty::Medium:
		return TEXT("Medium");
	case EShockDifficulty::Hard:
		return TEXT("Hard");
	case EShockDifficulty::Survivor:
		return TEXT("Survivor");
	default:
		return TEXT("?");
	}
}

/** One-line descriptions from the Remastered manual. */
inline const TCHAR* Description(EShockDifficulty Diff)
{
	switch (Diff)
	{
	case EShockDifficulty::Easy:
		return TEXT("You're new to shooters.");
	case EShockDifficulty::Medium:
		return TEXT("You've played other shooters.");
	case EShockDifficulty::Hard:
		return TEXT("You've played a lot of shooters.");
	case EShockDifficulty::Survivor:
		return TEXT("Every bullet counts.");
	default:
		return TEXT("");
	}
}
}
