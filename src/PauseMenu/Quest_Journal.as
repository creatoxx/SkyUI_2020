import gfx.controls.RadioButton;
import gfx.controls.ButtonGroup;
import gfx.io.GameDelegate;
import gfx.ui.InputDetails;
import Shared.GlobalFunc;
import gfx.ui.NavigationCode;
import gfx.managers.FocusHandler;

import skyui.components.ButtonPanel;

class Quest_Journal extends MovieClip
{
	#include "../version.as"

	var bTabsDisabled: Boolean;

	var iCurrentTab: Number;

	var BottomBar: MovieClip;
	var BottomBar_mc: MovieClip;

	var PageArray: Array;

	public var previousTabButton: MovieClip;
	public var nextTabButton: MovieClip;
	var TopmostPage: MovieClip;
	var QuestsFader: MovieClip;
	var StatsFader: MovieClip;
	var SystemFader: MovieClip;

	var QuestsTab: RadioButton;
	var StatsTab: RadioButton;
	var SystemTab: RadioButton;
	var TabButtonGroup: ButtonGroup;

	var ConfigPanel: MovieClip;
	
	/*public static var SKYUI_RELEASE_IDX = 2018;
	public static var SKYUI_VERSION_MAJOR = 5;
	public static var SKYUI_VERSION_MINOR = 2;
    public static var SKYUI_VERSION_STRING = Quest_Journal.SKYUI_VERSION_MAJOR + "." + Quest_Journal.SKYUI_VERSION_MINOR + " SE";*/ // not needed as long as version.as is imported, but latest Sky UI 5.2 does it like that?
	public static var PAGE_QUEST: Number = 0;
	public static var PAGE_STATS: Number = 1;
	public static var PAGE_SYSTEM: Number = 2;
	public static var QUESTS_TAB: Number = 0;
	public static var STATS_TAB: Number = 1;
	public static var SETTINGS_TAB: Number = 2;

	function Quest_Journal()
	{
		super();
		QuestsTab = QuestsTab;
		StatsTab = StatsTab;
		SystemTab = SystemTab;
		BottomBar_mc = BottomBar;
		PageArray = new Array(QuestsFader.Page_mc, StatsFader.Page_mc, SystemFader.Page_mc);
		TopmostPage = QuestsFader;
		bTabsDisabled = false;
		//iCurrentTab = Quest_Journal.PAGE_QUEST; //CrEaToXx: changed back to the way it was in legendary, opening the settings page, instead of the quest page when pressing ESC
	}

	function InitExtensions()
	{
		GlobalFunc.SetLockFunction();
		//MovieClip(BottomBar_mc).Lock("B");//this is present in latest Sky UI 5.2 release, but enabling breaks the bottom bar?
		
		ConfigPanel = _root.ConfigPanelFader.configPanel;

		QuestsTab.disableFocus = true;
		StatsTab.disableFocus = true;
		SystemTab.disableFocus = true;
		/*CrEaToXx: NMM specific
		QuestsTab.disabled = true; //CrEaToXx: the outcommented lines here would not exist in the original...we use it to make sure map and quests are not accesible, and the tabs are moved closer together
		QuestsTab._visible = false; 		
		StatsTab._x = (QuestsTab._x + 100) //CrEaToXx: move stats and system tab closer to the middle
		SystemTab._x = (SystemTab._x - 100)*/

		TabButtonGroup = ButtonGroup(QuestsTab.group);
		TabButtonGroup.addEventListener("itemClick", this, "onTabClick");
		TabButtonGroup.addEventListener("change", this, "onTabChange");
			
		GameDelegate.addCallBack("RestoreSavedSettings", this, "RestoreSavedSettings");
		GameDelegate.addCallBack("onRightStickInput", this, "onRightStickInput");
		GameDelegate.addCallBack("HideMenu", this, "DoHideMenu");
		GameDelegate.addCallBack("ShowMenu", this, "DoShowMenu");
		GameDelegate.addCallBack("StartCloseMenu", this, "CloseMenu");

		BottomBar_mc.InitBar();
	
		ConfigPanel.initExtensions();
	}

