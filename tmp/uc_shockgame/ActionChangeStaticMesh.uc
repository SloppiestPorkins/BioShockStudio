class ActionChangeStaticMesh extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name TargetLabel;
var travel StaticMesh StaticMesh;

function Variable execute()
{
	local Actor Target;

	super.execute();
	Target = parentScript.findByLabel(Class'Engine.Actor', TargetLabel);
	AssertWithDescription(__NFUN_119__(Target, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("The Script named ", string(parentScript.Name)), " tried to execute an ActionChangeStaticMesh on a Target defined by having the Label '"), string(TargetLabel)), "', but no such target was found."));
	Target.SetStaticMesh(StaticMesh);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Change static mesh on '", string(TargetLabel)), "' to static mesh '"), string(StaticMesh)), "'.");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	TargetLabel="UNSPECIFIED"
	actionDisplayName="Change a StaticMesh on an actor"
	actionHelp="Changes the StaticMesh of an Actor."
	Category="Actor"
}