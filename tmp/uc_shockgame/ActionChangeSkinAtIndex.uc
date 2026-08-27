class ActionChangeSkinAtIndex extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name TargetLabel;
var travel Material Material;
var travel int Index;

function Variable execute()
{
	local Actor Target;

	super.execute();
	Target = parentScript.findByLabel(Class'Engine.Actor', TargetLabel);
	AssertWithDescription(__NFUN_119__(Target, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("The Script named ", string(parentScript.Name)), " tried to execute an ActionChangeSkinAtIndex on a Target defined by having the Label '"), string(TargetLabel)), "', but no such target was found."));
	Target.SetSkin(Index, Material, true);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Change skin on '", string(TargetLabel)), "' at index "), string(Index)), " to material '"), string(Material)), "'.");
	return;
	@NULL
	Item
	Item
	@NULL
}

function Actor PrecacheGetSkinChangeTarget()
{
	return parentScript.findByLabel(Class'Engine.Actor', TargetLabel);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function Actor PrecacheDoSkinChange()
{
	local Actor Target;

	Target = parentScript.findByLabel(Class'Engine.Actor', TargetLabel);
	Target.SetSkin(Index, Material, true);
	return Target;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

defaultproperties
{
	TargetLabel="UNSPECIFIED"
	actionDisplayName="Change a material on an actor"
	actionHelp="Changes a material of an Actor."
	Category="Actor"
}