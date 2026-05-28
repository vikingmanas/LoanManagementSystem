require 'xcodeproj'
project_path = 'LoanManagementSystem.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Add files to the Views group (or just the main group)
group = project.main_group.find_subpath(File.join('LoanManagementSystem', 'LoanOfficer', 'Views'), true)

file1_path = 'LoanManagementSystem/LoanOfficer/Views/LoanOfficerPipelineDetailsSheet.swift'
file2_path = 'LoanManagementSystem/LoanOfficer/Views/OfficerApplicationListSheet.swift'

# Check if they exist in the project already
unless group.files.find { |f| f.path == file1_path }
  file1_ref = group.new_reference(file1_path)
  target.add_file_references([file1_ref])
  puts "Added LoanOfficerPipelineDetailsSheet"
end

unless group.files.find { |f| f.path == file2_path }
  file2_ref = group.new_reference(file2_path)
  target.add_file_references([file2_ref])
  puts "Added OfficerApplicationListSheet"
end

project.save
puts "Saved."
