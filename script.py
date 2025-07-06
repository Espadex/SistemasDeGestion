import re
import csv

def normalize_column(name: str) -> str:
    # 1) a minúsculas
    name = name.lower()
    # 2) cualquier carácter que no sea letra, número o guión bajo → guión bajo
    name = re.sub(r'[^\w]+', '_', name)
    # 3) colapsar múltiples guiones bajos en uno solo
    name = re.sub(r'__+', '_', name)
    # 4) quitar guiones bajos iniciales/finales
    return name.strip('_')

def main(csv_path: str):
    with open(csv_path, newline='', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = next(reader)

    normalized = [normalize_column(h) for h in headers]

    print("Mapeo de columnas:")
    for orig, norm in zip(headers, normalized):
        print(f"  '{orig}' → '{norm}'")

    print("\n-- Borrador de columnas SQL (ajusta tipos a tu gusto):")
    for col in normalized:
        print(f"  `{col}` INT,")

if __name__ == "__main__":
    # Reemplaza 'educacion.csv' por la ruta de tu fichero
    main("educacton.csv")
