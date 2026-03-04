#!/bin/bash
# Validates .claude-plugin/plugin.json:
#   1. Valid JSON syntax
#   2. Required field: name (non-empty, kebab-case)
#   3. Metadata field types (version, description, author, homepage, etc.)
#   4. Component path field types (skills, hooks, mcpServers, etc.)
#   5. No unknown top-level keys
#   6. Referenced paths exist on disk

MANIFEST=".claude-plugin/plugin.json"
errors=0

# --- Prerequisite: jq must be available ---
if ! command -v jq &>/dev/null; then
  echo "::error::jq is required but not installed"
  exit 1
fi

# --- Check 1: JSON syntax ---
if ! jq empty "$MANIFEST" 2>/dev/null; then
  echo "::error file=$MANIFEST::Invalid JSON syntax"
  exit 1
fi

manifest=$(cat "$MANIFEST")

# --- Check 2: name field (required, non-empty, kebab-case) ---
name=$(echo "$manifest" | jq -r '.name // empty')
if [[ -z "$name" ]]; then
  echo "::error file=$MANIFEST::Missing or empty required field 'name'"
  errors=$((errors + 1))
elif [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
  echo "::error file=$MANIFEST::Invalid name '$name' — must match ^[a-z0-9-]+$"
  errors=$((errors + 1))
fi

# --- Check 3: Metadata field types ---

# String fields (if present)
for field in version description homepage repository license; do
  type=$(echo "$manifest" | jq -r "if has(\"$field\") then (.${field} | type) else \"absent\" end")
  if [[ "$type" != "absent" && "$type" != "string" ]]; then
    echo "::error file=$MANIFEST::'$field' must be a string, got $type"
    errors=$((errors + 1))
  fi
done

# author (object with optional string fields, if present)
author_type=$(echo "$manifest" | jq -r 'if has("author") then (.author | type) else "absent" end')
if [[ "$author_type" != "absent" ]]; then
  if [[ "$author_type" != "object" ]]; then
    echo "::error file=$MANIFEST::'author' must be an object, got $author_type"
    errors=$((errors + 1))
  else
    for sub in name email url; do
      sub_type=$(echo "$manifest" | jq -r "if .author | has(\"$sub\") then (.author.${sub} | type) else \"absent\" end")
      if [[ "$sub_type" != "absent" && "$sub_type" != "string" ]]; then
        echo "::error file=$MANIFEST::'author.$sub' must be a string, got $sub_type"
        errors=$((errors + 1))
      fi
    done
  fi
fi

# keywords (array of strings, if present)
keywords_type=$(echo "$manifest" | jq -r 'if has("keywords") then (.keywords | type) else "absent" end')
if [[ "$keywords_type" != "absent" ]]; then
  if [[ "$keywords_type" != "array" ]]; then
    echo "::error file=$MANIFEST::'keywords' must be an array, got $keywords_type"
    errors=$((errors + 1))
  else
    non_string_count=$(echo "$manifest" | jq '[.keywords[] | type != "string"] | map(select(.)) | length')
    if [[ "$non_string_count" -gt 0 ]]; then
      echo "::error file=$MANIFEST::'keywords' must contain only strings, found $non_string_count non-string element(s)"
      errors=$((errors + 1))
    fi
  fi
fi

# --- Check 4: Component path field types ---

# Fields that accept string, array of strings, or object
for field in skills hooks mcpServers lspServers outputStyles; do
  type=$(echo "$manifest" | jq -r "if has(\"$field\") then (.${field} | type) else \"absent\" end")
  if [[ "$type" == "absent" ]]; then
    continue
  fi
  if [[ "$type" != "string" && "$type" != "array" && "$type" != "object" ]]; then
    echo "::error file=$MANIFEST::'$field' must be a string, array of strings, or object — got $type"
    errors=$((errors + 1))
  elif [[ "$type" == "array" ]]; then
    non_string_count=$(echo "$manifest" | jq "[.${field}[] | type != \"string\"] | map(select(.)) | length")
    if [[ "$non_string_count" -gt 0 ]]; then
      echo "::error file=$MANIFEST::'$field' array must contain only strings, found $non_string_count non-string element(s)"
      errors=$((errors + 1))
    fi
  fi
done

# Fields that accept string or array of strings only
for field in commands agents; do
  type=$(echo "$manifest" | jq -r "if has(\"$field\") then (.${field} | type) else \"absent\" end")
  if [[ "$type" == "absent" ]]; then
    continue
  fi
  if [[ "$type" != "string" && "$type" != "array" ]]; then
    echo "::error file=$MANIFEST::'$field' must be a string or array of strings — got $type"
    errors=$((errors + 1))
  elif [[ "$type" == "array" ]]; then
    non_string_count=$(echo "$manifest" | jq "[.${field}[] | type != \"string\"] | map(select(.)) | length")
    if [[ "$non_string_count" -gt 0 ]]; then
      echo "::error file=$MANIFEST::'$field' array must contain only strings, found $non_string_count non-string element(s)"
      errors=$((errors + 1))
    fi
  fi
done

# --- Check 5: No unknown top-level keys ---
known_keys='["name","version","description","author","homepage","repository","license","keywords","commands","agents","skills","hooks","mcpServers","outputStyles","lspServers"]'
unknown=$(echo "$manifest" | jq -r --argjson known "$known_keys" 'keys[] | select(. as $k | $known | index($k) | not)')
if [[ -n "$unknown" ]]; then
  while IFS= read -r key; do
    echo "::warning file=$MANIFEST::Unknown top-level key '$key'"
  done <<< "$unknown"
fi

# --- Check 6: Path validation ---
# Helper: check a single path exists relative to project root
check_path() {
  local field="$1"
  local path="$2"
  if [[ ! -e "$path" ]]; then
    echo "::error file=$MANIFEST::Path '$path' referenced by '$field' does not exist"
    errors=$((errors + 1))
  fi
}

for field in skills hooks mcpServers lspServers outputStyles commands agents; do
  type=$(echo "$manifest" | jq -r "if has(\"$field\") then (.${field} | type) else \"absent\" end")
  if [[ "$type" == "absent" ]]; then
    continue
  fi

  if [[ "$type" == "string" ]]; then
    path=$(echo "$manifest" | jq -r ".${field}")
    check_path "$field" "$path"
  elif [[ "$type" == "array" ]]; then
    while IFS= read -r path; do
      check_path "$field" "$path"
    done < <(echo "$manifest" | jq -r ".${field}[]")
  fi
  # Objects (inline configs) — skip path validation
done

# --- Summary ---
echo ""
if [[ $errors -gt 0 ]]; then
  echo "❌ Manifest validation failed with $errors error(s)."
  exit 1
else
  echo "✅ Plugin manifest is valid."
fi
