"""UE Python commandlet entry point for verify_vita_chamber."""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import verify_vita_chamber

verify_vita_chamber.main()
