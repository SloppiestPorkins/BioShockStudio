class ActionStopScriptedHandAnimationSequence extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable latentExecute()
{
	local Hands theHands;

	theHands = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetHands();
	AssertWithDescription(__NFUN_254__(theHands.__NFUN_284__(), 'PlayingScriptedHandAnimation'), __NFUN_112__(__NFUN_112__("The script '", string(parentScript.Name)), "' attempted to stop a scripted hand animation sequence, but no sequence was being played on the hands."));
	theHands.StopScriptedHandAnimationSequence();
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
	S = " Stop a scripted hand animation sequence";
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Stop a scripted hand animation sequence."
	actionHelp="Stop a scripted hand animation sequence."
	Category="Animation"
}