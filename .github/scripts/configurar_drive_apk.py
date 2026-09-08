#!/usr/bin/env python3
"""Atalho local para o bootstrap OAuth da distribuição de APK."""

from __future__ import annotations

import sys

from distribuir_apk_drive import main


if __name__ == "__main__":
    raise SystemExit(main(["bootstrap", *sys.argv[1:]]))
