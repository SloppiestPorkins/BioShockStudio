class Recycler extends Collectable
	abstract
	native
	config(Inventory);

struct native atomic RecyclerClassValuePair
{
	var config Class<Item> ItemClass;
	var config float RecyclePercentage;
};

var config array<RecyclerClassValuePair> RecyclerValue;
