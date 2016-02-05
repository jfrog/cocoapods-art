module Pod
  # Subclass of Pod::Source to provide support for Artifactory Specs repositories
  #
  class ArtSource < Source

    alias_method :old_url, :url

    # @param [String] repo The name of the repository
    #
    # @param [String] url see {#url}
    #
    def initialize(repo, url)
      super(repo)
      @source_url = url
    end

    # @return url of this repo
    def url
      if @source_url
        "#{@source_url}"
      else
        # after super(repo) repo is now the path to the repo
        File.read("#{repo}/.artpodrc") if File.exist?("#{dir}/.artpodrc")
      end
    end

  end
end
