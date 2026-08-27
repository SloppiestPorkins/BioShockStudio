class ActionForceGathererInteractable extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name GathererLabel;
var travel bool ForceInteractable;

function Variable latentExecute()
{
	local Gatherer targetGatherer;

	execute();
	targetGatherer = Gatherer(findByLabel(Class'ShockAI.Gatherer', GathererLabel));
	AssertWithDescription(__NFUN_119__(targetGatherer, none), __NFUN_112__("ActionForceGathererInteractable was called with a label for non-existent gatherer. GathererLabel=", string(GathererLabel)));
	targetGatherer.SetSaveOrPacifyExternallyEnabled(ForceInteractable);
	return none;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Force the gatherer labeled '", string(GathererLabel)), "' to be interactable.");
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	actionDisplayName="Force Gatherer Interactable"
	actionHelp="Force a gatherer to the interactable state (can be saved or pacified)."
	Category="AI"
}