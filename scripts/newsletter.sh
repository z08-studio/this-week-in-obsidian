#!/bin/bash

# Base directory of the project
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRAFTS_DIR="$BASE_DIR/drafts"
ARCHIVE_DIR="$BASE_DIR/archive"
TEMPLATE_FILE="$BASE_DIR/templates/newsletter-template.md"

command=$1

function get_next_tuesday() {
    # Return the upcoming Tuesday.
    # Always return the next Tuesday.
    local dow days_ahead

    # Mon=1 ... Sun=7
    dow=$(date +%u)

    if (( dow < 2 )); then
        days_ahead=$((2 - dow))
    else
        days_ahead=$((7 - dow + 2))
    fi

    date -d "+${days_ahead} days" +%Y-%m-%d
}

function ensure_no_future_drafts() {
    local target_date=$1
    local future_drafts=()

    shopt -s nullglob
    for f in "$DRAFTS_DIR"/*-issue-*.md; do
        local base
        base=$(basename "$f")

        if [[ $base =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-issue-[0-9]+\.md$ ]]; then
            local file_date=${BASH_REMATCH[1]}

            # ISO-8601 dates sort lexicographically
            if [[ "$file_date" > "$target_date" ]]; then
                future_drafts+=("$base")
            fi
        fi
    done
    shopt -u nullglob

    if (( ${#future_drafts[@]} > 0 )); then
        echo "Found draft(s) dated after $target_date in $DRAFTS_DIR:"
        printf ' - %s\n' "${future_drafts[@]}"
        echo "Archive/remove them (or rename) before creating a new draft."
        exit 1
    fi
}

function get_next_issue_number() {
    local max_num=0
    
    # Function to process a file and update max_num
    process_file() {
        local f=$1
        # Extract number after "issue-" and before ".md"
        if [[ $f =~ issue-([0-9]+)\.md ]]; then
            local num=${BASH_REMATCH[1]}
            # Force base 10
            num=$((10#$num))
            if (( num > max_num )); then
                max_num=$num
            fi
        fi
    }

    # Look in drafts
    for f in "$DRAFTS_DIR"/*-issue-*.md; do
        [ -e "$f" ] || continue
        process_file "$(basename "$f")"
    done
    
    # Look in archive (recursive)
    # We use find, but we need to be careful with spaces in filenames (though unlikely here)
    while IFS= read -r f; do
        process_file "$(basename "$f")"
    done < <(find "$ARCHIVE_DIR" -name "*-issue-*.md" 2>/dev/null)
    
    printf "%02d" $((max_num + 1))
}

function create_draft() {
    local next_date=${1:-$(get_next_tuesday)}
    local normalized_date

    if [[ ! "$next_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] ||
        ! normalized_date=$(date -d "$next_date" +%Y-%m-%d 2>/dev/null) ||
        [[ "$normalized_date" != "$next_date" ]]; then
        echo "Invalid publication date: $next_date. Use YYYY-MM-DD." >&2
        return 1
    fi

    if [[ $(date -d "$next_date" +%u) != 2 ]]; then
        echo "Publication date must be a Tuesday: $next_date" >&2
        return 1
    fi

    ensure_no_future_drafts "$next_date"

    local existing_file
    for existing_file in "$DRAFTS_DIR"/"$next_date"-issue-*.md \
        "$ARCHIVE_DIR"/"${next_date%%-*}"/"$next_date"-issue-*.md; do
        if [ -e "$existing_file" ]; then
            echo "An issue already exists for $next_date: $existing_file" >&2
            return 1
        fi
    done

    local issue_num=$(get_next_issue_number)
    local filename="${next_date}-issue-${issue_num}.md"
    local filepath="$DRAFTS_DIR/$filename"
    
    if [ -f "$filepath" ]; then
        echo "Draft already exists: $filepath"
        exit 1
    fi
    
    # Ensure drafts dir exists
    mkdir -p "$DRAFTS_DIR"

    # Fill both the issue heading and any date placeholder in the template.
    sed -e "s/#0x/#$issue_num/g" -e "s/\[Date\]/$next_date/g" \
        "$TEMPLATE_FILE" > "$filepath" || return 1
    
    echo "Created new draft: $filepath"
}

function archive_draft() {
    local file_path=$1
    
    # If no file specified, try to pick the only one in drafts
    if [ -z "$file_path" ]; then
        # Check how many markdown files are in drafts
        local count=$(find "$DRAFTS_DIR" -maxdepth 1 -name "*.md" | wc -l)
        
        if [ "$count" -eq 1 ]; then
            file_path=$(find "$DRAFTS_DIR" -maxdepth 1 -name "*.md")
        elif [ "$count" -eq 0 ]; then
            echo "No drafts found to archive."
            exit 1
        else
            echo "Multiple drafts found. Please specify which one to archive:"
            ls "$DRAFTS_DIR"/*.md
            exit 1
        fi
    fi
    
    # Check if file exists (handle relative or absolute path)
    if [ ! -f "$file_path" ]; then
        # Try relative to drafts dir if not found
        if [ -f "$DRAFTS_DIR/$file_path" ]; then
            file_path="$DRAFTS_DIR/$file_path"
        else
            echo "File not found: $file_path"
            exit 1
        fi
    fi
    
    local filename=$(basename "$file_path")
    # Extract year from filename YYYY-MM-DD...
    local year=$(echo "$filename" | cut -d'-' -f1)
    
    if [[ ! "$year" =~ ^[0-9]{4}$ ]]; then
        echo "Could not extract year from filename: $filename"
        echo "Using current year."
        year=$(date +%Y)
    fi
    
    local target_dir="$ARCHIVE_DIR/$year"
    mkdir -p "$target_dir"
    
    mv "$file_path" "$target_dir/"
    echo "Archived $filename to $target_dir/"
}

case "$command" in
    "new")
        create_draft "$2"
        ;;
    "archive")
        archive_draft "$2"
        ;;
    *)
        echo "Usage: $0 {new [YYYY-MM-DD]|archive [filename]}"
        exit 1
        ;;
esac
