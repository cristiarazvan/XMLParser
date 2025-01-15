#!/bin/bash


output_file=""




make_format_input() {
    local input_file="$1"
    output_file="${input_file%.*}_formatted.xml"
    
    sed 's/>/>\n/g; s/</\n</g'  "$input_file" | \
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
    sed '/^$/d' > "$output_file"

    echo "Created formatted file: $output_file"
}

add_indent() {
    local indent_level=0
    local line=""
    declare -a is_last_child
    
    while IFS= read -r line; do
        # Skip empty lines and XML declaration
        [[ -z "$line" || $line =~ ^\<\?xml ]] && continue
        
        # Calculate current line's indentation
        local prefix=""
        for ((i = 0; i < indent_level; i++)); do
            if [[ ${is_last_child[$i]} -eq 1 ]]; then
                prefix+="    "
            else
                prefix+="│   "
            fi
        done
        
        # Handle closing tags
        if [[ $line =~ ^"</" ]]; then
            ((indent_level--))
            # Get the last element's prefix
            prefix=""
            for ((i = 0; i < indent_level; i++)); do
                if [[ ${is_last_child[$i]} -eq 1 ]]; then
                    prefix+="    "
                else
                    prefix+="│   "
                fi
            done
            echo "${prefix}├── $line"
            is_last_child[$indent_level]=1
        # Handle opening tags
        elif [[ $line =~ ^"<"[^/] ]]; then
            echo "${prefix}├── $line"
            is_last_child[$indent_level]=0
            ((indent_level++))
        # Handle content
        else
            echo "${prefix}├── $line"
        fi
        
    done < "$1"
}

