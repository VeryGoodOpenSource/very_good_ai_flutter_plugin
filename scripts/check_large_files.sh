#!/bin/bash
# Claude Code loads these files into context - large files waste
# tokens and can degrade performance.
MAX_KB=50
echo "Checking for files larger than ${MAX_KB}KB..."
oversized=0
while IFS= read -r file; do
  size_kb=$(du -k "$file" | cut -f1)
  if [ "$size_kb" -gt "$MAX_KB" ]; then
    echo "::warning file=$file::File is ${size_kb}KB (limit: ${MAX_KB}KB). Large files consume context window tokens."
    oversized=$((oversized + 1))
  fi
done < <(find . -name "*.md" -not -path "./.git/*")

if [[ $oversized -gt 0 ]]; then
  echo "⚠️  $oversized file(s) exceed ${MAX_KB}KB. Consider splitting them."
else
  echo "✅ All Markdown files are within size limits."
fi