class ActionCreateWatcher extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var /*0x00000000-0x00100000*/ export editinline travel WatcherBase newWatcher;

function Variable execute()
{
	super.execute();
	// End:0x6E
	if(__NFUN_119__(newWatcher, none))
	{
		// End:0x4B
		if(newWatcher.enabled)
		{
			newWatcher.__NFUN_113__('LookAtExpression');
			parentScript.addWatcher(newWatcher);
		}
		goto J0x9A;
		logError("Tried to create an empty watcher");
	}
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	local string watcherDisplay, watcherName;

	watcherDisplay = "Do Nothing";
	watcherName = "Nothing";
	// End:0x7A
	if(__NFUN_119__(newWatcher, none))
	{
		newWatcher.editorDisplayString(watcherDisplay);
		watcherName = string(newWatcher.watcherName);
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Create watcher '", watcherName), "' to: "), watcherDisplay);
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	actionDisplayName="Create a new watcher"
	actionHelp="Creates a new watcher and puts it in the scripts watcher list"
	Category="Watch"
}