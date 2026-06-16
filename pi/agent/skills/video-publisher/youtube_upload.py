#!/usr/bin/env python3
"""YouTube Shorts uploader via YouTube Data API v3.

Usage:
    python3 youtube_upload.py upload --file VIDEO.mp4 --title "Title" --description "Desc" --tags "tag1,tag2"
    python3 youtube_upload.py auth    # Interactive OAuth setup (first time only)
    python3 youtube_upload.py check   # Verify credentials work
"""

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path

CREDS_DIR = Path(os.environ.get("YOUTUBE_CREDENTIALS_DIR", Path.home() / ".pi" / "youtube_credentials"))
CLIENT_SECRETS = CREDS_DIR / "client_secrets.json"
TOKEN_FILE = CREDS_DIR / "token.json"

# youtube.force-ssl is required for commentThreads.insert (posting comments).
# youtube.upload covers video uploads; youtube covers read ops.
SCOPES = ["https://www.googleapis.com/auth/youtube.upload",
          "https://www.googleapis.com/auth/youtube",
          "https://www.googleapis.com/auth/youtube.force-ssl"]


def get_credentials():
    """Load or refresh OAuth2 credentials."""
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request

    if not TOKEN_FILE.exists():
        print(f"ERROR: No token found at {TOKEN_FILE}")
        print("Run: python3 youtube_upload.py auth")
        sys.exit(1)

    creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
        TOKEN_FILE.write_text(creds.to_json())
    return creds


def do_auth():
    """Interactive OAuth2 flow. Run once to set up credentials."""
    from google_auth_oauthlib.flow import InstalledAppFlow

    CREDS_DIR.mkdir(parents=True, exist_ok=True)

    if not CLIENT_SECRETS.exists():
        print(f"ERROR: Place your client_secrets.json at:\n  {CLIENT_SECRETS}")
        print()
        print("To get it:")
        print("1. Go to https://console.cloud.google.com/")
        print("2. Create a project (or select existing)")
        print("3. Enable 'YouTube Data API v3'")
        print("4. Go to Credentials → Create Credentials → OAuth client ID")
        print("5. Application type: Desktop app")
        print("6. Download JSON → rename to client_secrets.json")
        print(f"7. Place at: {CLIENT_SECRETS}")
        sys.exit(1)

    flow = InstalledAppFlow.from_client_secrets_file(str(CLIENT_SECRETS), SCOPES)
    creds = flow.run_local_server(port=8090, prompt="consent")

    TOKEN_FILE.write_text(creds.to_json())
    print(f"Token saved to {TOKEN_FILE}")
    print("Authentication successful!")


def do_check():
    """Verify credentials work by fetching channel info."""
    from googleapiclient.discovery import build

    creds = get_credentials()
    youtube = build("youtube", "v3", credentials=creds)

    response = youtube.channels().list(part="snippet,statistics", mine=True).execute()
    if not response["items"]:
        print("ERROR: No channel found for this account")
        sys.exit(1)

    ch = response["items"][0]
    print(f"Channel: {ch['snippet']['title']}")
    print(f"Subscribers: {ch['statistics'].get('subscriberCount', 'hidden')}")
    print(f"Videos: {ch['statistics']['videoCount']}")

    # Read ACTUAL granted scopes from the token file — `creds.scopes` reflects
    # what we asked for, not what Google issued, so it can lie.
    token_data = json.loads(TOKEN_FILE.read_text())
    granted = set(token_data.get("scopes") or [])
    required = set(SCOPES)
    missing = required - granted
    upload_scope = "https://www.googleapis.com/auth/youtube.upload"
    comment_scope = "https://www.googleapis.com/auth/youtube.force-ssl"
    print()
    print(f"Can upload:   {'yes' if upload_scope in granted else 'NO'}")
    print(f"Can comment:  {'yes' if comment_scope in granted else 'NO (re-auth needed)'}")
    if missing:
        print()
        print(f"Missing scopes: {sorted(missing)}")
        print("Run: python3 youtube_upload.py auth   to re-authorize")
        sys.exit(2)
    print("Credentials OK!")


