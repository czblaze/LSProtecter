#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; --- Configuration ---
; IMPORTANT: Replace with the actual path to your image.
; Use forward slashes or escaped backslashes (e.g., "C:\\Path\\To\\Your\\Image.jpg").
ImageFilePath := "C:\Path\To\Your\LanSchool_Protecter.png"

; --- LanSchool Popup Detection Settings ---
; IMPORTANT: You MUST fill in ONE or more of these based on your Window Spy findings.
; Use the most specific information you found for reliable detection.

; Example 1: Detect by specific window title (most common for popups)
; Uncomment and replace "Exact LanSchool Popup Title" with the actual title.
LanSchoolPopupTitle := "Click here if you have a question for the Teacher." ; <--- REPLACE THIS
; SetTitleMatchMode, 3 ; Use 3 for exact title match, 2 for "contains", 1 for "starts with"

; Example 2: Detect by window class (often consistent for app dialogs)
; Uncomment and replace "LanSchoolWindowClass" with the actual class name (e.g., "Afx:400000:0:0:0:0").
; LanSchoolPopupClass := "LanSchoolWindowClass" ; <--- REPLACE THIS

; Example 3: Detect by process name (less specific for popups, but can be combined)
; Uncomment and replace "student.exe" with the actual process name.
; LanSchoolProcessName := "student.exe" ; <--- REPLACE THIS

; --- Script Logic ---
#Persistent ; Keep the script running indefinitely
SetTimer, CheckForLanSchoolPopup, 500 ; Check every 500 milliseconds (0.5 seconds)

; Global variable to track if the blocking image is currently displayed
BlockingImageDisplayed := false

; Global variable to store the ID of the detected LanSchool popup window
LanSchoolPopupID := 0

Return

CheckForLanSchoolPopup:
    ; Reset the found popup ID for each check
    FoundPopupID := 0

    ; --- Detection Logic (choose and uncomment your preferred method(s)) ---

    ; Method A: Detect by Window Title
    ; SetTitleMatchMode, 3 ; Set to exact match for the title
    ; If WinExist(LanSchoolPopupTitle)
    ; {
    ;     FoundPopupID := WinExist(LanSchoolPopupTitle)
    ; }
    ; SetTitleMatchMode, RegEx ; Reset to default or your preferred mode after check

    ; Method B: Detect by Window Class
    ; If WinExist("ahk_class " LanSchoolPopupClass)
    ; {
    ;     FoundPopupID := WinExist("ahk_class " LanSchoolPopupClass)
    ; }

    ; Method C: Detect by Process Name (less precise for a *popup* specifically)
    ; If ProcessExist(LanSchoolProcessName)
    ; {
    ;     ; If using process name, you might still want to check for a specific window
    ;     ; that appears when that process is actively viewing.
    ;     ; For example, if the process is running AND a specific window title appears:
    ;     ; If WinExist("LanSchool - Viewing Window Title")
    ;     ; {
    ;     ;     FoundPopupID := WinExist("LanSchool - Viewing Window Title")
    ;     ; }
    ; }

    ; --- Combined Detection (Example: Title AND Class) ---
    ; This is often the most robust approach for specific popups.
    ; Uncomment and adjust if you have both title and class information.
    SetTitleMatchMode, 3 ; For exact title match
    If (WinExist(LanSchoolPopupTitle) AND WinExist("ahk_class " LanSchoolPopupClass))
    {
        FoundPopupID := WinExist(LanSchoolPopupTitle) ; Get the ID of the window
    }
    SetTitleMatchMode, RegEx ; Reset to default or your preferred mode

    ; --- Action based on detection ---
    If (FoundPopupID != 0) ; If the LanSchool popup is detected
    {
        If (!BlockingImageDisplayed) ; If the blocking image is not already shown
        {
            ; Store the ID of the detected popup
            LanSchoolPopupID := FoundPopupID
            GoSub, DisplayFullScreenImage
            BlockingImageDisplayed := true
            ; Optional: Minimize or hide the actual LanSchool popup if it's not already
            ; WinMinimize, ahk_id %LanSchoolPopupID%
            ; WinHide, ahk_id %LanSchoolPopupID%
        }
    }
    Else ; If the LanSchool popup is NOT detected
    {
        If (BlockingImageDisplayed) ; If the blocking image is currently shown
        {
            GoSub, HideFullScreenImage
            BlockingImageDisplayed := false
            LanSchoolPopupID := 0 ; Reset the popup ID
        }
    }
Return

; --- Subroutine to Display Full-Screen Blocking Image ---
DisplayFullScreenImage:
    ; Destroy any existing GUI to prevent duplicates if called multiple times
    Gui, BlockerGui:Destroy

    ; Create a new GUI window for the blocking image
    ; +AlwaysOnTop: Keeps the image on top of other windows
    ; -Caption: Removes the title bar
    ; -Border: Removes the window border
    ; +ToolWindow: Prevents it from appearing in the taskbar or Alt+Tab menu (optional, can be removed)
    Gui, BlockerGui:+AlwaysOnTop -Caption -Border +ToolWindow
    Gui, BlockerGui:Color, Black ; Background color for the GUI

    ; Get screen resolution to make the image truly fullscreen
    SysGet, MonitorWorkArea, MonitorWorkArea

    ; Add the picture control to the GUI
    ; x0 y0: Position at top-left corner
    ; w%A_ScreenWidth% h%A_ScreenHeight%: Make it fill the entire screen
    ; vBlockingImage: Variable name for the picture control
    ; BackgroundTrans: Makes the background of the image transparent if the image itself has transparency
    ; gGuiClick: Call GuiClick subroutine if the image is clicked (to dismiss)
    Gui, BlockerGui:Add, Picture, x0 y0 w%A_ScreenWidth% h%A_ScreenHeight% vBlockingImage BackgroundTrans gGuiClick, %ImageFilePath%

    ; Show the GUI maximized and without activating it (so it doesn't steal focus)
    Gui, BlockerGui:Show, Maximize NoActivate

    ; Ensure the image window truly covers the entire screen and is on top
    ; Remove common window styles that might create borders or title bars
    WinSet, Style, -0xC40000, ahk_class AutoHotkeyGUI ahk_title BlockerGui
    ; Remove extended style for tool window if you want it to appear in Alt+Tab
    ; WinSet, ExStyle, -0x8, ahk_class AutoHotkeyGUI ahk_title BlockerGui
    ; Move and resize to cover the entire screen area
    WinMove, ahk_class AutoHotkeyGUI ahk_title BlockerGui,, 0, 0, A_ScreenWidth, A_ScreenHeight
    ; Ensure it stays on top, even above other always-on-top windows if possible
    WinSet, AlwaysOnTop, On, ahk_class AutoHotkeyGUI ahk_title BlockerGui
    WinSet, Top, , ahk_class AutoHotkeyGUI ahk_title BlockerGui
Return

; --- Subroutine to Hide Full-Screen Blocking Image ---
HideFullScreenImage:
    Gui, BlockerGui:Destroy ; Close and destroy the GUI window
Return

; --- Optional: Allow dismissing the image by clicking or pressing Escape ---
; This will hide the image, but it will reappear if the LanSchool popup is still detected.
BlockerGuiEscape:
BlockerGuiClose:
GuiClick:
    GoSub, HideFullScreenImage
    BlockingImageDisplayed := false
Return
