# Function to display error messages
function error {
    echo "Error: $1"
    exit 1
}

# Function to backup the current folder
function backup_folder {
    local date=$(date '+%Y-%m-%d-%H:%M:%S')

    local backup_folder="bak"
    # local parent_dir=$(dirname "$(pwd)")

    # local backup_dir="$parent_dir/$backup_folder/$date"
    local backup_dir="$backup_folder/$date"

    mkdir -p $backup_dir || error "Failed to create the backup directory"

    for file in *; do
      if [ "$file" != "$backup_dir" ] && [ "$file" != "backup_and_build.sh" ] && [ "$file" != "Web.config" ]; then
        mv "$file" "$backup_dir"
      fi
    done

    echo "Backup created successfully."
}

# Function to pull changes and build the application
function pull_and_build {
    local branch_name="$1"

    git checkout "$branch_name" || error "Failed to switch to $branch_name branch"
    git pull origin "$branch_name" || error "Failed to pull changes from $branch_name branch"
    
    # Assuming you use npm for building the React project
    npm install || error "Failed to install npm packages"
    npm run build || error "Failed to build the application"

    for file in *; do
      if [ "$file" != "bak" ] && [ "$file" != "backup_and_build.sh" ] && [ "$file" != "Web.config" ] && [ "$file" != "build" ]; then
        if [ -d "$file" ]; then
          rm -r "$file" || error "Failed to delete the directory: $file"
        else
          rm "$file" || error "Failed to delete the file: $file"
        fi
      fi
    done
}

# Main script

# Ask the user for the branch they want to update
read -p "Which branch would you like to pull and build? (development/staging/production): " branch_name

git fetch || error "Failed to fetch changes from the remote repository"

# Check if the current branch is tracking a remote branch
if [ -n "$(git ls-remote --exit-code origin "$branch_name")" ]; then
  # Compare the local and remote branches to check for any differences
  git fetch
  if git diff HEAD..origin/"$branch_name" --exit-code; then
    echo "No changes in the remote repository."
    exit 1
  else
    # Backup the current folder
    backup_folder

    git stash
    git stash clear

    # Update the chosen branch
    pull_and_build "$branch_name"
  fi
else
  echo "The current branch is not tracking a remote branch. Please configure tracking."
  exit 1
fi

echo "Update process completed successfully."
