"""Reuse TDD's existing font optimizer with the project's Lato Semibold face."""
from pathlib import Path
import importlib.util
root = Path(__file__).resolve().parents[2]
source = root / 'visuals/2026-10-eu-youth-unemployment/optimize-svg-fonts.py'
spec = importlib.util.spec_from_file_location('tdd_svg_optimizer', source)
optimizer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(optimizer)
optimizer.FACES[600] = 'SemiBold'
original_subset = optimizer.font_subset

def subset_with_semibold(weight, characters, flavor):
    previous = optimizer.FONT_DIR
    try:
        if weight == 600:
            optimizer.FONT_DIR = root / 'visuals/2026-10-switzerland-net-migration/data'
        return original_subset(weight, characters, flavor)
    finally:
        optimizer.FONT_DIR = previous

optimizer.font_subset = subset_with_semibold
optimizer.main()
