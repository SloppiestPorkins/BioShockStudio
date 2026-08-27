class ActionGathererCrawlThroughDoor extends TyrionScriptAction implements IInterestedPawnDied
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;
var travel name DoorLabel;
var travel bool bShouldUnlock;
var travel bool bShouldRun;
var travel bool bShouldBeAggressive;
var private Gatherer Gatherer;
var private ThreeStateDoor Door;
var private AI_Goal CrawlGoal;

function waitForGoal(AI_Goal Goal)
{
	J0x00:
	// End:0x4C [Loop If]
	if(__NFUN_130__(Class'Engine.Pawn'.static.checkAlive(Gatherer), __NFUN_129__(Goal.hasCompleted())))
	{
		__NFUN_256__(0.1000000);
		// [Loop Continue]
		goto J0x00;
		return;
		@NULL
		EcologyAI
		CommanderAction
	}
	@NULL
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	// End:0x21
	if(__NFUN_114__(DeadPawn, Gatherer))
	{
		CleanupCrawlGoal();
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function CleanupCrawlGoal()
{
	// End:0x29
	if(__NFUN_119__(CrawlGoal, none))
	{
		CrawlGoal.__NFUN_198__();
		CrawlGoal = none;
		return;
		@NULL
		EcologyCommanderAction
	}
	EcologyFighterCommanderAction
}

function Variable latentExecute()
{
	execute();
	Door = ThreeStateDoor(findByLabel(Class'ShockGame.ThreeStateDoor', DoorLabel));
	AssertWithDescription(__NFUN_119__(Door, none), __NFUN_112__("ActionGathererCrawlThroughDoor was called with a label for a non-existent door or one that the gatherer cannot crawl through. DoorLabel=", string(DoorLabel)));
	Gatherer = Gatherer(findByLabel(Class'ShockAI.Gatherer', Target));
	AssertWithDescription(__NFUN_119__(Gatherer, none), __NFUN_112__("ActionGathererCrawlThroughDoor was called with a label for a non-existent gatherer. target=", string(Target)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x310
	/*@Error*/
	Gatherer.Level.RegisterNotifyPawnDied(self);
	// End:0x201
	if(bShouldBeAggressive)
	{
		Gatherer.BecomeAggressive();
		goto J0x218;
		Gatherer.BecomePassive();
		// End:0x23F
		if(bShouldRun)
		{
			Gatherer.SetShouldRun();
			goto J0x256;
			Gatherer.SetShouldWalk();
			CrawlGoal = Class'ShockAI.CrawlThroughDoorGoal'.static.Allocate(self).;
		}
		construct_AI_ResourceThreeStateDoorBool(Gatherer.CharacterAI, Door, bShouldUnlock);
		CrawlGoal.postGoal(none).__NFUN_199__();
	}
	waitForGoal(CrawlGoal);
	CleanupCrawlGoal();
	Gatherer.Level.UnRegisterNotifyPawnDied(self);
	return none;
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_168__(__NFUN_168__(__NFUN_168__("Gatherer", propertyDisplayString('Target')), "crawls through"), string(DoorLabel));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7A
	/*@Error*/
	S = __NFUN_168__(S, "and unlocks it");
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	bShouldUnlock=true
	actionDisplayName="Gatherer crawls through a door"
	actionHelp="Gatherer crawls through a door"
	Category="AI"
}