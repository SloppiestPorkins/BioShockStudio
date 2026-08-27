class ActionControlScriptedSequence extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name TargetLabel;
var travel int RunNow;
var travel bool UseProvidedTweenTime;
var travel float ProvidedTweenTime;

function Variable execute()
{
	local ReactiveAnimatedMesh Target;

	super.execute();
	Target = ReactiveAnimatedMesh(parentScript.findByLabel(Class'VengeanceShared.ReactiveAnimatedMesh', TargetLabel));
	AssertWithDescription(__NFUN_119__(Target, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("The Script named ", string(parentScript.Name)), " tried to execute an ActionControlScriptedSequence on a Target defined by having the Label '"), string(TargetLabel)), "', but no such target was found."));
	AssertWithDescription(__NFUN_154__(int(Target.DrawType), int(2)), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("The Script named ", string(parentScript.Name)), " tried to execute an ActionControlScriptedSequence on a Target defined by having the Label '"), string(TargetLabel)), "'.\nThe target was found (named "), string(Target.Name)), "), but it is not DrawType DT_Mesh, so it can't play animations."));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x29E
	/*@Error*/
	Target.ControlScriptedSequence(RunNow, UseProvidedTweenTime, ProvidedTweenTime);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Go to item #", string(RunNow)), " for ReactiveAnimatedMesh labeled "), string(TargetLabel));
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Control a ReactiveAnimatedMesh's ScriptedSequence"
	actionHelp="Alters the flow of control in a ReactiveAnimatedMesh's ScriptedSequence"
	Category="ReactiveActor"
}