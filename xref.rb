sym_tab = [] # Will store scanned symbol table. Each element is a line in the table, indices respect columns
addresses  = [] # Stores address column of sym_tab
line_nums =  [] # Store Line column of sym_tab

filename = ARGV[0]
rust_file = filename.dup.concat(".rs")
src = File.readlines(rust_file)  #  Source code of executable
src_lines = "" # To help in building adding source code lines that do not have an entry in sym_tab
src_values = Hash.new # Maps source code line in sym_tab to lines with no entry in order to concat and replace

objdump = `objdump -d #{filename}` # Objdump of entire file, including external libs
objdump_file = "" # Objdump of file only

sym_tab_all = `llvm-dwarfdump --debug-line #{filename}` # Symbol table for everything the file uses and the file itself
sym_tab_file = "" # Symbol table for the file
sym_dict = Hash.new # Initial dictionary created from sym_tab

dict_rev = Hash.new # Mapped assembly code to corresponding src, but in reverse
# Helps in building keys and values for continguous assembly code to corresponding src.
obj_code = ""
src_val = ""
key_indexer = "" 

dict_dup = Hash.new # Mapped assembly code to corresponding src, but some instructions are duplicate

dic_miss = Hash.new # Mapped assembly code to corresponding src, but with missing src lines
dict_final = Hash.new # Final dictionary with key being continguous assembly code for the file and value being
                     # its respective 


# Function to reverse a string to parse objdump better
def double_reverse(lines)
    str = ""
    lines.reverse!
    lines.each_line do |line|
        line.chomp!
        line.reverse!
        str = str + "\n"+ line
    end

    return str
end

##  EXTRACT SYMBOL TABLE FOR FILE AND GET ADDRESSES AND LINE NUMBERS
sym_tab_all.each_line do |l|
    line = l.strip # Remove whitespace to make parsing easier
    break if line == "name: \"#{rust_file}\""
    
    sym_tab_all.slice! line
end

    
sym_tab_all.each_line do |l|
    if l.strip != ""
       break if l.strip.start_with?("debug_line")
       sym_tab_file.concat("\n".concat(l.strip))
    
     end
end

 # Scans symbol table file
 sym_tab_file.each_line do |l|
    if l.start_with?("0")
        sym_tab << l.gsub(/\s+/m, ' ').strip.split(" ") 
    end
end

# Make addresses easier for parsing
sym_tab.each do |value|
    value[0].slice! "0x000000000000"
end

sym_tab.each do |row|
    addresses.push(row[0])
    line_nums.push(row[1].to_i)
end

## EXTRACT OBJDUMP FOR FILE
objdump.each_line do |l|
    line = l.strip
    break if line.start_with?(addresses[0])

    objdump.slice! line
end

objdump.each_line do |l|
    line = l.strip
    if line != ""

        objdump_file.concat("\n".concat(line))
        break if line.start_with?(addresses[-1])
        
    end

end

objdump_rev = double_reverse(objdump_file)

## BEGIN MAPPING ASSEMBLY TO CORRESPONDING SOURCE CODE
    # The idea is that we build an intial dictionary and have a series of passes that process and refine
    # it (or better parsing, taking care of all the cases, etc.) to a dictionary that is closer and closer to
    # finished form, until it is finished. 
sym_tab.each do | entry |
    address = entry[0]
    line_num = entry[1]
    flag = entry[6]

    if flag != ""
        sym_dict[address] = line_num
    end
end

# PASS 1: Initial mapping
objdump_rev.each_line do |l|
    line=l.strip
    address = line[0..3]

    obj_code =  line +"\n" + obj_code 

    if sym_dict.key?(address) 
        key = obj_code
        obj_code = ""
        line_num = sym_dict[address].to_i

        if line_num != 0
            src_val = src[line_num - 1]
            dict_rev[key] = src_val

        end
    end

end

# PASS 2: Combine assembly code blocks for source code that is contingous
keys = dict_rev.keys.reverse()
dict_rev.reverse_each.each_with_index do |(key,value), index|
    curr_val = value
    curr_key = key

    next_val = dict_rev[keys[index + 1]]
    next_key = keys[index + 1]

    if curr_val == next_val
        key_indexer = key_indexer + key + next_key

    end
    
    if curr_val != next_val
        key_indexer = key_indexer + curr_key;

        dict_dup[key_indexer] = curr_val
        key_indexer = ""
    end

end

