#!/bin/bash
# Validates that every skills/*/SKILL.md follows the required structure:
#   1. YAML frontmatter delimiters (opening and closing ---)
#   2. name field present and matching ^vgv-[a-z0-9-]+$
#   3. name equals "vgv-" + parent directory name
#   4. description field present and non-empty
#   5. allowed-tools field present and non-empty
#   6. H1 heading after frontmatter
#   7. "## Core Standards" section exists

errors=0

while IFS= read -r file; do
  file_errors=0
  dir_name=$(basename "$(dirname "$file")")

  # --- Check 1: Frontmatter opening ---
  line1=$(sed -n '1p' "$file")
  if [[ "$line1" != "---" ]]; then
    echo "::error file=$file,line=1::Missing frontmatter opening delimiter (expected '---' on line 1)"
    errors=$((errors + 1))
    file_errors=$((file_errors + 1))
  fi

  # --- Check 2: Frontmatter closing ---
  closing_line=$(awk 'NR > 1 && /^---$/ { print NR; exit }' "$file")
  if [[ -z "$closing_line" ]]; then
    echo "::error file=$file::Missing frontmatter closing delimiter (no second '---' found)"
    errors=$((errors + 1))
    # Bail out — remaining checks depend on valid frontmatter
    continue
  fi

  # Extract frontmatter content (between the two --- lines)
  frontmatter=$(sed -n "2,$((closing_line - 1))p" "$file")

  # --- Check 3: name field exists ---
  name_line=$(echo "$frontmatter" | grep -m1 '^name:')
  if [[ -z "$name_line" ]]; then
    echo "::error file=$file::Missing 'name' field in frontmatter"
    errors=$((errors + 1))
    file_errors=$((file_errors + 1))
  else
    # --- Check 4: name format ---
    name_value=$(echo "$name_line" | sed 's/^name:[[:space:]]*//')
    if [[ ! "$name_value" =~ ^vgv-[a-z0-9-]+$ ]]; then
      echo "::error file=$file::Invalid name '$name_value' — must match ^vgv-[a-z0-9-]+$"
      errors=$((errors + 1))
      file_errors=$((file_errors + 1))
    fi

    # --- Check 5: name matches directory ---
    if [[ "$name_value" != "vgv-$dir_name" ]]; then
      echo "::error file=$file::Frontmatter name '$name_value' does not match expected 'vgv-$dir_name'"
      errors=$((errors + 1))
      file_errors=$((file_errors + 1))
    fi
  fi

  # --- Check 6: allowed-tools field ---
  allowed_tools_line=$(echo "$frontmatter" | grep -m1 '^allowed-tools:')
  if [[ -z "$allowed_tools_line" ]]; then
    echo "::error file=$file::Missing 'allowed-tools' field in frontmatter"
    errors=$((errors + 1))
    file_errors=$((file_errors + 1))
  else
    allowed_tools_value=$(echo "$allowed_tools_line" | sed 's/^allowed-tools:[[:space:]]*//')
    if [[ -z "$allowed_tools_value" ]]; then
      echo "::error file=$file::Empty 'allowed-tools' field in frontmatter"
      errors=$((errors + 1))
      file_errors=$((file_errors + 1))
    fi
  fi

  # --- Check 7: description field ---
  desc_line=$(echo "$frontmatter" | grep -m1 '^description:')
  if [[ -z "$desc_line" ]]; then
    echo "::error file=$file::Missing 'description' field in frontmatter"
    errors=$((errors + 1))
    file_errors=$((file_errors + 1))
  else
    desc_value=$(echo "$desc_line" | sed 's/^description:[[:space:]]*//')
    if [[ -z "$desc_value" ]]; then
      echo "::error file=$file::Empty 'description' field in frontmatter"
      errors=$((errors + 1))
      file_errors=$((file_errors + 1))
    fi
  fi

  # --- Check 8: H1 heading after frontmatter ---
  after_frontmatter=$(tail -n +"$((closing_line + 1))" "$file")
  h1_found=$(echo "$after_frontmatter" | grep -m1 '^# ')
  if [[ -z "$h1_found" ]]; then
    echo "::error file=$file::Missing H1 heading (no '# ' line after frontmatter)"
    errors=$((errors + 1))
    file_errors=$((file_errors + 1))
  fi

  # --- Check 9: Standards section ---
  standards_found=$(grep -c '^## Core Standards' "$file")
  if [[ "$standards_found" -eq 0 ]]; then
    echo "::error file=$file::Missing '## Core Standards' section"
    errors=$((errors + 1))
    file_errors=$((file_errors + 1))
  fi

  if [[ "$file_errors" -eq 0 ]]; then
    echo "✅ $file"
  fi
done < <(find ./skills -maxdepth 2 -name "SKILL.md" | sort)

echo ""
if [[ $errors -gt 0 ]]; then
  echo "❌ Validation failed with $errors error(s)."
  exit 1
else
  echo "✅ All SKILL.md files are valid."
fi
