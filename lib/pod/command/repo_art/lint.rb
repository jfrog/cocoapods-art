module Pod
  class Command
    class RepoArt
      class Lint < RepoArt
        self.summary = 'Validates all specs in a repo.'

        self.description = <<-DESC
          Lints the spec-repo `NAME`. If a directory is provided it is assumed
          to be the root of a repo. Finally, if `NAME` is not provided this
          will lint all the spec-repos known to CocoaPods, including all Artifactory-backed repos.
        DESC

        self.arguments = [
            CLAide::Argument.new(%w(NAME DIRECTORY), true)
        ]

        def self.options
          [
              ['--only-errors', 'Lint presents only the errors']
          ].concat(super)
        end

        def initialize(argv)
          @cmd = Pod::Command::Repo::Lint.new(argv)
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
