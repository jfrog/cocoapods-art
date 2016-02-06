module Pod
  class Command
    class RepoArt
      class Remove < RepoArt
        self.summary = 'Remove an Artifactory-backed Specs repo'

        self.description = <<-DESC
          Deletes the Spec repo called 'NAME' from the local spec-repos directory at '~/.cocoapods/repos/.'
        DESC

        self.arguments = [
            CLAide::Argument.new('NAME', true)
        ]

        def initialize(argv)
          @name = argv.shift_argument
          @cmd = Command::Repo::Remove.new(argv)
          super
        end

        def validate!
          super
          unless @name
            help! 'This command requires a repo name.'
          end
          @cmd.validate!
        end

        def run
          @cmd.run
        end

        end
      end
    end
  end
