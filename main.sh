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

# Main menu
main() {
    local file="example.xml"
    parse_xml "$file"
    
    while true; do
        echo -e "\nXML Parser Menu:"
        echo "1. Display XML content"
        echo "2. Modify XML content"
        echo "3. Exit"
        read -p "Choose an option (1-3): " option
        
        case $option in
            1) display_content ;;
            2) modify_xml "$file" ;;
            3) exit 0 ;;
            *) echo "Invalid option!" ;;
        esac
    done
}

# Run the script
main
