class MessageWatcher extends Message
	editinlinenew
	hidecategories(Object);

var name scriptName;
var name watcherName;

function Construct(name _scriptName, name _watcherName)
{
	scriptName = _scriptName;
	watcherName = _watcherName;
	return;
	@NULL
	Variable
	GetPropertyTextByName
	@NULL
}

function string editorDisplay(name TriggeredBy, Message filter)
{
	return __NFUN_112__("A watcher message from ", string(TriggeredBy));
	return;
	@NULL
}

defaultproperties
{
	specificTo=Class'Scripting.Script'
}