def do_recent(args):
    """Fetch recent videos with performance stats."""
    from googleapiclient.discovery import build

    creds = get_credentials()
    youtube = build("youtube", "v3", credentials=creds)

    # Get uploads playlist
    ch = youtube.channels().list(part="contentDetails", mine=True).execute()
    uploads_id = ch["items"][0]["contentDetails"]["relatedPlaylists"]["uploads"]

    count = args.count or 10
    pl = youtube.playlistItems().list(
        part="contentDetails", playlistId=uploads_id, maxResults=count
    ).execute()
    video_ids = [item["contentDetails"]["videoId"] for item in pl["items"]]

    if not video_ids:
        print("No videos found.")
        return

    vids = youtube.videos().list(
        part="snippet,statistics,contentDetails", id=",".join(video_ids)
    ).execute()

    for v in vids["items"]:
        s = v["snippet"]
        st = v["statistics"]
        print(f"TITLE: {s['title']}")
        print(f"  Views: {st.get('viewCount', 0)} | Likes: {st.get('likeCount', 0)} | Comments: {st.get('commentCount', 0)} | Duration: {v['contentDetails']['duration']}")
        print(f"  Published: {s['publishedAt']}")
        print()


def video_status_summary(youtube, video_id):
    """Return a compact status summary for an uploaded video."""
    response = youtube.videos().list(
        part="snippet,status,contentDetails", id=video_id
    ).execute()
    if not response.get("items"):
        return {"video_id": video_id, "error": "video not found"}

    item = response["items"][0]
    snippet = item.get("snippet", {})
    status = item.get("status", {})
    content = item.get("contentDetails", {})
    publish_at = status.get("publishAt")
    return {
        "video_id": video_id,
        "title": snippet.get("title"),
        "publishedAt": snippet.get("publishedAt"),
        "privacyStatus": status.get("privacyStatus"),
        "publishAt": publish_at,
        "publishAtLocal": iso_to_local_string(publish_at) if publish_at else None,
        "uploadStatus": status.get("uploadStatus"),
        "duration": content.get("duration"),
    }


def iso_to_local_string(value):
    """Format an ISO 8601 timestamp in the machine's local timezone."""
    if not value:
        return None
    try:
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
        return dt.astimezone().strftime("%Y-%m-%d %H:%M:%S %z %Z")
    except ValueError:
        return None


def do_comment(args):
    """Post a comment on a video."""
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError

    creds = get_credentials()
    youtube = build("youtube", "v3", credentials=creds)

    try:
        result = youtube.commentThreads().insert(
            part="snippet",
            body={
                "snippet": {
                    "videoId": args.video_id,
                    "topLevelComment": {
                        "snippet": {"textOriginal": args.text}
                    },
                }
            },
        ).execute()
    except HttpError as exc:
        status = video_status_summary(youtube, args.video_id)
        if status.get("privacyStatus") == "private" and status.get("publishAt"):
            print("ERROR: Cannot post a comment while the video is private/scheduled.")
            print(f"  Scheduled publish: {status.get('publishAt')} ({status.get('publishAtLocal')})")
            print("  Save this as pending_comment and post it after publication:")
            print()
            print(args.text)
            sys.exit(3)
        raise exc

    comment_id = result["id"]
    print(f"Comment posted!")
    print(f"  Comment ID: {comment_id}")
    print(f"  Video: https://www.youtube.com/shorts/{args.video_id}")


