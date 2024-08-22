# Fivem-Recording-Security-Cameras

## Config
### Allgemeine Einstellungen
- **Debug:** `false/true`  
  - Zeigt an, wo die Kamera hinschaut und wie weit die Reichweite ist.
- **Verfügbare Props:**  
  - `prop_cctv_cam_05a`, `prop_cctv_cam_06a`, `prop_cctv_pole_02`, `prop_cctv_cam_07a`

### Kamera-Einstellungen
- **PlayerCreateOwnCam:**  
  Ermöglicht es bestimmten Spielern, eigene Kameras zu erstellen.
  - `anybody = false`  
    - Wenn `false`, kann kein Spieler eine eigene Kamera erstellen.
  - **acces:**  
    - **Jobs:**  
      Definiert, welche Jobs Kameras erstellen dürfen und wie viele.
      ```lua
      jobs = {
        {name = "police", maxCams = 5}
      }
      ```
    - **Identifier:**  
      Definiert, welche spezifischen Spieler Kameras erstellen dürfen und wie viele.
      ```lua
      identifier = {
        {"steam:123456789abcdef", maxCams = 2}
      }
      ```
- **Cams:**  
  Hier werden die Positionen und Objekte der Kameras definiert.
  ```lua
  Cams = {
    {coords = vector4(0,0,0,0), obj = "prop_cctv_cam_05a"}
  }
  ```

## Client-Seite
- **Erkennung im Sichtfeld:**  
  Basierend auf den `coords` und dem `heading` der Kamera wird berechnet, ob sich ein Spieler im Sichtfeld der Kamera befindet. Falls ja, wird eine `NUIMessage` zum Starten der Aufnahme gesendet.

### Commands
- **viewcameras:**  
  Überprüft die Berechtigungen und zeigt dann das UI mit den jeweiligen Kameras an.

## Server-Seite
- **Permissions-Überprüfung:**  
  Der Server überprüft die Berechtigungen der Spieler, bevor eine Kamera erstellt oder eine Aufnahme gestartet wird.
- **Speicherung der Aufnahmen:**  
  Die aufgenommenen Videos werden im Cache oder auf Discord gespeichert (Discord kann als Cache verwendet werden).

## Benutzeroberfläche (UI)
- **UI Öffnen:**  
  Mit dem Befehl `viewcams` wird die Benutzeroberfläche geöffnet. Es wird empfohlen, die UI im Vollbildmodus anzuzeigen, aber dies kann individuell angepasst werden.
- **Auflistung der Kameras:**  
  Alle Kameras werden untereinander gelistet. Die Liste sollte folgende Informationen enthalten:
  - **Kamera-Name**
  - **Straßenname oder PLZ**
  - **Buttons:** 
    - **Cam anschauen:** Zeigt die Live-Ansicht der Kamera.
    - **Aufnahmen anschauen:** Zeigt alle gespeicherten Aufnahmen an.

### Aufnahmen Übersicht
- Wenn der Button "Aufnahmen anschauen" gedrückt wird, sollten folgende Details der Aufnahmen angezeigt werden:
  - **Datum der Aufnahme**
  - **Länge der Aufnahme**
  - **PLZ oder Straßenname**
  - **Kamera-Name**

## Offene Punkte
- Integration und Tests der `NUIMessage` zum Starten und Speichern der Aufnahmen.
- Implementierung der `viewcams` Benutzeroberfläche.
- Finalisierung der Speichermethoden für die Videos (Cache oder Discord).
- Berechtigungsverwaltung für das Erstellen von Kameras durch Spieler.
```
