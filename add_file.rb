require 'xcodeproj'

project_path = 'LoanManagementSystem.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Path to the group in Xcode. Sometimes the first element is the root group.
# Our main group might be named LoanManagementSystem.
group = project.main_group.find_subpath('LoanManagementSystem/Core/Modifiers', true)
file_ref = group.files.find { |f| f.path == 'AccessibilityModifier.swift' } || group.new_file('AccessibilityModifier.swift')

if !target.source_build_phase.files.any? { |build_file| build_file.file_ref && build_file.file_ref.path == file_ref.path }
  target.source_build_phase.add_file_reference(file_ref)
  puts "File added to build phase"
end

project.save
puts "Project saved."
