#pragma once

#include "CoreMinimal.h"
#include "ShockStationTypes.generated.h"

/** One stocked SKU on a Circus of Values / El Ammo Bandito machine. */
USTRUCT(BlueprintType)
struct BIOSHOCKRUNTIME_API FShockVendItem
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Vend")
	FName ItemClass = NAME_None;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Vend")
	FString DisplayName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Vend")
	int32 Price = 10;

	/** Price after the machine is hacked (cheaper). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Vend")
	int32 HackedPrice = 5;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Vend")
	int32 Stock = 1;

	/** Extra units unlocked when hacked. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Vend")
	int32 HackedBonusStock = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Vend")
	int32 StackPerPurchase = 1;
};

/** U-Invent recipe: consume InventoryStacks components, grant ResultItem. */
USTRUCT(BlueprintType)
struct BIOSHOCKRUNTIME_API FShockCraftRecipe
{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Craft")
	FString DisplayName;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Craft")
	FName ResultItem = NAME_None;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Craft")
	int32 ResultStack = 1;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Craft")
	TMap<FName, int32> Components;
};

UENUM(BlueprintType)
enum class EShockStationKind : uint8
{
	Vending UMETA(DisplayName = "Vending"),
	GeneBank UMETA(DisplayName = "Gene Bank"),
	UInvent UMETA(DisplayName = "U-Invent"),
	GathererGarden UMETA(DisplayName = "Gatherer's Garden"),
	ComboLock UMETA(DisplayName = "Combo Lock"),
	HealthStation UMETA(DisplayName = "Health Station"),
};

UENUM(BlueprintType)
enum class EShockGardenUpgrade : uint8
{
	HealthMax UMETA(DisplayName = "+Health max"),
	EveMax UMETA(DisplayName = "+EVE max"),
	PlasmidSlot UMETA(DisplayName = "Extra plasmid slot"),
	BuyPlasmid UMETA(DisplayName = "Buy plasmid"),
};
