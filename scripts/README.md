Download songs helper
=====================

What this does
- Read a plain text file with one song name per line.
- For each line, search YouTube and download audio as MP3 (192k) using yt-dlp + ffmpeg.
- If an MP3 matching the song is already present in your Windows Downloads folder, it will be copied into the new output folder instead of re-downloading.

Prerequisites
- Python 3.8+
- ffmpeg installed and on PATH (installed in WSL or Windows accessible via /mnt/c)
- Install Python deps:

```bash
python -m pip install -r scripts/requirements.txt
```

Usage

Create a text file, e.g. `songs.txt`, with one song name per line.

Run the script from the repo root or anywhere:

```bash
python3 scripts/download_songs.py songs.txt
```

Options
- --output / -o : custom output folder
- --workers / -w : parallel downloads (default 4)

Notes and WSL behavior
- The script will attempt to find your Windows Downloads folder under `/mnt/c/Users/<you>/Downloads` when running in WSL; if not found it will use `~/Downloads` inside WSL.
- The script only copies existing mp3s from the Downloads folder. It won't search other folders.
- No support for private or authenticated videos.

Legal
- Downloading YouTube content may violate YouTube's Terms of Service; you confirmed you intend to download only content you're allowed to in your jurisdiction.
