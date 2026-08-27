class ActionClearContainer extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ContainerLabel;

function Variable execute()
{
	local IHaveAContainer ContainerOwner;
	local Container Container;
	local int i;

	super.execute();
	ContainerOwner = IHaveAContainer(findByLabel(Class'Engine.Actor', ContainerLabel));
	// End:0xB0
	if(__NFUN_114__(ContainerOwner, none))
	{
		log(,, __NFUN_112__(__NFUN_112__("ActionRemoveItemFromContainer: Could not find a container with the label '", string(ContainerOwner)), "'."));
		return none;
		Container = ContainerOwner.GetContainer();
		// End:0x138
		if(__NFUN_114__(Container, none))
		{
		}
		else
		{
			log(,, __NFUN_112__(__NFUN_112__("ActionRemoveItemFromContainer: No container specified in '", string(ContainerOwner)), "'."));
			return none;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x18F
			/*@Error*/
			Container.AddItem(i, none);
		}
	}
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x143;
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Remove all items from ", string(ContainerLabel)), ".");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Remove all items from a container."
	actionHelp="Removes and destroys all items in a container."
	Category="Container"
}