def do_upload(args):
    """Upload a video to YouTube as a Short."""
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload

    if not os.path.exists(args.file):
        print(f"ERROR: File not found: {args.file}")
        sys.exit(1)

    creds = get_credentials()
    youtube = build("youtube", "v3", credentials=creds)

    # Build request body
    body = {
        "snippet": {
            "title": args.title,
            "description": args.description,
            "tags": [t.strip() for t in args.tags.split(",")] if args.tags else [],
            "categoryId": "22",  # People & Blogs
            "defaultLanguage": args.language or "ru",
            "defaultAudioLanguage": args.language or "ru",
        },
        "status": {
            "privacyStatus": "private" if args.publish_at else (args.privacy or "public"),
            "selfDeclaredMadeForKids": False,
            "shorts": {"shortsEligibility": "ELIGIBLE"},
            **({"publishAt": args.publish_at} if args.publish_at else {}),
        },
    }

    media = MediaFileUpload(
        args.file,
        mimetype="video/mp4",
        resumable=True,
        chunksize=10 * 1024 * 1024,  # 10MB chunks
    )

    request = youtube.videos().insert(
        part="snippet,status",
        body=body,
        media_body=media,
    )

    print(f"Uploading: {args.file}")
    print(f"Title: {args.title}")
    print(f"Privacy: {'private (scheduled)' if args.publish_at else (args.privacy or 'public')}")
    if args.publish_at:
        print(f"Publish at: {args.publish_at} ({iso_to_local_string(args.publish_at) or 'local time unknown'})")
        if args.pending_comment:
            print("Pending comment: saved to result JSON; scheduled/private videos cannot be commented before publication.")

    response = None
    while response is None:
        status, response = request.next_chunk()
        if status:
            pct = int(status.progress() * 100)
            print(f"  Progress: {pct}%")

    video_id = response["id"]
    url = f"https://www.youtube.com/shorts/{video_id}"
    studio_url = f"https://studio.youtube.com/video/{video_id}/edit"

    print()
    print(f"Upload complete!")
    print(f"  Watch: {url}")
    print(f"  Studio: {studio_url}")
    print(f"  Video ID: {video_id}")

    # Verify the server-side status after upload. This is especially important
    # for scheduled uploads: YouTube keeps them private until `publishAt`.
    status = video_status_summary(youtube, video_id)
    print("  Status:")
    print(f"    privacyStatus: {status.get('privacyStatus')}")
    print(f"    uploadStatus:  {status.get('uploadStatus')}")
    if status.get("publishAt"):
        print(f"    publishAt:     {status.get('publishAt')}")
        print(f"    local time:    {status.get('publishAtLocal')}")

    # Output JSON for programmatic use and traceability.
    result = {
        "video_id": video_id,
        "url": url,
        "studio_url": studio_url,
        "title": args.title,
        "description": args.description,
        "tags": [t.strip() for t in args.tags.split(",")] if args.tags else [],
        "privacy_requested": args.privacy,
        "privacy_effective": status.get("privacyStatus"),
        "publish_at_requested": args.publish_at or None,
        "pending_comment": args.pending_comment or None,
        "status": status,
    }
    result_file = Path(args.file).parent / f".upload_result_{video_id}.json"
    result_file.write_text(json.dumps(result, ensure_ascii=False, indent=2))
    print(f"  Result saved: {result_file}")


def main():
    parser = argparse.ArgumentParser(description="YouTube Shorts Uploader")
    sub = parser.add_subparsers(dest="command")

    sub.add_parser("auth", help="Interactive OAuth setup")
    sub.add_parser("check", help="Verify credentials")

    upload_p = sub.add_parser("upload", help="Upload video")
    upload_p.add_argument("--file", required=True, help="Path to MP4 file")
    upload_p.add_argument("--title", required=True, help="Video title")
    upload_p.add_argument("--description", default="", help="Video description")
    upload_p.add_argument("--tags", default="", help="Comma-separated tags")
    upload_p.add_argument("--privacy", default="public", choices=["public", "unlisted", "private"])
    upload_p.add_argument("--publish-at", default="", help="Schedule publish time in ISO 8601 (e.g. 2026-04-01T20:00:00+03:00). Sets privacy to private until publish time.")
    upload_p.add_argument("--pending-comment", default="", help="Comment text to save in the upload result JSON for scheduled/private videos. It is not posted automatically before publication.")
    upload_p.add_argument("--language", default="ru", help="Content language code")

    recent_p = sub.add_parser("recent", help="Show recent videos with stats")
    recent_p.add_argument("--count", type=int, default=10, help="Number of videos to fetch")

    comment_p = sub.add_parser("comment", help="Post a comment on a video")
    comment_p.add_argument("--video-id", required=True, help="YouTube video ID")
    comment_p.add_argument("--text", required=True, help="Comment text")

    args = parser.parse_args()
    if args.command == "auth":
        do_auth()
    elif args.command == "check":
        do_check()
    elif args.command == "upload":
        do_upload(args)
    elif args.command == "recent":
        do_recent(args)
    elif args.command == "comment":
        do_comment(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