# PASS 3: Delete duplicate instructions that formed as a result.
dict_dup.each do | k, v|
    key_str = k.split("\n")
    dic_miss[key_str.uniq] = v

end

# PASS 4: Include source code that do not have an entry in the symbol table.
src.each_with_index do | line, i |
    line_num = i + 1
    src_lines = src_lines + line

    if line_nums.include? line_num

        src_values[line] = src_lines
        src_lines = ""
    end
   
end
dic_miss.each do |k,v|
    old_val = v
    new_val = src_values[v]

    dict_final[k] = new_val
end

def count_occ dict 
    arr_count = Hash.new
    dict.each do |key, value|
        if !arr_count.key?(value)
            arr_count[value] = 1
        end
    end
    return arr_count
end

def parse_line line
    split_line = line.split(/\t| {2,}/)
    return split_line
end


#generate html by appending the corresponding tags as strings to the output file
def generate_html dict
    arr_count = count_occ dict
    file_name = "out.html"
    fileHtml = File.new(File.join(Dir.pwd, "/XREF", file_name), "w+")
    fileHtml.puts "<!doctype html>\n"
    fileHtml.puts "<html>\n"
    fileHtml.puts "<head>\n"
    fileHtml.puts "<meta charset = \"utf-8\">\n"
    #Adding styling from bootstrap
    fileHtml.puts "<link rel=\"stylesheet\" href=\"https://cdn.jsdelivr.net/npm/bootstrap@4.5.3/dist/css/bootstrap.min.css\" integrity=\"sha384-TX8t27EcRE3e/ihU7zmQxVncDAy5uIKz4rEkgIXeMed4M0jlfIDPvg6uqKI2xXr2\" crossorigin=\"anonymous\">"
    fileHtml.puts "<title>My site</title>"
    fileHtml.puts "</head>\n"
    fileHtml.puts "<body>\n"
    #adding  JQuery which is necessary to run bootstrap
    fileHtml.puts "<script src=\"https://code.jquery.com/jquery-3.5.1.slim.min.js\" integrity=\"sha384-DfXdz2htPH0lsSSs5nCTpuj/zy4C+OGpamoFVy38MVBnE+IbbVYUew+OrCXaRkfj\" crossorigin=\"anonymous\"></script>\n"
    #loop through the keys where each key is the object code and the value is the corresponding source code
    dict.each do |key, value|
        fileHtml.puts "<div class=\"container\">\n"
        fileHtml.puts "<div class=\"row border\">\n"
        fileHtml.puts "<ul class=\"container col-lg\">\n"
        #parse each line as <address instr_code instruction instruction_operands>
        key.each do |line|
            parsed_str = parse_line line
            if !line.eql?("\n")
                fileHtml.puts "<li class=\"row border\">\n"
                parsed_str.each do |component|
                    fileHtml.puts "<span>"
                    ##if the current component has the format of an address
                    if component[0..3].match(/[0-9a-f][0-9a-f][0-9a-f][0-9a-f]/) and component.length<=5
                        fileHtml.puts "<a name=\"address#{component[0..3]}\" href=\"#address#{component[0..3]}\">#{component}</a>\n"
                    #if it contains the format of an address but its length is greater than that of an address, then link it 
                    #to the corresponding address
                    elsif component[0..3].match(/[0-9a-f][0-9a-f][0-9a-f][0-9a-f]/) and component.length>5
                        fileHtml.puts "<a href=\"#address#{component[0..3]}\">#{component}</a>\n"
                    else
                        fileHtml.puts "#{component}"
                    end
                    fileHtml.puts "</span>\n"
                    fileHtml.puts "<span>&nbsp;&nbsp;</span>\n"
                
                end 
                fileHtml.puts "</li>\n"
            end
            
        end
        fileHtml.puts "</ul>\n"
        # fileHtml.puts "</div>\n"
        ##decrement the count by 1 when you first meet a src code line
        if arr_count[value]==1
            fileHtml.puts "<div class=\"border col-md\">#{value}</div>\n"
            arr_count[value] = 0
        #if the count is zero then gray out all other appearances 
        elsif arr_count[value]==0
            fileHtml.puts "<div class=\"border col-md text-info bg-light\">#{value}</div>\n"
        end
        fileHtml.puts "</div>\n"
        fileHtml.puts "</div>\n"
        fileHtml.puts "<span><br></span>"
    end
    
    fileHtml.puts "</body>"
    fileHtml.puts "</html>"
    fileHtml.close()
end 

generate_html dict_final


