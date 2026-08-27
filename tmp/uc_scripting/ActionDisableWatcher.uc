class ActionDisableWatcher extends ActionSetWatcherEnabled
	editinlinenew
	collapsecategories
	hidecategories(Object);

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Disable watcher ", propertyDisplayString('scriptName')), "."), propertyDisplayString('watcherName'));
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Disable Watcher"
	actionHelp="Disables a watcher in a given script"
	Category="Watch"
}