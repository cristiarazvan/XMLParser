#!/bin/bash


output_file=""




make_line_input() {
    local input_file="$1"
    output_file="${input_file%.*}_line.xml"
    
    sed 's/>/>\n/g; s/</\n</g'  "$input_file" | \
    sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | \
    sed '/^$/d' > "$output_file"

   
}

add_indent() {
    local indent_level=0
    local line=""
    declare -a is_last_child
    
    while IFS= read -r line; do
     
        [[ -z "$line" || $line =~ ^\<\?xml ]] && continue
        
      
        local prefix=""
        for ((i = 0; i < indent_level; i++)); do
            if [[ ${is_last_child[$i]} -eq 1 ]]; then
                prefix+="    "
            else
                prefix+="│   "
            fi
        done
        
 
        if [[ $line =~ ^"</" ]]; then
            ((indent_level--))
           
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
       
        elif [[ $line =~ ^"<"[^/] ]]; then
            echo "${prefix}├── $line"
            is_last_child[$indent_level]=0
            ((indent_level++))
     
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


    local result=""
    
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

            result="$result$line"$'\n'
        done < "$output_file"
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

            
            result="$result$line"$'\n'
        done < "$output_file"
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

         
            result="$result$line"$'\n'
        done < "$output_file"
    else
        echo "Too many arguments."
        return 1 
    fi


    echo "$result" > "$output_file"
    echo "Tag deleted successfully!"
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
    echo "Attribute deleted successfully!"
}


add_tag(){
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
        echo -e "Xml tag is not a valid tag name"
        read -p "Please select an existent tag name: " parent_tag
        continue
    fi
    
    ok=0
    cnt=0
        while IFS= read -r line; do
            if [[ $line =~ \<$parent_tag[[:space:]] ]] || [[ $line =~ \<$parent_tag\> ]]; then
                ok=1
                cnt=$((cnt+1))
            fi
        done < "$file"

        if [ $ok -eq 1 ]; then
            break
        fi
        read -p "Please select an existent tag name: " parent_tag
    done

    ok=0

    while [ 0 -eq 0 ]; do
        read -p "Enter index of the parent tag (or press enter to insert in all of the specified parent tag): " index_ptag
        if [ -z "$index_ptag" ]; then
            index_ptag=1
            ok=1
            break
        fi

        if [[ $index =~ \*[^0-9\s]\* ]]; then
            echo -e "The index must be a number"
            continue
        else
            if [ $index_ptag -le 0 ]; then
                echo -e "The index must be a number greater than 0"
                continue
            fi
            if [ $cnt -ge $index_ptag ]; then
                break
            fi
            continue
        fi

    done

    read -p "Enter new tag name (or press enter for no tag): " new_tag

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
        if [[ $line =~ \<$parent_tag[[:space:]] ]] || [[ $line =~ \<$parent_tag\> ]]; then
            index_ptag=$((index_ptag-1))
            if [ "$index_ptag" -ne 0 ]; then
                continue
            else
                if [ $ok -eq 1 ]; then
                    index_ptag=1
                fi
            fi
            
       
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
    local tag_name=""
    local attr_name=""
    local choice=""
    local type=""
    local index=""
    local start_index=""
    local count=""
    
  
    echo "What do you want to delete?"
    echo "1. Tag"
    echo "2. Attribute"
    read -p "Enter your choice (1 or 2): " choice
    
    case $choice in
        1)  # Delete tag
            read -p "Enter the tag name to delete: " tag_name
            echo -e "\nDelete options:"
            echo "1. Bulk Delete (all occurrences)"
            echo "2. Single Delete (specific index)"
            echo "3. Range Delete (from start index, count times)"
            read -p "Enter delete type (1-3): " type
            
            case $type in
                1) delete_xml_tag "$tag_name" ;;
                2) read -p "Enter the index: " index
                   delete_xml_tag "$tag_name" "$index" ;;
                3) read -p "Enter start index: " start_index
                   read -p "Enter count: " count
                   delete_xml_tag "$tag_name" "$start_index" "$count" ;;
                *) echo "Invalid delete type"; return 1 ;;
            esac
            ;;
            
        2)  # Delete attribute
            read -p "Enter the attribute name to delete: " attr_name
            
            
            echo -e "\nDelete options:"
            echo "1. Bulk Delete (all occurrences in specified tag)"
            echo "2. Single Delete (specific tag occurrence)"
            echo "3. Range Delete (from start tag occurrence, count times)"
            read -p "Enter delete type (1-3): " type
            
            case $type in
                1) delete_xml_attr "$attr_name";;
                2) read -p "Enter the tag name containing the attribute: " tag_name
                   read -p "Enter the tag occurrence index: " index
                   delete_xml_attr "$attr_name" "$tag_name" "$index" ;;
                3) read -p "Enter the tag name containing the attribute: " tag_name
                   read -p "Enter start tag index: " start_index
                   read -p "Enter count: " count
                   delete_xml_attr "$attr_name" "$tag_name" "$start_index" "$count" ;;
                *) echo "Invalid delete type"; return 1 ;;
            esac
            ;;
            
        *) echo "Invalid choice"; return 1 ;;
    esac
}

