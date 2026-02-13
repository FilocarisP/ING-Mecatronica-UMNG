import json

input_file = r"C:\Users\pinzo\Documents\GitHub\UMNG\LAB IA\06-Array-Arithmetic-with-NumPy.ipynb"
output_file = r"C:\Users\pinzo\Documents\GitHub\UMNG\LAB IA\markdown_content.txt"

with open(input_file, 'r', encoding='utf-8') as f:
    nb = json.load(f)

with open(output_file, 'w', encoding='utf-8') as f:
    for i, cell in enumerate(nb['cells']):
        if cell['cell_type'] == 'markdown':
            f.write(f"CELL {i}:\n")
            f.write("".join(cell['source']))
            f.write("\n" + "="*20 + "\n")
