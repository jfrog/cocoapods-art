require 'fileutils'

module Pod
  class RepoArt
    class RepoUtil

      # @return whether a source is an Artifactory backed repo.
      #
      # @param  [Pathname] repo_root_path root directory of the repo.
      #
      def self.art_repo?(repo_root_path)
        true if File.exist?("#{repo_root_path}/.artpodrc")
      end

      # @return the url of this Artifactory repo which is stored in the .artpodrc file in it's root
      #
      # @param  [Pathname] repo_root_path root directory of the repo.
      #
      def self.get_art_url(repo_root_path)
        File.read("#{repo_root_path}/.artpodrc")
      end

      # @return if the .artpodrc file exists in the given dir
      #
      # @param  [Pathname] dir root directory of the repo.
      #
      def self.artpodrc_file_exists(dir)
        File.exist?("#{dir}/.artpodrc")
      end

    end
  end
end

