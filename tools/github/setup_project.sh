#!/usr/bin/env bash
# Creates the GitHub labels, milestones, card issues, DD-005 sub-issues and the
# GitHub Project board for deal-desk-check. Safe to re-run: existing items are reused.
#
# Before running:
#   1. The repo exists on GitHub and is pushed.
#   2. gh is logged in with project scope:   gh auth refresh -s project
# Run from the repo root:                    bash tools/github/setup_project.sh
# Override the defaults if needed:           REPO=owner/name PROJECT_TITLE="..." bash tools/github/setup_project.sh
#
# Written for bash 3.2 (the macOS default): no associative arrays.
set -euo pipefail

command -v gh >/dev/null || { echo "gh is required: brew install gh"; exit 1; }
command -v jq >/dev/null || { echo "jq is required: brew install jq"; exit 1; }

REPO="${REPO:-raduteodoriu-stack/deal-desk-check}"
OWNER="${REPO%%/*}"
PROJECT_TITLE="${PROJECT_TITLE:-Deal Desk MVP}"
DIR="$(cd "$(dirname "$0")" && pwd)/issues"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# id|title|phase|estimate_days|area|milestone|extra_label|depends_on (space-separated)
# DD-005 estimate is 0 because its 3.5 days sit on the A/B/C sub-issues (no double counting).
CARDS='DD-001|Scope & governance|MVP|0.5|Docs|MVP||
DD-002|Deal desk policy & rules v1.4|MVP|0.5|Rules|MVP|rule-change|DD-001
DD-003|Test deal set & answer keys|MVP|1.5|Tests|MVP||DD-002
DD-004|Quote engine (slim)|MVP|1.5|Engine|MVP||DD-002 DD-003
DD-006|Standard contract, clause playbook, contract generator|MVP|1|Tests|MVP||DD-003
DD-014|Deterministic pre-check: hash, diff, regex|MVP|1|Engine|MVP||DD-006
DD-007|LLM extraction for changed clauses|MVP|1|AI|MVP||DD-014
DD-008|Comparator & decision|MVP|1|Engine|MVP||DD-004 DD-014 DD-007
DD-005|Salesforce thin slice: gate, terms approvals, Flows|MVP|0|Salesforce|MVP||DD-002 DD-003
DD-005A|Booking gate|MVP|1|Salesforce|MVP||
DD-005B|Price book and non-standard terms approval|MVP|1|Salesforce|MVP||
DD-005C|Record-triggered Flows|MVP|1|Salesforce|MVP||DD-005B
DD-013|Portfolio (slim)|MVP|0.5|Docs|MVP||DD-008 DD-005
DD-012|Claude skills packaging + evals|Post-MVP|1|AI|Post-MVP||DD-004 DD-008
DD-009|Orchestration in n8n|Post-MVP|1.5|Automation|Post-MVP||DD-005 DD-008
DD-010|Booking queue & Finance export|Post-MVP|1|Salesforce|Post-MVP||DD-005 DD-009
DD-011|Deal desk analytics (dbt + Superset)|Post-MVP|1.5|Analytics|Post-MVP||DD-004 DD-010'

AREAS="Rules,Tests,Engine,AI,Salesforce,Automation,Analytics,Docs"

echo "== Labels"
gh label create card --repo "$REPO" --color 0E8A16 --description "One issue per DD card" --force
gh label create rule-change --repo "$REPO" --color D93F0B --description "Changes a rules file version; needs a change note" --force
IFS=',' ; for a in $AREAS; do
  low="$(echo "$a" | tr '[:upper:]' '[:lower:]')"
  gh label create "area:$low" --repo "$REPO" --color 1D76DB --force
done ; unset IFS

echo "== Milestones"
for m in "MVP" "Post-MVP"; do
  exists="$(gh api "repos/$REPO/milestones?state=all" --jq ".[] | select(.title==\"$m\") | .number")"
  [ -n "$exists" ] || gh api "repos/$REPO/milestones" -f title="$m" >/dev/null
done

