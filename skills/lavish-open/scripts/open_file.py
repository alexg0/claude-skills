#!/usr/bin/env python3
"""Open HTML directly or render Markdown/text for Lavish."""

import argparse
from html.parser import HTMLParser
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


class FirstHeading(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.active = False
        self.done = False

    def handle_starttag(self, tag, attrs):
        if re.fullmatch(r"h[1-6]", tag) and not self.done:
            self.active = True

    def handle_endtag(self, tag):
        if re.fullmatch(r"h[1-6]", tag) and self.active:
            self.active = False
            self.done = True

    def handle_data(self, data):
        if self.active:
            self.parts.append(data)


def open_file(source):
    source = source.expanduser().resolve(strict=True)
    if not source.is_file():
        raise ValueError(f"Not a file: {source}")
    launcher = os.environ.get("LAVISH_AXI", "lavish-axi")
    if not shutil.which(launcher):
        raise ValueError(f"Missing lavish-axi executable: {launcher}; install it separately.")
    suffix = source.suffix.lower()
    output = source
    if suffix not in {".html", ".htm"}:
        if suffix not in {".md", ".markdown", ".txt", ".text", ""}:
            raise ValueError(f"Unsupported file type: {suffix}; use HTML, Markdown, or plain text.")
        if not shutil.which("pandoc"):
            raise ValueError("Missing pandoc executable; install it separately.")
        content = source.read_text(encoding="utf-8")
        title = source.name
        command = ["pandoc", "-f", "gfm", "-t", "html5"]
        if suffix in {".md", ".markdown"}:
            fragment = subprocess.run(command, input=content, text=True,
                                      capture_output=True, check=True).stdout
            heading = FirstHeading()
            heading.feed(fragment)
            title = "".join(heading.parts).strip() or title
        else:
            # A longer fence preserves literal text, including Markdown and HTML.
            fence = "`" * max(3, 1 + max((len(m.group()) for m in
                                        re.finditer(r"`+", content)), default=0))
            content = f"{fence}\n{content}\n{fence}\n"
        directory = Path.cwd() / ".lavish"
        directory.mkdir(exist_ok=True)
        style = Path(__file__).resolve().parents[1] / "assets" / "style.html"
        with tempfile.NamedTemporaryFile(dir=directory, prefix="report-",
                                         suffix=".html", delete=False) as handle:
            output = Path(handle.name)
        try:
            subprocess.run(command + ["-s", "--toc", "--toc-depth=2",
                           "--metadata", f"title={title}", "--include-in-header", str(style),
                           "-o", str(output)], input=content, text=True, check=True)
        except BaseException:
            output.unlink(missing_ok=True)
            raise
    print(f"Opened HTML: {output}", file=sys.stderr, flush=True)
    subprocess.run([launcher, str(output)], check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", type=Path)
    args = parser.parse_args()
    try:
        open_file(args.file)
    except (OSError, UnicodeError, ValueError, subprocess.CalledProcessError) as error:
        print(f"lavish-open: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
