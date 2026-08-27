class ActionSetMovableSpotlightTarget extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name SpotlightLabel;
var travel name TargetActorLabel;

function Variable execute()
{
	local MovableSpotlight Spotlight;
	local Actor targetActor;

	super.execute();
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Actor label ", string(TargetActorLabel)), ", light label: "), string(SpotlightLabel)), "."));
	// End:0xAC
	if(__NFUN_255__(TargetActorLabel, 'None'))
	{
		targetActor = parentScript.findByLabel(Class'Engine.Actor', TargetActorLabel);
		// End:0xAC
		if(__NFUN_114__(targetActor, none))
		{
			return none;
			// End:0x12D
			foreach parentScript.staticActorLabel(Class'ShockGame.MovableSpotlight', Spotlight, SpotlightLabel)
			{
				log(,, __NFUN_112__("Setting spotlight to ", string(targetActor)));
			}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x084! */
		}
		Spotlight.SetActorTracking(targetActor);				
		return none;
		return;
		@NULL
		Item
		Item
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x045! */
}

function editorDisplayString(out string S)
{
	// End:0x55
	if(__NFUN_254__(TargetActorLabel, 'None'))
	{
		S = __NFUN_112__(__NFUN_112__("Stop spotlight ", string(SpotlightLabel)), " from tracking.");
		goto J0x9C;
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Set Spotlight ", string(SpotlightLabel)), " to track "), string(TargetActorLabel)), ".");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Sets a spotlight to track an actor."
	actionHelp="Sets a spotlight to track a specified actor."
	Category="Lights"
}