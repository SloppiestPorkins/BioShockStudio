class ActionStartScriptedHandAnimationSequence extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable latentExecute()
{
	local Hands theHands;

	theHands = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetHands();
	AssertWithDescription(theHands.CanExecuteAction('PlayScriptedHandAnimation'), __NFUN_112__(__NFUN_112__("The script '", string(parentScript.Name)), "' attempted to start a scripted hand animation sequence, but the hands were not in a state where this is permissible."));
	theHands.StartScriptedHandAnimationSequence();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x15D
	/*@Error*/
	__NFUN_256__(0.0000000);
	goto J0x134;
	return none;
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function Variable execute()
{
	super.execute();
	return none;
	return;
	@NULL
}

function editorDisplayString(out string S)
{
	S = " Start a scripted hand animation sequence";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Start a scripted hand animation sequence."
	actionHelp="Start a scripted hand animation sequence."
	Category="Animation"
}