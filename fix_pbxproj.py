import re

file_path = 'LoanManagementSystem.xcodeproj/project.pbxproj'
with open(file_path, 'r') as f:
    lines = f.readlines()

# IDs of the removed products
removed_ids = [
    'ADADD4972FC025D10072F8EF', # Auth product dependency
    'ADADD4982FC025D10072F8EF', # Auth in Frameworks
    'ADADD4992FC025D10072F8EF', # Functions product dependency
    'ADADD49A2FC025D10072F8EF', # Functions in Frameworks
    'ADADD49B2FC025D10072F8EF', # PostgREST product dependency
    'ADADD49C2FC025D10072F8EF', # PostgREST in Frameworks
    'ADADD49D2FC025D10072F8EF', # Realtime product dependency
    'ADADD49E2FC025D10072F8EF', # Realtime in Frameworks
    'ADADD49F2FC025D10072F8EF', # Storage product dependency
    'ADADD4A02FC025D10072F8EF', # Storage in Frameworks
]

new_lines = []
skip_next = 0
for i, line in enumerate(lines):
    if skip_next > 0:
        skip_next -= 1
        continue
    
    # Check if the line is defining one of the removed XCSwiftPackageProductDependency or PBXBuildFile objects
    match = re.search(r'([A-Z0-9]{24}) /\* .*? \*/ = \{', line)
    if match and match.group(1) in removed_ids:
        # These are usually 4 or 5 lines long block, we can just skip until '};'
        skip = True
        j = i
        while skip:
            if '};' in lines[j]:
                skip = False
            j += 1
        skip_next = j - i - 1
        continue
    
    # Check if the line is just a reference in a list (like in PBXFrameworksBuildPhase or target package dependencies)
    if any(rid in line for rid in removed_ids):
        continue
        
    new_lines.append(line)

with open(file_path, 'w') as f:
    f.writelines(new_lines)

print("Fixed project.pbxproj")
