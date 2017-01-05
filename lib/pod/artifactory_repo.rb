module Pod
  class ArtifactoryRepo
    def initialize(path, url)
      @path = path
      @url = url
      create_name
    end

    def create_name
      split = @path.split("/")
      if split.length > 0
        @name = split[split.length - 1]
      end
    end

    attr_reader :name
    attr_reader :path
    attr_reader :url
  end
end


