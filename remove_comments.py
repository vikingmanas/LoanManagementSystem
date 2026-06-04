import os
import re

def strip_comments(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Matches lines that start with any whitespace, followed by //, but NOT ///
    # It removes the entire line.
    new_content = re.sub(r'^[ \t]*//(?!/).*$\n?', '', content, flags=re.MULTILINE)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Cleaned {file_path}")

def main():
    root_dir = "/Users/apple/Desktop/LoanManagementSystem/LoanManagementSystem"
    count = 0
    for subdir, _, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.swift'):
                strip_comments(os.path.join(subdir, file))
                count += 1
    print(f"Processed {count} Swift files.")

if __name__ == '__main__':
    main()