echo "== Issues"
gh issue list --repo "$REPO" --state all --limit 200 --json title,number,url > "$TMP/existing.json"
while IFS='|' read -r id title phase est area ms extra deps <&3; do
  url="$(jq -r --arg p "$id " '.[] | select(.title | startswith($p)) | .url' "$TMP/existing.json" | head -n1)"
  if [ -z "$url" ]; then
    low="$(echo "$area" | tr '[:upper:]' '[:lower:]')"
    labels="card,area:$low"; [ -n "$extra" ] && labels="$labels,$extra"
    url="$(gh issue create --repo "$REPO" --title "$id $title" --body-file "$DIR/$id.md" \
            --label "$labels" --milestone "$ms")"
    echo "created $id -> $url"
  else
    echo "exists  $id -> $url"
  fi
  echo "$url" > "$TMP/$id.url"
  echo "${url##*/}" > "$TMP/$id.num"
done 3<<< "$CARDS"

echo "== DD-005 sub-issues"
parent="$(cat "$TMP/DD-005.num")"
for child in DD-005A DD-005B DD-005C; do
  cid="$(gh api "repos/$REPO/issues/$(cat "$TMP/$child.num")" --jq .id)"
  gh api -X POST "repos/$REPO/issues/$parent/sub_issues" -F sub_issue_id="$cid" >/dev/null 2>&1 \
    && echo "linked $child under DD-005" || echo "skip  $child (already linked or not supported)"
done

echo "== Blocked-by links (best effort; the 'Depends on' line in each issue stays the record)"
while IFS='|' read -r id title phase est area ms extra deps <&3; do
  for d in $deps; do
    did="$(gh api "repos/$REPO/issues/$(cat "$TMP/$d.num")" --jq .id)"
    gh api -X POST "repos/$REPO/issues/$(cat "$TMP/$id.num")/dependencies/blocked_by" -F issue_id="$did" >/dev/null 2>&1 \
      && echo "$id blocked by $d" || echo "skip  $id <- $d"
  done
done 3<<< "$CARDS"

echo "== Project"
pnum="$(gh project list --owner "$OWNER" --format json --jq ".projects[] | select(.title==\"$PROJECT_TITLE\") | .number" | head -n1)"
if [ -z "$pnum" ]; then
  pnum="$(gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json --jq .number)"
  echo "created project #$pnum"
fi
gh project link "$pnum" --owner "$OWNER" --repo "$REPO" >/dev/null 2>&1 || true
pid="$(gh project view "$pnum" --owner "$OWNER" --format json --jq .id)"

gh project field-list "$pnum" --owner "$OWNER" --format json > "$TMP/fields.json"
has_field() { jq -e --arg n "$1" '.fields[] | select(.name==$n)' "$TMP/fields.json" >/dev/null; }
has_field "Phase" || gh project field-create "$pnum" --owner "$OWNER" --name "Phase" --data-type SINGLE_SELECT --single-select-options "MVP,Post-MVP" >/dev/null
has_field "Area"  || gh project field-create "$pnum" --owner "$OWNER" --name "Area" --data-type SINGLE_SELECT --single-select-options "$AREAS" >/dev/null
has_field "Estimate (days)" || gh project field-create "$pnum" --owner "$OWNER" --name "Estimate (days)" --data-type NUMBER >/dev/null
gh project field-list "$pnum" --owner "$OWNER" --format json > "$TMP/fields.json"

fid()  { jq -r --arg n "$1" '.fields[] | select(.name==$n) | .id' "$TMP/fields.json"; }
oid()  { jq -r --arg n "$1" --arg o "$2" '.fields[] | select(.name==$n) | .options[] | select(.name==$o) | .id' "$TMP/fields.json"; }
F_PHASE="$(fid Phase)"; F_AREA="$(fid Area)"; F_EST="$(fid 'Estimate (days)')"

echo "== Add issues to the board and set fields"
while IFS='|' read -r id title phase est area ms extra deps <&3; do
  item="$(gh project item-add "$pnum" --owner "$OWNER" --url "$(cat "$TMP/$id.url")" --format json --jq .id)"
  gh project item-edit --id "$item" --project-id "$pid" --field-id "$F_PHASE" --single-select-option-id "$(oid Phase "$phase")" >/dev/null
  gh project item-edit --id "$item" --project-id "$pid" --field-id "$F_AREA"  --single-select-option-id "$(oid Area "$area")" >/dev/null
  gh project item-edit --id "$item" --project-id "$pid" --field-id "$F_EST"   --number "$est" >/dev/null
  echo "board  $id ($phase, $area, $est d)"
done 3<<< "$CARDS"

echo
echo "Done. One manual step in the browser: open the project, then Settings > Status field,"
echo "and rename the options to: Backlog, Ready, In progress, Review, Done."
echo "Then switch the view to Board, grouped by Status, and filter Phase = MVP."
