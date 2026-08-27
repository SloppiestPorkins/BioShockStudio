class Watcher extends WatcherBase
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel bool watchedExpression;

function Variable execute()
{
	// End:0x11
	if(__NFUN_129__(enabled))
	{
		return none;
		super(Action).execute();
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x91
	/*@Error*/
	enabled = false;
	parentScript.dispatchMessage(Class'Scripting.MessageWatcher'.static.Allocate(self)., construct_NameName(parentScript.Label, watcherName));
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Send a watch message when ", propertyDisplayString('watchedExpression')), " is true");
	return;
	@NULL
}

state LookAtExpression
{	J0x00:
	// End:0x22 [Loop If]
	if(enabled)
	{
		__NFUN_256__(1.0000000);
		execute();
		// [Loop Continue]
		goto J0x00;
		stop;		
	}
	@NULL
}

defaultproperties
{
	actionDisplayName="Watcher"
	actionHelp="Sends a watcher message if the watched expression is true"
	Category="Watch"
}