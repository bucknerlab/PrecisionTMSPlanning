import os
import shutil
import numpy as np
import asyncio
import nest_asyncio
from playwright.async_api import async_playwright
import fitz
import subprocess
from datetime import datetime
from PIL import Image, ImageOps

from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.enum.shapes import MSO_SHAPE
from pptx.dml.color import RGBColor

import matplotlib.pyplot as plt
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas

print("Hello World")