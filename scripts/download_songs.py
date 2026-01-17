#!/usr/bin/env python3
"""Download MP3s for song names (YouTube search -> mp3) into user's Downloads folder.

Behavior:
- Read plain text file with one song name per line.
- For each name, search YouTube and download audio as MP3 (192k) using yt-dlp + ffmpeg.
- If an MP3 with a matching filename already exists in the user's Downloads folder, copy it into the target folder instead of downloading.
- Parallel downloads with a thread pool (default 4).
- Write basic ID3 tags (title) and embed thumbnail when available.
"""

import argparse
import concurrent.futures
import datetime
import os
import shutil
import subprocess
import sys
from pathlib import Path

try:
    import yt_dlp
except Exception:
    print("yt-dlp is required. Install from requirements.txt (pip install -r requirements.txt)")
    raise

try:
    from mutagen.easyid3 import EasyID3
    from mutagen.id3 import ID3, APIC
except Exception:
    print("mutagen is required. Install from requirements.txt (pip install -r requirements.txt)")
    raise


def downloads_folder_windows_from_wsl():
    # Try common WSL path to Windows Downloads
    # If WSL mounts C: under /mnt/c
    possible = [Path('/mnt/c/Users')]
    for base in possible:
        if base.exists():
            # attempt to find current Windows user by matching /mnt/c/Users/<username>
            for userdir in base.iterdir():
                downloads = userdir / 'Downloads'
                if downloads.exists():
                    return downloads
    # fallback to Linux ~/Downloads
    return Path.home() / 'Downloads'


def find_existing_in_downloads(name, downloads_dir):
    # Simple heuristic: look for files in downloads_dir whose stem contains all words from name
    words = [w.lower() for w in name.replace('-', ' ').split() if w]
    for f in downloads_dir.glob('**/*.mp3'):
        stem = f.stem.lower()
        if all(w in stem for w in words):
            return f
    return None


def download_song(name, target_dir, downloads_dir, bitrate='192k'):
    safe_name = " - ".join([name])
    out_path = target_dir / f"{safe_name}.mp3"

    # If file exists in target, skip
    if out_path.exists():
        return f"skipped (exists): {out_path}"

    # If matching file exists in Downloads, copy
    existing = find_existing_in_downloads(name, downloads_dir)
    if existing:
        shutil.copy2(existing, out_path)
        return f"copied from downloads: {existing.name} -> {out_path.name}"

    # Use yt-dlp to search and download best audio, then convert to mp3 192k via ffmpeg
    ydl_opts = {
        'format': 'bestaudio/best',
        'outtmpl': str((target_dir / '%(title)s.%(ext)s')),
        'noplaylist': True,
        'quiet': True,
        'no_warnings': True,
        'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'mp3',
            'preferredquality': '192',
        }, {
            'key': 'EmbedThumbnail',
        }],
        # don't write metadata via yt-dlp; we'll adjust tags after
    }

    query = f"ytsearch1:{name}"
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(query, download=True)
            # Find the downloaded file path
            if 'entries' in info and info['entries']:
                info = info['entries'][0]
            filename = ydl.prepare_filename(info)
            # prepared filename might have original extension; convert to .mp3
            mp3_name = Path(filename).with_suffix('.mp3')
            if mp3_name.exists():
                # set ID3 title tag
                try:
                    audio = EasyID3(str(mp3_name))
                except Exception:
                    audio = ID3()
                try:
                    EasyID3(str(mp3_name))
                    EasyID3(str(mp3_name))['title'] = info.get('title', name)
                    EasyID3(str(mp3_name)).save()
                except Exception:
                    pass
                # Move/rename to desired output name
                mp3_name.rename(out_path)
                return f"downloaded: {out_path.name}"
            else:
                return f"failed: no mp3 produced for {name}"
    except Exception as e:
        return f"error: {name} -> {e}"


def main():
    parser = argparse.ArgumentParser(description='Download songs from YouTube into MP3s')
    parser.add_argument('input', help='Plain text file with one song name per line')
    parser.add_argument('--output', '-o', help='Output folder (optional)')
    parser.add_argument('--workers', '-w', type=int, default=4, help='Parallel downloads')
    args = parser.parse_args()

    input_file = Path(args.input)
    if not input_file.exists():
        print('Input file not found:', input_file)
        sys.exit(2)

    # Determine downloads folder (Windows via WSL or Linux)
    downloads_dir = downloads_folder_windows_from_wsl()

    date = datetime.date.today().isoformat()
    default_out = downloads_dir / f"songs converted {date}"
    target_dir = Path(args.output) if args.output else default_out
    target_dir.mkdir(parents=True, exist_ok=True)

    with input_file.open('r', encoding='utf-8') as f:
        lines = [l.strip() for l in f if l.strip()]

    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.workers) as ex:
        futures = [ex.submit(download_song, name, target_dir, downloads_dir) for name in lines]
        for fut in concurrent.futures.as_completed(futures):
            results.append(fut.result())

    for r in results:
        print(r)


if __name__ == '__main__':
    main()
