#!/bin/bash

# Function to generate the appropriate indentation
generate_indent() {
    local depth=$1
    local is_last=$2
    local indent=""
    
    for ((i=1; i<depth; i++)); do
        indent+="│   "
    done
    
    if [[ $depth -gt 0 ]]; then
        if [[ $is_last -eq 1 ]]; then
            indent+="└── "
        else
            indent+="├── "
        fi
    fi
    echo "$indent"
}

# Function to trim whitespace
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"   
    echo "$var"
}

# Function to extract tag name
get_tag_name() {
    local line="$1"
    line=$(trim "$line")
    
    # Skip if not a tag
    if [[ ${line:0:1} != "<" ]]; then
        return
    fi
    
    # Remove < from start
    line="${line:1}"
    # Remove everything after first space or >
    tag_name="${line%% *}"
    tag_name="${tag_name%%>*}"
    # Remove any trailing /
    tag_name="${tag_name%/}"
    
    echo "$tag_name"
}

# Function to extract attributes
get_attributes() {
    local line="$1"
    line=$(trim "$line")
    
    # If no space after tag, return empty
    if [[ ! "$line" == *" "* ]]; then
        return
    fi
    
    # Get everything after tag name
    local full_tag="${line#<*" "}"
    # Remove closing bracket and any trailing slash
    full_tag="${full_tag%>}"
    full_tag="${full_tag%/}"
    
    # Process each attribute
    local result=""
    local in_quotes=0
    local current_attr=""
    
    for ((i=0; i<${#full_tag}; i++)); do
        char="${full_tag:$i:1}"
        
        # Handle quotes
        if [[ "$char" == '"' ]]; then
            if ((in_quotes == 0)); then
                in_quotes=1
            else
                in_quotes=0
            fi
        fi
        
        # Add character to current attribute
        if ((in_quotes == 1)) || [[ "$char" != " " ]]; then
            current_attr+="$char"
        elif [[ -n "$current_attr" ]]; then
            # Add separator if not first attribute
            if [[ -n "$result" ]]; then
                result+=", "
            fi
            result+="$current_attr"
            current_attr=""
        fi
    done
    
    # Add last attribute if exists
    if [[ -n "$current_attr" ]]; then
        if [[ -n "$result" ]]; then
            result+=", "
        fi
        result+="$current_attr"
    fi
    
    echo "$result"
}

# Function to check if line is a closing tag
is_closing_tag() {
    local line="$1"
    line=$(trim "$line")
    [[ ${line:0:2} == "</" ]]
}

# Function to check if line is a self-closing tag
is_self_closing_tag() {
    local line="$1"
    line=$(trim "$line")
    [[ ${line: -2} == "/>" ]]
}

# Function to display XML in tree format
display_xml() {
    local xml_file="$1"
    local depth=0
    local prev_line=""
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        line=$(trim "$line")
        
        # Skip empty lines and XML declaration
        if [[ -z "$line" || "$line" == "<?xml"* ]]; then
            continue
        fi
        
        # Handle closing tags
        if is_closing_tag "$line"; then
            ((depth--))
            continue
        fi
        
        # Get tag name and attributes
        tag_name=$(get_tag_name "$line")
        attributes=$(get_attributes "$line")
        
        # Skip if no tag name found
        if [[ -z "$tag_name" ]]; then
            continue
        fi
        
        # Determine if this is the last item at this level
        is_last=0
        next_line=$(tail -n +$(($(grep -n "$line" "$xml_file" | cut -d: -f1) + 1)) "$xml_file" | grep -v '^[[:space:]]*$' | head -n 1)
        next_line=$(trim "$next_line")
        if [[ ${next_line:0:2} == "</" ]]; then
            is_last=1
        fi
        
        # Display the current node
        indent=$(generate_indent $depth $is_last)
        if [[ -n "$attributes" ]]; then
            echo "${indent}${tag_name} [${attributes}]"
        else
            echo "${indent}${tag_name}"
        fi
        
        # Store current line for next iteration
        prev_line="$line"
        
        # Adjust depth for next iteration
        if ! is_self_closing_tag "$line"; then
            ((depth++))
        fi
    done < "$xml_file"
}

# Check if file argument is provided
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <xml_file>"
    exit 1
fi

# Check if file exists
if [[ ! -f "$1" ]]; then
    echo "Error: File '$1' not found"
    exit 1
fi

# Display the XML tree
display_xml "$1"
