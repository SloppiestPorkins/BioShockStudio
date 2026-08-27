class ActionEnableWatcher extends ActionSetWatcherEnabled
	editinlinenew
	collapsecategories
	hidecategories(Object);

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Enable watcher ", propertyDisplayString('scriptName')), "."), propertyDisplayString('watcherName'));
	return;
	@NULL
}

defaultproperties
{
	enabled=true
	actionDisplayName="Enable Watcher"
	actionHelp="Enables a watcher in a given script"
	Category="Watch"
}