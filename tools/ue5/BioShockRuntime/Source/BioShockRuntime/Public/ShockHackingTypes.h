#pragma once

#include "ShockHackingTypes.generated.h"

/** Pipe geometry on a hacking board tile (BioShock pipe-puzzle stand-in). */
UENUM(BlueprintType)
enum class EShockHackTileType : uint8
{
	Empty UMETA(DisplayName = "Empty"),
	Straight UMETA(DisplayName = "Straight"),
	Elbow UMETA(DisplayName = "Elbow"),
	Tee UMETA(DisplayName = "T"),
	Cross UMETA(DisplayName = "Cross"),
	Source UMETA(DisplayName = "Source"),
	Target UMETA(DisplayName = "Target"),
};

/** Hazard triggered when fluid enters the tile. */
UENUM(BlueprintType)
enum class EShockHackHazard : uint8
{
	None UMETA(DisplayName = "None"),
	SpeedUp UMETA(DisplayName = "Speed-Up"),
	Overload UMETA(DisplayName = "Overload"),
	Alarm UMETA(DisplayName = "Alarm"),
};

UENUM(BlueprintType)
enum class EShockHackResult : uint8
{
	Playing UMETA(DisplayName = "Playing"),
	Won UMETA(DisplayName = "Won"),
	Failed UMETA(DisplayName = "Failed"),
};

/**
 * One cell on the hacking board.
 * Rotation is 0..3 quarter-turns clockwise; ports are derived from Type + Rotation.
 */
USTRUCT(BlueprintType)
struct BIOSHOCKRUNTIME_API FShockHackTile
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Hacking")
	EShockHackTileType Type = EShockHackTileType::Empty;

	/** 0..3 quarter-turns clockwise from the type's canonical port mask. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Hacking")
	int32 Rotation = 0;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Hacking")
	bool bRevealed = true;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Hacking")
	EShockHackHazard Hazard = EShockHackHazard::None;
};
