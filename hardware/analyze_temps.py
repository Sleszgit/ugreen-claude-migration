#!/usr/bin/env python3
import csv
import sys

def analyze_hwinfo_csv(filename):
    """Analyze HWiNFO CSV file for key temperature and power metrics"""

    print(f"\n{'='*80}")
    print(f"ANALYZING: {filename}")
    print(f"{'='*80}\n")

    with open(filename, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)

        # Find key columns
        max_temp = 0
        max_power = 0
        thermal_throttle_count = 0
        power_limit_exceeded_count = 0
        total_rows = 0

        # Track maximum values
        max_cpu_package = 0
        max_ia_power = 0
        max_total_power = 0

        for row in reader:
            total_rows += 1

            try:
                # Get CPU Package temperature (Cały procesor)
                if 'Cały procesor [°C]' in row and row['Cały procesor [°C]']:
                    temp = float(row['Cały procesor [°C]'])
                    if temp > max_cpu_package:
                        max_cpu_package = temp

                # Get maximum core temperature
                if 'Maksymalny Rdzeń [°C]' in row and row['Maksymalny Rdzeń [°C]']:
                    temp = float(row['Maksymalny Rdzeń [°C]'])
                    if temp > max_temp:
                        max_temp = temp

                # Get total CPU power consumption
                if 'Całkowite zużycie mocy przez procesor [W]' in row and row['Całkowite zużycie mocy przez procesor [W]']:
                    power = float(row['Całkowite zużycie mocy przez procesor [W]'])
                    if power > max_total_power:
                        max_total_power = power

                # Get IA cores power
                if 'Rdzenie IA Pobór mocy [W]' in row and row['Rdzenie IA Pobór mocy [W]']:
                    power = float(row['Rdzenie IA Pobór mocy [W]'])
                    if power > max_ia_power:
                        max_ia_power = power

                # Check for thermal throttling on any core
                throttle_cols = [col for col in row.keys() if 'Dławienie termiczne' in col]
                for col in throttle_cols:
                    if row[col] == 'Yes':
                        thermal_throttle_count += 1
                        break  # Count once per row

                # Check for power limit exceeded
                power_limit_cols = [col for col in row.keys() if 'Przekroczono limit mocy' in col]
                for col in power_limit_cols:
                    if row[col] == 'Yes':
                        power_limit_exceeded_count += 1
                        break  # Count once per row

            except (ValueError, KeyError) as e:
                continue

    # Calculate percentages
    throttle_percent = (thermal_throttle_count / total_rows * 100) if total_rows > 0 else 0
    power_limit_percent = (power_limit_exceeded_count / total_rows * 100) if total_rows > 0 else 0

    # Print results
    print("📊 TEMPERATURE ANALYSIS")
    print(f"   Maximum CPU Package Temp:  {max_cpu_package:.1f}°C")
    print(f"   Maximum Core Temp:         {max_temp:.1f}°C")
    print(f"   Target Maximum (Tj,max):   100.0°C")
    print(f"   Temperature Status:        {'🔥 CRITICAL!' if max_temp >= 100 else '⚠️  HIGH' if max_temp >= 85 else '✅ OK'}")
    print()

    print("⚡ POWER CONSUMPTION ANALYSIS")
    print(f"   Maximum Total CPU Power:   {max_total_power:.1f}W")
    print(f"   Maximum IA Cores Power:    {max_ia_power:.1f}W")
    print(f"   PL1 Limit (configured):    180.0W")
    print(f"   PL2 Limit (configured):    220.0W")
    print(f"   Power Status:              {'⚠️  EXCEEDS PL2' if max_total_power > 220 else '✅ Within limits'}")
    print()

    print("🚨 THROTTLING ANALYSIS")
    print(f"   Total data points:         {total_rows}")
    print(f"   Thermal throttling events: {thermal_throttle_count} ({throttle_percent:.1f}%)")
    print(f"   Power limit exceeded:      {power_limit_exceeded_count} ({power_limit_percent:.1f}%)")
    print(f"   Throttle Status:           {'🔥 SEVERE THROTTLING!' if throttle_percent > 50 else '⚠️  MODERATE' if throttle_percent > 10 else '✅ Minimal' if throttle_percent > 0 else '✅ None'}")
    print()

if __name__ == "__main__":
    files = [
        "/home/sleszugreen/hardware/12 12 2025.CSV",
        "/home/sleszugreen/hardware/12 12 2025 v2.CSV",
        "/home/sleszugreen/hardware/new temps 2025 12 12.CSV"
    ]

    for filename in files:
        try:
            analyze_hwinfo_csv(filename)
        except Exception as e:
            print(f"Error analyzing {filename}: {e}")
            continue

    print(f"\n{'='*80}")
    print("ANALYSIS COMPLETE")
    print(f"{'='*80}\n")
