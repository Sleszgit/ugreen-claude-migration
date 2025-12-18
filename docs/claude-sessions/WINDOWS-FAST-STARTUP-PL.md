# Wyłączenie Windows Fast Startup - Instrukcja PL

**System:** Windows 11 Pro (Polish)
**Data:** 12.12.2025
**Cel:** Naprawienie problemu resetujących się ustawień BIOS

---

## Dlaczego To Zrobić?

**Fast Startup (Szybkie Uruchamianie)** może uniemożliwiać pełną inicjalizację BIOS, co powoduje:
- ❌ Resetowanie ustawień limitów mocy (PL1/PL2)
- ❌ Resetowanie typu chłodzenia CPU (CPU Cooler Type)
- ❌ Problemy z zachowaniem konfiguracji BIOS

**Rozwiązanie:** Wyłącz Fast Startup aby BIOS w pełni inicjalizował się przy każdym uruchomieniu.

---

## Metoda 1: Panel Sterowania (Zalecana)

### Krok po kroku:

1. **Otwórz Panel Sterowania:**
   - Naciśnij **Windows + R**
   - Wpisz: `control panel`
   - Naciśnij **Enter**

2. **Przejdź do Opcji zasilania:**
   - Kliknij: **Sprzęt i dźwięk**
   - Kliknij: **Opcje zasilania**

3. **Wybierz funkcje przycisków zasilania:**
   - Po lewej stronie kliknij: **"Wybierz działanie przycisków zasilania"**

4. **Odblokuj ukryte ustawienia:**
   - U góry kliknij linkiem: **"Zmień ustawienia, które są obecnie niedostępne"**
   - Może pojawić się okno **Kontroli konta użytkownika (UAC)** - kliknij **"Tak"**

5. **Wyłącz szybkie uruchamianie:**
   - Przewiń w dół do sekcji **"Ustawienia zamykania"**
   - Znajdź opcję: **"Włącz szybkie uruchamianie (zalecane)"**
   - **ODZNACZ** to pole wyboru: ☐
   - Kliknij: **"Zapisz zmiany"**

6. **Uruchom ponownie komputer:**
   - Wykonaj pełny **restart** (nie wyłączanie!)
   - To zapewni pełną inicjalizację BIOS przy następnym uruchomieniu

---

## Metoda 2: PowerShell (Alternatywna - Szybsza)

### Krok po kroku:

1. **Otwórz PowerShell jako Administrator:**
   - Naciśnij **Windows + X**
   - Z menu wybierz: **"Terminal (Administrator)"** lub **"Windows PowerShell (Administrator)"**
   - Kliknij **"Tak"** w oknie UAC

2. **Wykonaj polecenie:**
   ```powershell
   powercfg /h off
   ```
   - Wpisz lub wklej to polecenie
   - Naciśnij **Enter**

3. **Uruchom ponownie komputer:**
   - Pełny restart (nie wyłączanie)

**⚠️ Uwaga:** To polecenie również **wyłącza hibernację**.

**Jeśli chcesz hibernację zachować:**
- Użyj Metody 1 zamiast Metody 2
- Metoda 1 wyłącza tylko Fast Startup, zachowując hibernację

---

## Metoda 3: Rejestr Windows (Tylko jeśli Metody 1 i 2 nie działają)

### Krok po kroku:

1. **Otwórz Edytor rejestru:**
   - Naciśnij **Windows + R**
   - Wpisz: `regedit`
   - Naciśnij **Enter**
   - Kliknij **"Tak"** w oknie UAC

2. **Przejdź do odpowiedniego klucza:**
   ```
   HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power
   ```
   - Rozwiń kolejno: HKEY_LOCAL_MACHINE → SYSTEM → CurrentControlSet → Control → Session Manager → Power

3. **Zmodyfikuj wartość:**
   - Znajdź klucz: **HiberbootEnabled**
   - Kliknij dwukrotnie na **HiberbootEnabled**
   - Zmień wartość z **1** na **0**
   - Kliknij **OK**

4. **Zamknij Edytor rejestru**

