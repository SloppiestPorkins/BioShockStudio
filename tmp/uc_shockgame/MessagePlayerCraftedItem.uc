class MessagePlayerCraftedItem extends Message
	editinlinenew
	hidecategories(Object);

var Class<Item> ItemClass;

function Construct(Class<Item> craftedItemClass)
{
	ItemClass = craftedItemClass;
	return;
	@NULL
	Item
}

static function string editorDisplay(name Instigator, Message filter)
{
	return "The Player crafted an item.";
	return;
}

defaultproperties
{
	specificTo=Class'ShockGame.CraftingStation'
}