	function RestoreSavedSettings(aiSavedTab: Number, abTabsDisabled: Boolean): Void
	{		
		iCurrentTab = Math.min(Math.max(aiSavedTab, 0), TabButtonGroup.length - 1);
		bTabsDisabled = abTabsDisabled;
		if (bTabsDisabled) {
			iCurrentTab = TabButtonGroup.length - 1;
			QuestsTab.disabled = true;
			StatsTab.disabled = true;
		}
		SwitchPageToFront(iCurrentTab, true);
		TabButtonGroup.setSelectedButton(TabButtonGroup.getButtonAt(iCurrentTab));
	}

	function SwitchPageToFront(aiTab: Number, abForceFade: Boolean): Void
	{
		if (TopmostPage != PageArray[iCurrentTab]._parent)
		{
			TopmostPage.gotoAndStop("hide");
			PageArray[iCurrentTab]._parent.swapDepths(TopmostPage);
			TopmostPage = PageArray[iCurrentTab]._parent;
		}
		TopmostPage.gotoAndPlay(abForceFade ? "ForceFade" : "fadeIn");
		//BottomBar_mc.LevelMeterRect._visible = iCurrentTab != 0; //this hides level meter on the quest tab for whatever reason? maybe the button tabs got messed up?
		BottomBar_mc.SetMode(iCurrentTab); //this is how it is currently done in vanilla SE, but the .fla file provides no sign to why you would switch modes to begin with???
		//however, this does not hide the level meter on changing tabs
	}

