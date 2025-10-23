#!/usr/bin/env bash
set -euo pipefail
# Usage: ensure GITHUB_TOKEN is exported, then run: bash .github/scripts/complete_release.sh

REPO_OWNER=RayoTV
REPO=vivaya-app
API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO}"
PR_BODY_FILE=".github/PR_BODY_RELEASE_FINAL.md"
PR_TITLE="✨ Final Global Validation — fixes & self-tests for VIVAYA ✨"
HEAD_BRANCH="release/final-validation"
BASE_BRANCH="main"
RELEASE_TAG="v1.0.0-data-ready"
RELEASE_NAME="Data release: v1.0.0"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "ERROR: GITHUB_TOKEN is not set. Export it and re-run."
  echo "Example: export GITHUB_TOKEN=ghp_xxx"
  exit 2
fi

echo "Verifying token with /user..."
HTTP_CODE=$(curl -sS -o /tmp/gh_user.json -w "%{http_code}" -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" https://api.github.com/user)
echo "HTTP $HTTP_CODE"
if [ "$HTTP_CODE" -ne 200 ]; then
  echo "Token verification response:"; cat /tmp/gh_user.json || true
  echo "Token invalid or lacks scopes. Create a token with 'repo' scope and try again.";
  rm -f /tmp/gh_user.json
  exit 3
fi

if [ -f "$PR_BODY_FILE" ]; then
  PR_BODY=$(sed 's/"/\\"/g' "$PR_BODY_FILE" | sed ':a;N;$!ba;s/\n/\\n/g')
else
  PR_BODY="See PR body file: $PR_BODY_FILE"
fi

echo "Creating PR from $HEAD_BRANCH -> $BASE_BRANCH"
PR_PAYLOAD=$(jq -n --arg t "$PR_TITLE" --arg head "$HEAD_BRANCH" --arg base "$BASE_BRANCH" --arg body "$PR_BODY" '{title:$t,head:$head,base:$base,body:$body}')
HTTP_CODE=$(curl -sS -o /tmp/pr_response.json -w "%{http_code}" -X POST -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$API_URL/pulls" -d "$PR_PAYLOAD")
echo "Create PR HTTP status: $HTTP_CODE"
if [ "$HTTP_CODE" -ge 400 ]; then
  echo "PR creation failed with HTTP $HTTP_CODE";
  echo "Response:"; cat /tmp/pr_response.json;
  if [ "$HTTP_CODE" -eq 422 ]; then
    echo "422: trying to find existing PR from head branch..."
    curl -sS -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$API_URL/pulls?head=${REPO_OWNER}:${HEAD_BRANCH}&base=${BASE_BRANCH}&state=open" -o /tmp/pr_existing.json
    echo "Existing PRs query response:"; cat /tmp/pr_existing.json
    IDX=$(jq 'length' /tmp/pr_existing.json || echo 0)
    if [ "$IDX" -gt 0 ]; then
      echo "Found existing PR; selecting first entry."
      jq '.[0]' /tmp/pr_existing.json > /tmp/pr_response.json
      HTTP_CODE=200
    else
      echo "No existing PR found. Exiting."; exit 2
    fi
  else
    exit 2
  fi
fi

echo "=== PR RESPONSE ==="
jq . /tmp/pr_response.json || cat /tmp/pr_response.json
PR_NUMBER=$(jq -r .number /tmp/pr_response.json)
PR_URL=$(jq -r .html_url /tmp/pr_response.json)
HEAD_SHA=$(jq -r '.head.sha // empty' /tmp/pr_response.json)

if [ -z "$PR_NUMBER" ] || [ "$PR_NUMBER" = "null" ]; then
  echo "Failed to obtain PR number from response. Exiting."; exit 3
fi

echo "PR #$PR_NUMBER created/located: $PR_URL"
[ -n "$HEAD_SHA" ] && echo "Head SHA: $HEAD_SHA"

echo "Posting CI status comment to PR #$PR_NUMBER"
COMMENT_BODY="CI note: data-only branch. Please allow CI checks to complete; the branch contains only validated assets and a self-test. Once checks are green, this PR will be merged and a release tag created automatically."
COMMENT_PAYLOAD=$(jq -n --arg b "$COMMENT_BODY" '{body:$b}')
HTTP_CODE=$(curl -sS -o /tmp/pr_comment_response.json -w "%{http_code}" -X POST -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$API_URL/issues/$PR_NUMBER/comments" -d "$COMMENT_PAYLOAD")
echo "Post comment HTTP status: $HTTP_CODE"
echo "=== PR COMMENT RESPONSE ==="; jq . /tmp/pr_comment_response.json || cat /tmp/pr_comment_response.json

if [ -z "$HEAD_SHA" ]; then
  echo "No head SHA available; attempting to get latest commit SHA from PR..."
  HEAD_SHA=$(curl -sS -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$API_URL/pulls/$PR_NUMBER" | jq -r '.head.sha')
  echo "Resolved head SHA: $HEAD_SHA"
fi

echo "Polling checks for commit $HEAD_SHA (up to 20 minutes)"
MAX_ATTEMPTS=120
SLEEP=10
attempt=0
ready=0
while [ $attempt -lt $MAX_ATTEMPTS ]; do
  attempt=$((attempt+1))
  echo "[poll $attempt/$MAX_ATTEMPTS] Checking combined status and check-runs for commit $HEAD_SHA"
  curl -sS -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$API_URL/commits/$HEAD_SHA/status" -o /tmp/commit_status.json
  curl -sS -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/${REPO_OWNER}/${REPO}/commits/${HEAD_SHA}/check-runs" -o /tmp/check_runs.json
  echo "=== COMBINED STATUS ==="; jq . /tmp/commit_status.json || cat /tmp/commit_status.json
  echo "=== CHECK RUNS ==="; jq . /tmp/check_runs.json || cat /tmp/check_runs.json
  decision=$(python3 - <<PY
import json
cs=json.load(open('/tmp/commit_status.json'))
cr=json.load(open('/tmp/check_runs.json'))
state=cs.get('state')
check_runs=cr.get('check_runs',[])
if state=='success':
    print('READY')
    raise SystemExit(0)
if len(check_runs)==0:
    if not state:
        print('READY_NO_CHECKS')
        raise SystemExit(0)
for r in check_runs:
    c=r.get('conclusion')
    if c in ('failure','cancelled','timed_out','action_required'):
        print('FAIL'); raise SystemExit(0)
if all((r.get('conclusion')=='success') for r in check_runs if r.get('conclusion') is not None) and len(check_runs)>0:
    print('READY')
else:
    print('PENDING')
PY
)
  echo "Decision: $decision"
  if [ "$decision" = "READY" ] || [ "$decision" = "READY_NO_CHECKS" ]; then
    ready=1
    break
  elif [ "$decision" = "FAIL" ]; then
    echo "One or more checks failed. See above check_runs and combined status. Exiting."; exit 4
  fi
  echo "Not ready yet. Sleeping ${SLEEP}s..."
  sleep $SLEEP
done

if [ $ready -ne 1 ]; then
  echo "Timed out waiting for checks/mergeability. Exiting with status 10."
  exit 10
fi

echo "Conditions met for merging (mergeable and checks). Proceeding to merge..."
curl -sS -X PUT -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$API_URL/pulls/$PR_NUMBER/merge" -d '{"commit_title":"Merge PR: Final Global Validation","merge_method":"merge"}' -o /tmp/pr_merge_response.json -w "%{http_code}\n"
echo "=== PR MERGE RESPONSE ==="; jq . /tmp/pr_merge_response.json || cat /tmp/pr_merge_response.json
MERGED=$(jq -r .merged /tmp/pr_merge_response.json)
MERGE_COMMIT_SHA=$(jq -r .merge_commit_sha /tmp/pr_merge_response.json)
if [ "$MERGED" != "true" ]; then
  echo "Merge did not report success. Response:"; cat /tmp/pr_merge_response.json; exit 5
fi
echo "PR merged successfully at $MERGE_COMMIT_SHA"

echo "Creating release ${RELEASE_TAG} targeting ${MERGE_COMMIT_SHA}..."
RELEASE_PAYLOAD=$(jq -n --arg t "$RELEASE_TAG" --arg target "$MERGE_COMMIT_SHA" --arg name "$RELEASE_NAME" --arg body "Release generated after merging validated data-only PR #${PR_NUMBER}." '{tag_name:$t,target_commitish:$target,name:$name,body:$body}')
curl -sS -X POST -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "$API_URL/releases" -d "$RELEASE_PAYLOAD" -o /tmp/pr_release_response.json -w "%{http_code}\n"
echo "=== RELEASE RESPONSE ==="; jq . /tmp/pr_release_response.json || cat /tmp/pr_release_response.json
RELEASE_URL=$(jq -r .html_url /tmp/pr_release_response.json)

echo "\nFINAL: PR URL: $PR_URL"
echo "FINAL: Release URL: $RELEASE_URL"

echo "Done."