display_tree() {
    local file="$1"
    echo -e "\nXML Tree Structure:"
    add_indent "$file"
}
delete_xml_tag() {
    if [ $# -eq 0 ]; then
        echo "No arguments passed."
        return 1
    fi
    # Bulk Delete
    if [ $# -eq 1 ]; then
        local tag_name="$1"
        local skip=0

        while IFS= read -r line; do
            
            if [[ $line =~ ^\<${tag_name}([[:space:]]|>) ]]; then
                skip=$((skip + 1)) 
                continue
            fi

            if [[ $line =~ ^\<\/${tag_name}\> ]]; then
                
                skip=$((skip - 1)) 
                if [ $skip -eq 0 ]; then
                    continue 
                fi
            fi

            if [ $skip -gt 0 ]; then
                continue
            fi

            
            echo "$line"
        done < "$output_file"

    # Single Delete

    elif [ $# -eq 2 ]; then
        local tag_name="$1"
        local index="$2"
        local skip=0
        local current_index=0

        while IFS= read -r line; do
            
            if [[ $line =~ ^\<${tag_name}([[:space:]]|>) ]]; then
                current_index=$((current_index + 1)) 
                if [ $current_index -eq $index ]; then
                    skip=$((skip + 1)) 
                    continue
                fi
            fi

            
            if [[ $line =~ ^\<\/${tag_name}\> ]]; then
                if [ $skip -gt 0 ]; then
                    skip=$((skip - 1)) 
                    if [ $skip -eq 0 ]; then
                        continue 
                    fi
                fi
            fi

            
            if [ $skip -gt 0 ]; then
                continue
            fi

            
            echo "$line"
        done < "$output_file"

    # Range Delete

    elif [ $# -eq 3 ]; then
        local tag_name="$1"
        local start_index="$2"
        local count="$3"
        local skip=0
        local current_index=0
        local tags_to_skip=$count

        while IFS= read -r line; do
            
            if [[ $line =~ ^\<${tag_name}([[:space:]]|>) ]]; then
                current_index=$((current_index + 1)) 

                
                if [ $current_index -ge $start_index ] && [ $tags_to_skip -gt 0 ]; then
                    skip=$((skip + 1)) 
                    tags_to_skip=$((tags_to_skip - 1)) 
                    continue
                fi
            fi

            
            if [[ $line =~ ^\<\/${tag_name}\> ]]; then
                if [ $skip -gt 0 ]; then
                    skip=$((skip - 1)) 
                    if [ $skip -eq 0 ]; then
                        continue 
                    fi
                fi
            fi

            
            if [ $skip -gt 0 ]; then
                continue
            fi

            echo "$line"
        done < "$output_file"
    else 
        echo "Too many arguments."
    fi
}

delete_xml_attr() {
    if [ $# -eq 0 ]; then
        echo "No arguments passed."
        return 1
    fi

    
    local result=""

    if [ $# -eq 1 ]; then
        local attribute_name="$1"
        local skip=0

        while IFS= read -r line; do
            
            line=$(echo "$line" | sed -E "s/\s$attribute_name=[^[:space:]]*([[:space:]]|>)/\1/g")
            
            result="$result$line"$'\n'
        done < "$output_file"
    elif [ $# -eq 2 ]; then
        local attribute_name="$1"
        local tag_name="$2"
        local skip=0

        while IFS= read -r line; do
            
            if [[ $line =~ \<${tag_name}[[:space:]] ]]; then
                line=$(echo "$line" | sed -E "s/\s$attribute_name=[^[:space:]]*([[:space:]]|>)/\1/g")
            fi
            
            result="$result$line"$'\n'
        done < "$output_file"
    elif [ $# -eq 3 ]; then
        local attribute_name="$1"
        local tag_name="$2"
        local index="$3"
        local skip=0
        local current_index=0

        while IFS= read -r line; do
            
            if [[ $line =~ \<${tag_name}[[:space:]] ]]; then
                current_index=$((current_index + 1))
                if [ $current_index -eq $index ]; then
                    
                    line=$(echo "$line" | sed -E "s/\s$attribute_name=[^[:space:]]*([[:space:]]|>)/\1/g")
                fi
            fi
            result="$result$line"$'\n'
        done < "$output_file"
    elif [ $# -eq 4 ]; then
        local attribute_name="$1"
        local tag_name="$2"
        local start_index="$3"
        local count="$4"
        local skip=0
        local current_index=0
        local tags_to_remove=$count

        while IFS= read -r line; do
            
            if [[ $line =~ \<${tag_name}[[:space:]] ]]; then
                current_index=$((current_index + 1))
                if [ $current_index -ge $start_index ] && [ $tags_to_remove -gt 0 ]; then
                    line=$(echo "$line" | sed -E "s/\s$attribute_name=[^[:space:]]*([[:space:]]|>)/\1/g")
                    tags_to_remove=$((tags_to_remove - 1))
                fi
            fi
            result="$result$line"$'\n'
        done < "$output_file"
    else
        echo "Too many arguments."
        return 1
    fi

    
    echo "$result" > "$output_file"
}

add(){
    local file="$1"
    local parent_tag
    local index_ptag
    local new_tag
    local content
    local attributes
    
    local ok=0
    local cnt=0

    read -p "Enter parent tag name where to add: " parent_tag
    while [ 0 -eq 0 ]; do
    if [[ $parent_tag == "xml" ]]; then
        echo -e "Xml tag is not a valid tag name\n"
        read -p "Please select an existent tag name: " parent_tag
        continue
    fi
    
    ok=0
    cnt=0
        while IFS= read -r line; do
            if [[ $line =~ \<$parent_tag.*\> ]]; then
                ok=1
                cnt=$((cnt+1))
            fi
        done < "$file"

        if [ $ok -eq 1 ]; then
            break
        fi
        read -p "Please select an existent tag name: " parent_tag
    done

    while [ 0 -eq 0 ]; do
        read -p "Enter index of the parent tag (or press enter to insert in all occurances of the specified parent tag): " index_ptag
        if [ -z "$index_ptag" ]; then
            index_ptag=0
            echo -e $index_ptag
            break
        fi

        if [[ $index =~ \*[^0-9\s]\* ]]; then
            echo -e "The index must be a number"
            continue
        else
            if [ $cnt -ge $index_ptag ]; then
                break
            fi
            continue
        fi

    done

    read -p "Enter new tag name (or press enter for no tag): " new_tag
    echo -e $new_tag

    read -p "Enter tag content (or press enter for none): " content

    while [ 0 -eq 0 ]; do
        if [[ "$content" =~ [\<\>] ]]; then
            echo -e "Xml format does not support < and >"
            read -p "Please select a supported tag content: " content
            continue
        fi
        break
    done

    if [ -n "$new_tag" ]; then
        read -p "Enter attributes (format: attr1=\"value1\" attr2=\"value2\" or press enter for none): " attributes
    fi
    
    local temp_file=$(mktemp)
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        if [[ $line == "<$parent_tag "* ]]; then
            index_ptag=$((index_ptag-1))
            if [ "$index_ptag" -gt 0 ]; then
                continue
            fi
            
            # Add the new tag after parent tag
            if [ -n "$new_tag" ]; then
                if [[ -n "$attributes" ]]; then
                    echo "<$new_tag $attributes>" >> "$temp_file"
                else
                    echo "<$new_tag>" >> "$temp_file"
                fi
                if [[ -n "$content" ]]; then
                    echo "$content" >> "$temp_file"
                fi
                echo "</$new_tag>" >> "$temp_file"
            else
                if [[ -n "$content" ]]; then
                    echo "$content" >> "$temp_file"
                fi 
            fi
        fi
    done < "$file"
    
    mv "$temp_file" "$file"
    echo "Tag added successfully!"
}
 
delete() {
    local file="$1"
    local tag_name
    local attr_name
    local tagOrAttr
    local index
    local typeOfDelete
    local count
    local start_index
    read -p "Enter what you want to delete: 1) Tag 2) Attribute: " tagOrAttr

    # if its an tag enter tag name to delete if its an attribute enter attribute name to delete
    if [ $tagOrAttr -eq 1 ]; then
        read -p "Enter the tag name to delete: " tag_name

    else

        read -p "Enter the attribute name to delete: " attr_name 
    fi
    
    

    read -p "Enter the type of delete: 1) Bulk Delete 2) Single Delete 3) Range Delete: " typeOfDelete


    if [ $typeOfDelete -eq 1 ]; then
        
        if [ $tagOrAttr -eq 1 ]; then
            delete_xml_tag "$tag_name"
        else
            delete_xml_attr "$attr_name"
        fi
        
    elif [ $typeOfDelete -eq 2 ]; then
        read -p "Enter the index: " index

        if [ $tagOrAttr -eq 1 ]; then
            delete_xml_tag "$tag_name" $index
        else
            delete_xml_attr "$attr_name" $index
        fi
    else
        read -p "Enter the start index: " start_index
        read -p "Enter the count: " count
        if [ $tagOrAttr -eq 1 ]; then
            delete_xml_tag "$tag_name" $start_index $count
        else
            delete_xml_attr "$attr_name" $start_index $count
        fi
    fi

}

modify() {
    local file="$1"
    local tag_name
    local index
    local modification
    local current_index=0
    local temp_file=$(mktemp)
    local skip=0
    
    read -p "Enter the tag name to modify: " tag_name
    read -p "Enter the index of the tag to modify: " index
    read -p "Enter the modified version: " modification
    
    # Split the modification into tag name and attributes
    local mod_tag=$(echo "$modification" | awk '{print $1}')
    local mod_attrs=$(echo "$modification" | cut -d' ' -f2-)
    
    while IFS= read -r line; do
        if [[ $line =~ ^\<$tag_name([[:space:]]|>) ]]; then
            ((current_index++))
            if [ $current_index -eq $index ]; then
                # Handle modification with or without attributes
                if [ -n "$mod_attrs" ]; then
                    echo "<$mod_tag $mod_attrs>" >> "$temp_file"
                else
                    echo "<$mod_tag>" >> "$temp_file"
                fi
                skip=1
                continue
            fi
        elif [[ $line =~ ^\<\/${tag_name}\> && $skip -eq 1 ]]; then
            echo "</$mod_tag>" >> "$temp_file"
            skip=0
            continue
        fi
        echo "$line" >> "$temp_file"
    done < "$file"
    
    mv "$temp_file" "$file"
    echo "Tag modified successfully!"
}

format_xml() {
    local file="$1"
    local indent=0
    local temp_file=$(mktemp)
    
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        # Calculate indentation spaces
        local spaces=""
        for ((i=0; i<indent; i++)); do
            spaces+="    "
        done
        
        # Handle closing tags
        if [[ $line =~ \<\/.+\> ]]; then
            ((indent--))
            spaces=""
            for ((i=0; i<indent; i++)); do
                spaces+="    "
            done
            echo "${spaces}${line}" >> "$temp_file"
        # Handle opening tags
        elif [[ $line =~ \<[^/].+\> ]]; then
            echo "${spaces}${line}" >> "$temp_file"
            ((indent++))
        # Handle content
        else
            echo "${spaces}${line}" >> "$temp_file"
        fi
    done < "$file"
    
    mv "$temp_file" "$file"
    echo "XML file formatted successfully!"
}

main() {
    local file="example.xml"
    make_format_input "$file"
    
    while true; do
        echo -e "\nXML Parser Menu:"
        echo "1. Display XML tree structure"
        echo "2. Add"
        echo "3. Delete"
        echo "4. Modify"
        echo "5. Format XML"
        echo "6. Exit"
        read -p "Choose an option (1-6): " choice
        
        case $choice in
            1) display_tree "$output_file" ;;
            2) add "$output_file" ;;
            3) delete "$output_file" ;;
            4) modify "$output_file" ;;
            5) format_xml "$output_file" ;;
            6) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option! Please choose 1-6" ;;
        esac
    done
}

main



