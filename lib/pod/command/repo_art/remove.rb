module Pod
  class Command
    class RepoArt
      class Remove < RepoArt
        self.summary = 'Remove an Artifactory-backed Specs repo'

        self.description = <<-DESC
          Deletes the Spec repo called 'NAME' from the local spec-repos directory at '~/.cocoapods/repos-art/.'
        DESC

        self.arguments = [
            CLAide::Argument.new('NAME', true)
        ]

        def initialize(argv)
          init
          @name = argv.shift_argument
          super
        end

        def validate!
          super
          help! 'Deleting a repo needs a `NAME`.' unless @name
          help! "repo #{@name} does not exist" unless File.directory?(repo_dir_root)
          help! "You do not have permission to delete the #{@name} repository." \
                'Perhaps try prefixing this command with sudo.' unless File.writable?(repo_dir_root)
        end

        def run
          UI.section("Removing spec repo `#{@name}`") do
            FileUtils.rm_rf(repo_dir_root)
          end
        end

        def repo_dir_root
          "#{@repos_art_dir}/#{@name}"
        end
      end
    end
  end
end