5. **Uruchom ponownie komputer**

---

## Weryfikacja - Sprawdź czy Fast Startup jest wyłączony

### Po restarcie:

1. Wróć do: **Panel Sterowania → Opcje zasilania → Wybierz działanie przycisków zasilania**
2. Kliknij: **"Zmień ustawienia, które są obecnie niedostępne"**
3. Sprawdź sekcję **"Ustawienia zamykania"**
4. Opcja **"Włącz szybkie uruchamianie (zalecane)"** powinna być **ODZNACZONA** ☐

---

## Nazwy w Polskiej Wersji Windows 11 - Słowniczek

| Angielska Nazwa | Polska Nazwa |
|-----------------|--------------|
| Control Panel | Panel Sterowania |
| Hardware and Sound | Sprzęt i dźwięk |
| Power Options | Opcje zasilania |
| Choose what the power buttons do | Wybierz działanie przycisków zasilania |
| Change settings that are currently unavailable | Zmień ustawienia, które są obecnie niedostępne |
| Shutdown settings | Ustawienia zamykania |
| Turn on fast startup (recommended) | Włącz szybkie uruchamianie (zalecane) |
| Save changes | Zapisz zmiany |
| User Account Control | Kontrola konta użytkownika |
| Terminal (Admin) | Terminal (Administrator) |
| Registry Editor | Edytor rejestru |

---

## Co Dalej?

**Po wyłączeniu Fast Startup:**

1. ✅ **Uruchom ponownie komputer** (pełny restart)

2. ✅ **Wejdź do BIOS** (F2 lub DEL podczas startu)

3. ✅ **Sprawdź ustawienia:**
   - OC Tweaker → CPU Configuration
   - "Load Intel Base Power Limit Settings" = **[Disabled]**
   - "CPU Cooler Type" = **360mm AIO** lub **Water Cooling**
   - PL1 = **180W**
   - PL2 = **220W**

4. ✅ **Ustaw undervolting:**
   - OC Tweaker → Voltage Configuration
   - CPU Core/Cache Voltage = **Offset Mode: -0.120V**

5. ✅ **Zapisz do profilu:**
   - F11 → Save to Profile 1
   - F10 → Save & Exit

6. ✅ **Testuj w grze:**
   - Uruchom Call of Duty
   - Monitoruj temperatury w HWiNFO64
   - Oczekiwane: **65-80°C** (obecnie: 100-105°C)

---

## Oczekiwane Rezultaty

**Przed:**
- Temperatury w grze: **100-105°C** (throttling)
- Moc procesora: **~250W**
- Ustawienia BIOS: **Resetują się**

**Po (Fast Startup wyłączony + BIOS poprawnie skonfigurowany):**
- Temperatury w grze: **65-80°C** (brak throttlingu)
- Moc procesora: **180-220W** (kontrolowana)
- Ustawienia BIOS: **Trwałe** (nie resetują się)

---

## Rozwiązywanie Problemów

### Jeśli po wyłączeniu Fast Startup ustawienia BIOS dalej się resetują:

1. **Sprawdź baterię CMOS:**
   - Bateria CR2032 na płycie głównej
   - Jeśli komputer ma 3+ lata, wymień baterię

2. **Sprawdź inne oprogramowanie:**
   - Razer Synapse (już zidentyfikowany jako problematyczny)
   - iCUE (może modyfikować ustawienia)
   - ASRock A-Tuning Tool (wyłącz jeśli zainstalowany)

3. **Zaktualizuj BIOS:**
   - Obecna wersja: 21.02 (Październik 2025)
   - Sprawdź na stronie ASRock czy jest nowsza wersja

4. **Multi-Core Enhancement (MCE):**
   - Niektóre płyty główne mają to ustawienie
   - Może nadpisywać limity mocy
   - Ustaw na **[Disabled]** lub **[Auto]**

---

**Utworzono:** 12.12.2025
**Dla:** DESKTOP24 (Windows 11 Pro PL)
**Cel:** Naprawa resetujących się ustawień BIOS i optymalizacja termiczna
