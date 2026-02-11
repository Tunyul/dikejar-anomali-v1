# Struktur Panel Misi (DailyMissionsMenu)

Sumber scene: `res://scenes/DailyMissionsMenu.tscn`

## Node Tree

`DailyMissionsMenu (Control)`

- `AdManager (Node)`
- `MissionsManager (Node)`
- `UI (CanvasLayer)`
  - `ConfirmPanel (PackedScene instance: ConfirmPanel.tscn)`
  - `Panel (ColorRect)`
  - `MissionPanel (TextureRect)`
    - `PanelContent (Control)`
      - `VBox (VBoxContainer)`
        - `Tabs (HBoxContainer)`
          - `DailyButton (Button)`
          - `MissionButton (Button)`
          - `WeeklyButton (Button)`
          - `MonthlyButton (Button)`
          - `ChallengeButton (Button)`
        - `ResetHeaderRow (HBoxContainer)`
          - `DailyGroup (HBoxContainer)`
            - `DailyTotalLabel (Label)`
            - `DailyTotalBar (ProgressBar)`
            - `DailyAllRewardLabel (Label)`
            - `ClaimDailyAllButton (Button)`
          - `Spacer (Control)`
          - `ResetTimeLabel (Label)`
          - `ResetDailyButton (Button)`
        - `MissionListContainer (PanelContainer)`
          - `MissionsScroll (ScrollContainer)`
            - `MissionsPanel (VBoxContainer)`
              - `Mission1..Mission5 (HBoxContainer template)`
                - `Name (Label)`
                - `Bar (ProgressBar)`
                - `Reward (Label)`
                - `ClaimButton (Button)`
        - `BackButton (Button)`
    - `CloseButton (TextureButton)`
  - `TitleLabel (Label)`

## Script Terkait

- UI + layout responsif + render list: `res://scripts/DailyMissionsMenu.gd`
- Drag scroll list: `res://scripts/MissionsListScroll.gd`
- Data misi + progres + save: `res://scripts/MissionsManager.gd`

## Titik Ukuran Penting (yang sering diubah)

- Ukuran tombol tab: `Tabs/*Button.custom_minimum_size.x`
- Padding area tab: gunakan `Tabs.theme_override_constants/separation` dan margin `PanelContent`
- Margin dalam kartu (isi panel): `MissionPanel/PanelContent.offset_left/top/right/bottom`
- Tinggi list: `MissionListContainer.custom_minimum_size.y` dan `MissionsScroll.custom_minimum_size.y`
