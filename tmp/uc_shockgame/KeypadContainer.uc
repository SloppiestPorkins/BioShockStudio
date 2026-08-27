class KeypadContainer extends NonPhysicalStaticMeshContainer implements IHandleMovieEvents
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Movement,Collision);

var(movie) name movie;
var bool isUnlocked;
var private config localized string KeypadFailureText;

function PreBeginPlay()
{
	super(StaticMeshContainer).PreBeginPlay();
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'SelectedValue');
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'CancelKeypad');
	return;
	@NULL
	Item
	Item
}

function PostLoadGame()
{
	super(ReactiveActor).PostLoadGame();
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'SelectedValue');
	Level.GetFlashLiaison().RegisterForMovieEvent(self, 'CancelKeypad');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function Destroyed()
{
	Level.GetFlashLiaison().UnRegisterForAllMovieEvents(self);
	super(ReactiveActor).Destroyed();
	return;
	@NULL
	Item
}

function OnUsed(Pawn Pawn)
{
	// End:0x23
	if(isUnlocked)
	{
		super(StaticMeshContainer).OnUsed(Pawn);
		goto J0x99;
		Level.GetFlashGUIController().PlayMovie(movie);
	}
	Level.GetFlashGUIController().GetPlayingMovie(movie).CallMethodInt("SetHacked", 1);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnMovieEvent(name Event, MovieEventData Data)
{
	local string KeycodeEntered;

	// End:0x36
	if(__NFUN_119__(ShockPlayerController(Level.GetLocalPlayerController()).GetCurrentUsedObject(), self))
	{
		return;
		switch(Event)
		{
			// End:0x131
			case 'SelectedValue':
			}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x031! */
			KeycodeEntered = Data.GetValue('Keys');
			log('Doors',, __NFUN_112__(__NFUN_112__(string(self), ": keycode entered. Keys="), KeycodeEntered));
			dispatchMessage(Class'ShockGame.MessageKeypadContainerUsed'.static.Allocate(self)., construct_StrName(KeycodeEntered, Actor(ShockPlayerController(Level.GetLocalPlayerController()).GetCurrentUseFocus()).Label));
			// End:0x147
			break;
			// End:0x140
			case 'CancelKeypad':
				// End:0x147
				break;
				// End:0xFFFF
				default:
					assert(false);
					Level.GetFlashGUIController().StopMovie(movie);
					break;/* Tried to find Switch scope, found Case instead */
			return;
			@NULL
			Item
			Item/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x02A! */
		@NULL
	}/* !MISMATCHING REMOVE, tried Switch got Type:If Position:0x000! */
}

function KeypadUsed(bool Success)
{
	// End:0x2F
	if(Success)
	{
		TriggerEffectEvent('KeypadSucceeded');
		isUnlocked = true;
		goto J0x79;
		Level.GetLocalPlayerController().ClientMessage(KeypadFailureText, 'Warning');
	}
	TriggerEffectEvent('KeypadFailed');
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	movie="ComboLock"
	KeypadFailureText="Incorrect code entered."
}