class ActionStartTimer extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel float Seconds;

function Variable execute()
{
	super.execute();
	parentScript.__NFUN_280__(Seconds, false);
	return none;
	return;
	@NULL
	Variable
	Variable
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Start timer for ", propertyDisplayString('Seconds')), " second");
	// End:0x67
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
	actionDisplayName="Start Timer"
	actionHelp="Starts a timer that will send a timer expired message after n seconds."
	Category="Script"
}