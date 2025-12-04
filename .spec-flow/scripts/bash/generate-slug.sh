#!/usr/bin/env bash
# Slug Generation Engine
# Converts feature description to normalized kebab-case slug
#
# Usage: generate-slug.sh "feature description"
# Output: normalized-slug-name
#
# Rules:
#   - Remove filler words (the, a, an, to, for, with, etc.)
#   - Convert to kebab-case
#   - Max 50 characters
#   - Remove special characters
#   - Collapse multiple hyphens

set -uo pipefail

# Input validation
if [ -z "${1:-}" ]; then
    echo "error-no-description"
    exit 1
fi

DESCRIPTION="$1"

# Filler words to remove (common articles, prepositions, conjunctions)
FILLER_WORDS="^the$|^a$|^an$|^to$|^for$|^with$|^and$|^or$|^of$|^in$|^on$|^at$|^by$|^as$|^is$|^it$|^be$|^are$|^was$|^were$|^been$|^being$|^have$|^has$|^had$|^do$|^does$|^did$|^will$|^would$|^could$|^should$|^may$|^might$|^must$|^shall$|^can$|^need$|^dare$|^ought$|^used$|^that$|^this$|^these$|^those$|^which$|^who$|^whom$|^whose$|^what$|^where$|^when$|^why$|^how$|^all$|^each$|^every$|^both$|^few$|^more$|^most$|^other$|^some$|^such$|^no$|^nor$|^not$|^only$|^own$|^same$|^so$|^than$|^too$|^very$|^just$|^but$|^if$|^into$|^from$|^up$|^down$|^out$|^off$|^over$|^under$|^again$|^further$|^then$|^once$"

# Action words to keep at start (helps identify feature type)
ACTION_WORDS="add|create|build|implement|fix|update|remove|delete|refactor|optimize|enhance|improve|migrate|integrate|configure|setup|enable|disable"

# Step 1: Convert to lowercase
slug=$(echo "$DESCRIPTION" | tr '[:upper:]' '[:lower:]')

# Step 2: Remove special characters except spaces and hyphens
slug=$(echo "$slug" | sed 's/[^a-z0-9 -]//g')

# Step 3: Split into words and process
words=()
first_word=""
for word in $slug; do
    # Keep action words at the start
    if [ -z "$first_word" ] && echo "$word" | grep -qiE "$ACTION_WORDS"; then
        first_word="$word"
        continue
    fi

    # Remove filler words
    if ! echo "$word" | grep -qiE "$FILLER_WORDS"; then
        words+=("$word")
    fi
done

# Step 4: Reconstruct slug with action word first (if present)
if [ -n "$first_word" ]; then
    slug="$first_word"
    for word in "${words[@]}"; do
        slug="$slug-$word"
    done
else
    # Join remaining words with hyphens
    slug=$(IFS=-; echo "${words[*]}")
fi

# Step 5: Collapse multiple hyphens and trim
slug=$(echo "$slug" | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//')

# Step 6: Truncate to 50 characters (at word boundary if possible)
if [ ${#slug} -gt 50 ]; then
    # Try to cut at a hyphen boundary
    truncated="${slug:0:50}"
    if [[ "$truncated" == *-* ]]; then
        # Find last hyphen position
        last_hyphen=$(echo "$truncated" | grep -ob '-' | tail -1 | cut -d: -f1)
        if [ -n "$last_hyphen" ] && [ "$last_hyphen" -gt 20 ]; then
            slug="${truncated:0:$last_hyphen}"
        else
            slug="$truncated"
        fi
    else
        slug="$truncated"
    fi
fi

# Step 7: Final cleanup - remove trailing hyphens
slug=$(echo "$slug" | sed 's/-$//')

# Output the slug
echo "$slug"
