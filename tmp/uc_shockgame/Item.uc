class Item extends Object
	abstract
	native
	config(Inventory);

var config int MaximumStackSize;
var config localized string Description;
var config localized string FriendlyName;
var config Material Icon;
var config float CreditValue;
var config bool JunkItem;
var config name ItemDisplayCategory;
var config int ItemDisplayPriority;
var private name PickedUpEffectEventName;

defaultproperties
{
	MaximumStackSize=1
	Description="Item Description Not Yet Configured In Inventory.ini for this Item"
	FriendlyName="The 'FriendlyName' field needs to be configured in Inventory.ini for this Item"
	ItemDisplayCategory="Misc"
	PickedUpEffectEventName="PickedUpItem"
}