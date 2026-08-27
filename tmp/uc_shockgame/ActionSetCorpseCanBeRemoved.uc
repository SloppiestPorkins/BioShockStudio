class ActionSetCorpseCanBeRemoved extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name CorpseLabel;
var travel bool bCorpseCanBeRemoved;

function Variable execute()
{
	local BaseShockAI Target;

	super.execute();
	Target = BaseShockAI(parentScript.findByLabel(Class'ShockGame.BaseShockAI', CorpseLabel));
	AssertWithDescription(__NFUN_119__(Target, none), __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("The Script named ", string(parentScript.Name)), " tried to execute an ActionSetCorpseCanBeRemoved on a Corpse defined by having the Label '"), string(CorpseLabel)), "', but no such target was found."));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x140
	/*@Error*/
	__NFUN_164__(Target.DelayCorpseRemoval);
	goto J0x158;
	__NFUN_163__(Target.DelayCorpseRemoval);
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Set bCorpseCanBeRemoved for AI ", string(Name)), " to "), string(bCorpseCanBeRemoved));
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Set bCorpseCanBeRemoved for AI"
	actionHelp="Set bCorpseCanBeRemoved for AI"
	returnType=Class'Scripting.Variable'
	Category="Actor"
}