	function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		var bHandledInput: Boolean = false;
		if (pathToFocus != undefined && pathToFocus.length > 0) {
			bHandledInput = pathToFocus[0].handleInput(details, pathToFocus.slice(1));
		}
		if (!bHandledInput && GlobalFunc.IsKeyPressed(details, false)) {
			var triggerLeft = NavigationCode.GAMEPAD_L2;
			var triggerRight = NavigationCode.GAMEPAD_R2;
			if(PageArray[Quest_Journal.PAGE_SYSTEM].GetIsRemoteDevice()) {
				triggerLeft = NavigationCode.GAMEPAD_L1;
				triggerRight = NavigationCode.GAMEPAD_R1;
			}
			if (details.navEquivalent === NavigationCode.TAB) {
				CloseMenu();
				break; //CrEaToXx: missing but needed! no reason to keep processing till the end of the function
			} else if (details.navEquivalent === triggerLeft) {
				if (!bTabsDisabled) {
					PageArray[iCurrentTab].endPage();
					iCurrentTab = iCurrentTab + (details.navEquivalent == triggerLeft ? -1 : 1);
					if (iCurrentTab == -1) {
						iCurrentTab = TabButtonGroup.length - 1;
					}
					if (iCurrentTab == TabButtonGroup.length) {
						iCurrentTab = 0;
					}
					SwitchPageToFront(iCurrentTab, false);
					TabButtonGroup.setSelectedButton(TabButtonGroup.getButtonAt(iCurrentTab));
				}
			} else if (details.navEquivalent === triggerRight) {
				if (!bTabsDisabled) {
					PageArray[iCurrentTab].endPage();
					iCurrentTab = iCurrentTab + (details.navEquivalent == triggerLeft ? -1 : 1);
					if (iCurrentTab == -1) {
						iCurrentTab = TabButtonGroup.length - 1;
					}
					if (iCurrentTab == TabButtonGroup.length) {
						iCurrentTab = 0;
					}
					SwitchPageToFront(iCurrentTab, false);
					TabButtonGroup.setSelectedButton(TabButtonGroup.getButtonAt(iCurrentTab));
				}
			} else if (details.navEquivalent === NavigationCode.LEFT) { // CrEaToXx: added directional key navigation
				if (!bTabsDisabled) {
					PageArray[iCurrentTab].endPage();
					iCurrentTab = iCurrentTab + (details.navEquivalent == NavigationCode.LEFT ? -1 : 1);
					if (iCurrentTab == -1) {
						iCurrentTab = TabButtonGroup.length - 1;
					}
					if (iCurrentTab == TabButtonGroup.length) {
						iCurrentTab = 0;
					}
					SwitchPageToFront(iCurrentTab, false);
					TabButtonGroup.setSelectedButton(TabButtonGroup.getButtonAt(iCurrentTab));
				}
			} else if (details.navEquivalent === NavigationCode.RIGHT) { // CrEaToXx: added directional key navigation
				if (!bTabsDisabled) {
					PageArray[iCurrentTab].endPage();
					iCurrentTab = iCurrentTab + (details.navEquivalent == NavigationCode.LEFT ? -1 : 1);
					if (iCurrentTab == -1) {
						iCurrentTab = TabButtonGroup.length - 1;
					}
					if (iCurrentTab == TabButtonGroup.length) {
						iCurrentTab = 0;
					}
					SwitchPageToFront(iCurrentTab, false);
					TabButtonGroup.setSelectedButton(TabButtonGroup.getButtonAt(iCurrentTab));
				}
			}			
		}
		return true;
	}	

	function CloseMenu(abForceClose: Boolean): Void
	{
		if (abForceClose != true) {
			GameDelegate.call("PlaySound", ["UIJournalClose"]);
		}
		GameDelegate.call("CloseMenu", [iCurrentTab, QuestsFader.Page_mc.selectedQuestID, QuestsFader.Page_mc.selectedQuestInstance]);
	}

	function onTabClick(event: Object): Void
	{
		if (bTabsDisabled) {
			return;
		}

		var iOldTab: Number = iCurrentTab;

		if (event.item == QuestsTab) {
			iCurrentTab = 0;
		} else if (event.item == StatsTab) {
			iCurrentTab = 1;
		} else if (event.item == SystemTab) {
			iCurrentTab = 2;
		}
		if (iOldTab != iCurrentTab) {
			PageArray[iOldTab].endPage();
			// Moved SwitchPageToFront to within this statement
			// if you click the same tab it won't reload it
			SwitchPageToFront(iCurrentTab, false); // Bugfix for vanilla
		}
	}

	function onTabChange(event: Object): Void
	{
		event.item.gotoAndPlay("selecting");
		PageArray[iCurrentTab].startPage();
		GameDelegate.call("PlaySound", ["UIJournalTabsSD"]);
	}

	function onRightStickInput(afX: Number, afY: Number): Void
	{
		if (PageArray[iCurrentTab].onRightStickInput != undefined) {
			PageArray[iCurrentTab].onRightStickInput(afX, afY);
		}
	}

	function SetPlatform(aiPlatform: Number, abPS3Switch: Boolean): Void
	{

		if (aiPlatform == 0) {
			previousTabButton._visible = nextTabButton._visible = false;
		} else {
			previousTabButton._visible = nextTabButton._visible = true;
			previousTabButton.gotoAndStop(280);
			nextTabButton.gotoAndStop(281);
		}

		for (var i: String in PageArray) {
			if (PageArray[i].SetPlatform != undefined) {
				PageArray[i].SetPlatform(aiPlatform, abPS3Switch);
			}
		}
		BottomBar_mc.setPlatform(aiPlatform, abPS3Switch);

		ConfigPanel.setPlatform(aiPlatform, abPS3Switch);
		/*TabButtonHelp.gotoAndStop(aiPlatform + 1); present in SSE vanilla??? is named previousTabButton in the SkyUI .fla
		previousTabButton.gotoAndStop(aiPlatform + 1); SkyUI has not enabled it however...survival mode?*/
	}

	function DoHideMenu(): Void
	{
		_parent.gotoAndPlay("fadeOut");
	}

	function DoShowMenu(): Void
	{
		_parent.gotoAndPlay("fadeIn");
	}

	function DisableTabs(abEnable: Boolean): Void
	{
		QuestsTab.disabled = abEnable; //CrEaToxx, NMM specific: make sure quests tab is disabled when exiting any other instance of main menu, org -> abEnable, modded -> true
		StatsTab.disabled = abEnable;
		SystemTab.disabled = abEnable;
	}

	function ConfigPanelOpen(): Void
	{
		DisableTabs(true);
		SystemFader.Page_mc.endPage();
		DoHideMenu();
		_root.ConfigPanelFader.swapDepths(_root.QuestJournalFader);
		FocusHandler.instance.setFocus(ConfigPanel, 0);
		ConfigPanel.startPage();
	}

	function ConfigPanelClose(): Void
	{
		ConfigPanel.endPage();
		_root.QuestJournalFader.swapDepths(_root.ConfigPanelFader);
		FocusHandler.instance.setFocus(this, 0);
		DoShowMenu();
		SystemFader.Page_mc.startPage();
		DisableTabs(false);
	}
}
