#pragma once

#include "ShockAction.h"
#include "ShockActionGetNumItemsInPlayersInventory.generated.h"

/**
 * ShockGame.ActionGetNumItemsInPlayersInventory ("Get Number of Items in Inventory"): returns
 * VariableFloat(the player's stack count of ItemClass). An expression node: Medical's Fisheries
 * quarantine gate binds BooleanStatement61.lhs to one of these (ItemClass SteinmanQuarantineKey)
 * through resolveInfoList, so the gate only opens while the player holds Steinman's key.
 */
UCLASS(BlueprintType)
class BIOSHOCKRUNTIME_API UShockActionGetNumItemsInPlayersInventory : public UShockAction
{
	GENERATED_BODY()

public:
	UShockActionGetNumItemsInPlayersInventory();

	/** UnrealScript Class<Item> ItemClass, carried as the class name (e.g. SteinmanQuarantineKey). */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	FName ItemClass;

	UFUNCTION(BlueprintCallable, Category="BioShock|Action")
	void Configure(FName InItemClass);

	virtual bool ApplyInWorld(const FShockActionContext& Ctx) override;
};
