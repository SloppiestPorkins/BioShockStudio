class ActionGetNumItemsInContainer extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Class<Item> ItemClass;
var travel name ContainerLabel;

function Variable execute()
{
	local IHaveAContainer theContainer;
	local int total, i;
	local ItemStack stack;

	super.execute();
	theContainer = IHaveAContainer(findByLabel(Class'Engine.Actor', ContainerLabel));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x130
	/*@Error*/
	// End:0xF8
	if(__NFUN_114__(ItemClass, none))
	{
		i = 0;
		// End:0xF5
		if(__NFUN_150__(i, Class'ShockGame.Container'.3))
		{
			stack = theContainer.GetContainer().GetItem(i);
			// End:0xE7
			if(__NFUN_119__(stack, none))
			{
				__NFUN_161__(total, stack.StackSize);
				__NFUN_163__(i);
				// [Loop Continue]
				goto J0x62;
				goto J0x130;
				total = theContainer.GetContainer().GetNumberOfItems(ItemClass);
				return newTemporaryVariable(Class'Scripting.VariableFloat', string(total));
			}
			return;
		}
		@NULL
	}
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x63
	if(__NFUN_114__(ItemClass, none))
	{
		S = __NFUN_112__("Get the total number of items in the container labeled: ", string(ContainerLabel));
		goto J0xBC;
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Get the number of <", string(ItemClass)), "> in the container labeled: "), string(ContainerLabel));
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Get Number of Items in a Container"
	actionHelp="Returns the number of items in the specified container"
	returnType=Class'Scripting.Variable'
	Category="Inventory"
}