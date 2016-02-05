module Pod
  class Command
    class RepoArt
      class Remove < RepoArt
        self.summary = 'Remove an Artifactory-backed Specs repo'

        self.description = <<-DESC
          Deletes the Spec repo called `NAME` from the local spec-repos directory at `~/.cocoapods/repos/.`
        DESC

        self.arguments = [
            CLAide::Argument.new('NAME', true),
        ]

        def initialize(argv)
          @cmd = Command::Repo::Remove.new(argv)
        end

        def validate!
          @cmd.validate!
        end

        def run
          @cmd.run
        end

        end
      end
    end
  end
