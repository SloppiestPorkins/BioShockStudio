class ActionPlayMovie extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name MovieName;

function Variable execute()
{
	super.execute();
	parentScript.Level.GetFlashGUIController().PlayMovie(MovieName);
	return none;
	return;
	@NULL
	Variable
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Play movie ", string(MovieName));
	return;
	@NULL
	Variable
}

defaultproperties
{
	actionDisplayName="Play a Movie"
	actionHelp="Play a Movie"
	Category="Other"
}