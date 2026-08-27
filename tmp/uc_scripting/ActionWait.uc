class ActionWait extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel float Seconds;

function Variable latentExecute()
{
	local float WakeTime;

	resolveParameters();
	WakeTime = __NFUN_174__(parentScript.Level.TimeSeconds, Seconds);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x9A
	/*@Error*/
	__NFUN_256__(0.0000000);
	// [Loop Continue]
	goto J0x42;
	return none;
	return;
	@NULL
	MessageTriggerVolume
	Variable
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
	S = __NFUN_112__(__NFUN_112__("Wait ", propertyDisplayString('Seconds')), " second");
	// End:0x5C
	if(__NFUN_181__(Seconds, 1.0000000))
	{
		S = __NFUN_112__(S, "s");
		return;
		@NULL
		Variable
		Variable
	}
	@NULL
}

defaultproperties
{
	Seconds=1.0000000
	actionDisplayName="Wait n seconds"
	actionHelp="Suspends this script for n seconds"
	Category="Script"
	bIsGameCritical=false
}