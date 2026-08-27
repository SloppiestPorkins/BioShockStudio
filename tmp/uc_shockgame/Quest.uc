class Quest extends DeletableObject
	native
	config(Quests)
	perobjectconfig;

struct native atomic QuestHint
{
	var name HintName;
	var localized string Text;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var config localized string FriendlyName;
var config localized string Description;
var config localized string ObjectiveDescription;
var config localized string CompletedDescription;
var config localized string CompletedObjectiveDescription;
var config localized string LevelFriendlyName;
var config localized string CompleteMessage;
var config localized string ObjectiveMessage;
var config name ParentName;
var config name MapUIRegion;
var config travel name ArrowActor;
var config travel name ArrowActorLevelLabel;
var config array<name> ReleventLevelLabel;
var config float TimeToComplete;
var travel float FailureTime;
var config int NumberOfObjectivesToComplete;
var travel int NumberOfObjectivesCompleted;
var config bool CompleteWhenAllChildrenAreCompleted;
var config localized array<localized QuestHint> QuestHints;
var travel name CurrentHintName;
var config float HintReminderTime;
var travel bool HasSeenCurrentHint;
var travel bool Completed;
var config int ADAMAward;
var travel bool Hidden;
var travel bool Active;
var travel Quest Parent;
var travel array<Quest> Children;
var travel Quest ReplacedBy;
var config name ObjectiveIcon;

function DumpQuest(float LevelTime, int Level, optional bool bShowHidden, optional bool bShowCompleted)
{
	local int i;
	local string displayString;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x248
	/*@Error*/
	i = 0;
	// End:0x89
	if(__NFUN_150__(i, Level))
	{
		displayString = __NFUN_112__(displayString, "    ");
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x49;
		displayString = __NFUN_112__(__NFUN_112__(__NFUN_112__(displayString, FriendlyName), " | Complete: "), string(Completed));
	}
	// End:0x15F
	if(__NFUN_151__(NumberOfObjectivesToComplete, 1))
	{
		displayString = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(displayString, " | "), string(NumberOfObjectivesCompleted)), "/"), string(NumberOfObjectivesToComplete)), " ");
		// End:0x141
		if(Completed)
		{
			displayString = __NFUN_112__(displayString, ObjectiveDescription);
			goto J0x15F;
			displayString = __NFUN_112__(displayString, CompletedObjectiveDescription);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x1BD
			/*@Error*/
			displayString = __NFUN_112__(__NFUN_112__(displayString, " | Time Remaining: "), string(__NFUN_175__(FailureTime, LevelTime)));
			log(,, displayString);
		}
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x248
		/*@Error*/
	}
	Children[i].DumpQuest(LevelTime, __NFUN_146__(Level, 1), bShowHidden, bShowCompleted);
	__NFUN_165__(i);
	goto J0x1D8;
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	LevelFriendlyName="LevelFriendlyName missing"
	CompleteMessage="Goal Completed"
	ObjectiveMessage="Objective Completed"
	NumberOfObjectivesToComplete=1
	HintReminderTime=1200.0000000
	Hidden=true
	ObjectiveIcon="NoIcon"
}