#!/usr/bin/env python3
import argparse
from rich.console import Console
from rich.table import Table
from rich import box

# Parse command-line arguments
parser = argparse.ArgumentParser(description="Compare two header files and show differences.")
parser.add_argument("file1", help="Path to the first header file")
parser.add_argument("file2", help="Path to the second header file")
args = parser.parse_args()

# Read files
with open(args.file1, 'r') as f1, open(args.file2, 'r') as f2:
    file1_lines = f1.readlines()
    file2_lines = f2.readlines()

# Create a console for rich output
console = Console()

# Create a table for unique lines comparison
table = Table(show_header=True, header_style="bold magenta", box=box.SIMPLE)
table.add_column("Line #", style="dim", width=8)
table.add_column(f"{args.file1} (Unique)", style="green")
table.add_column(f"{args.file2} (Unique)", style="red")

# Find lines unique to file1
for i, line in enumerate(file1_lines, start=1):
    if line not in file2_lines:
        table.add_row(str(i), line.rstrip(), "[red]NOT FOUND[/red]")

# Find lines unique to file2
for i, line in enumerate(file2_lines, start=1):
    if line not in file1_lines:
        table.add_row(str(i), "[red]NOT FOUND[/red]", line.rstrip())

# Print the table
console.print(table)