modify() {
    local file="$1"
    local tag_name
    local index
    local new_tag_name
    local new_attrs
    local current_index=0
    local temp_file=$(mktemp)
    
    read -p "Enter the tag name to modify: " tag_name
    read -p "Enter the index of the tag to modify: " index
    read -p "Enter new tag name: " new_tag_name
    read -p "Enter new attributes (format: attr1=\"value1\" attr2=\"value2\"): " new_attrs
    
    while IFS= read -r line; do
        if [[ $line =~ ^\<$tag_name([[:space:]]|>) ]]; then
            ((current_index++))
            if [ $current_index -eq $index ]; then
                echo "<$new_tag_name $new_attrs>" >> "$temp_file"
                continue
            fi
        elif [[ $line =~ ^\<\/${tag_name}\> ]]; then
            if [ $current_index -eq $index ]; then
                echo "</$new_tag_name>" >> "$temp_file"
                continue
            fi
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
        
        
        local spaces=""
        for ((i=0; i<indent; i++)); do
            spaces+="    "
        done
        
        
        if [[ $line =~ \<\/.+\> ]]; then
            ((indent--))
            spaces=""
            for ((i=0; i<indent; i++)); do
                spaces+="    "
            done
            echo "${spaces}${line}" >> "$temp_file"
       
        elif [[ $line =~ \<[^/].+\> ]]; then
            echo "${spaces}${line}" >> "$temp_file"
            ((indent++))
       
        else
            echo "${spaces}${line}" >> "$temp_file"
        fi
    done < "$file"
    





    mv "$temp_file" "$file"
    echo "XML file formatted successfully!"
}

show_usage() {
    echo "Usage: $0 <xml_file>"
    echo "Example: $0 example.xml"
    exit 1
}

execute_operation() {
    local operation=$1
    local file=$2
    

    make_line_input "$file"
    
    case $operation in
        "display") 
            display_tree "$output_file"
            rm "$output_file"
            ;;
        "add") 
            add_tag "$output_file"
            format_xml "$output_file"
            cp "$output_file" "$file"
            rm "$output_file"
            ;;
        "delete") 
            delete "$output_file"
            format_xml "$output_file"
            cp "$output_file" "$file"
            rm "$output_file"
            ;;
        "modify")
            modify "$output_file"
            format_xml "$output_file"
            cp "$output_file" "$file"
            rm "$output_file"
            ;;
        "format")
            format_xml "$output_file"
            cp "$output_file" "$file"
            rm "$output_file"
            ;;
    esac
}

main() {
    if [ $# -eq 0 ]; then
        show_usage
    fi

    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found!"
        show_usage
    fi
    
    make_line_input "$file"
    
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
            1) execute_operation "display" "$file" ;;
            2) execute_operation "add" "$file" ;;
            3) execute_operation "delete" "$file" ;;
            4) execute_operation "modify" "$file" ;;
            5) execute_operation "format" "$file" ;;
            6) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option! Please choose 1-6" ;;
        esac
    done
}

main "$@"
