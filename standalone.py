import os
import sys

os.chdir(getattr(sys, '_MEIPASS', os.path.dirname(os.path.abspath(__file__))))
sys.path.append(os.getcwd())
PYBIN = sys.executable

import runpy
result = runpy._run_module_as_main("hammer")
