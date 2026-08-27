class CraftingFormula extends QuestLog
	native
	config(Crafting);

struct native atomic ComponentRequirement
{
	var config Class<Item> ItemClass;
	var config int Amount;
};

var config array<ComponentRequirement> RequiredComponents;
var config Class<Pickup> PickupClass;
var config Class<Item> ItemClass;
var config int Amount;
var config bool RemoveFormulaAfterCraftingOnce;

defaultproperties
{
	LogType="Formula"
	PickedUpEffectEventName="PickedUpCraftingFormula"
}