#!/opt/homebrew/bin/bash

declare -A xml_content
declare -A xml_attributes
declare -A xml_paths

# Function to read XML file and populate arrays
parse_xml() {
    local file="$1"
    local current_path=""
    local line_number=0
    
    while IFS= read -r line; do
        ((line_number++))
        if [[ $line =~ \<([^/][^>]*)\> ]]; then
            local tag="${BASH_REMATCH[1]}"
            # Handle attributes
            if [[ $tag =~ ([^[:space:]]+)[[:space:]]+(.*) ]]; then
                tag="${BASH_REMATCH[1]}"
                local attrs="${BASH_REMATCH[2]}"
                xml_attributes["$line_number"]="$attrs"
            fi
            
            if [ -z "$current_path" ]; then
                current_path="$tag"
            else
                current_path="$current_path -> $tag"
            fi
            xml_paths["$line_number"]="$current_path"
            
            # Get content if it exists
            if [[ $line =~ \>([^<]+)\< ]]; then
                local content="${BASH_REMATCH[1]}"
                content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                if [ ! -z "$content" ]; then
                    xml_content["$current_path"]="$content"
                fi
            fi
        elif [[ $line =~ \</([^>]+)\> ]]; then
            current_path=$(echo "$current_path" | sed 's/ -> [^>]*$//')
        fi
    done < "$file"
}

# Function to display XML content
display_content() {
    echo "XML Structure and Content:"
    echo "========================="
    for path in "${!xml_content[@]}"; do
        echo "Path: $path"
        echo "├── Content: ${xml_content[$path]}"
        local line_num
        for line_num in "${!xml_paths[@]}"; do
            if [ "${xml_paths[$line_num]}" == "$path" ] && [ ! -z "${xml_attributes[$line_num]}" ]; then
                echo "├── Attributes: ${xml_attributes[$line_num]}"
            fi
        done
        echo "-------------------------"
    done
}

# Function to modify XML content
modify_xml() {
    local file="$1"
    echo "Available tags with content:"
    local i=1
    declare -A path_map
    for path in "${!xml_content[@]}"; do
        echo "$i) $path"
        path_map[$i]="$path"
        ((i++))
    done
    
    read -p "Enter number of tag to modify: " choice
    if [ -n "${path_map[$choice]}" ]; then
        local selected_path="${path_map[$choice]}"
        local tag=$(echo "$selected_path" | awk -F " -> " '{print $NF}')
        read -p "Enter new content for $tag: " new_content
        
        # Update array
        xml_content["$selected_path"]="$new_content"
        
        # Update file
        sed -i '' "s|<$tag[^>]*>\([^<]*\)<\/$tag>|<$tag>$new_content<\/$tag>|" "$file"
        echo "Content updated successfully!"
    else
        echo "Invalid choice!"
    fi
}

# Function to add new tag
add_new_tag() {
    local file="$1"
    echo "Current XML structure:"
    echo "===================="
    
    # Show existing paths for reference
    local i=1
    declare -A path_map
    path_map[0]="ROOT"
    echo "0) ROOT (top level)"
    for path in "${!xml_paths[@]}"; do
        echo "$i) ${xml_paths[$path]}"
        path_map[$i]="${xml_paths[$path]}"
        ((i++))
    done
    
    # Get parent path
    read -p "Select parent location number (0 for root): " parent_choice
    local parent_path="${path_map[$parent_choice]}"
    
    # Get new tag details
    read -p "Enter new tag name: " new_tag
    read -p "Add attributes? (y/n): " add_attrs
    local attrs=""
    if [[ "$add_attrs" == "y" ]]; then
        read -p "Enter attributes (format: attr1=\"value1\" attr2=\"value2\"): " attrs
        attrs=" $attrs"
    fi
    
    read -p "Enter content for tag (leave empty for no content): " content
    
    # Prepare new tag
    local new_tag_content
    if [ -z "$content" ]; then
        new_tag_content="<$new_tag$attrs></$new_tag>"
    else
        new_tag_content="<$new_tag$attrs>$content</$new_tag>"
    fi
    
    # Insert tag at appropriate location
    if [ "$parent_choice" == "0" ]; then
        # Add at root level, before closing root tag
        sed -i '' "/<\/[^>]*>$/i\\
        $new_tag_content" "$file"
    else
        # Add before parent's closing tag
        local parent_tag=$(echo "$parent_path" | awk -F " -> " '{print $NF}')
        sed -i '' "/<\/$parent_tag>/i\\
        $new_tag_content" "$file"
    fi
    
    # Refresh arrays
    xml_content=()
    xml_attributes=()
    xml_paths=()
    parse_xml "$file"
    
    echo "New tag added successfully!"
}

# Main menu
main() {
    local file="example.xml"
    parse_xml "$file"
    
    while true; do
        echo -e "\nXML Parser Menu:"
        echo "1. Display XML content"
        echo "2. Modify XML content"
        echo "3. Add new tag"
        echo "4. Exit"
        read -p "Choose an option (1-4): " option
        
        case $option in
            1) display_content ;;
            2) modify_xml "$file" ;;
            3) add_new_tag "$file" ;;
            4) exit 0 ;;
            *) echo "Invalid option!" ;;
        esac
    done
}

# Run the script
main
