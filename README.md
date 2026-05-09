# 🚀 GitHub API Pro CLI

![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Status](https://img.shields.io/badge/Status-Production--Ready-brightgreen)

A high-performance, secure, and robust Bash CLI tool for interacting with the GitHub REST API. This tool handles complex tasks like pagination, rate limiting, and JSON integrity automatically.

## ✨ Key Features

- 🔐 **Secure Auth:** Supports `GITHUB_TOKEN` via env, `.env` files, or secure hidden prompt. No more tokens in shell history!
- 📄 **Smart Pagination:** Automatically fetches all pages and merges them into a single **valid** JSON array using `jq`.
- 📊 **Rate Limit Awareness:** Real-time monitoring of GitHub API limits to prevent unexpected blocks.
- ⚡ **Full HTTP Support:** Easily perform `GET`, `POST`, and `DELETE` requests with custom headers and payloads.
- 🎨 **Enhanced UX:** Color-coded logging, progress spinners, and a detailed `--help` menu.
- 🛡️ **Safe & Clean:** Built with `set -euo pipefail` and automated cleanup of temporary files via `trap`.

## 📦 Prerequisites

Ensure you have the following installed:
- `curl`
- `jq` (JSON processor)

## 🚀 Installation & Usage

1. **Clone and Permissions:**
   ```bash
   chmod +x github-api-helper.sh
   ```

2. **Examples:**

   **Fetch all issues from a repo (handles pagination):**
   ```bash
   ./github-api-helper.sh /repos/owner/repo/issues
   ```

   **Post a comment to an issue:**
   ```bash
   ./github-api-helper.sh -X POST -d '{"body": "Fixed in v1.2"}' /repos/owner/repo/issues/1/comments
   ```

   **Save output to a file:**
   ```bash
   ./github-api-helper.sh -o results.json /orgs/my-org/members
   ```

## 🛠 Options

| Flag | Description |
|------|-------------|
| `-t, --token` | GitHub personal access token |
| `-X, --method` | HTTP method (GET, POST, DELETE) |
| `-d, --data` | JSON payload for POST/PUT |
| `-o, --output`| Save results to a specific file |
| `-v, --verbose`| Enable debug logging |

## 📜 License
This project is licensed under the MIT License.
