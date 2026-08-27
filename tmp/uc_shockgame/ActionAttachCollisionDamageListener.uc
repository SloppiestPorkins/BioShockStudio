class ActionAttachCollisionDamageListener extends Action
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name TargetLabel;
var name OwnerLabel;

function AttachListener(ReactiveActor Target, Actor Owner)
{
	//native.Target;
	//native.Owner;	
	@NULL
	@NULL
}

function Variable execute()
{
	local ReactiveActor Target;
	local Actor Owner;

	super.execute();
	// End:0x47
	if(__NFUN_255__(OwnerLabel, 'None'))
	{
		Owner = findByLabel(Class'Engine.Actor', OwnerLabel);
		Target = ReactiveActor(findByLabel(Class'VengeanceShared.ReactiveActor', TargetLabel));
	}
	AttachListener(Target, Owner);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_168__("Attaches a collision damage listener to", string(TargetLabel));
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Attaches collision damage listener to actor"
	actionHelp="Attaches a collision listener to an actor that does damage to whatever the object hits"
	Category="Physics"
}